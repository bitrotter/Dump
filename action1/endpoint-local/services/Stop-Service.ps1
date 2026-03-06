<#
.SYNOPSIS
    Stops a service.

.DESCRIPTION
    Stops the specified service.

.PARAMETER ServiceName
    Service name to stop.

.EXAMPLE
    .\Stop-Service.ps1 -ServiceName "Spooler"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Stop Service ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $ServiceName) {
    Write-Host "Usage: Stop-Service -ServiceName <name>" -ForegroundColor Yellow
    exit 0
}

Write-Host "Stopping service: $ServiceName" -ForegroundColor Yellow

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if (-not $svc) {
    Write-Host "Service not found" -ForegroundColor Red
    exit 1
}

Write-Host "  Current status: $($svc.Status)" -ForegroundColor White

try {
    Stop-Service -Name $ServiceName -Force -ErrorAction Stop
    Start-Sleep -Seconds 2
    
    $svc = Get-Service -Name $ServiceName
    Write-Host "  New status: $($svc.Status)" -ForegroundColor Green
    
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "RESULT:OK - Service stopped" -ForegroundColor Green
exit 0
