<#
.SYNOPSIS
    Clears Windows Update download cache.

.DESCRIPTION
    Stops Windows Update service, clears SoftwareDistribution cache,
    and restarts services.

.PARAMETER KeepHistory
    Keep update history (only clear downloads).

.EXAMPLE
    .\Clear-WindowsUpdateCache.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$KeepHistory
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows Update Cache Clear ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$wuPath = "$env:WINDIR\SoftwareDistribution"

Write-Host "Checking current cache size..." -ForegroundColor Yellow

if (Test-Path $wuPath) {
    $cacheSize = (Get-ChildItem $wuPath -Recurse | Measure-Object Length -Sum).Sum
    $cacheSizeMB = [math]::Round($cacheSize / 1MB, 2)
    $cacheSizeGB = [math]::Round($cacheSize / 1GB, 2)
    
    Write-Host "  Current cache size: $cacheSizeMB MB ($cacheSizeGB GB)" -ForegroundColor White
}

Write-Host ""
Write-Host "Stopping Windows Update services..." -ForegroundColor Yellow

$services = @("wuauserv", "BITS", "CryptSvc", "TrustedInstaller")

foreach ($svc in $services) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Host "  Stopped $svc" -ForegroundColor Gray
    }
}

Start-Sleep -Seconds 2

Write-Host ""
Write-Host "Clearing cache folders..." -ForegroundColor Yellow

$pathsToClear = @(
    "$wuPath\Download",
    "$wuPath\Log"
)

if (-not $KeepHistory) {
    $pathsToClear += @("$wuPath\DataStore")
}

foreach ($path in $pathsToClear) {
    if (Test-Path $path) {
        $beforeSize = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        
        Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "  Cleared: $path" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Restarting services..." -ForegroundColor Yellow

foreach ($svc in $services) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        
        $service = Get-Service -Name $svc
        $color = if ($service.Status -eq "Running") { "Green" } else { "Yellow" }
        Write-Host "  $svc : $($service.Status)" -ForegroundColor $color
    }
}

Start-Sleep -Seconds 2

Write-Host ""
Write-Host "Verifying cache cleared..." -ForegroundColor Yellow

if (Test-Path $wuPath) {
    $newSize = (Get-ChildItem $wuPath -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    $newSizeMB = [math]::Round($newSize / 1MB, 2)
    Write-Host "  New cache size: $newSizeMB MB" -ForegroundColor White
}

Write-Host ""
Write-Host "RESULT:OK - Windows Update cache cleared" -ForegroundColor Green
exit 0
