# J&Y Audio - Driver Helper Script
# Two modes:
#   1. -FixEOL <inf_path>   Convert INF line endings from LF to CRLF
#   2. -EnableDevice         Find and enable the audio device

param(
    [string]$FixEOLPath,
    [switch]$EnableDevice
)

$ErrorActionPreference = "Stop"

function Write-Log($msg) {
    $timestamp = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    Write-Host "$timestamp $msg"
}

# =====================================================================
# Mode 1: Fix INF line endings (LF -> CRLF)
# The .cat file was generated with CRLF line endings. If the INF file
# has LF endings (from git/Linux/file transfers), pnputil rejects it
# with "hash not in catalog file".
# =====================================================================
if ($FixEOLPath) {
    $infPath = $FixEOLPath
    if (-not $infPath) {
        Write-Log "FixEOL: ERROR - no INF path provided"
        exit 1
    }
    if (-not (Test-Path $infPath)) {
        Write-Log "FixEOL: ERROR - INF file not found: $infPath"
        exit 1
    }
    
    Write-Log "FixEOL: Reading $infPath..."
    $bytes = [IO.File]::ReadAllBytes($infPath)
    
    # Count current line endings
    $lfCount = 0; $crlfCount = 0
    for ($i = 0; $i -lt $bytes.Count; $i++) {
        if ($bytes[$i] -eq 10) {  # LF
            if ($i -gt 0 -and $bytes[$i-1] -eq 13) { $crlfCount++ }  # CRLF
            else { $lfCount++ }  # standalone LF
        }
    }
    Write-Log "FixEOL: Found $lfCount LF, $crlfCount CRLF line endings"
    
    if ($lfCount -eq 0) {
        Write-Log "FixEOL: INF already has Windows CRLF endings, nothing to fix"
        exit 0
    }
    
    # Convert: add CR before any LF not already preceded by CR
    $newBytes = [System.Collections.ArrayList]::new()
    for ($i = 0; $i -lt $bytes.Count; $i++) {
        if ($bytes[$i] -eq 10 -and ($i -eq 0 -or $bytes[$i-1] -ne 13)) {
            [void]$newBytes.Add(13)  # Add CR before LF
        }
        [void]$newBytes.Add($bytes[$i])
    }
    
    [IO.File]::WriteAllBytes($infPath, $newBytes.ToArray())
    Write-Log "FixEOL: Converted $lfCount LF -> CRLF, wrote $($newBytes.Count) bytes"
    exit 0
}

# =====================================================================
# Mode 2: Enable the audio device
# After driver install, Windows may leave the virtual audio device
# disabled. This searches the MMDevices registry for the device and
# sets DeviceState=1 to enable it.
# =====================================================================
if ($EnableDevice) {
    Write-Log "EnableDevice: Starting device enable check..."

    $renderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
    $deviceNameProp = "{a45c254e-df1c-4efd-8020-67d146a850e0},2"

    # Search for both names: INF default ("FxSound Audio Enhancer")
    # and post-setname name ("J&Y Audio Enhancer")
    $targetNames = @("FxSound Audio Enhancer", "J&Y Audio Enhancer")
    $found = $false
    $enabled = $false

    try {
        $devices = Get-ChildItem -Path $renderPath -ErrorAction SilentlyContinue
        if (-not $devices) {
            Write-Log "EnableDevice: No render devices found (registry empty?)"
            exit 0
        }
        
        foreach ($device in $devices) {
            try {
                $props = Get-ItemProperty -Path $device.PSPath -ErrorAction SilentlyContinue
                $name = $props.$deviceNameProp
                if (-not $name) { continue }
                
                $matched = $false
                foreach ($target in $targetNames) {
                    if ($name.StartsWith($target)) {
                        $matched = $true
                        break
                    }
                }
                if (-not $matched) { continue }
                
                $found = $true
                Write-Log "EnableDevice: Found '$name' (GUID: $($device.PSChildName))"
                
                $currentState = $props.DeviceState
                Write-Log "EnableDevice: Current DeviceState=0x$('{0:X}' -f $currentState)"
                
                # DEVICE_STATE_DISABLED = 0x10000001
                if ($currentState -band 0x10000001) {
                    Write-Log "EnableDevice: Device is DISABLED, enabling..."
                    Set-ItemProperty -Path $device.PSPath -Name "DeviceState" -Value 1 -Type DWord -Force
                    Write-Log "EnableDevice: DeviceState set to 1 (enabled)"
                    $enabled = $true
                } else {
                    Write-Log "EnableDevice: Device already enabled"
                    $enabled = $true
                }
                break
            } catch {
                # Skip devices we can't read
            }
        }
    } catch {
        Write-Log "EnableDevice: ERROR accessing registry: $_"
    }

    if (-not $found) {
        Write-Log "EnableDevice: Device not found (may appear after reboot)"
    }
    if ($enabled) {
        Write-Log "EnableDevice: Done"
    }
    exit 0
}

# If no mode specified, show usage
Write-Log "helper.ps1: No mode specified. Use -FixEOL <path> or -EnableDevice"
exit 0
