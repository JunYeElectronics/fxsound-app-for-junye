@echo off
REM J&Y Audio - Driver Installation Script
REM Called by MSI installer after file copy
REM Must run as Administrator

set "APPDIR=%~1"
if "%APPDIR%"=="" exit /b 1

REM Detect Windows version and architecture
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%VERSION%"=="10.0" (
    set "DRIVERDIR=%APPDIR%\Drivers\win10\x64"
    set "DEVCON=%DRIVERDIR%\fxdevcon64.exe"
) else (
    set "DRIVERDIR=%APPDIR%\Drivers\win7\x64"
    set "DEVCON=%DRIVERDIR%\fxdevcon64.exe"
)

set "INF=%DRIVERDIR%\fxvad.inf"
set "DFXSETUP=%APPDIR%\Apps\DfxSetupDrv.exe"

REM Check if files exist
if not exist "%DEVCON%" exit /b 1
if not exist "%INF%" exit /b 1
if not exist "%DFXSETUP%" exit /b 1

REM Remove old driver if exists
"%DEVCON%" remove *DFX12 >nul 2>&1
timeout /t 2 /nobreak >nul

REM Install new driver
"%DEVCON%" install "%INF%"
if %errorLevel% neq 0 exit /b 1

timeout /t 2 /nobreak >nul

REM Configure driver
"%DFXSETUP%" getguid >nul 2>&1
"%DFXSETUP%" setname >nul 2>&1
"%DFXSETUP%" defaultbuffersize >nul 2>&1

exit /b 0
