<#
.SYNOPSIS
    Finds a service by name pattern.

.DESCRIPTION
    Searches for services matching a pattern.

.PARAMETER Pattern
    Search pattern.

.EXAMPLE
    .\Find-Service.ps1 -Pattern "Windows*"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Pattern = "*"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Find Service ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Pattern: $Pattern" -ForegroundColor Gray
Write-Host ""

Write-Host "Matching Services:" -ForegroundColor Yellow

$services = Get-Service -Name $Pattern

foreach ($svc in $services) {
    $color = if ($svc.Status -eq "Running") { "Green" } else { "Gray" }
    Write-Host "  $($svc.Name): $($svc.Status) ($($svc.StartType))" -ForegroundColor $color
}

Write-Host ""
Write-Host "Found: $($services.Count)" -ForegroundColor White

Write-Host ""
Write-Host "RESULT:OK - Search complete" -ForegroundColor Green
exit 0
