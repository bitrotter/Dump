<#
.SYNOPSIS
    Checks critical Windows services.

.DESCRIPTION
    Verifies that essential system services are running.

.EXAMPLE
    .\Check-CriticalServices.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Critical Services Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$criticalServices = @{
    "wuauserv" = "Windows Update"
    "BITS" = "Background Intelligent Transfer"
    "EventLog" = "Windows Event Log"
    "WinDefend" = "Windows Defender"
    "MpsSvc" = "Windows Firewall"
    "Dhcp" = "DHCP Client"
    "Dnscache" = "DNS Client"
    "LanmanServer" = "Server"
    "LanmanWorkstation" = "Workstation"
    "W32Time" = "Windows Time"
    "PlugPlay" = "Plug and Play"
    "RpcSs" = "RPCSS"
    "SamSs" = "Security Accounts Manager"
    "Spooler" = "Print Spooler"
}

$issues = @()

Write-Host "Checking critical services..." -ForegroundColor Yellow
Write-Host ""

foreach ($service in $criticalServices.GetEnumerator()) {
    $svc = Get-Service -Name $service.Key -ErrorAction SilentlyContinue
    
    if ($svc) {
        $status = if ($svc.Status -eq "Running") { "OK" } else { "STOPPED" }
        $color = if ($svc.Status -eq "Running") { "Green" } else { "Red" }
        
        if ($svc.Status -ne "Running") {
            $issues += $service.Value
        }
        
        Write-Host "  $($service.Value): $status" -ForegroundColor $color
    } else {
        Write-Host "  $($service.Value): NOT FOUND" -ForegroundColor Gray
    }
}

Write-Host ""

if ($issues.Count -gt 0) {
    Write-Host "RESULT:WARNING - $($issues.Count) critical service(s) not running" -ForegroundColor Yellow
    Write-Host "  Issues: $($issues -join ', ')" -ForegroundColor Red
    exit 1
} else {
    Write-Host "RESULT:OK - All critical services running" -ForegroundColor Green
    exit 0
}
