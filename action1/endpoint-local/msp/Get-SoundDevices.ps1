<#
.SYNOPSIS
    Lists sound devices and drivers.

.DESCRIPTION
    Reports audio devices and their status.

.EXAMPLE
    .\Get-SoundDevices.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Sound Devices ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Audio Devices:" -ForegroundColor Yellow

$soundDevices = Get-CimInstance Win32_SoundDevice

if ($soundDevices) {
    foreach ($device in $soundDevices) {
        Write-Host "  $($device.Name)" -ForegroundColor White
        Write-Host "    Status: $($device.Status)" -ForegroundColor $(if ($device.Status -eq "OK") { "Green" } else { "Red" })
        Write-Host "    Device ID: $($device.DeviceID)" -ForegroundColor Gray
    }
} else {
    Write-Host "  No sound devices found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Default Playback Device:" -ForegroundColor Yellow

try {
    $playback = Get-CimInstance -Namespace root/cimv2 -ClassName Win32_SoundDevice | Where-Object { $_.ConfigManagerErrorCode -eq 0 } | Select-Object -First 1
    
    if ($playback) {
        Write-Host "  $($playback.Name)" -ForegroundColor Green
    }
} catch {
    Write-Host "  Could not determine default device" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Audio Service:" -ForegroundColor Yellow

$audioSvc = Get-Service -Name "Audiosrv" -ErrorAction SilentlyContinue

if ($audioSvc) {
    Write-Host "  Audio Service: $($audioSvc.Status)" -ForegroundColor $(if ($audioSvc.Status -eq "Running") { "Green" } else { "Red" })
} else {
    Write-Host "  Service not found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Windows Audio Endpoint Builder:" -ForegroundColor Yellow

$endpointSvc = Get-Service -Name "AudioEndpointBuilder" -ErrorAction SilentlyContinue

if ($endpointSvc) {
    Write-Host "  Status: $($endpointSvc.Status)" -ForegroundColor $(if ($endpointSvc.Status -eq "Running") { "Green" } else { "Red" })
}

Write-Host ""
Write-Host "RESULT:OK - Sound devices listed" -ForegroundColor Green
exit 0
