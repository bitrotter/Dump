<#
.SYNOPSIS
    Runs SFC scan and repair.

.DESCRIPTION
    Runs System File Checker to repair corrupted files.

.PARAMETER ScanOnly
    Only scan without repairing.

.EXAMPLE
    .\Invoke-SFCRepair.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ScanOnly
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== SFC Scan & Repair ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if ($ScanOnly) {
    Write-Host "Running SFC scan (read-only)..." -ForegroundColor Yellow
    $result = sfc /scannow 2>&1
} else {
    Write-Host "Running SFC repair..." -ForegroundColor Yellow
    $result = sfc /scannow 2>&1
}

Write-Host ""
Write-Host "Output:" -ForegroundColor Gray

$lines = $result | Select-Object -Last 10
foreach ($line in $lines) {
    Write-Host "  $line" -ForegroundColor Gray
}

Write-Host ""

if ($result -match "Windows Resource Protection did not find any integrity violations") {
    Write-Host "RESULT:OK - No integrity violations found" -ForegroundColor Green
    exit 0
} elseif ($result -match "was unable to perform") {
    Write-Host "RESULT:WARNING - SFC could not complete" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - SFC scan complete" -ForegroundColor Green
    exit 0
}
