# J&Y Audio - Enable Audio Driver Device
# After driver installation, Windows may leave the virtual audio device disabled.
# This script searches for the device by its friendly name and sets DeviceState=1.
#
# Note: The INF creates the device as "FxSound Audio Enhancer" (original name).
# After DfxSetupDrv setname, it may be renamed to "J&Y Audio Enhancer".
# We search for both names to handle fresh installs and re-installs.

$ErrorActionPreference = "Stop"
$logFile = "$env:TEMP\jyaudio_install.log"

function Write-Log($msg) {
    $timestamp = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    "$timestamp $msg" | Out-File -Append -Encoding ASCII $logFile
}

Write-Log "enable_driver.ps1: Starting device enable check..."

$renderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
$deviceNameProp = "{a45c254e-df1c-4efd-8020-67d146a850e0},2"

# Search for both names: INF default name and post-setname name
$targetNames = @("FxSound Audio Enhancer", "J&Y Audio Enhancer")
$found = $false
$enabled = $false

try {
    $devices = Get-ChildItem -Path $renderPath -ErrorAction SilentlyContinue
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
            Write-Log "Found device: $name (GUID: $($device.PSChildName))"
            
            $currentState = $props.DeviceState
            Write-Log "Current DeviceState: 0x$('{0:X}' -f $currentState)"
            
            # DEVICE_STATE_DISABLED = 0x10000001
            if ($currentState -band 0x10000001) {
                Write-Log "Device is DISABLED, enabling..."
                Set-ItemProperty -Path $device.PSPath -Name "DeviceState" -Value 1 -Type DWord -Force
                Write-Log "DeviceState set to 1 (enabled)"
                $enabled = $true
            } else {
                Write-Log "Device is already enabled (DeviceState=$currentState)"
                $enabled = $true
            }
            break
        } catch {
            # Skip devices we can't read
        }
    }
} catch {
    Write-Log "ERROR: Cannot access render path: $_"
}

if (-not $found) {
    Write-Log "WARNING: Device not found in render devices"
    Write-Log "This may be OK if driver was just installed and needs a moment"
}

if ($enabled) {
    Write-Log "enable_driver.ps1: Device enabled successfully"
} else {
    Write-Log "enable_driver.ps1: WARNING - device was not found or could not be enabled"
}
