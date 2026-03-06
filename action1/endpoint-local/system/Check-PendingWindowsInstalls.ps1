<#
.SYNOPSIS
    Checks for pending Windows component-based installs.

.DESCRIPTION
    Checks for pending Windows setup, feature installs, and 
    component store cleanup status.

.EXAMPLE
    .\Check-PendingWindowsInstalls.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Pending Windows Installs ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Component Based Servicing:" -ForegroundColor Yellow

$cbsPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing"

if (Test-Path $cbsPath) {
    $cbs = Get-ItemProperty -Path $cbsPath
    
    if ($cbs.RebootPending) {
        Write-Host "  Reboot Pending: Yes" -ForegroundColor Red
    } else {
        Write-Host "  Reboot Pending: No" -ForegroundColor Green
    }
    
    if ($cbs.PackagesPending) {
        Write-Host "  Packages Pending: Yes" -ForegroundColor Yellow
    } else {
        Write-Host "  Packages Pending: No" -ForegroundColor Green
    }
    
    if ($cbs.SKUUpgrade) {
        Write-Host "  SKU Upgrade: Yes" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Component store info not available" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Windows Setup:" -ForegroundColor Yellow

$setupPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State"

if (Test-Path $setupPath) {
    $setup = Get-ItemProperty -Path $setupPath
    
    if ($setup.ImageState) {
        Write-Host "  Image State: $($setup.ImageState)" -ForegroundColor White
        
        if ($setup.ImageState -eq "IMAGE_STATE_INCOMPLETE_BOOT") {
            Write-Host "  Boot incomplete - may need reboot" -ForegroundColor Yellow
        }
    }
    
    if ($setup.UpgradePending) {
        Write-Host "  Upgrade Pending: Yes" -ForegroundColor Red
    }
    
    if ($setup.Rollback) {
        Write-Host "  Rollback Available: Yes" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Windows Setup info not available" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Windows Update Feature Updates:" -ForegroundColor Yellow

$wuPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Feature"

if (Test-Path $wuPath) {
    $wu = Get-ItemProperty -Path $wuPath
    
    if ($wu.LastSuccessTime) {
        Write-Host "  Last Feature Update: $($wu.LastSuccessTime)" -ForegroundColor White
    }
    
    if ($wu.Pending) {
        Write-Host "  Pending Feature Update: Yes" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Feature update info not available" -ForegroundColor Gray
}

Write-Host ""
Write-Host "DISM Component Store:" -ForegroundColor Yellow

try {
    $dism = dism /Online /Get-Features /Format:List 2>&1 | Out-String
    
    if ($dism -match "Feature Name") {
        Write-Host "  Feature list accessible" -ForegroundColor Green
    }
} catch {
    Write-Host "  Could not query component store" -ForegroundColor Gray
}

Write-Host ""

$pending = $false
if ($cbs -and ($cbs.RebootPending -or $cbs.PackagesPending)) { $pending = $true }
if ($setup -and ($setup.UpgradePending -or $setup.ImageState -ne "IMAGE_STATE_COMPLETE")) { $pending = $true }

if ($pending) {
    Write-Host "RESULT:REBOOT_REQUIRED - Windows install pending" -ForegroundColor Yellow
    exit 2
} else {
    Write-Host "RESULT:OK - No pending installs" -ForegroundColor Green
    exit 0
}
