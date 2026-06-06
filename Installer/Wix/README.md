# J&Y Audio Installer (WiX)

## Prerequisites

1. **WiX Toolset 3.14+** - https://wixtoolset.org/releases/
   - Download and install the .exe installer
   - Add to PATH: `C:\Program Files (x86)\WiX Toolset v3.14\bin`

2. **Compiled binaries** (build in VS first):
   - `fxsound/Project/FxSound.sln` → Release|x64
   - `Installer/DfxInstall/DfxInstall.sln` → Release|x64

## Build Steps

### Option 1: Command Line
```
cd Installer/Wix
build.bat
```

### Option 2: Manual
```
cd Installer/Wix

REM Compile
candle.exe -nologo -out jyaudio.wixobj Wix\jyaudio.wxs

REM Link
light.exe -nologo -ext WixUIExtension -out Output\jyaudio_setup.msi jyaudio.wixobj
```

## Output

- `Installer/Output/jyaudio_setup.msi` - MSI installer package

## What Gets Installed

```
Program Files\Jun Ye Electronics\J&Y Audio\
├── FxSound.exe          (main app)
├── fxdiag.exe           (diagnostic tool)
├── audiopassthru.dll    (audio passthrough)
├── DfxDsp.dll           (DSP library)
├── updater.exe          (auto-updater)
├── *.otf / *.ttf        (20 font files)
├── Apps/
│   ├── DfxInstall.dll   (installer helper)
│   └── DfxSetupDrv.exe  (driver setup)
├── Drivers/
│   ├── win10/x64/       (Win10 64-bit driver)
│   ├── win10/x86/       (Win10 32-bit driver)
│   ├── win7/x64/        (Win7 64-bit driver)
│   └── win7/x86/        (Win7 32-bit driver)
└── Factsoft/            (12 preset files + Default.fac)

%ProgramData%\J&Y Audio\
└── FxSound.settings     (user settings)

Desktop + Start Menu
└── J&Y Audio shortcut
```

## Driver Installation

The installer uses `DfxSetupDrv.exe` to:
1. Register the virtual audio device driver (fxvad.sys)
2. Create "J&Y Audio Enhancer" as an audio output device
3. The driver must be signed with a valid certificate for production use

## Notes

- This installer is for **x64 only** (no 32-bit support)
- Original FxSound driver must be uninstalled first
- The MSI requires admin privileges to install drivers
