<#
.SYNOPSIS
    Installs Windows features on demand.

.DESCRIPTION
    Installs optional Windows features like Hyper-V.

.PARAMETER FeatureName
    Name of feature to install.

.EXAMPLE
    .\Install-WindowsFeature.ps1 -FeatureName "Microsoft-Hyper-V"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$FeatureName
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Install Windows Feature ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $FeatureName) {
    Write-Host "Available Features:" -ForegroundColor Yellow
    
    $features = Get-WindowsFeature | Where-Object { $_.InstallState -eq "Available" } | Select-Object -First 20
    
    foreach ($feature in $features) {
        Write-Host "  $($feature.Name)" -ForegroundColor White
    }
    
    exit 0
}

Write-Host "Installing feature: $FeatureName" -ForegroundColor Yellow

try {
    Install-WindowsFeature -Name $FeatureName -IncludeAllSubFeature -NoRestart -ErrorAction Stop
    
    Write-Host "  Feature installed (reboot may be required)" -ForegroundColor Green
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "RESULT:OK - Feature installed" -ForegroundColor Green
exit 0
