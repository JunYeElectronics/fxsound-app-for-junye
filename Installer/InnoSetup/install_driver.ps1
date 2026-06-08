# J&Y Audio Driver Installer
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File install_driver.ps1
# Must run as Administrator

$ErrorActionPreference = "Stop"

# --- Paths ---
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$DriverDir  = "$ScriptDir\Drivers\win10\x64"
$AppDir     = "$ScriptDir\Apps"
$LogFile    = "$env:TEMP\jyaudio_install.log"

function log($msg) {
    $ts = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    "$ts $msg" | Out-File -Append -Encoding ASCII $LogFile
    Write-Host "$ts $msg"
}

log "=== J&Y Audio Driver Installation ==="
log "ScriptDir: $ScriptDir"
log "DriverDir: $DriverDir"

# ===================================================================
# Step 0: Fix INF CRLF (exactly the manual command)
# ===================================================================
log "Step 0: Fixing INF line endings..."
$infPath = "$DriverDir\fxvad.inf"
$txt = [IO.File]::ReadAllText($infPath)
# Count LFs
$lfOnly = ([regex]::Matches($txt, "(?<!\r)\n")).Count
log "Found $lfOnly bare LF endings"
if ($lfOnly -gt 0) {
    $txt = $txt -replace "`r`n", "`n" -replace "`n", "`r`n"
    [IO.File]::WriteAllText($infPath, $txt)
    log "Converted to CRLF, wrote $((Get-Item $infPath).Length) bytes"
} else {
    log "Already CRLF"
}

# ===================================================================
# Step 1: Clean up old driver
# ===================================================================
log "Step 1: Cleaning up old driver..."

$devcon = "$DriverDir\fxdevcon64.exe"
if (Test-Path $devcon) {
    # Redirect to temp file to avoid cmd.exe handle lock
    $tmp = "$env:TEMP\_jyaudio_cleanup.tmp"
    
    & $devcon remove *DFX12 > $tmp 2>&1
    Get-Content $tmp | ForEach-Object { log $_ }
    
    & $devcon remove Root\FXVAD > $tmp 2>&1
    Get-Content $tmp | ForEach-Object { log $_ }
    
    Remove-Item $tmp -ErrorAction SilentlyContinue
    Start-Sleep 2
}

$tmp = "$env:TEMP\_jyaudio_pnputil.tmp"
pnputil /delete-driver fxvad.inf /uninstall /force > $tmp 2>&1
Get-Content $tmp | ForEach-Object { log $_ }
Remove-Item $tmp -ErrorAction SilentlyContinue

# ===================================================================
# Step 2: Install driver (EXACT manual commands)
#   cd DriverDir; fxdevcon64.exe install fxvad.inf
# ===================================================================
log "Step 2: Installing driver (fxdevcon64 install fxvad.inf)..."

Push-Location $DriverDir
try {
    # EXACT equivalent of manual admin cmd:
    #   cd Drivers\win10\x64
    #   fxdevcon64.exe install fxvad.inf
    #
    # BUT using Start-Process to launch fxdevcon as a completely
    # independent process (fresh console, no handle inheritance from
    # Inno Setup runhidden). Wait up to 5 minutes for completion.
    
    $proc = Start-Process -FilePath $devcon `
        -ArgumentList "install", "fxvad.inf" `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput "$env:TEMP\_fxdevcon_out.tmp" `
        -RedirectStandardError "$env:TEMP\_fxdevcon_err.tmp"
    
    $exitCode = $proc.ExitCode
    
    # Dump output to log
    $tmpOut = "$env:TEMP\_fxdevcon_out.tmp"
    $tmpErr = "$env:TEMP\_fxdevcon_err.tmp"
    if (Test-Path $tmpOut) {
        Get-Content $tmpOut | ForEach-Object { log $_ }
        Remove-Item $tmpOut
    }
    if (Test-Path $tmpErr) {
        $errContent = Get-Content $tmpErr
        if ($errContent) {
            $errContent | ForEach-Object { log $_ }
        }
        Remove-Item $tmpErr
    }
    
    log "fxdevcon64 exit code: $exitCode"
    
    if ($exitCode -ne 0) {
        log "fxdevcon64 failed, trying pnputil fallback..."
        $tmp = "$env:TEMP\_jyaudio_pnputil.tmp"
        pnputil /add-driver $infPath /install > $tmp 2>&1
        Get-Content $tmp | ForEach-Object { log $_ }
        Remove-Item $tmp -ErrorAction SilentlyContinue
        
        log "Scanning for new devices..."
        pnputil /scan-devices > $tmp 2>&1
        Get-Content $tmp | ForEach-Object { log $_ }
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
} finally {
    Pop-Location
}

log "Driver installed, waiting 5s for device enumeration..."
Start-Sleep 5

# ===================================================================
# Step 3: Enable audio device
# ===================================================================
log "Step 3: Enabling audio device..."

$mmdevKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
$nameProp = "{a45c254e-df1c-4efd-8020-67d146a850e0},2"
$targetNames = @("FxSound Audio Enhancer", "J&Y Audio Enhancer")
$found = $false

if (Test-Path $mmdevKey) {
    Get-ChildItem $mmdevKey -ErrorAction SilentlyContinue | ForEach-Object {
        $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
        $name = $props.$nameProp
        if (-not $name) { return }
        
        $matched = $false
        foreach ($t in $targetNames) {
            if ($name.StartsWith($t)) { $matched = $true; break }
        }
        if (-not $matched) { return }
        
        $found = $true
        $state = $props.DeviceState
        log "Found: '$name' (State: 0x$('{0:X}' -f $state))"
        
        if ($state -band 0x10000001) {
            log "Device is DISABLED, enabling..."
            Set-ItemProperty -Path $_.PSPath -Name "DeviceState" -Value 1 -Type DWord -Force
            log "DeviceState set to 1 (enabled)"
        } else {
            log "Device already enabled"
        }
    }
}

if (-not $found) {
    log "Device not found in MMDevices (may appear after reboot)"
}

Start-Sleep 2

# ===================================================================
# Step 4-7: getguid, setname, defaultbuffersize, powercfg
# ===================================================================
$dfxSetup = "$AppDir\DfxSetupDrv.exe"

Push-Location $AppDir
try {
    $tmp = "$env:TEMP\_jyaudio_dfx.tmp"
    
    log "Step 4: Getting driver GUID..."
    & $dfxSetup getguid > $tmp 2>&1
    $guidOut = Get-Content $tmp -Raw
    log $guidOut.Trim()
    
    log "Step 5: Setting driver name..."
    & $dfxSetup setname > $tmp 2>&1
    log (Get-Content $tmp -Raw).Trim()
    
    log "Step 6: Setting buffer size..."
    & $dfxSetup defaultbuffersize > $tmp 2>&1
    log (Get-Content $tmp -Raw).Trim()
    
    Remove-Item $tmp -ErrorAction SilentlyContinue
} finally {
    Pop-Location
}

log "Step 7: Configuring power override..."
$tmp = "$env:TEMP\_jyaudio_pwr.tmp"
powercfg -REQUESTSOVERRIDE DRIVER "J&Y Audio Enhancer" SYSTEM > $tmp 2>&1
Get-Content $tmp | ForEach-Object { log $_ }
Remove-Item $tmp -ErrorAction SilentlyContinue

log "=== Installation completed ==="
