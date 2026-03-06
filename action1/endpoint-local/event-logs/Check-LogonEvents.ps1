<#
.SYNOPSIS
    Checks Security log for logon events.

.DESCRIPTION
    Analyzes Security event log for logon activity.

.PARAMETER Hours
    Hours to look back (default: 24).

.EXAMPLE
    .\Check-LogonEvents.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Hours = 24
)

$ErrorActionPreference = 'SilentlyContinue'

$startTime = (Get-Date).AddHours(-$Hours)

Write-Host "=== Logon Events ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Last $Hours hours" -ForegroundColor Gray
Write-Host ""

Write-Host "Successful Logons:" -ForegroundColor Green

$logons = Get-WinEvent -FilterHashtable @{
    LogName = "Security"
    Id = 4624
    StartTime = $startTime
} -MaxEvents 20 -ErrorAction SilentlyContinue

if ($logons) {
    foreach ($event in $logons | Select-Object -First 10) {
        $time = $event.TimeCreated
        $user = $event.Properties[5].Value
        $domain = $event.Properties[6].Value
        $logonType = $event.Properties[8].Value
        
        $logonTypeStr = switch ($logonType) {
            2 { "Interactive" }
            3 { "Network" }
            4 { "Batch" }
            5 { "Service" }
            7 { "Unlock" }
            10 { "RemoteInteractive" }
            11 { "CachedInteractive" }
            default { "Type $logonType" }
        }
        
        Write-Host "  $time - $domain\$user ($logonTypeStr)" -ForegroundColor White
    }
} else {
    Write-Host "  No logons found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Failed Logons:" -ForegroundColor Red

$failed = Get-WinEvent -FilterHashtable @{
    LogName = "Security"
    Id = 4625
    StartTime = $startTime
} -MaxEvents 20 -ErrorAction SilentlyContinue

if ($failed) {
    foreach ($event in $failed | Select-Object -First 10) {
        $time = $event.TimeCreated
        $user = $event.Properties[5].Value
        $domain = $event.Properties[6].Value
        $reason = $event.Properties[10].Value
        
        Write-Host "  $time - $domain\$user" -ForegroundColor Yellow
        Write-Host "    Reason: $reason" -ForegroundColor Gray
    }
} else {
    Write-Host "  No failed logons" -ForegroundColor Green
}

Write-Host ""
Write-Host "Special Logons:" -ForegroundColor Cyan

$special = Get-WinEvent -FilterHashtable @{
    LogName = "Security"
    Id = 4672
    StartTime = $startTime
} -MaxEvents 10 -ErrorAction SilentlyContinue

if ($special) {
    foreach ($event in $special) {
        $time = $event.TimeCreated
        $user = $event.Properties[1].Value
        
        Write-Host "  $time - $user (Special privileges)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "RESULT:OK - Logon events checked" -ForegroundColor Green
exit 0
