<#
.SYNOPSIS
    Checks power plan and settings.

.DESCRIPTION
    Reports active power plan and key power settings.

.PARAMETER SetHighPerformance
    Switch to High Performance plan.

.EXAMPLE
    .\Check-PowerSettings.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$SetHighPerformance
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Power Settings ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Active Power Plan:" -ForegroundColor Yellow

$plan = powercfg /getactivescheme

if ($plan -match "GUID:") {
    $planGuid = ($plan -split "GUID:")[1].Split("(")[0].Trim()
    $planName = ($plan -split "\(")[1].Split(")")[0].Trim()
    
    Write-Host "  Plan: $planName" -ForegroundColor White
    Write-Host "  GUID: $planGuid" -ForegroundColor Gray
    
    if ($planName -match "Balanced") {
        Write-Host "  Note: Balanced may cause performance issues" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Power Button Settings:" -ForegroundColor Yellow

$powerButtons = powercfg /query SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION

if ($powerButtons -match "Current AC Power Setting Index:") {
    $action = ($powerButtons -split "Current AC Power Setting Index:")[1].Trim()
    Write-Host "  Power Button: $action" -ForegroundColor White
}

Write-Host ""
Write-Host "Sleep Settings:" -ForegroundColor Yellow

$sleep = powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLETIMEOUT

if ($sleep -match "Current AC Power Setting Index:") {
    $timeout = ($sleep -split "Current AC Power Setting Index:")[1].Trim()
    $minutes = [int]$timeout / 60
    Write-Host "  Sleep Timeout: $minutes minutes" -ForegroundColor White
}

Write-Host ""
Write-Host "Display Settings:" -ForegroundColor Yellow

$display = powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE

if ($display -match "Current AC Power Setting Index:") {
    $timeout = ($display -split "Current AC Power Setting Index:")[1].Trim()
    $minutes = [int]$timeout / 60
    Write-Host "  Display Timeout: $minutes minutes" -ForegroundColor White
}

if ($SetHighPerformance) {
    Write-Host ""
    Write-Host "Switching to High Performance..." -ForegroundColor Yellow
    powercfg /setactive SCHEME_MIN
    Write-Host "  Switched to High Performance" -ForegroundColor Green
}

Write-Host ""

$issues = @()

if ($planName -match "Balanced" -and $SetHighPerformance -eq $false) {
    $issues += "Using Balanced plan"
}

if ($issues.Count -gt 0) {
    Write-Host "RESULT:WARNING - $($issues -join ', ')" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Power settings normal" -ForegroundColor Green
    exit 0
}
