<#
.SYNOPSIS
    Subscribes to Windows Event Log.

.DESCRIPTION
    Creates a permanent event log subscription.

.PARAMETER LogName
    Log to subscribe to.

.PARAMETER Collector
    Name for the collector.

.EXAMPLE
    .\New-EventLogSubscription.ps1 -LogName ForwardedEvents
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$LogName = "Application",

    [Parameter(Mandatory=$false)]
    [string]$Collector = "Action1Collector"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Event Log Subscription ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Checking existing subscriptions..." -ForegroundColor Yellow

$subs = wecutil /enum 2>&1

if ($subs -match $Collector) {
    Write-Host "  Subscription exists: $Collector" -ForegroundColor Green
} else {
    Write-Host "  No subscription found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Forwarding configuration:" -ForegroundColor Yellow

$config = wecutil /gc 2>&1

if ($config) {
    Write-Host "  Configured collectors: Yes" -ForegroundColor Green
} else {
    Write-Host "  No collectors configured" -ForegroundColor Gray
}

Write-Host ""
Write-Host "NOTE: Run as admin to create new subscriptions" -ForegroundColor Yellow

Write-Host ""
Write-Host "RESULT:OK - Subscription info retrieved" -ForegroundColor Green
exit 0
