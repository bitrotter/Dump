<#
.SYNOPSIS
    Monitors service status.

.DESCRIPTION
    Watches for service status changes.

.PARAMETER ServiceName
    Service to monitor.

.PARAMETER Seconds
    Duration in seconds.

.EXAMPLE
    .\Watch-Service.ps1 -ServiceName Spooler -Seconds 60
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName,

    [Parameter(Mandatory=$false)]
    [int]$Seconds = 30
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Watch Service ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $ServiceName) {
    Write-Host "Usage: Watch-Service -ServiceName <name> -Seconds <duration>" -ForegroundColor Yellow
    exit 0
}

Write-Host "Monitoring: $ServiceName for $Seconds seconds" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
$initialStatus = $svc.Status

Write-Host "Initial status: $initialStatus" -ForegroundColor White

$startTime = Get-Date

while (((Get-Date) - $startTime).TotalSeconds -lt $Seconds) {
    $current = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    
    if ($current.Status -ne $initialStatus) {
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] STATUS CHANGE: $($current.Status)" -ForegroundColor Red
        $initialStatus = $current.Status
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "RESULT:OK - Monitoring complete" -ForegroundColor Green
exit 0
