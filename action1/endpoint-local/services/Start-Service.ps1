<#
.SYNOPSIS
    Starts a service.

.DESCRIPTION
    Starts the specified service.

.PARAMETER ServiceName
    Service name to start.

.EXAMPLE
    .\Start-Service.ps1 -ServiceName "Spooler"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Start Service ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $ServiceName) {
    Write-Host "Usage: Start-Service -ServiceName <name>" -ForegroundColor Yellow
    exit 0
}

Write-Host "Starting service: $ServiceName" -ForegroundColor Yellow

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if (-not $svc) {
    Write-Host "Service not found" -ForegroundColor Red
    exit 1
}

Write-Host "  Current status: $($svc.Status)" -ForegroundColor White

try {
    Start-Service -Name $ServiceName -ErrorAction Stop
    Start-Sleep -Seconds 2
    
    $svc = Get-Service -Name $ServiceName
    Write-Host "  New status: $($svc.Status)" -ForegroundColor $(if ($svc.Status -eq "Running") { "Green" } else { "Yellow" })
    
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "RESULT:OK - Service started" -ForegroundColor Green
exit 0
