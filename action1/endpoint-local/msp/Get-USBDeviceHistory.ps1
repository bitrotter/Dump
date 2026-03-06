<#
.SYNOPSIS
    Gets USB device history.

.DESCRIPTION
    Lists currently connected and previously connected USB devices.

.EXAMPLE
    .\Get-USBDeviceHistory.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== USB Device History ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Connected USB Devices:" -ForegroundColor Yellow

$usb = Get-PnpDevice -Class USB -Status OK

if ($usb) {
    foreach ($device in $usb) {
        Write-Host "  $($device.FriendlyName)" -ForegroundColor Green
        Write-Host "    Status: $($device.Status)" -ForegroundColor Gray
    }
} else {
    Write-Host "  No USB devices found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "All USB Devices (including removed):" -ForegroundColor Yellow

$allUsb = Get-PnpDevice -Class USB

foreach ($device in $allUsb) {
    $status = if ($device.Status -eq "OK") { "Connected" } else { "Removed" }
    $color = if ($device.Status -eq "OK") { "Green" } else { "Gray" }
    Write-Host "  $($device.FriendlyName) - $status" -ForegroundColor $color
}

Write-Host ""
Write-Host "USB Storage Devices:" -ForegroundColor Yellow

$storage = Get-PnpDevice -Class USB | Where-Object { $_.FriendlyName -match "Storage|Disk|Thumb|Flash" }

if ($storage) {
    foreach ($device in $storage) {
        Write-Host "  $($device.FriendlyName)" -ForegroundColor White
    }
} else {
    Write-Host "  None detected" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - USB history retrieved" -ForegroundColor Green
exit 0
