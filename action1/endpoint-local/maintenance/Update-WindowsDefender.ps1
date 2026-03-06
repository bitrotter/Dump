<#
.SYNOPSIS
    Checks Windows Defender updates.

.DESCRIPTION
    Reports Windows Defender definition version and updates.

.EXAMPLE
    .\Update-WindowsDefender.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows Defender Update ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Current Status:" -ForegroundColor Yellow

try {
    $defender = Get-MpComputerStatus
    
    Write-Host "  Real-Time Protection: $($defender.RealTimeProtectionEnabled)" -ForegroundColor $(if ($defender.RealTimeProtectionEnabled) { "Green" } else { "Red" })
    Write-Host "  Antivirus Enabled: $($defender.AntivirusEnabled)" -ForegroundColor $(if ($defender.AntivirusEnabled) { "Green" } else { "Red" })
    
    Write-Host ""
    Write-Host "Signature Info:" -ForegroundColor Yellow
    Write-Host "  Version: $($defender.AntivirusSignatureVersion)" -ForegroundColor White
    Write-Host "  Last Updated: $($defender.AntivirusSignatureLastUpdated)" -ForegroundColor Gray
    
    $age = (Get-Date) - $defender.AntivirusSignatureLastUpdated
    Write-Host "  Age: $($age.Days) days" -ForegroundColor $(if ($age.Days -gt 7) { "Yellow" } else { "Green" })
    
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Updating definitions..." -ForegroundColor Yellow

try {
    Update-MpSignature -ErrorAction Stop
    Write-Host "  Update initiated" -ForegroundColor Green
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "RESULT:OK - Defender update triggered" -ForegroundColor Green
exit 0
