<#
.SYNOPSIS
    Restarts a Windows service.

.DESCRIPTION
    Restarts the specified service.

.PARAMETER ServiceName
    Name of service to restart.

.EXAMPLE
    .\Restart-Service.ps1 -ServiceName "Spooler"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Restart Service ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $ServiceName) {
    Write-Host "Common Services:" -ForegroundColor Yellow
    $services = @("Spooler", "wuauserv", "BITS", "EventLog", "W32Time")
    
    foreach ($svc in $services) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) {
            Write-Host "  $svc : $($s.Status)" -ForegroundColor White
        }
    }
    
    exit 0
}

Write-Host "Restarting service: $ServiceName" -ForegroundColor Yellow

$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if (-not $service) {
    Write-Host "Service not found" -ForegroundColor Red
    exit 1
}

Write-Host "  Current status: $($service.Status)" -ForegroundColor White

try {
    Restart-Service -Name $ServiceName -Force -ErrorAction Stop
    Start-Sleep -Seconds 2
    
    $service = Get-Service -Name $ServiceName
    Write-Host "  New status: $($service.Status)" -ForegroundColor Green
    
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "RESULT:OK - Service restarted" -ForegroundColor Green
exit 0
