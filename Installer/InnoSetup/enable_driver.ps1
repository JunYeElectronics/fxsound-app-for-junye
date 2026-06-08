# J&Y Audio - Enable Audio Driver Device
# After fxdevcon installs the driver, Windows may leave it disabled.
# This script finds the "J&Y Audio Enhancer" device and enables it
# by setting DeviceState=1 in the MMDevices registry.

$ErrorActionPreference = "Stop"
$logFile = "$env:TEMP\jyaudio_install.log"

function Write-Log($msg) {
    $timestamp = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    "$timestamp $msg" | Out-File -Append -Encoding ASCII $logFile
}

Write-Log "enable_driver.ps1: Starting device enable check..."

$renderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
$deviceNameProp = "{a45c254e-df1c-4efd-8020-67d146a850e0},2"
$targetName = "J&Y Audio Enhancer"
$found = $false
$enabled = $false

try {
    $devices = Get-ChildItem -Path $renderPath -ErrorAction SilentlyContinue
    foreach ($device in $devices) {
        try {
            $props = Get-ItemProperty -Path $device.PSPath -ErrorAction SilentlyContinue
            $name = $props.$deviceNameProp
            if ($name -and $name.StartsWith($targetName)) {
                $found = $true
                Write-Log "Found device: $name (GUID: $($device.PSChildName))"
                
                $currentState = $props.DeviceState
                Write-Log "Current DeviceState: 0x$('{0:X}' -f $currentState)"
                
                # Check if disabled (DEVICE_STATE_DISABLED = 0x10000001)
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
            }
        } catch {
            # Skip devices we can't read
        }
    }
} catch {
    Write-Log "ERROR: Cannot access render path: $_"
}

if (-not $found) {
    Write-Log "WARNING: '$targetName' device not found in render devices"
    Write-Log "This is OK if device was just installed and needs a moment to appear"
}

if ($enabled) {
    Write-Log "enable_driver.ps1: Device enabled successfully"
} else {
    Write-Log "enable_driver.ps1: WARNING - device was not found/enabled"
}