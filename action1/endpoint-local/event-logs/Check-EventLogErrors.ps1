<#
.SYNOPSIS
    Checks for recent errors in Windows Event Logs.

.DESCRIPTION
    Scans System, Application, and Security logs for errors in the last 24 hours.

.PARAMETER Hours
    Number of hours to look back. Default: 24.

.PARAMETER LogName
    Specific log to check. Default: all (System,Application,Security).

.EXAMPLE
    .\Check-EventLogErrors.ps1

.EXAMPLE
    .\Check-EventLogErrors.ps1 -Hours 48
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Hours = 24,

    [Parameter(Mandatory=$false)]
    [ValidateSet("System", "Application", "Security", "All")]
    [string]$LogName = "All"
)

$ErrorActionPreference = 'SilentlyContinue'

$startTime = (Get-Date).AddHours(-$Hours)

Write-Host "=== Event Log Error Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Time Range: Last $Hours hours" -ForegroundColor Gray
Write-Host ""

$logs = if ($LogName -eq "All") { @("System", "Application", "Security") } else { @($LogName) }

$totalErrors = 0
$errorDetails = @()

foreach ($log in $logs) {
    $events = Get-WinEvent -FilterHashtable @{
        LogName = $log
        StartTime = $startTime
        Level = 1,2,3
    } -MaxEvents 50 -ErrorAction SilentlyContinue
    
    $errors = $events | Where-Object { $_.LevelDisplayName -eq "Error" }
    $warnings = $events | Where-Object { $_.LevelDisplayName -eq "Warning" }
    
    $errorCount = $errors.Count
    $warningCount = $warnings.Count
    $totalErrors += $errorCount
    
    $statusColor = if ($errorCount -gt 0) { "Red" } elseif ($warningCount -gt 0) { "Yellow" } else { "Green" }
    
    Write-Host "$log Log" -ForegroundColor Cyan
    Write-Host "  Errors  : $errorCount" -ForegroundColor $statusColor
    Write-Host "  Warnings: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })
    
    if ($errors -and $errorCount -le 10) {
        foreach ($err in $errors) {
            $errorDetails += [PSCustomObject]@{
                TimeGenerated = $err.TimeCreated
                LogName      = $log
                Level       = "Error"
                Source      = $err.ProviderName
                Message     = ($err.Message -split "`n")[0]
            }
        }
    }
}

Write-Host ""
Write-Host "Total Errors: $totalErrors" -ForegroundColor $(if ($totalErrors -gt 0) { "Red" } else { "Green" })

if ($errorDetails -and $errorDetails.Count -le 20) {
    Write-Host ""
    Write-Host "Recent Errors:" -ForegroundColor Cyan
    $errorDetails | Format-Table TimeGenerated, LogName, Source, Message | Out-String | Write-Host
}

Write-Host ""

if ($totalErrors -gt 10) {
    Write-Host "RESULT:CRITICAL - $totalErrors errors found in last $Hours hours" -ForegroundColor Red
    exit 2
} elseif ($totalErrors -gt 0) {
    Write-Host "RESULT:WARNING - $totalErrors errors found in last $Hours hours" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - No errors in recent event logs" -ForegroundColor Green
    exit 0
}
