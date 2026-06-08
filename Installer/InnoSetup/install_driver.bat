@echo off
REM J&Y Audio - Driver Installation Script
REM Must run as Administrator

echo [%DATE% %TIME%] Starting driver installation >> "%TEMP%\jyaudio_install.log"

REM Get the directory where this batch file lives (app root)
set "APPDIR=%~dp0"
if "%APPDIR:~-1%"=="\" set "APPDIR=%APPDIR:~0,-1%"

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

set "INF=%DRIVERDIR%\fxvad.inf"
set "DFXSETUP=%APPDIR%\Apps\DfxSetupDrv.exe"
set "DEVCON=%DRIVERDIR%\fxdevcon64.exe"
set "ENABLEPS=%APPDIR%\enable_driver.ps1"

echo [%DATE% %TIME%] INF=%INF% >> "%TEMP%\jyaudio_install.log"
echo [%DATE% %TIME%] DFXSETUP=%DFXSETUP% >> "%TEMP%\jyaudio_install.log"

REM Check if INF exists
if not exist "%INF%" (
    echo [%DATE% %TIME%] ERROR: fxvad.inf not found >> "%TEMP%\jyaudio_install.log"
    exit /b 1
)
if not exist "%DFXSETUP%" (
    echo [%DATE% %TIME%] ERROR: DfxSetupDrv.exe not found >> "%TEMP%\jyaudio_install.log"
    exit /b 1
)

echo [%DATE% %TIME%] All files found, proceeding with installation >> "%TEMP%\jyaudio_install.log"

REM Step 1: Clean up any existing driver installations
REM    Try to remove old DFX12 (original FxSound driver)
REM    Also try to remove our FXVAD (from previous install attempts)
echo [%DATE% %TIME%] Step 1: Cleaning up old driver installations... >> "%TEMP%\jyaudio_install.log"

if exist "%DEVCON%" (
    "%DEVCON%" remove *DFX12 >> "%TEMP%\jyaudio_install.log" 2>&1
    "%DEVCON%" remove Root\FXVAD >> "%TEMP%\jyaudio_install.log" 2>&1
    timeout /t 2 /nobreak >nul
)

REM Also try pnputil to remove any leftover driver package
echo [%DATE% %TIME%] Checking for existing driver package... >> "%TEMP%\jyaudio_install.log"
pnputil /delete-driver fxvad.inf /uninstall /force >> "%TEMP%\jyaudio_install.log" 2>&1

REM Step 2: Install driver using pnputil (modern Windows driver install)
REM    This handles driver signing, catalog verification, and adds to driver store
echo [%DATE% %TIME%] Step 2: Installing driver via pnputil... >> "%TEMP%\jyaudio_install.log"
pnputil /add-driver "%INF%" /install >> "%TEMP%\jyaudio_install.log" 2>&1
set PNPERR=%errorLevel%

REM If pnputil failed, fall back to fxdevcon64
echo [%DATE% %TIME%] pnputil exit code: %PNPERR% >> "%TEMP%\jyaudio_install.log"

if %PNPERR% neq 0 (
    echo [%DATE% %TIME%] pnputil failed, trying fxdevcon64... >> "%TEMP%\jyaudio_install.log"
    if exist "%DEVCON%" (
        "%DEVCON%" install "%INF%" >> "%TEMP%\jyaudio_install.log" 2>&1
        if %errorLevel% neq 0 (
            echo [%DATE% %TIME%] ERROR: fxdevcon64 install also failed >> "%TEMP%\jyaudio_install.log"
            exit /b 1
        )
    ) else (
        echo [%DATE% %TIME%] ERROR: fxdevcon64.exe not found and pnputil failed >> "%TEMP%\jyaudio_install.log"
        exit /b 1
    )
)

echo [%DATE% %TIME%] Driver installed, waiting for device to appear... >> "%TEMP%\jyaudio_install.log"
timeout /t 5 /nobreak >nul

REM Step 3: Enable the audio device (Windows may leave it disabled)
echo [%DATE% %TIME%] Step 3: Enabling audio device... >> "%TEMP%\jyaudio_install.log"
if exist "%ENABLEPS%" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENABLEPS%" >> "%TEMP%\jyaudio_install.log" 2>&1
) else (
    echo [%DATE% %TIME%] WARNING: enable_driver.ps1 not found >> "%TEMP%\jyaudio_install.log"
)
timeout /t 2 /nobreak >nul

REM Step 4: Get driver GUID and write to registry
echo [%DATE% %TIME%] Step 4: Getting driver GUID... >> "%TEMP%\jyaudio_install.log"
"%DFXSETUP%" getguid >> "%TEMP%\jyaudio_install.log" 2>&1

REM Step 5: Set driver name (renames from "FxSound Audio Enhancer" to "J&Y Audio Enhancer")
echo [%DATE% %TIME%] Step 5: Setting driver name... >> "%TEMP%\jyaudio_install.log"
"%DFXSETUP%" setname >> "%TEMP%\jyaudio_install.log" 2>&1

REM Step 6: Set default buffer size
echo [%DATE% %TIME%] Step 6: Setting buffer size... >> "%TEMP%\jyaudio_install.log"
"%DFXSETUP%" defaultbuffersize >> "%TEMP%\jyaudio_install.log" 2>&1

REM Step 7: Prevent system sleep from disrupting audio processing
echo [%DATE% %TIME%] Step 7: Configuring power override... >> "%TEMP%\jyaudio_install.log"
powercfg -REQUESTSOVERRIDE DRIVER "J&Y Audio Enhancer" SYSTEM >> "%TEMP%\jyaudio_install.log" 2>&1

echo [%DATE% %TIME%] ======================================== >> "%TEMP%\jyaudio_install.log"
echo [%DATE% %TIME%] Driver installation completed >> "%TEMP%\jyaudio_install.log"
echo [%DATE% %TIME%] ======================================== >> "%TEMP%\jyaudio_install.log"
exit /b 0
