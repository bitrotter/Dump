<#
.SYNOPSIS
    Gets service logon account.

.DESCRIPTION
    Shows which account a service runs under.

.PARAMETER ServiceName
    Service name.

.EXAMPLE
    .\Get-ServiceLogon.ps1 -ServiceName "Spooler"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Service Logon Account ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $ServiceName) {
    Write-Host "Common Services:" -ForegroundColor Yellow
    
    $services = @("Spooler", "wuauserv", "BITS", "EventLog", "W32Time")
    
    foreach ($svc in $services) {
        $s = Get-WmiObject Win32_Service -Filter "Name='$svc'" -ErrorAction SilentlyContinue
        
        if ($s) {
            Write-Host "  $($s.Name): $($s.StartName)" -ForegroundColor White
        }
    }
    
    exit 0
}

Write-Host "Service: $ServiceName" -ForegroundColor Yellow

$svc = Get-WmiObject Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue

if ($svc) {
    Write-Host "  Start Name: $($svc.StartName)" -ForegroundColor White
    Write-Host "  Path: $($svc.PathName)" -ForegroundColor Gray
    Write-Host "  State: $($svc.State)" -ForegroundColor $(if ($svc.State -eq "Running") { "Green" } else { "Red" })
} else {
    Write-Host "  Service not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "RESULT:OK - Logon info retrieved" -ForegroundColor Green
exit 0
