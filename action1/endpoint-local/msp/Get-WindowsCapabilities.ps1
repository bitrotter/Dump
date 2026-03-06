<#
.SYNOPSIS
    Lists installed Windows capabilities.

.DESCRIPTION
    Shows optional Windows capabilities like languages, features on demand.

.EXAMPLE
    .\Get-WindowsCapabilities.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows Capabilities ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Installed Capabilities:" -ForegroundColor Yellow

$caps = Get-WindowsCapability -Online | Select-Object Name, State

$enabled = $caps | Where-Object { $_.State -eq "Installed" }
$removed = $caps | Where-Object { $_.State -eq "Removed" }

Write-Host "  Enabled: $($enabled.Count)" -ForegroundColor Green
Write-Host "  Removed: $($removed.Count)" -ForegroundColor Gray

Write-Host ""
Write-Host "Language Packs:" -ForegroundColor Yellow

$langs = $enabled | Where-Object { $_.Name -match "Language" }

foreach ($lang in $langs) {
    $name = $lang.Name -replace "Language.*", ""
    Write-Host "  $name" -ForegroundColor White
}

Write-Host ""
Write-Host "Features on Demand:" -ForegroundColor Yellow

$features = $caps | Where-Object { $_.Name -match "NetFX|DirectX|Graphics" }

foreach ($feature in $features | Select-Object -First 10) {
    $name = ($feature.Name -split "~~")[0]
    Write-Host "  $name" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - Capabilities listed" -ForegroundColor Green
exit 0
