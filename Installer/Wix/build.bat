@echo off
REM ============================================================
REM  J&Y Audio Installer Build Script
REM  Prerequisites: WiX Toolset 3.x installed and in PATH
REM  Download: https://wixtoolset.org/releases/
REM ============================================================

setlocal
cd /d "%~dp0"

echo.
echo ============================================
echo   J&Y Audio Installer Builder
echo ============================================
echo.

REM Check WiX is available
where candle.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] WiX Toolset not found in PATH!
    echo.
    echo Install WiX Toolset 3.x from:
    echo   https://wixtoolset.org/releases/
    echo.
    echo After install, add to PATH:
    echo   C:\Program Files (x86)\WiX Toolset v3.14\bin
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

echo [1/3] Compiling WiX source...
candle.exe -nologo -dAPPDIR="." -dDFX_VERSION="1.0.0.0" -out jyaudio.wixobj Wix\jyaudio.wxs
if %errorlevel% neq 0 (
    echo [ERROR] Candle compilation failed!
    goto :end
)

echo [2/3] Linking MSI package...
light.exe -nologo -ext WixUIExtension -out Output\jyaudio_setup.msi jyaudio.wixobj
if %errorlevel% neq 0 (
    echo [ERROR] Light linking failed!
    goto :end
)

echo [3/3] Creating EXE bootstrapper...
REM Optional: Create EXE wrapper for easy distribution
REM Requires WiX Burn extension

echo.
echo ============================================
echo   BUILD SUCCESSFUL!
echo ============================================
echo.
echo Output: Installer\Output\jyaudio_setup.msi
echo.
echo To test: run the MSI on a machine with FxSound
echo          already installed (need original driver).
echo.

:end
pause
