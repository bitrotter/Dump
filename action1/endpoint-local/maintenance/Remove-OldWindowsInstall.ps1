<#
.SYNOPSIS
    Removes old Windows installations.

.DESCRIPTION
    Frees up space by removing previous Windows installations.

.EXAMPLE
    .\Remove-OldWindowsInstall.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Remove Old Windows Installations ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Checking for old Windows installations..." -ForegroundColor Yellow

$windowsOld = "C:\Windows.old"

if (Test-Path $windowsOld) {
    $size = (Get-ChildItem $windowsOld -Recurse | Measure-Object Length -Sum).Sum
    $sizeGB = [math]::Round($size / 1GB, 2)
    
    Write-Host "  Found Windows.old: $sizeGB GB" -ForegroundColor White
    
    Write-Host "  Removing..." -ForegroundColor Yellow
    
    Remove-Item $windowsOld -Recurse -Force -ErrorAction SilentlyContinue
    
    if (-not (Test-Path $windowsOld)) {
        Write-Host "  Removed successfully" -ForegroundColor Green
    } else {
        Write-Host "  Could not remove (may need admin)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  No old installation found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Checking for Windows upgrade files..." -ForegroundColor Yellow

$upgradePath = "$env:WINDIR\Windows.old"

if (Test-Path $upgradePath) {
    Write-Host "  Found upgrade files" -ForegroundColor White
} else {
    Write-Host "  No upgrade files found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - Check complete" -ForegroundColor Green
exit 0
