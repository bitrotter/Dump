<#
.SYNOPSIS
    Checks Windows system file health.

.DESCRIPTION
    Runs DISM to check system image health and reports issues.

.PARAMETER Repair
    Attempt to repair system image.

.EXAMPLE
    .\Check-DISMHealth.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Repair
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== DISM Health Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Checking system image..." -ForegroundColor Yellow

$dism = dism /Online /CheckHealth /LimitAccess 2>&1 | Out-String

if ($dism -match "The component store is repairable") {
    Write-Host "  Status: Repairable" -ForegroundColor Yellow
} elseif ($dism -match "No component store corruption detected") {
    Write-Host "  Status: No corruption detected" -ForegroundColor Green
} elseif ($dism -match "The operation completed successfully") {
    Write-Host "  Status: Healthy" -ForegroundColor Green
} elseif ($dism -match "Files are supported") {
    Write-Host "  Status: Repair needed" -ForegroundColor Red
}

Write-Host ""
Write-Host "DISM Output:" -ForegroundColor Gray

$lines = $dism -split "`n" | Select-Object -Last 10
$lines | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

if ($Repair) {
    Write-Host ""
    Write-Host "Attempting repair..." -ForegroundColor Yellow
    
    $repair = dism /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-String
    
    if ($repair -match "The operation completed successfully") {
        Write-Host "  Repair completed" -ForegroundColor Green
    } else {
        Write-Host "  Repair failed" -ForegroundColor Red
    }
}

Write-Host ""

if ($dism -match "corruption detected") {
    Write-Host "RESULT:CRITICAL - System image corruption found" -ForegroundColor Red
    exit 2
} elseif ($dism -match "repairable") {
    Write-Host "RESULT:WARNING - System image needs repair" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - System image healthy" -ForegroundColor Green
    exit 0
}
