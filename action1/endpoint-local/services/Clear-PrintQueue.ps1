<#
.SYNOPSIS
    Clears print queue and restarts spooler.

.DESCRIPTION
    Stops print spooler, removes all print jobs,
    and restarts the service.

.PARAMETER KeepSpooler
    Do not restart spooler after clearing.

.EXAMPLE
    .\Clear-PrintQueue.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$KeepSpooler
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Print Queue Clear ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$spoolerPath = "$env:WINDIR\System32\spool\PRINTERS"

Write-Host "Checking print queue..." -ForegroundColor Yellow

$printers = Get-Printer -ErrorAction SilentlyContinue
Write-Host "  Installed printers: $($printers.Count)" -ForegroundColor White

if (Test-Path $spoolerPath) {
    $queueFiles = Get-ChildItem $spoolerPath -ErrorAction SilentlyContinue
    $jobCount = $queueFiles.Count
    
    Write-Host "  Pending jobs: $jobCount" -ForegroundColor White
    
    if ($jobCount -gt 0) {
        Write-Host ""
        Write-Host "Stopping Print Spooler..." -ForegroundColor Yellow
        
        Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        
        Write-Host "Clearing print queue..." -ForegroundColor Yellow
        
        $cleared = Remove-Item "$spoolerPath\*" -Force -ErrorAction SilentlyContinue
        
        $remaining = (Get-ChildItem $spoolerPath -ErrorAction SilentlyContinue).Count
        Write-Host "  Remaining files: $remaining" -ForegroundColor $(if ($remaining -eq 0) { "Green" } else { "Yellow" })
        
        if (-not $KeepSpooler) {
            Write-Host ""
            Write-Host "Starting Print Spooler..." -ForegroundColor Yellow
            
            Start-Service -Name Spooler -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            
            $spooler = Get-Service -Name Spooler
            Write-Host "  Service status: $($spooler.Status)" -ForegroundColor $(if ($spooler.Status -eq "Running") { "Green" } else { "Red" })
        }
    } else {
        Write-Host "  Queue already empty" -ForegroundColor Green
    }
} else {
    Write-Host "  Spooler directory not found" -ForegroundColor Red
}

Write-Host ""

if ($jobCount -gt 0) {
    Write-Host "RESULT:OK - Cleared $jobCount print jobs" -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT:OK - Queue was empty" -ForegroundColor Green
    exit 0
}
