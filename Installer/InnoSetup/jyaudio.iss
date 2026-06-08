; J&Y Audio Installer - Inno Setup Script
; Build with Inno Setup 6.x: https://jrsoftware.org/isdl.php

#define MyAppName "J&Y Audio"
#define MyAppVersion "1.0.0.0"
#define MyAppPublisher "Jun Ye Electronics"
#define MyAppURL "https://www.jun-ye.com"
#define MyAppExeName "FxSound.exe"

[Setup]
AppId={{1CA2081B-0D5A-41DF-86E8-2788204CE340}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=..\Output
OutputBaseFilename=jyaudio_setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main application - to app root directory
Source: "..\..\bin\x64\FxSound.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\bin\x64\fxdiag.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Apps\Version14\DfxInstall.dll"; DestDir: "{app}\Apps"; Flags: ignoreversion
Source: "..\Apps\Version14\DfxSetupDrv.exe"; DestDir: "{app}\Apps"; Flags: ignoreversion
Source: "..\Resources\FxSound.settings"; DestDir: "{app}"; Flags: ignoreversion

; Driver files - Win10 x64
Source: "..\Drivers\Version14\win10\x64\fxvad.inf"; DestDir: "{app}\Drivers\win10\x64"; Flags: ignoreversion
Source: "..\Drivers\Version14\win10\x64\fxvad.sys"; DestDir: "{app}\Drivers\win10\x64"; Flags: ignoreversion
Source: "..\Drivers\Version14\win10\x64\fxvadntamd64.cat"; DestDir: "{app}\Drivers\win10\x64"; Flags: ignoreversion
Source: "..\Drivers\Version14\win10\x64\fxdevcon64.exe"; DestDir: "{app}\Drivers\win10\x64"; Flags: ignoreversion

; Driver files - Win7 x64
Source: "..\Drivers\Version14\win7\x64\fxvad.inf"; DestDir: "{app}\Drivers\win7\x64"; Flags: ignoreversion
Source: "..\Drivers\Version14\win7\x64\fxvad.sys"; DestDir: "{app}\Drivers\win7\x64"; Flags: ignoreversion
Source: "..\Drivers\Version14\win7\x64\fxvadntamd64.cat"; DestDir: "{app}\Drivers\win7\x64"; Flags: ignoreversion
Source: "..\Drivers\Version14\win7\x64\fxdevcon64.exe"; DestDir: "{app}\Drivers\win7\x64"; Flags: ignoreversion

; Font files - copy to app root directory (app loads from CWD, not Fonts subdirectory)
Source: "..\Resources\Fonts\NotoSansSC-Regular.otf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansSC-Medium.otf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansSC-Bold.otf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansKR-Regular.otf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansKR-Medium.otf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansKR-Bold.otf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansJP-Regular.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansJP-Medium.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansJP-Bold.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansTC-Regular.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansTC-Medium.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansTC-Bold.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansThai-Regular.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\NotoSansThai-Medium.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\MontserratAlternates-Regular.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\MontserratAlternates-Medium.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\MontserratAlternates-Bold.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\IBMPlexSansArabic-Regular.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\IBMPlexSansArabic-Medium.ttf"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\Fonts\IBMPlexSansArabic-Bold.ttf"; DestDir: "{app}"; Flags: ignoreversion

; Preset files
Source: "..\Resources\Factsoft\Default.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion
Source: "..\Resources\Factsoft\1.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion
Source: "..\Resources\Factsoft\2.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion
Source: "..\Resources\Factsoft\3.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion
Source: "..\Resources\Factsoft\4.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion
Source: "..\Resources\Factsoft\5.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion
Source: "..\Resources\Factsoft\6.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion
Source: "..\Resources\Factsoft\7.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion
Source: "..\Resources\Factsoft\8.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion
Source: "..\Resources\Factsoft\9.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion
Source: "..\Resources\Factsoft\10.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion
Source: "..\Resources\Factsoft\11.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion
Source: "..\Resources\Factsoft\12.fac"; DestDir: "{app}\Factsoft"; Flags: ignoreversion

; Icon files
Source: "..\Resources\dfx.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resources\fxsound.ico"; DestDir: "{app}"; Flags: ignoreversion

; Driver installation script + enable helper
Source: "install_driver.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "enable_driver.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Install driver after file copy (requires admin)
Filename: "{app}\install_driver.bat"; StatusMsg: "Installing audio driver..."; Flags: runhidden waituntilterminated

[UninstallRun]
; Uninstall driver before file removal
Filename: "{app}\Apps\DfxSetupDrv.exe"; Parameters: "/uninstall ""{app}\Drivers"" ""{app}"" 1.0.0.0"; Flags: runhidden waituntilterminated
