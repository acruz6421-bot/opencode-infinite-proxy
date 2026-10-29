import { exec } from "node:child_process";
import { promisify } from "node:util";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const execAsync = promisify(exec);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const WARP_CLI = process.env.WARP_CLI || "\"C:/Program Files/Cloudflare/Cloudflare WARP/warp-cli.exe\"";
const WARP_PROXY = process.env.WARP_PROXY || "http://127.0.0.1:40000";
const KEY_FILE = path.join(__dirname, "warp-key.txt");

export function getWarpLicense() {
  if (process.env.WARP_LICENSE && process.env.WARP_LICENSE.trim()) {
    return process.env.WARP_LICENSE.trim();
  }
  try {
    if (fs.existsSync(KEY_FILE)) {
      const k = fs.readFileSync(KEY_FILE, "utf8").trim();
      if (k && !k.startsWith("#") && k !== "SUA_KEY_AQUI") return k;
    }
  } catch {}
  return "";
}

let isRotating = false;
let rotationPromise = null;
let lastRotationAt = 0;
let lastKnownIp = "";

export async function getCurrentIp() {
  try {
    const res = await fetch("https://www.cloudflare.com/cdn-cgi/trace", {
      proxy: WARP_PROXY,
      signal: AbortSignal.timeout(5000)
    });
    const text = await res.text();
    const ipLine = text.split("\n").find(l => l.startsWith("ip="));
    const warpLine = text.split("\n").find(l => l.startsWith("warp="));
    const ip = ipLine ? ipLine.replace("ip=", "").trim() : "unknown";
    const warp = warpLine ? warpLine.replace("warp=", "").trim() : "unknown";
    lastKnownIp = ip;
    return { ip, warp };
  } catch (err) {
    return { ip: "error", warp: "off", error: err.message };
  }
}

export async function ensureWarpReady() {
  const license = getWarpLicense();
  try {
    console.log("[warp-rotator] Verificando status do proxy WARP...");
    const check = await getCurrentIp();
    if (check.ip !== "error" && check.ip !== "unknown") {
      console.log(`[warp-rotator] ✅ WARP proxy online. IP de saida: ${check.ip} (warp=${check.warp})`);
      return check;
    }
  } catch {}

  console.log("[warp-rotator] Iniciando WARP em modo proxy local (porta 40000)...");
  try {
    await execAsync(`${WARP_CLI} --accept-tos mode proxy`).catch(() => execAsync(`${WARP_CLI} mode proxy`));
    if (license) {
      await execAsync(`${WARP_CLI} --accept-tos registration license ${license}`).catch(() => {});
    }
    await execAsync(`${WARP_CLI} --accept-tos connect`).catch(() => execAsync(`${WARP_CLI} connect`));
    await new Promise(r => setTimeout(r, 2500));
    const checkAfter = await getCurrentIp();
    console.log(`[warp-rotator] ✅ WARP inicializado. IP de saida: ${checkAfter.ip} (warp=${checkAfter.warp})`);
    return checkAfter;
  } catch (err) {
    console.error("[warp-rotator] 🔴 Falha ao iniciar WARP:", err.message);
    throw err;
  }
}

export async function rotateWarp(reason = "quota") {
  if (isRotating && rotationPromise) {
    console.log(`[warp-rotator] ⏳ Aguardando rotacao em andamento...`);
    return rotationPromise;
  }

  const now = Date.now();
  if (now - lastRotationAt < 3000) {
    console.log(`[warp-rotator] Cooldown ativo (${now - lastRotationAt}ms). Pulando ciclo redundante.`);
    return { ok: true, ip: lastKnownIp, skipped: true };
  }

  isRotating = true;
  lastRotationAt = now;

  rotationPromise = (async () => {
    const start = Date.now();
    const license = getWarpLicense();
    const oldIp = lastKnownIp || (await getCurrentIp()).ip;
    console.log(`[warp-rotator] 🔄 Limite atingido (${reason}). IP atual: ${oldIp}`);

    try {
      await execAsync(`${WARP_CLI} disconnect`);
      await new Promise(r => setTimeout(r, 1200));
      await execAsync(`${WARP_CLI} connect`);
      await new Promise(r => setTimeout(r, 2000));

      let newInfo = await getCurrentIp();
      let tries = 0;

      while (newInfo.ip === oldIp && tries < 2) {
        tries++;
        console.log(`[warp-rotator] IP mantido (${newInfo.ip}), recriando sessao WARP [tentativa ${tries}]...`);
        try {
          await execAsync(`${WARP_CLI} disconnect`).catch(() => {});
          await execAsync(`${WARP_CLI} --accept-tos registration new`).catch(() => execAsync(`${WARP_CLI} registration new`));
          await new Promise(r => setTimeout(r, 1000));
          if (license) {
            await execAsync(`${WARP_CLI} --accept-tos registration license ${license}`).catch(() => execAsync(`${WARP_CLI} registration license ${license}`));
            await new Promise(r => setTimeout(r, 1000));
          }
          await execAsync(`${WARP_CLI} --accept-tos mode proxy`).catch(() => execAsync(`${WARP_CLI} mode proxy`));
          await execAsync(`${WARP_CLI} --accept-tos connect`).catch(() => execAsync(`${WARP_CLI} connect`));
          await new Promise(r => setTimeout(r, 2000));
        } catch (subErr) {
          console.error("[warp-rotator] Erro ao re-registrar:", subErr.message);
        }
        newInfo = await getCurrentIp();
      }

      const elapsed = Date.now() - start;
      console.log(`[warp-rotator] ✅ IP rotacionado em ${elapsed}ms: ${oldIp} ➔ ${newInfo.ip} (warp=${newInfo.warp})`);
      return { ok: true, oldIp, newIp: newInfo.ip, warp: newInfo.warp, elapsedMs: elapsed };
    } catch (err) {
      console.error("[warp-rotator] 🔴 Falha na rotacao:", err.message);
      return { ok: false, error: err.message };
    } finally {
      isRotating = false;
      rotationPromise = null;
    }
  })();

  return rotationPromise;
}
