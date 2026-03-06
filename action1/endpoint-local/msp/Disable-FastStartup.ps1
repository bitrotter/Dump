<#
.SYNOPSIS
    Disables Windows Fast Startup.

.DESCRIPTION
    Disables hybrid boot for better shutdown/startup.

.EXAMPLE
    .\Disable-FastStartup.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Disable Fast Startup ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Current Setting:" -ForegroundColor Yellow

$fastPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$fast = (Get-ItemProperty -Path $fastPath -Name "HiberbootEnabled" -ErrorAction SilentlyContinue).HiberbootEnabled

if ($fast -eq 0) {
    Write-Host "  Fast Startup: Disabled" -ForegroundColor Green
} else {
    Write-Host "  Fast Startup: Enabled" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Disabling Fast Startup..." -ForegroundColor Yellow

Set-ItemProperty -Path $fastPath -Name "HiberbootEnabled" -Value 0 -Type DWord -Force

$powercfg = powercfg /change standby-timeout-ac 0
Write-Host "  Sleep timeout set to never" -ForegroundColor Green

Write-Host ""
Write-Host "RESULT:OK - Fast Startup disabled" -ForegroundColor Green
exit 0
