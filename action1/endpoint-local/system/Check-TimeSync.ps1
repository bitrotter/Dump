<#
.SYNOPSIS
    Checks Windows Time service and sync status.

.DESCRIPTION
    Reports time sync configuration, source, and drift.

.PARAMETER SyncNow
    Force time sync.

.EXAMPLE
    .\Check-TimeSync.ps1

.EXAMPLE
    .\Check-TimeSync.ps1 -SyncNow
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$SyncNow
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Time Sync Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$w32time = Get-Service -Name W32Time

Write-Host "Windows Time Service:" -ForegroundColor Yellow
Write-Host "  Status: $($w32time.Status)" -ForegroundColor $(if ($w32time.Status -eq "Running") { "Green" } else { "Red" })

Write-Host ""
Write-Host "Time Configuration:" -ForegroundColor Yellow

$timeConfig = w32tm /query /configuration 2>&1 | Out-String

if ($timeConfig -match "Type:") {
    $type = ($timeConfig -split "Type:")[1].Split("`n")[0].Trim()
    Write-Host "  Type: $type" -ForegroundColor White
}

if ($timeConfig -match "NTP Server:") {
    $ntpServer = ($timeConfig -split "NTP Server:")[1].Split("`n")[0].Trim()
    Write-Host "  NTP Server: $ntpServer" -ForegroundColor White
}

Write-Host ""
Write-Host "Time Source:" -ForegroundColor Yellow

$timeSource = w32tm /query /source 2>&1
Write-Host "  Source: $timeSource" -ForegroundColor White

$lastSync = w32tm /query /status 2>&1 | Out-String

if ($lastSync -match "Last Successful Sync:") {
    $lastSyncTime = ($lastSync -split "Last Successful Sync:")[1].Split("`n")[0].Trim()
    Write-Host "  Last Sync: $lastSyncTime" -ForegroundColor White
}

Write-Host ""
Write-Host "Current Time:" -ForegroundColor Yellow

$currentTime = Get-Date
Write-Host "  Local: $($currentTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "  UTC: $($currentTime.ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

if ($SyncNow) {
    Write-Host ""
    Write-Host "Forcing time sync..." -ForegroundColor Yellow
    
    if ($w32time.Status -ne "Running") {
        Start-Service -Name W32Time
        Start-Sleep -Seconds 1
    }
    
    w32tm /resync /force 2>&1 | Out-String | Write-Host
    
    $newSource = w32tm /query /source 2>&1
    Write-Host "  Source after sync: $newSource" -ForegroundColor White
}

Write-Host ""

$drift = [math]::Abs(($currentTime.ToUniversalTime() - (Get-Date).ToUniversalTime()).TotalSeconds)

if ($w32time.Status -ne "Running") {
    Write-Host "RESULT:CRITICAL - Time service not running" -ForegroundColor Red
    exit 2
} else {
    Write-Host "RESULT:OK - Time service running" -ForegroundColor Green
    exit 0
}
