@echo off
chcp 65001 >nul
title LBP3 Bonsai Patch Installer
cd /d "%~dp0"
if "%~1"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-LBP3-Bonsai-Patch.ps1"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-LBP3-Bonsai-Patch.ps1" -PortDirArg "%~1"
)
echo.
pause
