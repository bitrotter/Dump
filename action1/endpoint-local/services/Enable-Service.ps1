<#
.SYNOPSIS
    Enables a disabled service.

.DESCRIPTION
    Enables and starts a disabled service.

.PARAMETER ServiceName
    Service name.

.EXAMPLE
    .\Enable-Service.ps1 -ServiceName "Spooler"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Enable Service ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $ServiceName) {
    Write-Host "Usage: Enable-Service -ServiceName <name>" -ForegroundColor Yellow
    exit 0
}

Write-Host "Enabling service: $ServiceName" -ForegroundColor Yellow

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if (-not $svc) {
    Write-Host "Service not found" -ForegroundColor Red
    exit 1
}

Write-Host "  Current status: $($svc.Status)" -ForegroundColor White

try {
    Set-Service -Name $ServiceName -StartupType Automatic -ErrorAction Stop
    Start-Service -Name $ServiceName -ErrorAction Stop
    
    Start-Sleep -Seconds 2
    
    $svc = Get-Service -Name $ServiceName
    Write-Host "  New status: $($svc.Status)" -ForegroundColor Green
    
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "RESULT:OK - Service enabled" -ForegroundColor Green
exit 0
