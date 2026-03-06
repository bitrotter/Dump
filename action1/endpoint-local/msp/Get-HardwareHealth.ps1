<#
.SYNOPSIS
    Gets comprehensive hardware health info.

.DESCRIPTION
    Collects hardware health data for support tickets.

.EXAMPLE
    .\Get-HardwareHealth.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Hardware Health ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "System:" -ForegroundColor Yellow

$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem

Write-Host "  Manufacturer: $($cs.Manufacturer)" -ForegroundColor White
Write-Host "  Model: $($cs.Model)" -ForegroundColor White
Write-Host "  Serial: $($cs.Name)" -ForegroundColor Gray

Write-Host ""
Write-Host "CPU:" -ForegroundColor Yellow

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

Write-Host "  Name: $($cpu.Name)" -ForegroundColor White
Write-Host "  Cores: $($cpu.NumberOfCores)" -ForegroundColor Gray
Write-Host "  Max Speed: $($cpu.MaxClockSpeed) MHz" -ForegroundColor Gray

$load = (Get-CimInstance Win32_Processor).LoadPercentage
Write-Host "  Current Load: $load%" -ForegroundColor $(if ($load -gt 80) { "Red" } else { "Green" })

Write-Host ""
Write-Host "Memory:" -ForegroundColor Yellow

$totalGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB / 1024, 2)
$usedGB = $totalGB - $freeGB

Write-Host "  Total: $totalGB GB" -ForegroundColor White
Write-Host "  Used: $usedGB GB" -ForegroundColor Gray
Write-Host "  Free: $freeGB GB" -ForegroundColor Green

Write-Host ""
Write-Host "Disk:" -ForegroundColor Yellow

$disks = Get-CimInstance Win32_DiskDrive

foreach ($disk in $disks) {
    $sizeTB = [math]::Round($disk.Size / 1TB, 2)
    Write-Host "  Drive $($disk.Index):" -ForegroundColor White
    Write-Host "    Model: $($disk.Model)" -ForegroundColor Gray
    Write-Host "    Size: $sizeTB TB" -ForegroundColor Gray
    Write-Host "    Status: $($disk.Status)" -ForegroundColor $(if ($disk.Status -eq "OK") { "Green" } else { "Yellow" })
}

Write-Host ""
Write-Host "Network:" -ForegroundColor Yellow

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($adapter in $adapters) {
    Write-Host "  $($adapter.Name):" -ForegroundColor White
    Write-Host "    MAC: $($adapter.MacAddress)" -ForegroundColor Gray
    Write-Host "    Speed: $($adapter.LinkSpeed)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Battery (if laptop):" -ForegroundColor Yellow

$battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue

if ($battery) {
    Write-Host "  Status: $($battery.BatteryStatus)" -ForegroundColor $(if ($battery.BatteryStatus -eq 1) { "Green" } else { "Yellow" })
    Write-Host "  Charge: $($battery.EstimatedChargeRemaining)%" -ForegroundColor White
    Write-Host "  Runtime: $($battery.EstimatedRunTime) min" -ForegroundColor Gray
} else {
    Write-Host "  No battery detected (desktop)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Temperature:" -ForegroundColor Yellow

try {
    $temp = Get-CimInstance MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" -ErrorAction SilentlyContinue
    if ($temp) {
        $celsius = ($temp.CurrentTemperature - 2732) / 10
        Write-Host "  Temperature: $celsius C" -ForegroundColor $(if ($celsius -gt 70) { "Red" } else { "Green" })
    } else {
        Write-Host "  Not available" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Not available" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - Hardware info collected" -ForegroundColor Green
exit 0
