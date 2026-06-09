@echo off
REM J&Y Audio - Simple Installer with Driver Support
REM This script copies files and installs the driver
REM Must be run as Administrator

echo ========================================
echo    J^&Y Audio Installer v1.0.0.0
echo    Jun Ye Electronics
echo ========================================
echo.

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This installer requires Administrator privileges.
    echo Please right-click and select "Run as administrator".
    pause
    exit /b 1
)

REM Set installation directory
set "INSTALLDIR=%ProgramFiles%\J^&Y Audio"
echo Installing to: %INSTALLDIR%
echo.

REM Create directories
if not exist "%INSTALLDIR%" mkdir "%INSTALLDIR%"
if not exist "%INSTALLDIR%\Apps" mkdir "%INSTALLDIR%\Apps"
if not exist "%INSTALLDIR%\Drivers\win10\x64" mkdir "%INSTALLDIR%\Drivers\win10\x64"
if not exist "%INSTALLDIR%\Drivers\win7\x64" mkdir "%INSTALLDIR%\Drivers\win7\x64"
if not exist "%INSTALLDIR%\Fonts" mkdir "%INSTALLDIR%\Fonts"
if not exist "%INSTALLDIR%\Factsoft" mkdir "%INSTALLDIR%\Factsoft"

REM Copy main application files
echo Copying application files...
copy /Y "..\..\bin\x64\FxSound.exe" "%INSTALLDIR%\" >nul
copy /Y "..\..\bin\x64\fxdiag.exe" "%INSTALLDIR%\" >nul
copy /Y "..\Apps\Version14\DfxInstall.dll" "%INSTALLDIR%\Apps\" >nul
copy /Y "..\Apps\Version14\DfxSetupDrv.exe" "%INSTALLDIR%\Apps\" >nul
copy /Y "..\Resources\FxSound.settings" "%INSTALLDIR%\" >nul

REM Copy driver files
echo Copying driver files...
copy /Y "..\Drivers\Version14\win10\x64\fxvad.inf" "%INSTALLDIR%\Drivers\win10\x64\" >nul
copy /Y "..\Drivers\Version14\win10\x64\fxvad.sys" "%INSTALLDIR%\Drivers\win10\x64\" >nul
copy /Y "..\Drivers\Version14\win10\x64\fxvadntamd64.cat" "%INSTALLDIR%\Drivers\win10\x64\" >nul
copy /Y "..\Drivers\Version14\win10\x64\fxdevcon64.exe" "%INSTALLDIR%\Drivers\win10\x64\" >nul

copy /Y "..\Drivers\Version14\win7\x64\fxvad.inf" "%INSTALLDIR%\Drivers\win7\x64\" >nul
copy /Y "..\Drivers\Version14\win7\x64\fxvad.sys" "%INSTALLDIR%\Drivers\win7\x64\" >nul
copy /Y "..\Drivers\Version14\win7\x64\fxvadntamd64.cat" "%INSTALLDIR%\Drivers\win7\x64\" >nul
copy /Y "..\Drivers\Version14\win7\x64\fxdevcon64.exe" "%INSTALLDIR%\Drivers\win7\x64\" >nul

REM Copy font files
echo Copying font files...
copy /Y "..\Resources\Fonts\*.otf" "%INSTALLDIR%\Fonts\" >nul
copy /Y "..\Resources\Fonts\*.ttf" "%INSTALLDIR%\Fonts\" >nul

REM Copy preset files
echo Copying preset files...
copy /Y "..\Resources\Factsoft\*.fac" "%INSTALLDIR%\Factsoft\" >nul

REM Copy icon files
copy /Y "..\Resources\dfx.ico" "%INSTALLDIR%\" >nul
copy /Y "..\Resources\fxsound.ico" "%INSTALLDIR%\" >nul

echo.
echo Installing audio driver...
echo.

REM Install the driver
"%INSTALLDIR%\Apps\DfxSetupDrv.exe" /install "%INSTALLDIR%\Drivers" "%INSTALLDIR%" 1.0.0.0

if %errorLevel% equ 0 (
    echo.
    echo ========================================
    echo    Installation completed successfully!
    echo ========================================
    echo.
    echo You can now run J^&Y Audio from:
    echo %INSTALLDIR%\FxSound.exe
    echo.
    
    REM Create desktop shortcut
    echo Creating desktop shortcut...
    powershell "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%USERPROFILE%\Desktop\J^&Y Audio.lnk'); $s.TargetPath = '%INSTALLDIR%\FxSound.exe'; $s.WorkingDirectory = '%INSTALLDIR%'; $s.Save()"
    
    echo.
    pause
) else (
    echo.
    echo ERROR: Driver installation failed.
    echo Please check if the driver files are present.
    echo.
    pause
)
