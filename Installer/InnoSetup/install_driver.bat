@echo off
setlocal enabledelayedexpansion
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
set "SUBLOG=%TEMP%\jyaudio_sub.log"

echo [%DATE% %TIME%] INF=%INF% >> "%TEMP%\jyaudio_install.log"
echo [%DATE% %TIME%] DFXSETUP=%DFXSETUP% >> "%TEMP%\jyaudio_install.log"

REM Check if files exist
if not exist "%INF%" (
    echo [%DATE% %TIME%] ERROR: fxvad.inf not found >> "%TEMP%\jyaudio_install.log"
    exit /b 1
)
if not exist "%DFXSETUP%" (
    echo [%DATE% %TIME%] ERROR: DfxSetupDrv.exe not found >> "%TEMP%\jyaudio_install.log"
    exit /b 1
)

echo [%DATE% %TIME%] All files found, proceeding with installation >> "%TEMP%\jyaudio_install.log"

REM ========================================================================
REM Step 0: Fix INF line endings (LF -> CRLF) for .cat signature match
REM ========================================================================
echo [%DATE% %TIME%] Step 0: Fixing INF line endings for .cat match... >> "%TEMP%\jyaudio_install.log"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENABLEPS%" -FixEOLPath "%INF%" >> "%TEMP%\jyaudio_install.log" 2>&1

REM ========================================================================
REM Step 1: Clean up any existing driver installations
REM ========================================================================
echo [%DATE% %TIME%] Step 1: Cleaning up old driver installations... >> "%TEMP%\jyaudio_install.log"

if exist "%DEVCON%" (
    start "" /wait cmd /c "\"%DEVCON%\" remove *DFX12 > \"%SUBLOG%\" 2>&1"
    type "%SUBLOG%" >> "%TEMP%\jyaudio_install.log"
    start "" /wait cmd /c "\"%DEVCON%\" remove Root\FXVAD > \"%SUBLOG%\" 2>&1"
    type "%SUBLOG%" >> "%TEMP%\jyaudio_install.log"
    timeout /t 2 /nobreak >nul
)

start "" /wait cmd /c "pnputil /delete-driver fxvad.inf /uninstall /force > \"%SUBLOG%\" 2>&1"
type "%SUBLOG%" >> "%TEMP%\jyaudio_install.log"

REM ========================================================================
REM Step 2: Install driver via fxdevcon (creates device node + installs driver)
REM
REM  KEY CHANGE: Use "start /wait cmd /c" to launch fxdevcon in a SEPARATE
REM  cmd.exe process. This avoids inheriting the hidden-console handles from
REM  Inno Setup's "runhidden" flag, which was causing UpdateDriverForPlugAndPlay
REM  to hang. The separate cmd.exe gets its own console environment, identical
REM  to running fxdevcon from an admin command prompt.
REM ========================================================================
echo [%DATE% %TIME%] Step 2: Installing driver via fxdevcon64... >> "%TEMP%\jyaudio_install.log"

if exist "%DEVCON%" (
    start "" /wait cmd /c "\"%DEVCON%\" install \"%INF%\" > \"%SUBLOG%\" 2>&1"
    set "DEVERR=!errorLevel!"
    type "%SUBLOG%" >> "%TEMP%\jyaudio_install.log"
    echo [%DATE% %TIME%] fxdevcon64 exit code: !DEVERR! >> "%TEMP%\jyaudio_install.log"
    if !DEVERR! neq 0 (
        echo [%DATE% %TIME%] fxdevcon64 failed, trying pnputil... >> "%TEMP%\jyaudio_install.log"
        start "" /wait cmd /c "pnputil /add-driver \"%INF%\" /install > \"%SUBLOG%\" 2>&1"
        set "PNPERR=!errorLevel!"
        type "%SUBLOG%" >> "%TEMP%\jyaudio_install.log"
        echo [%DATE% %TIME%] pnputil exit code: !PNPERR! >> "%TEMP%\jyaudio_install.log"
        if !PNPERR! neq 0 (
            echo [%DATE% %TIME%] ERROR: Both fxdevcon64 and pnputil failed >> "%TEMP%\jyaudio_install.log"
            del "%SUBLOG%" 2>nul
            exit /b 1
        )
        echo [%DATE% %TIME%] pnputil succeeded, scanning for new devices... >> "%TEMP%\jyaudio_install.log"
        start "" /wait cmd /c "pnputil /scan-devices > \"%SUBLOG%\" 2>&1"
        type "%SUBLOG%" >> "%TEMP%\jyaudio_install.log"
    )
) else (
    echo [%DATE% %TIME%] fxdevcon64.exe not found, trying pnputil... >> "%TEMP%\jyaudio_install.log"
    start "" /wait cmd /c "pnputil /add-driver \"%INF%\" /install > \"%SUBLOG%\" 2>&1"
    set "PNPERR=!errorLevel!"
    type "%SUBLOG%" >> "%TEMP%\jyaudio_install.log"
    echo [%DATE% %TIME%] pnputil exit code: !PNPERR! >> "%TEMP%\jyaudio_install.log"
    if !PNPERR! neq 0 (
        echo [%DATE% %TIME%] ERROR: pnputil failed >> "%TEMP%\jyaudio_install.log"
        del "%SUBLOG%" 2>nul
        exit /b 1
    )
    echo [%DATE% %TIME%] pnputil succeeded, scanning for new devices... >> "%TEMP%\jyaudio_install.log"
    start "" /wait cmd /c "pnputil /scan-devices > \"%SUBLOG%\" 2>&1"
    type "%SUBLOG%" >> "%TEMP%\jyaudio_install.log"
)

del "%SUBLOG%" 2>nul

echo [%DATE% %TIME%] Driver installed, waiting for device enumeration... >> "%TEMP%\jyaudio_install.log"
timeout /t 5 /nobreak >nul

REM ========================================================================
REM Step 3: Enable the audio device (Windows may leave it disabled)
REM ========================================================================
echo [%DATE% %TIME%] Step 3: Enabling audio device... >> "%TEMP%\jyaudio_install.log"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENABLEPS%" -EnableDevice >> "%TEMP%\jyaudio_install.log" 2>&1
timeout /t 2 /nobreak >nul

REM ========================================================================
REM Step 4-7: Get GUID, set name, set buffer, powercfg override
REM ========================================================================
echo [%DATE% %TIME%] Step 4: Getting driver GUID... >> "%TEMP%\jyaudio_install.log"
start "" /wait cmd /c "\"%DFXSETUP%\" getguid > \"%SUBLOG%\" 2>&1"
type "%SUBLOG%" >> "%TEMP%\jyaudio_install.log"

echo [%DATE% %TIME%] Step 5: Setting driver name... >> "%TEMP%\jyaudio_install.log"
start "" /wait cmd /c "\"%DFXSETUP%\" setname > \"%SUBLOG%\" 2>&1"
type "%SUBLOG%" >> "%TEMP%\jyaudio_install.log"

echo [%DATE% %TIME%] Step 6: Setting buffer size... >> "%TEMP%\jyaudio_install.log"
start "" /wait cmd /c "\"%DFXSETUP%\" defaultbuffersize > \"%SUBLOG%\" 2>&1"
type "%SUBLOG%" >> "%TEMP%\jyaudio_install.log"

echo [%DATE% %TIME%] Step 7: Configuring power override... >> "%TEMP%\jyaudio_install.log"
start "" /wait cmd /c "powercfg -REQUESTSOVERRIDE DRIVER \"J^&Y Audio Enhancer\" SYSTEM > \"%SUBLOG%\" 2>&1"
type "%SUBLOG%" >> "%TEMP%\jyaudio_install.log"

del "%SUBLOG%" 2>nul

echo [%DATE% %TIME%] ======================================== >> "%TEMP%\jyaudio_install.log"
echo [%DATE% %TIME%] Driver installation completed >> "%TEMP%\jyaudio_install.log"
echo [%DATE% %TIME%] ======================================== >> "%TEMP%\jyaudio_install.log"
exit /b 0
