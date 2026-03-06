<#
.SYNOPSIS
    Gets recent system errors for troubleshooting.

.DESCRIPTION
    Collects errors from multiple logs for support tickets.

.PARAMETER Hours
    Hours to look back. Default: 24.

.EXAMPLE
    .\Get-SystemErrors.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Hours = 24
)

$ErrorActionPreference = 'SilentlyContinue'

$startTime = (Get-Date).AddHours(-$Hours)

Write-Host "=== System Errors Report ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Last $Hours hours" -ForegroundColor Gray
Write-Host ""

$logs = @("System", "Application", "Security")
$allErrors = @()

foreach ($logName in $logs) {
    Write-Host "Checking $logName log..." -ForegroundColor Yellow
    
    $events = Get-WinEvent -FilterHashtable @{
        LogName = $logName
        StartTime = $startTime
        Level = 1,2
    } -MaxEvents 20 -ErrorAction SilentlyContinue
    
    if ($events) {
        Write-Host "  Found $($events.Count) errors/warnings" -ForegroundColor White
        
        foreach ($event in $events) {
            $allErrors += [PSCustomObject]@{
                Time = $event.TimeCreated
                Log = $logName
                Level = $event.LevelDisplayName
                Source = $event.ProviderName
                Message = ($event.Message -split "`n")[0]
            }
        }
    } else {
        Write-Host "  No errors" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Critical Errors:" -ForegroundColor Red

$critical = $allErrors | Where-Object { $_.Level -eq "Error" } | Select-Object -First 10

if ($critical) {
    foreach ($err in $critical) {
        Write-Host ""
        Write-Host "  [$($err.Time.ToString('HH:mm'))] $($err.Log): $($err.Source)" -ForegroundColor White
        $msg = $err.Message
        if ($msg.Length -gt 80) { $msg = $msg.Substring(0, 80) + "..." }
        Write-Host "    $msg" -ForegroundColor Gray
    }
} else {
    Write-Host "  None" -ForegroundColor Green
}

Write-Host ""
Write-Host "Error Count by Source:" -ForegroundColor Yellow

$bySource = $allErrors | Group-Object Source | Sort-Object Count -Descending | Select-Object -First 10

foreach ($source in $bySource) {
    Write-Host "  $($source.Name): $($source.Count)" -ForegroundColor White
}

Write-Host ""

$errorCount = ($allErrors | Where-Object { $_.Level -eq "Error" }).Count

if ($errorCount -gt 20) {
    Write-Host "RESULT:CRITICAL - $errorCount errors found" -ForegroundColor Red
    exit 2
} elseif ($errorCount -gt 0) {
    Write-Host "RESULT:WARNING - $errorCount errors found" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - No errors" -ForegroundColor Green
    exit 0
}
