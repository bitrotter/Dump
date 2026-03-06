<#
.SYNOPSIS
    Checks service dependencies.

.DESCRIPTION
    Shows service dependency tree.

.PARAMETER ServiceName
    Service name.

.EXAMPLE
    .\Get-ServiceDependencies.ps1 -ServiceName "Spooler"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Service Dependencies ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $ServiceName) {
    Write-Host "Usage: Get-ServiceDependencies -ServiceName <name>" -ForegroundColor Yellow
    exit 0
}

Write-Host "Dependencies for: $ServiceName" -ForegroundColor Yellow
Write-Host ""

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if (-not $svc) {
    Write-Host "Service not found" -ForegroundColor Red
    exit 1
}

Write-Host "Requires (depends on):" -ForegroundColor White

$required = $svc.ServicesDependedOn

if ($required) {
    foreach ($req in $required) {
        $color = if ($req.Status -eq "Running") { "Green" } else { "Red" }
        Write-Host "  $($req.Name): $($req.Status)" -ForegroundColor $color
    }
} else {
    Write-Host "  None" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Required by:" -ForegroundColor White

$dependents = $svc.DependentServices

if ($dependents) {
    foreach ($dep in $dependents) {
        $color = if ($dep.Status -eq "Running") { "Green" } else { "Red" }
        Write-Host "  $($dep.Name): $($dep.Status)" -ForegroundColor $color
    }
} else {
    Write-Host "  None" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - Dependencies shown" -ForegroundColor Green
exit 0
