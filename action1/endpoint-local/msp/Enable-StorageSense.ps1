<#
.SYNOPSIS
    Enables Storage Sense automatic cleanup.

.DESCRIPTION
    Enables and configures Windows Storage Sense.

.PARAMETER Daily
    Run cleanup daily.

.EXAMPLE
    .\Enable-StorageSense.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Daily
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Enable Storage Sense ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Configuring Storage Sense..." -ForegroundColor Yellow

$storagePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense"

if (-not (Test-Path $storagePath)) {
    New-Item -Path $storagePath -Force | Out-Null
}

Set-ItemProperty -Path $storagePath -Name "StorageSenseEnabled" -Value 1 -Type DWord -Force
Write-Host "  Enabled: Yes" -ForegroundColor Green

$frequency = if ($Daily) { 0 } else { 7 }
Set-ItemProperty -Path $storagePath -Name "StorageSenseFrequency" -Value $frequency -Type DWord -Force
Write-Host "  Frequency: $(if ($Daily) { 'Daily' } else { 'Weekly' })" -ForegroundColor Green

Write-Host ""
Write-Host "Configuring cleanup options..." -ForegroundColor Yellow

Set-ItemProperty -Path $storagePath -Name "DeleteTempFiles" -Value 1 -Type DWord -Force
Write-Host "  Temp files: Enabled" -ForegroundColor Green

Set-ItemProperty -Path $storagePath -Name "DeleteRecycleBinFiles" -Value 1 -Type DWord -Force
Write-Host "  Recycle Bin: Enabled" -ForegroundColor Green

Set-ItemProperty -Path $storagePath -Name "DeleteOldFiles" -Value 1 -Type DWord -Force
Write-Host "  Old files: Enabled" -ForegroundColor Green

Write-Host ""
Write-Host "Storage Sense Run:" -ForegroundColor Yellow

$storageSense = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StorageSense"

if ($storageSense) {
    $runTime = $storageSense.LastStorageSenseRunTime
    if ($runTime) {
        Write-Host "  Last run: $runTime" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "RESULT:OK - Storage Sense enabled" -ForegroundColor Green
exit 0
