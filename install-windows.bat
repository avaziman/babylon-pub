@echo off
setlocal enableextensions enabledelayedexpansion

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: 1. Ensure Chocolatey is installed (requires admin if not installed)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

where choco >nul 2>&1
if %errorlevel% neq 0 (
    echo Chocolatey not found. Installing Chocolatey requires administrative privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -Verb RunAs -FilePath '%~dpnx0' -ArgumentList 'choco_install'"
    exit /b
)

set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

if "%1"=="choco_install" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& {if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))}}"
    exit /b
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: 2. Check if WSL is enabled; if not, request admin and install it
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

powershell -NoProfile -ExecutionPolicy Bypass -Command "& {
    $wslState = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State;
    if ($wslState -ne 'Enabled') {
        Write-Host 'WSL not enabled. Elevating for installation...';
        Start-Process -Verb RunAs -FilePath '%~dpnx0' -ArgumentList 'install_wsl';
        exit;
    } else {
        Write-Host 'WSL is already enabled.';
    }
}"

if "%1"=="install_wsl" (
    echo Enabling WSL and installing WSL2...
    choco install wsl2 --yes
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart; Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart"
    echo WSL2 installation triggered. A restart may be required.
    exit /b
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: 3. Check if Ubuntu is installed in WSL; if not, install it
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

powershell -NoProfile -ExecutionPolicy Bypass -Command "& {
    $installedDistros = wsl -l -q;
    if ($installedDistros -notcontains 'Ubuntu') {
        Write-Host 'Installing Ubuntu...';
        wsl --install -d Ubuntu;
        Write-Host 'Ubuntu installation triggered.';
    } else {
        Write-Host 'Ubuntu is already installed in WSL.';
    }
}"

:: Give WSL a few seconds to finalize installation
timeout /t 10 > nul

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: 4. Run the shell script inside WSL
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

powershell -NoProfile -ExecutionPolicy Bypass -Command "& {
    if (-not (Test-Path 'docker-compose.yml')) {
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/avaziman/babylon-pub/refs/heads/main/docker-compose.yml' -OutFile 'docker-compose.yml';
        Write-Host 'docker-compose.yml downloaded successfully.';
    }
}"

powershell -NoProfile -ExecutionPolicy Bypass -Command "& {
    if (-not (Test-Path 'install-ubuntu.bash')) {
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/avaziman/babylon-pub/refs/heads/main/install-ubuntu.bash' -OutFile 'install-ubuntu.bash';
    }
}"

:: Execute the install-ubuntu.sh script using WSL
wsl -d Ubuntu --user root bash ./install-ubuntu.bash

echo "Opening application in the default browser (port 8080)..."
start http://localhost:8080

echo.
echo Script finished. If WSL, VirtualMachinePlatform, or Ubuntu was just installed,
echo you may need to reboot or open a new Terminal/WSL session.
echo.

exit /b 0

