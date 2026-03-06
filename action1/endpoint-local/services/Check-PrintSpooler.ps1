<#
.SYNOPSIS
    Checks and fixes Print Spooler service.

.DESCRIPTION
    Checks Print Spooler status, clears stuck print jobs, 
    and restarts service if needed.

.PARAMETER ClearQueue
    Clear all pending print jobs.

.PARAMETER AutoRestart
    Automatically restart service if stopped.

.EXAMPLE
    .\Check-PrintSpooler.ps1

.EXAMPLE
    .\Check-PrintSpooler.ps1 -ClearQueue -AutoRestart
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ClearQueue,

    [Parameter(Mandatory=$false)]
    [switch]$AutoRestart
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Print Spooler Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$spooler = Get-Service -Name Spooler

Write-Host "Service Status: " -NoNewline -ForegroundColor Yellow
Write-Host $spooler.Status -ForegroundColor $(if ($spooler.Status -eq "Running") { "Green" } else { "Red" })

if ($spooler.Status -ne "Running") {
    if ($AutoRestart) {
        Write-Host "Attempting to start service..." -ForegroundColor Yellow
        Start-Service -Name Spooler
        Start-Sleep -Seconds 2
        
        $spooler = Get-Service -Name Spooler
        if ($spooler.Status -eq "Running") {
            Write-Host "Service started successfully" -ForegroundColor Green
        } else {
            Write-Host "Failed to start service" -ForegroundColor Red
        }
    }
}

$spoolerPath = "$env:WINDIR\System32\spool\PRINTERS"
$queueFiles = Get-ChildItem $spoolerPath -ErrorAction SilentlyContinue

Write-Host "Print Jobs in Queue: $($queueFiles.Count)" -ForegroundColor White

if ($queueFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Pending Jobs:" -ForegroundColor Yellow
    $queueFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    
    if ($ClearQueue) {
        Write-Host ""
        Write-Host "Clearing print queue..." -ForegroundColor Yellow
        Stop-Service -Name Spooler -Force
        Start-Sleep -Seconds 1
        
        Remove-Item "$spoolerPath\*" -Force -ErrorAction SilentlyContinue
        
        Start-Service -Name Spooler
        Start-Sleep -Seconds 2
        
        $queueFiles = Get-ChildItem $spoolerPath -ErrorAction SilentlyContinue
        Write-Host "Queue cleared. Remaining: $($queueFiles.Count)" -ForegroundColor Green
    }
}

Write-Host ""

if ($spooler.Status -ne "Running") {
    Write-Host "RESULT:CRITICAL - Print Spooler not running" -ForegroundColor Red
    exit 2
} elseif ($queueFiles.Count -gt 0) {
    Write-Host "RESULT:WARNING - $($queueFiles.Count) jobs in queue" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Print Spooler running, queue empty" -ForegroundColor Green
    exit 0
}
