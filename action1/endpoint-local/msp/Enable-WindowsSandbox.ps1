<#
.SYNOPSIS
    Checks and enables Windows Sandbox.

.DESCRIPTION
    Verifies Sandbox capability and enables it if needed.

.EXAMPLE
    .\Enable-WindowsSandbox.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows Sandbox ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Checking Sandbox capability..." -ForegroundColor Yellow

$isVM = $false
$cs = Get-CimInstance Win32_ComputerSystem
if ($cs.Model -match "Virtual|VMware|VirtualBox|Hyper-V") { $isVM = $true }

if ($isVM) {
    Write-Host "  Warning: Running in VM - Sandbox may not work" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Checking Virtualization:" -ForegroundColor Yellow

$virt = (Get-ComputerInfo).HyperVisorPresent
Write-Host "  Hyper-V: $virt" -ForegroundColor $(if ($virt) { "Green" } else { "Red" })

Write-Host ""
Write-Host "Windows Features:" -ForegroundColor Yellow

$sandbox = Get-WindowsOptionalFeature -Online -FeatureName "Containers-Sandbox" -ErrorAction SilentlyContinue

if ($sandbox) {
    Write-Host "  Sandbox feature state: $($sandbox.State)" -ForegroundColor White
    
    if ($sandbox.State -ne "Enabled") {
        Write-Host ""
        Write-Host "Enabling Sandbox..." -ForegroundColor Yellow
        
        try {
            Enable-WindowsOptionalFeature -Online -FeatureName "Containers-Sandbox" -All -NoRestart -ErrorAction Stop
            Write-Host "  Enabled - reboot required" -ForegroundColor Green
        } catch {
            Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  Not available on this Windows edition" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - Sandbox check complete" -ForegroundColor Green
exit 0
