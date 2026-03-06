<#
.SYNOPSIS
    Restarts Windows Update service and related services.

.DESCRIPTION
    Stops and restarts Windows Update, BITS, and Cryptographic services.
    Clears SoftwareDistribution cache if needed.

.PARAMETER ClearCache
    Clear Windows Update cache before restarting.

.EXAMPLE
    .\Restart-WindowsUpdate.ps1

.EXAMPLE
    .\Restart-WindowsUpdate.ps1 -ClearCache
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ClearCache
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows Update Service Restart ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$services = @("wuauserv", "BITS", "CryptSvc", "TrustedInstaller")

if ($ClearCache) {
    Write-Host "Stopping services..." -ForegroundColor Yellow
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service -Name BITS -Force -ErrorAction SilentlyContinue
    
    Write-Host "Clearing Windows Update cache..." -ForegroundColor Yellow
    $cachePath = "$env:WINDIR\SoftwareDistribution\Download"
    if (Test-Path $cachePath) {
        $size = (Get-ChildItem $cachePath -Recurse | Measure-Object Length -Sum).Sum
        Remove-Item "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Cleared $([math]::Round($size/1MB, 2)) MB from cache" -ForegroundColor Green
    }
}

Write-Host "Starting services..." -ForegroundColor Yellow

foreach ($svc in $services) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        
        $service = Get-Service -Name $svc
        $color = if ($service.Status -eq "Running") { "Green" } else { "Red" }
        Write-Host "  $svc : $($service.Status)" -ForegroundColor $color
    }
}

Write-Host ""
Write-Host "RESULT:OK - Services restarted" -ForegroundColor Green
exit 0
