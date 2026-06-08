@echo off
REM J&Y Audio - Driver Installation Script
REM Must run as Administrator

echo [%DATE% %TIME%] Starting driver installation >> "%TEMP%\jyaudio_install.log"

set "APPDIR=%~1"
if "%APPDIR%"=="" (
    echo [%DATE% %TIME%] ERROR: No APPDIR parameter >> "%TEMP%\jyaudio_install.log"
    exit /b 1
)

echo [%DATE% %TIME%] APPDIR=%APPDIR% >> "%TEMP%\jyaudio_install.log"

REM Detect Windows version
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
echo [%DATE% %TIME%] Windows version: %VERSION% >> "%TEMP%\jyaudio_install.log"

REM Select correct driver directory
if "%VERSION%"=="10.0" (
    set "DRIVERDIR=%APPDIR%\Drivers\win10\x64"
) else (
    set "DRIVERDIR=%APPDIR%\Drivers\win7\x64"
)

set "DEVCON=%DRIVERDIR%\fxdevcon64.exe"
set "INF=%DRIVERDIR%\fxvad.inf"
set "DFXSETUP=%APPDIR%\Apps\DfxSetupDrv.exe"
set "ENABLEPS=%APPDIR%\enable_driver.ps1"

echo [%DATE% %TIME%] DEVCON=%DEVCON% >> "%TEMP%\jyaudio_install.log"
echo [%DATE% %TIME%] INF=%INF% >> "%TEMP%\jyaudio_install.log"
echo [%DATE% %TIME%] DFXSETUP=%DFXSETUP% >> "%TEMP%\jyaudio_install.log"

REM Check if files exist
if not exist "%DEVCON%" (
    echo [%DATE% %TIME%] ERROR: fxdevcon64.exe not found >> "%TEMP%\jyaudio_install.log"
    exit /b 1
)
if not exist "%INF%" (
    echo [%DATE% %TIME%] ERROR: fxvad.inf not found >> "%TEMP%\jyaudio_install.log"
    exit /b 1
)
if not exist "%DFXSETUP%" (
    echo [%DATE% %TIME%] ERROR: DfxSetupDrv.exe not found >> "%TEMP%\jyaudio_install.log"
    exit /b 1
)

echo [%DATE% %TIME%] All files found, proceeding with installation >> "%TEMP%\jyaudio_install.log"

REM Step 1: Check if old driver exists and remove it
echo [%DATE% %TIME%] Step 1: Checking for old driver... >> "%TEMP%\jyaudio_install.log"
"%DFXSETUP%" check >> "%TEMP%\jyaudio_install.log" 2>&1
if %errorLevel% equ 0 (
    echo [%DATE% %TIME%] Old driver found, removing... >> "%TEMP%\jyaudio_install.log"
    "%DEVCON%" remove *DFX12 >> "%TEMP%\jyaudio_install.log" 2>&1
    timeout /t 2 /nobreak >nul
)

REM Step 2: Install new driver using fxdevcon64.exe
echo [%DATE% %TIME%] Step 2: Installing driver... >> "%TEMP%\jyaudio_install.log"
"%DEVCON%" install "%INF%" >> "%TEMP%\jyaudio_install.log" 2>&1
if %errorLevel% neq 0 (
    echo [%DATE% %TIME%] ERROR: Driver installation failed with code %errorLevel% >> "%TEMP%\jyaudio_install.log"
    exit /b 1
)
echo [%DATE% %TIME%] Driver installed, waiting for device to appear... >> "%TEMP%\jyaudio_install.log"
timeout /t 5 /nobreak >nul

REM Step 3: ENABLE the audio device (Windows may leave virtual audio devices disabled)
echo [%DATE% %TIME%] Step 3: Enabling J&Y Audio Enhancer device... >> "%TEMP%\jyaudio_install.log"
if exist "%ENABLEPS%" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENABLEPS%" >> "%TEMP%\jyaudio_install.log" 2>&1
) else (
    echo [%DATE% %TIME%] WARNING: enable_driver.ps1 not found, skipping enable step >> "%TEMP%\jyaudio_install.log"
)
timeout /t 2 /nobreak >nul

REM Step 4: Get driver GUID and write to registry
echo [%DATE% %TIME%] Step 4: Getting driver GUID... >> "%TEMP%\jyaudio_install.log"
"%DFXSETUP%" getguid >> "%TEMP%\jyaudio_install.log" 2>&1

REM Step 5: Set driver name
echo [%DATE% %TIME%] Step 5: Setting driver name... >> "%TEMP%\jyaudio_install.log"
"%DFXSETUP%" setname >> "%TEMP%\jyaudio_install.log" 2>&1

REM Step 6: Set default buffer size
echo [%DATE% %TIME%] Step 6: Setting buffer size... >> "%TEMP%\jyaudio_install.log"
"%DFXSETUP%" defaultbuffersize >> "%TEMP%\jyaudio_install.log" 2>&1

REM Step 7: Prevent system sleep from disrupting audio processing
echo [%DATE% %TIME%] Step 7: Configuring power override... >> "%TEMP%\jyaudio_install.log"
powercfg -REQUESTSOVERRIDE DRIVER "J&Y Audio Enhancer" SYSTEM >> "%TEMP%\jyaudio_install.log" 2>&1

echo [%DATE% %TIME%] Driver installation completed successfully >> "%TEMP%\jyaudio_install.log"
exit /b 0
