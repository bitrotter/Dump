<#
.SYNOPSIS
    Monitors an event log in real-time.

.DESCRIPTION
    Watches for new events matching criteria.

.PARAMETER LogName
    Log to monitor (default: Application).

.PARAMETER Filter
    Event ID or keyword to filter.

.PARAMETER Seconds
    How long to monitor (default: 30).

.EXAMPLE
    .\Watch-EventLog.ps1 -LogName System -Seconds 60
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$LogName = "Application",

    [Parameter(Mandatory=$false)]
    [string]$Filter,

    [Parameter(Mandatory=$false)]
    [int]$Seconds = 30
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Watch Event Log ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Monitoring: $LogName for $Seconds seconds" -ForegroundColor Gray
Write-Host ""

Write-Host "Watching for events..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date

while (((Get-Date) - $startTime).TotalSeconds -lt $Seconds) {
    $events = Get-WinEvent -LogName $LogName -MaxEvents 1 -ErrorAction SilentlyContinue
    
    if ($events) {
        $event = $events[0]
        
        $match = $true
        if ($Filter) {
            $match = ($event.Message -match $Filter -or $event.Id -eq $Filter)
        }
        
        if ($match) {
            $color = switch ($event.LevelDisplayName) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                default { "White" }
            }
            
            Write-Host "[$($event.TimeCreated.ToString('HH:mm:ss'))] $($event.LevelDisplayName): $($event.Message.Substring(0, [Math]::Min(100, $event.Message.Length)))..." -ForegroundColor $color
        }
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "RESULT:OK - Watch complete" -ForegroundColor Green
exit 0
