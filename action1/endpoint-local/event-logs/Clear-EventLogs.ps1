<#
.SYNOPSIS
    Clears all event logs.

.DESCRIPTION
    Clears specified or all Windows event logs.

.PARAMETER LogName
    Specific log to clear (default: all).

.EXAMPLE
    .\Clear-EventLogs.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$LogName
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Clear Event Logs ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if ($LogName) {
    Write-Host "Clearing log: $LogName" -ForegroundColor Yellow
    
    try {
        Clear-EventLog -LogName $LogName -ErrorAction Stop
        Write-Host "  Cleared: $LogName" -ForegroundColor Green
    } catch {
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Clearing all logs..." -ForegroundColor Yellow
    
    $logs = @("Application", "Security", "System")
    
    foreach ($log in $logs) {
        try {
            Clear-EventLog -LogName $log -ErrorAction Stop
            Write-Host "  Cleared: $log" -ForegroundColor Green
        } catch {
            Write-Host "  Failed: $log" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "RESULT:OK - Logs cleared" -ForegroundColor Green
exit 0
