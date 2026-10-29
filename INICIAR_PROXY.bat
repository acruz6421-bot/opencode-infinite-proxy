@echo off
setlocal EnableExtensions EnableDelayedExpansion
title OpenCode Zen Proxy Infinite (Auto-Rotate WARP)

cd /d "%~dp0"

echo ====================================================================
echo    OpenCode Zen Proxy Infinite - Cota Infinita + Auto-Rotate WARP
echo ====================================================================
echo.

REM --- 1. Verificar Cloudflare WARP ---
set "WARP_CLI="
if exist "%ProgramFiles%\Cloudflare\Cloudflare WARP\warp-cli.exe" set "WARP_CLI=%ProgramFiles%\Cloudflare\Cloudflare WARP\warp-cli.exe"
if not defined WARP_CLI if exist "%LOCALAPPDATA%\Cloudflare\Cloudflare WARP\warp-cli.exe" set "WARP_CLI=%LOCALAPPDATA%\Cloudflare\Cloudflare WARP\warp-cli.exe"
if not defined WARP_CLI (
    for /f "delims=" %%w in ('where warp-cli.exe 2^>nul') do if not defined WARP_CLI set "WARP_CLI=%%w"
)

if not defined WARP_CLI (
    echo [!] Cloudflare WARP nao encontrado no sistema!
    echo     O WARP e obrigatorio para fazer a rotacao automatica de IP sem afetar sua internet.
    echo.
    choice /c SN /n /m "Deseja baixar e instalar o Cloudflare WARP automaticamente agora? [S/N]: "
    if errorlevel 2 (
        echo Instale manualmente em https://1.1.1.1 e abra este arquivo novamente.
        pause
        exit /b 1
    )
    echo Baixando instalador oficial do Cloudflare WARP...
    curl.exe -L -f -s --max-time 600 -o "%TEMP%\Cloudflare_WARP_x64.msi" "https://downloads.cloudflareclient.com/v1/download/windows/ga"
    echo Instalando WARP ^(aceite a confirmacao de Administrador se aparecer^)...
    powershell -NoProfile -Command "Start-Process msiexec.exe -ArgumentList '/i','%TEMP%\Cloudflare_WARP_x64.msi','/qn' -Verb RunAs -Wait"
    if exist "%ProgramFiles%\Cloudflare\Cloudflare WARP\warp-cli.exe" set "WARP_CLI=%ProgramFiles%\Cloudflare\Cloudflare WARP\warp-cli.exe"
    if not defined WARP_CLI (
        echo [!] Nao foi possivel localizar o WARP apos a instalacao. Instale de https://1.1.1.1
        pause
        exit /b 1
    )
)

REM --- 2. Verificar Chave do WARP (warp-key.txt) ---
set "USER_KEY="
if exist "warp-key.txt" (
    set /p USER_KEY=<"warp-key.txt"
)
if "!USER_KEY!"=="SUA_KEY_AQUI" set "USER_KEY="

if not defined USER_KEY (
    echo --------------------------------------------------------------------
    echo  CONFIGURACAO INICIAL DA CHAVE CLOUDFLARE WARP
    echo --------------------------------------------------------------------
    echo  Para que a rotacao de IP funcione de forma estavel, voce precisa
    echo  informar uma Chave de Licenca do Cloudflare WARP ^(pode ser uma
    echo  chave GRATUITA do app 1.1.1.1 ou uma chave WARP+ Unlimited^).
    echo.
    echo  Como pegar no celular ^(App 1.1.1.1^):
    echo    Configuracoes ^> Conta ^> Chave ^(ex: xxxxxxxx-xxxxxxxx-xxxxxxxx^)
    echo --------------------------------------------------------------------
    echo.
    set /p USER_KEY="Cole sua Chave do WARP aqui e aperte ENTER: "
    if defined USER_KEY (
        >"warp-key.txt" echo !USER_KEY!
        echo [OK] Chave salva em warp-key.txt!
    ) else (
        echo [!] Nenhuma chave informada. Registrando sessao gratuita padrao do WARP...
        "%WARP_CLI%" --accept-tos registration new >nul 2>&1
    )
)

REM --- 3. Ativar modo Proxy Isolado na porta 40000 ---
echo [1/3] Ativando WARP em modo Proxy Local ^(porta 40000 - nao altera a rede do PC^)...
"%WARP_CLI%" --accept-tos mode proxy >nul 2>&1
"%WARP_CLI%" mode proxy >nul 2>&1
if defined USER_KEY (
    "%WARP_CLI%" --accept-tos registration license !USER_KEY! >nul 2>&1
    "%WARP_CLI%" registration license !USER_KEY! >nul 2>&1
)
"%WARP_CLI%" --accept-tos connect >nul 2>&1
"%WARP_CLI%" connect >nul 2>&1

REM --- 4. Verificar Bun Runtime ---
echo [2/3] Verificando runtime Bun...
where bun >nul 2>&1
if errorlevel 1 (
    if exist "%USERPROFILE%\.bun\bin\bun.exe" (
        set "PATH=%PATH%;%USERPROFILE%\.bun\bin"
    ) else (
        echo [!] Bun nao encontrado. Instalando Bun automaticamente...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "irm bun.sh/install.ps1 | iex"
        set "PATH=%PATH%;%USERPROFILE%\.bun\bin"
    )
)

where bun >nul 2>&1
if errorlevel 1 (
    echo [!] Erro ao localizar o Bun. Feche e abra esta janela novamente.
    pause
    exit /b 1
)

set "HTTP_PROXY=http://127.0.0.1:40000"
set "HTTPS_PROXY=http://127.0.0.1:40000"
set "NO_PROXY=localhost,127.0.0.1,0.0.0.0"

echo [3/3] Iniciando Servidor Proxy na porta 8787...
echo.
echo  ====================================================================
echo   SERVIDOR PRONTO! MANTENHA ESTA JANELA ABERTA ^(PODE MINIMIZAR^)
echo  ====================================================================
echo   Painel Web / Dashboard:   http://127.0.0.1:8787/
echo   Base URL OpenAI:          http://127.0.0.1:8787/v1
echo   Base URL Anthropic:       http://127.0.0.1:8787/v1
echo   API Key ^(qualquer uma^):   public
echo  ====================================================================
echo.

bun zen-proxy.mjs

pause
