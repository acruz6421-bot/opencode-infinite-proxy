# ⚡ OpenCode Infinite Proxy (Zen Free Models + Cloudflare WARP Auto-Rotate)

Servidor proxy reverso local (OpenAI + Anthropic compatible) que desbloqueia os **modelos gratuitos do OpenCode Zen** para qualquer agente de código (**Claude Code, Cursor, Cline, Roo Code, Continue, Aider, Hermes**) com **rotação automática de IP via Cloudflare WARP** quando a cota por IP atinge o limite (`429 FreeUsageLimitError`).

---

## 🔥 Como Funciona o Bypass de Cota (Zero Interrupção)

O gateway gratuito do OpenCode Zen aplica duas travas:
1. **Fingerprinting de Cliente e TLS:** Exige a pilha TLS do **Bun**, cabeçalhos internos do OpenCode CLI v2 (`x-opencode-client`, `x-opencode-session`, `x-opencode-project`), preâmbulo de sistema oficial e manifesto de ferramentas nativas.
2. **Limite de Cota por IP + Sessão:** A cota gratuita é contabilizada por IP de saída e par `session/project`.

### O que o **OpenCode Infinite Proxy** faz no próprio servidor:
- **Modo Proxy Isolado (`127.0.0.1:40000`):** Roda o Cloudflare WARP exclusivamente como um túnel SOCKS5/HTTP local. **Não altera o IP do seu Windows**, não derruba conexões, jogos, SSH ou downloads.
- **Interceptação de `429` em Voo:** Quando um modelo retorna `429 FreeUsageLimitError`:
  1. O proxy segura a requisição do seu agente;
  2. Aciona o `warp-rotator.mjs`, que gira o IP de saída no Cloudflare WARP em **~3 segundos**;
  3. Zera e recria os hashes criptográficos de `session` e `project`;
  4. Repete a chamada automaticamente e entrega a resposta ao agente sem erro.

---

## 🔑 Pré-requisito Obrigatório: Chave do Cloudflare WARP (Gratuita ou Paga)

Para que o rotacionador possa autenticar e girar o túnel do WARP de forma estável, **é necessário informar uma Chave de Licença do Cloudflare WARP** — pode ser tanto uma **chave gratuita** quanto uma chave **WARP+ Unlimited**.

### Como pegar sua chave (leva 1 minuto):
1. Instale o aplicativo **1.1.1.1: Faster Internet** no celular (Android / iOS) ou abra o Cloudflare WARP.
2. Vá em **Configurações (ícone de engrenagem) ➔ Conta (Account) ➔ Chave (Key)**.
3. Copie a chave no formato `xxxxxxxx-xxxxxxxx-xxxxxxxx`.

---

## 🚀 Como Usar no Windows (2 Cliques)

1. Baixe a pasta do repositório (ou o `.zip` na aba **Releases**).
2. Dê dois cliques em **`INICIAR_PROXY.bat`**.
3. Na primeira execução:
   - Se o **Cloudflare WARP** ou o runtime **Bun** não estiverem instalados, o próprio launcher baixa e instala automaticamente.
   - O terminal pedirá sua **Chave do WARP**. Cole a chave e pressione `Enter` (ela ficará salva localmente em `warp-key.txt`, ignorada pelo Git).
   - Para trocar de chave depois, basta abrir o **`TROCAR_KEY_WARP.bat`**.
4. Mantenha a janela aberta (pode minimizar).

---

## 🔌 Endpoints e Configuração nos Agentes

Com o proxy rodando na porta `8787`:

| Parâmetro | Valor |
|---|---|
| **Dashboard Web (Catálogo ao vivo)** | `http://127.0.0.1:8787/` |
| **OpenAI Base URL** | `http://127.0.0.1:8787/v1` |
| **Anthropic Base URL** | `http://127.0.0.1:8787/v1` |
| **API Key** | `public` *(ou qualquer texto)* |

### Modelos Gratuitos Suportados (atualizados automaticamente via auto-sync)
- `deepseek-v4.1-flash-free` *(Raciocínio + Tool Calling nativo)*
- `big-pickle` *(Modelo principal do OpenCode)*
- `glm-5.3-flash-free` *(Rápido e estável para código)*
- `nemotron-3.5-super-vl-free` *(Baixíssima latência + Visão)*
- `mimo-v2.6-flash-free`
- `nemotron-3.5-lightning-free`
- `flint-40b-free`
- `beam-free`

### Exemplo no Claude Code
```cmd
set ANTHROPIC_BASE_URL=http://127.0.0.1:8787
set ANTHROPIC_AUTH_TOKEN=public
claude --model deepseek-v4.1-flash-free
```

### Exemplo no Cline / Roo Code / Cursor / Continue
- **API Provider:** `OpenAI Compatible`
- **Base URL:** `http://127.0.0.1:8787/v1`
- **API Key:** `public`
- **Model:** `deepseek-v4.1-flash-free`

---

## 📄 Licença
MIT License.
