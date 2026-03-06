<#
.SYNOPSIS
    Checks Application Event Log for errors.

.DESCRIPTION
    Scans Application log for errors and warnings,
    grouped by source.

.PARAMETER Hours
    Hours to look back. Default: 24.

.PARAMETER Top
    Number of top error sources to show. Default: 10.

.EXAMPLE
    .\Check-ApplicationEventLog.ps1

.EXAMPLE
    .\Check-ApplicationEventLog.ps1 -Hours 48
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Hours = 24,

    [Parameter(Mandatory=$false)]
    [int]$Top = 10
)

$ErrorActionPreference = 'SilentlyContinue'

$startTime = (Get-Date).AddHours(-$Hours)

Write-Host "=== Application Event Log Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Time Range: Last $Hours hours" -ForegroundColor Gray
Write-Host ""

Write-Host "Scanning Application log..." -ForegroundColor Yellow

$events = Get-WinEvent -FilterHashtable @{
    LogName = "Application"
    StartTime = $startTime
    Level = 1,2,3
} -MaxEvents 500 -ErrorAction SilentlyContinue

$errors = $events | Where-Object { $_.LevelDisplayName -eq "Error" }
$warnings = $events | Where-Object { $LevelDisplayName -eq "Warning" }

$errorCount = ($errors | Measure-Object).Count
$warningCount = ($warnings | Measure-Object).Count

Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Warnings: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })

if ($errorCount -gt 0) {
    Write-Host ""
    Write-Host "Top Error Sources:" -ForegroundColor Red
    
    $errorSources = $errors | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First $Top
    
    foreach ($source in $errorSources) {
        Write-Host "  $($source.Name): $($source.Count)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Recent Errors:" -ForegroundColor Red
    
    $errors | Select-Object -First 10 | ForEach-Object {
        $msg = $_.Message -split "`n" | Select-Object -First 1
        if ($msg.Length -gt 80) { $msg = $msg.Substring(0, 80) + "..." }
        Write-Host "  [$($_.TimeCreated.ToString('HH:mm:ss'))] $($_.ProviderName): $msg" -ForegroundColor Gray
    }
}

if ($warningCount -gt 0) {
    Write-Host ""
    Write-Host "Top Warning Sources:" -ForegroundColor Yellow
    
    $warningSources = $warnings | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First $Top
    
    foreach ($source in $warningSources) {
        Write-Host "  $($source.Name): $($source.Count)" -ForegroundColor White
    }
}

Write-Host ""

if ($errorCount -gt 20) {
    Write-Host "RESULT:CRITICAL - $errorCount errors in Application log" -ForegroundColor Red
    exit 2
} elseif ($errorCount -gt 0) {
    Write-Host "RESULT:WARNING - $errorCount errors in Application log" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - No Application errors" -ForegroundColor Green
    exit 0
}
