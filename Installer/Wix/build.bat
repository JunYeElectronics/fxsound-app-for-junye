@echo off
REM ============================================================
REM  J&Y Audio Installer Build Script (WiX v7)
REM  Prerequisites: WiX Toolset v7 installed (wix-cli-x64.msi)
REM ============================================================

setlocal
cd /d "%~dp0"

echo.
echo ============================================
echo   J&Y Audio Installer Builder (WiX v7)
echo ============================================
echo.

REM Check WiX is available
where wix.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] WiX Toolset v7 not found in PATH!
    echo.
    echo Install from:
    echo   https://github.com/wixtoolset/wix/releases
    echo   Download: wix-cli-x64.msi
    echo.
    goto :end
)

REM Check that compiled binaries exist
if not exist "..\bin\x64\FxSound.exe" (
    echo [ERROR] FxSound.exe not found at ..\bin\x64\
    echo Please build the solution first:
    echo   1. Open fxsound\Project\FxSound.sln
    echo   2. Build Release^|x64
    echo.
    goto :end
)

if not exist "Apps\Version14\DfxInstall.dll" (
    echo [ERROR] DfxInstall.dll not found at Apps\Version14\
    echo Please build the installer solution first:
    echo   1. Open Installer\DfxInstall\DfxInstall.sln
    echo   2. Build Release^|x64
    echo.
    goto :end
)

REM Create output directory
if not exist "Output" mkdir Output

echo [1/2] Building MSI installer...
wix build jyaudio.wxs -o Output\jyaudio_setup.msi
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] WiX build failed!
    echo.
    goto :end
)

echo.
echo ============================================
echo   BUILD SUCCESSFUL!
echo ============================================
echo.
echo Output: Installer\Wix\Output\jyaudio_setup.msi
echo.
echo To test: run the MSI on a machine with FxSound
echo          already installed (need original driver).
echo.

:end
pause
