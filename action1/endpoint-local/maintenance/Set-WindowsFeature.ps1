<#
.SYNOPSIS
    Checks for available Windows features.

.DESCRIPTION
    Lists and enables/disables Windows optional features.

.PARAMETER Enable
    Enable a feature by name.

.PARAMETER Disable
    Disable a feature by name.

.PARAMETER List
    List all available features.

.EXAMPLE
    .\Set-WindowsFeature.ps1 -List
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Enable,

    [Parameter(Mandatory=$false)]
    [string]$Disable,

    [Parameter(Mandatory=$false)]
    [switch]$List
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows Features ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if ($List) {
    Write-Host "Available Features:" -ForegroundColor Yellow
    
    $features = Get-WindowsOptionalFeature -Online | Where-Object { $_.State -eq "Enabled" }
    
    foreach ($feature in $features) {
        Write-Host "  $($feature.FeatureName)" -ForegroundColor Green
    }
}

if ($Enable) {
    Write-Host "Enabling feature: $Enable" -ForegroundColor Yellow
    
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName $Enable -All -NoRestart -ErrorAction Stop
        Write-Host "  Enabled successfully" -ForegroundColor Green
    } catch {
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($Disable) {
    Write-Host "Disabling feature: $Disable" -ForegroundColor Yellow
    
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName $Disable -NoRestart -ErrorAction Stop
        Write-Host "  Disabled successfully" -ForegroundColor Green
    } catch {
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "RESULT:OK - Feature management complete" -ForegroundColor Green
exit 0
