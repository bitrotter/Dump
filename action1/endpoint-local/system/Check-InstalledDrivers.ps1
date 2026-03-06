<#
.SYNOPSIS
    Lists installed drivers.

.DESCRIPTION
    Shows all installed drivers and their versions.

.PARAMETER Outdated
    Show only potentially outdated drivers.

.EXAMPLE
    .\Check-InstalledDrivers.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Outdated
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Installed Drivers ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$drivers = Get-WindowsDriver -Online -ErrorAction SilentlyContinue

if (-not $drivers) {
    $drivers = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DriverDate } | Select-Object DeviceName, DriverVersion, DriverDate, Manufacturer
}

Write-Host "Total Drivers: $($drivers.Count)" -ForegroundColor White
Write-Host ""

if ($Outdated) {
    $oneYearAgo = (Get-Date).AddYears(-1)
    $drivers = $drivers | Where-Object { $_.DriverDate -lt $oneYearAgo }
    Write-Host "Outdated Drivers (older than 1 year):" -ForegroundColor Yellow
} else {
    Write-Host "Sample Drivers:" -ForegroundColor Yellow
}

$drivers | Select-Object -First 20 | ForEach-Object {
    if ($_.DeviceName) {
        Write-Host "  $($_.DeviceName)" -ForegroundColor Green
        if ($_.DriverVersion) { Write-Host "    Version: $($_.DriverVersion)" -ForegroundColor White }
        if ($_.DriverDate) { Write-Host "    Date: $($_.DriverDate)" -ForegroundColor Gray }
        if ($_.Manufacturer) { Write-Host "    Manufacturer: $($_.Manufacturer)" -ForegroundColor Gray }
    }
}

Write-Host ""
Write-Host "RESULT:OK - Driver list retrieved" -ForegroundColor Green
exit 0
