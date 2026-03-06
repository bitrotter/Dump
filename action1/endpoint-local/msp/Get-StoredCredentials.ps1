<#
.SYNOPSIS
    Checks credential manager.

.DESCRIPTION
    Lists stored Windows credentials.

.EXAMPLE
    .\Get-StoredCredentials.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Stored Credentials ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Windows Credential Manager:" -ForegroundColor Yellow

$credPath = "HKCU:\Software\Microsoft\Credentials"

if (Test-Path $credPath) {
    $creds = Get-ChildItem $credPath -ErrorAction SilentlyContinue
    
    Write-Host "  Stored credentials: $($creds.Count)" -ForegroundColor White
    
    foreach ($cred in $creds | Select-Object -First 10) {
        Write-Host "    $($cred.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "  No stored credentials" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Generic Credentials:" -ForegroundColor Yellow

$genPath = "HKCU:\Software\Microsoft\Generic Credentials"

if (Test-Path $genPath) {
    $genCreds = Get-ChildItem $genPath -ErrorAction SilentlyContinue
    
    Write-Host "  Generic credentials: $($genCreds.Count)" -ForegroundColor White
}

Write-Host ""
Write-Host "Web Credentials:" -ForegroundColor Yellow

$webPath = "HKCU:\Software\Microsoft\Windows\WebCredentials"

if (Test-Path $webPath) {
    $webCreds = Get-ChildItem $webPath -ErrorAction SilentlyContinue
    
    Write-Host "  Web credentials: $($webCreds.Count)" -ForegroundColor White
}

Write-Host ""
Write-Host "RESULT:OK - Credentials listed" -ForegroundColor Green
exit 0
