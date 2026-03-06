<#
.SYNOPSIS
    Gets detailed service information.

.DESCRIPTION
    Shows service details including dependencies.

.PARAMETER ServiceName
    Service name to check.

.EXAMPLE
    .\Get-ServiceDetails.ps1 -ServiceName "Spooler"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Service Details ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $ServiceName) {
    Write-Host "Running Services:" -ForegroundColor Yellow
    
    Get-Service | Where-Object { $_.Status -eq "Running" } | Select-Object -First 20 | ForEach-Object {
        Write-Host "  $($_.Name): $($_.DisplayName)" -ForegroundColor Green
    }
    
    exit 0
}

Write-Host "Service: $ServiceName" -ForegroundColor Yellow

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if (-not $svc) {
    Write-Host "Service not found" -ForegroundColor Red
    exit 1
}

Write-Host "  Display Name: $($svc.DisplayName)" -ForegroundColor White
Write-Host "  Status: $($svc.Status)" -ForegroundColor $(if ($svc.Status -eq "Running") { "Green" } else { "Red" })
Write-Host "  Start Type: $($svc.StartType)" -ForegroundColor Gray

Write-Host ""
Write-Host "Dependencies:" -ForegroundColor Yellow

$deps = $svc.DependentServices

if ($deps) {
    foreach ($dep in $deps) {
        $color = if ($dep.Status -eq "Running") { "Green" } else { "Red" }
        Write-Host "  $($dep.Name): $($dep.Status)" -ForegroundColor $color
    }
} else {
    Write-Host "  None" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Required Services:" -ForegroundColor Yellow

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
Write-Host "WMI Information:" -ForegroundColor Yellow

$wmi = Get-CimInstance Win32_Service | Where-Object { $_.Name -eq $ServiceName }

if ($wmi) {
    Write-Host "  Path: $($wmi.PathName)" -ForegroundColor Gray
    Write-Host "  Process ID: $($wmi.ProcessId)" -ForegroundColor Gray
    Write-Host "  Description: $($wmi.Description)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - Service details retrieved" -ForegroundColor Green
exit 0
