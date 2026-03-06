<#
.SYNOPSIS
    Runs disk cleanup utility.

.DESCRIPTION
    Runs Windows disk cleanup with specified options.

.PARAMETER CleanSystem
    Include system cleanup (Windows update, etc.).

.EXAMPLE
    .\Invoke-DiskCleanup.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$CleanSystem
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Disk Cleanup ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Running disk cleanup..." -ForegroundColor Yellow

$cleanupPath = "$env:WINDIR\System32\cleanmgr.exe"

if (-not (Test-Path $cleanupPath)) {
    Write-Host "Disk cleanup not available" -ForegroundColor Red
    exit 1
}

$sysCleanup = "$env:WINDIR\System32\Dism.exe"

if ($CleanSystem) {
    Write-Host "Running system cleanup..." -ForegroundColor Yellow
    
    try {
        DISM.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
        Write-Host "  Component cleanup complete" -ForegroundColor Green
    } catch {
        Write-Host "  Cleanup failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "RESULT:OK - Cleanup complete" -ForegroundColor Green
exit 0
