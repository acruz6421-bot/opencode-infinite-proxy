@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Trocar Chave do Cloudflare WARP

cd /d "%~dp0"

echo ====================================================================
echo    ALTERAR CHAVE DE LICENCA DO CLOUDFLARE WARP
echo ====================================================================
echo.
if exist "warp-key.txt" (
    set /p ATUAL=<"warp-key.txt"
    echo Chave atual configurada: !ATUAL!
    echo.
)

set /p NOVA_KEY="Digite ou cole a nova Chave do WARP ^(gratuita ou Unlimited^): "
if not defined NOVA_KEY (
    echo Operacao cancelada.
    pause
    exit /b 0
)

>"warp-key.txt" echo !NOVA_KEY!
echo.
echo [OK] Nova chave salva em warp-key.txt!

set "WARP_CLI="
if exist "%ProgramFiles%\Cloudflare\Cloudflare WARP\warp-cli.exe" set "WARP_CLI=%ProgramFiles%\Cloudflare\Cloudflare WARP\warp-cli.exe"
if not defined WARP_CLI if exist "%LOCALAPPDATA%\Cloudflare\Cloudflare WARP\warp-cli.exe" set "WARP_CLI=%LOCALAPPDATA%\Cloudflare\Cloudflare WARP\warp-cli.exe"

if defined WARP_CLI (
    echo Aplicando chave no Cloudflare WARP...
    "%WARP_CLI%" --accept-tos registration license !NOVA_KEY! >nul 2>&1
    "%WARP_CLI%" registration license !NOVA_KEY! >nul 2>&1
    echo [OK] Chave aplicada com sucesso no cliente WARP!
)

echo.
pause
