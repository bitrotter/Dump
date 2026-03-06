<#
.SYNOPSIS
    Lists Windows optional features.

.DESCRIPTION
    Shows enabled and disabled optional Windows features.

.PARAMETER ShowDisabled
    Show disabled features.

.EXAMPLE
    .\Check-OptionalFeatures.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowDisabled
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows Optional Features ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$features = Get-WindowsOptionalFeature -Online -ErrorAction SilentlyContinue

if (-not $features) {
    $features = dism /Online /Get-Features /Format:List 2>&1 | Out-String
    
    Write-Host $features -ForegroundColor White
    Write-Host ""
    Write-Host "RESULT:OK - Features listed" -ForegroundColor Green
    exit 0
}

Write-Host "Enabled Features:" -ForegroundColor Green

$enabled = $features | Where-Object { $_.State -eq "Enabled" }

foreach ($feature in $enabled) {
    Write-Host "  $($feature.FeatureName)" -ForegroundColor White
}

Write-Host ""
Write-Host "Disabled Features:" -ForegroundColor Gray

$disabled = $features | Where-Object { $_.State -eq "Disabled" }

if ($ShowDisabled) {
    foreach ($feature in $disabled) {
        Write-Host "  $($feature.FeatureName)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Enabled: $($enabled.Count)" -ForegroundColor Green
Write-Host "  Disabled: $($disabled.Count)" -ForegroundColor Gray

Write-Host ""
Write-Host "RESULT:OK - Features listed" -ForegroundColor Green
exit 0
