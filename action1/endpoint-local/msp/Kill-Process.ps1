<#
.SYNOPSIS
    Kills a hung or unresponsive process.

.DESCRIPTION
    Terminates a process by name or PID.

.PARAMETER ProcessName
    Name of process to kill.

.PARAMETER PID
    Process ID to kill.

.EXAMPLE
    .\Kill-Process.ps1 -ProcessName "notepad"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ProcessName,

    [Parameter(Mandatory=$false)]
    [int]$PID
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Kill Process ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $ProcessName -and -not $PID) {
    Write-Host "ERROR: Must specify -ProcessName or -PID" -ForegroundColor Red
    exit 1
}

if ($PID) {
    Write-Host "Killing PID: $PID" -ForegroundColor Yellow
    
    $process = Get-Process -Id $PID -ErrorAction SilentlyContinue
    
    if ($process) {
        Stop-Process -Id $PID -Force -ErrorAction Stop
        Write-Host "  Process terminated" -ForegroundColor Green
    } else {
        Write-Host "  Process not found" -ForegroundColor Red
        exit 1
    }
}

if ($ProcessName) {
    Write-Host "Killing process: $ProcessName" -ForegroundColor Yellow
    
    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    
    if ($processes) {
        $count = $processes.Count
        Stop-Process -Name $ProcessName -Force -ErrorAction Stop
        Write-Host "  Terminated $count instance(s)" -ForegroundColor Green
    } else {
        Write-Host "  Process not found" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "RESULT:OK - Process killed" -ForegroundColor Green
exit 0
