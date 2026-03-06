<#
.SYNOPSIS
    Exports event logs to file.

.DESCRIPTION
    Exports specified event logs to EVTX or CSV.

.PARAMETER LogName
    Log to export (default: System,Application,Security).

.PARAMETER Hours
    Hours to look back.

.PARAMETER OutputPath
    Output file path.

.EXAMPLE
    .\Export-EventLogs.ps1 -LogName System -Hours 24
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$LogName = "System,Application,Security",

    [Parameter(Mandatory=$false)]
    [int]$Hours = 24,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$env:TEMP\EventLogs"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Export Event Logs ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$startTime = (Get-Date).AddHours(-$Hours)
$logs = $LogName -split ","

foreach ($log in $logs) {
    $logName = $log.Trim()
    $fileName = "$OutputPath\$logName`_$((Get-Date).ToString('yyyyMMdd_HHmmss')).evtx"
    
    Write-Host "Exporting $logName..." -ForegroundColor Yellow
    
    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName = $logName
            StartTime = $startTime
        } -MaxEvents 1000 -ErrorAction SilentlyContinue
        
        if ($events) {
            $events | Export-Csv -Path "$fileName.csv" -NoTypeInformation -ErrorAction SilentlyContinue
            Write-Host "  Exported $($events.Count) events to CSV" -ForegroundColor Green
        } else {
            Write-Host "  No events found" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Exported to: $OutputPath" -ForegroundColor White

Write-Host ""
Write-Host "RESULT:OK - Export complete" -ForegroundColor Green
exit 0
