<#
.SYNOPSIS
    Checks Windows Firewall status.

.DESCRIPTION
    Reports firewall status for all profiles (Domain, Private, Public).

.PARAMETER EnableFirewall
    Enable firewall if disabled.

.EXAMPLE
    .\Check-WindowsFirewall.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$EnableFirewall
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows Firewall Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$profiles = Get-NetFirewallProfile

$disabled = @()

foreach ($profile in $profiles) {
    $status = if ($profile.Enabled) { "Enabled" } else { "Disabled" }
    $color = if ($profile.Enabled) { "Green" } else { "Red" }
    
    if (-not $profile.Enabled) {
        $disabled += $profile.Name
    }
    
    Write-Host "$($profile.Name) Profile: $status" -ForegroundColor $color
}

if ($EnableFirewall -and $disabled.Count -gt 0) {
    Write-Host ""
    Write-Host "Enabling disabled profiles..." -ForegroundColor Yellow
    
    foreach ($profile in $profiles) {
        if (-not $profile.Enabled) {
            Set-NetFirewallProfile -Name $profile.Name -Enabled True
            Write-Host "  Enabled $($profile.Name)" -ForegroundColor Green
        }
    }
    
    $profiles = Get-NetFirewallProfile
    $disabled = @()
    foreach ($profile in $profiles) {
        if (-not $profile.Enabled) {
            $disabled += $profile.Name
        }
    }
}

Write-Host ""

$rulesCount = (Get-NetFirewallRule -ErrorAction SilentlyContinue).Count
Write-Host "Total Firewall Rules: $rulesCount" -ForegroundColor White

$enabledRules = (Get-NetFirewallRule -Enabled True -ErrorAction SilentlyContinue).Count
Write-Host "Enabled Rules: $enabledRules" -ForegroundColor Green

Write-Host ""

if ($disabled.Count -gt 0) {
    Write-Host "RESULT:CRITICAL - Firewall disabled on: $($disabled -join ', ')" -ForegroundColor Red
    exit 2
} else {
    Write-Host "RESULT:OK - All firewalls enabled" -ForegroundColor Green
    exit 0
}
