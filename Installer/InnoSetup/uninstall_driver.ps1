# J&Y Audio Driver Uninstaller
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File uninstall_driver.ps1
# Must run as Administrator

$ErrorActionPreference = "Stop"

# --- Paths ---
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$DriverDir  = "$ScriptDir\Drivers\win10\x64"
$AppDir     = "$ScriptDir\Apps"
$LogFile    = "$env:TEMP\jyaudio_uninstall.log"

function log($msg) {
    $ts = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    "$ts $msg" | Out-File -Append -Encoding ASCII $LogFile
    Write-Host "$ts $msg"
}

log "=== J&Y Audio Driver Uninstall ==="
log "ScriptDir: $ScriptDir"

# ===================================================================
# Step 0: Kill running FxSound process
# ===================================================================
log "Step 0: Killing FxSound.exe..."
$proc = Get-Process -Name "FxSound" -ErrorAction SilentlyContinue
if ($proc) {
    Stop-Process -Name "FxSound" -Force -ErrorAction SilentlyContinue
    Start-Sleep 2
    log "FxSound.exe terminated"
} else {
    log "FxSound.exe not running"
}

# ===================================================================
# Step 1: Remove powercfg override
# ===================================================================
log "Step 1: Removing powercfg override..."
$tmp = "$env:TEMP\_jyaudio_pwr_uninstall.tmp"
powercfg -REQUESTSOVERRIDE DRIVER "J&Y Audio Enhancer" > $tmp 2>&1
Get-Content $tmp | ForEach-Object { log $_ }
Remove-Item $tmp -ErrorAction SilentlyContinue

# ===================================================================
# Step 2: Remove device with fxdevcon
# ===================================================================
log "Step 2: Removing device (fxdevcon64 remove)..."

$devcon = "$DriverDir\fxdevcon64.exe"
if (Test-Path $devcon) {
    # Try *DFX12 first (old driver hardware ID)
    $proc = Start-Process -FilePath $devcon `
        -ArgumentList "remove", "*DFX12" `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput "$env:TEMP\_fxdevcon_rm_out.tmp" `
        -RedirectStandardError "$env:TEMP\_fxdevcon_rm_err.tmp"
    
    $tmpOut = "$env:TEMP\_fxdevcon_rm_out.tmp"
    $tmpErr = "$env:TEMP\_fxdevcon_rm_err.tmp"
    if (Test-Path $tmpOut) {
        Get-Content $tmpOut | ForEach-Object { log $_ }
        Remove-Item $tmpOut
    }
    if (Test-Path $tmpErr) {
        $errContent = Get-Content $tmpErr
        if ($errContent) { $errContent | ForEach-Object { log $_ } }
        Remove-Item $tmpErr
    }
    log "fxdevcon64 remove *DFX12 exit code: $($proc.ExitCode)"
    
    # Also try Root\FXVAD
    $proc = Start-Process -FilePath $devcon `
        -ArgumentList "remove", "Root\FXVAD" `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput "$env:TEMP\_fxdevcon_rm_out.tmp" `
        -RedirectStandardError "$env:TEMP\_fxdevcon_rm_err.tmp"
    
    if (Test-Path $tmpOut) {
        Get-Content $tmpOut | ForEach-Object { log $_ }
        Remove-Item $tmpOut
    }
    if (Test-Path $tmpErr) {
        $errContent = Get-Content $tmpErr
        if ($errContent) { $errContent | ForEach-Object { log $_ } }
        Remove-Item $tmpErr
    }
    log "fxdevcon64 remove Root\FXVAD exit code: $($proc.ExitCode)"
    
    Start-Sleep 2
}

# ===================================================================
# Step 3: Delete driver package with pnputil
# ===================================================================
log "Step 3: Deleting driver package (pnputil)..."

$tmp = "$env:TEMP\_jyaudio_pnputil_rm.tmp"
pnputil /delete-driver fxvad.inf /uninstall /force > $tmp 2>&1
Get-Content $tmp | ForEach-Object { log $_ }
Remove-Item $tmp -ErrorAction SilentlyContinue

# Also try the oemXX.inf version that pnputil may have renamed it to
$oemDrivers = pnputil /enum-drivers 2>&1 | Select-String "J&Y|FxSound|DFX|FxVAD|DFX12"
if ($oemDrivers) {
    log "Found remaining driver entries:"
    $oemDrivers | ForEach-Object { log $_ }
    
    # Extract oemXX.inf names
    $oemPattern = [regex]::Matches($oemDrivers, 'oem\d+\.inf')
    foreach ($match in $oemPattern) {
        $oemInf = $match.Value
        log "Removing $oemInf..."
        $tmp = "$env:TEMP\_jyaudio_pnputil_rm.tmp"
        pnputil /delete-driver $oemInf /uninstall /force > $tmp 2>&1
        Get-Content $tmp | ForEach-Object { log $_ }
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
}

# ===================================================================
# Step 4: Scan for hardware changes
# ===================================================================
log "Step 4: Scanning for hardware changes..."
$tmp = "$env:TEMP\_jyaudio_scan.tmp"
pnputil /scan-devices > $tmp 2>&1
Get-Content $tmp | ForEach-Object { log $_ }
Remove-Item $tmp -ErrorAction SilentlyContinue

# ===================================================================
# Step 5: Clean registry (DFX settings)
# ===================================================================
log "Step 5: Cleaning DFX registry..."
$paths = @(
    "HKCU:\Software\DFX",
    "HKLM:\Software\DFX"
)
foreach ($p in $paths) {
    if (Test-Path $p) {
        Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
        log "Removed $p"
    } else {
        log "$p not found"
    }
}

log "=== Uninstall completed ==="
