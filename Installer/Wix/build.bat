@echo off
REM ============================================================
REM  J^&Y Audio Installer Build Script (WiX v3)
REM  Prerequisites: WiX Toolset v3.14 installed
REM  Download: https://github.com/wixtoolset/wix3/releases/tag/wix3141rtm
REM ============================================================

cd /d "%~dp0"
echo.
echo ============================================
echo   J^&Y Audio Installer Builder (WiX v3)
echo ============================================
echo.

REM Check WiX
echo Checking WiX...
where candle.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] candle.exe not found in PATH
    echo Install WiX v3.14 and add to PATH
    goto :end
)
echo [OK] WiX found
echo.

REM Check FxSound.exe
echo Checking FxSound.exe...
if exist "..\..\bin\x64\FxSound.exe" (
    echo [OK] FxSound.exe found
) else (
    echo [ERROR] NOT found: ..\..\bin\x64\FxSound.exe
    goto :end
)
echo.

REM Check DfxInstall.dll
echo Checking DfxInstall.dll...
if exist "..\DfxInstall\x64\Release\DfxInstall.dll" (
    echo [OK] DfxInstall.dll found
) else (
    echo [ERROR] NOT found: ..\DfxInstall\x64\Release\DfxInstall.dll
    goto :end
)
echo.

REM Create output directory
if not exist "Output" mkdir Output

REM Step 1: Compile
echo [1/3] Compiling...
candle.exe -nologo -out Output\jyaudio.wixobj jyaudio.wxs
if %errorlevel% neq 0 (
    echo [ERROR] candle failed
    goto :end
)

REM Step 2: Link
echo [2/3] Linking MSI...
light.exe -nologo -ext WixUIExtension -out Output\jyaudio_setup.msi Output\jyaudio.wixobj
if %errorlevel% neq 0 (
    echo [ERROR] light failed
    goto :end
)

echo.
echo ============================================
echo   BUILD SUCCESSFUL!
echo ============================================
echo Output: %CD%\Output\jyaudio_setup.msi
echo.

:end
pause
