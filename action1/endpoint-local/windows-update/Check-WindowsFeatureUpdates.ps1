<#
.SYNOPSIS
    Checks for pending Windows feature updates.

.DESCRIPTION
    Queries Windows feature update status and pending changes.
    Useful for checking if a major Windows version upgrade is pending.

.PARAMETER CheckUpgrade
    Check for available Windows upgrades.

.EXAMPLE
    .\Check-WindowsFeatureUpdates.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$CheckUpgrade
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows Feature Update Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$os = Get-CimInstance Win32_OperatingSystem

Write-Host "Current OS:" -ForegroundColor Yellow
Write-Host "  Version: $($os.Version)" -ForegroundColor White
Write-Host "  Build: $($os.BuildNumber)" -ForegroundColor White
Write-Host "  Caption: $($os.Caption)" -ForegroundColor White

Write-Host ""
Write-Host "Feature Update Status:" -ForegroundColor Yellow

$cuPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install"

if (Test-Path $cuPath) {
    $lastUpdate = Get-ItemProperty -Path $cuPath -ErrorAction SilentlyContinue
    
    if ($lastUpdate.LastSuccessTime) {
        Write-Host "  Last Feature Update: $($lastUpdate.LastSuccessTime)" -ForegroundColor White
    }
}

$pendingPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"

if (Test-Path $pendingPath) {
    Write-Host "  Pending Reboot: Yes" -ForegroundColor Red
}

$featureUpdatePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

$targetBuild = Get-ItemProperty -Path $featureUpdatePath -Name "TargetBuild" -ErrorAction SilentlyContinue
$UBR = Get-ItemProperty -Path $featureUpdatePath -Name "UBR" -ErrorAction SilentlyContinue

if ($targetBuild) {
    Write-Host "  Target Build: $($targetBuild.TargetBuild)" -ForegroundColor White
}
if ($UBR) {
    Write-Host "  Update Build Revision: $($UBR.UBR)" -ForegroundColor White
}

Write-Host ""
Write-Host "Windows Servicing:" -ForegroundColor Yellow

try {
    $servicing = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing" -ErrorAction SilentlyContinue
    
    if ($servicing) {
        if ($servicing.RebootPending) {
            Write-Host "  Reboot Pending: Yes" -ForegroundColor Red
        }
        if ($servicing.PackagesPending) {
            Write-Host "  Packages Pending: Yes" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  Servicing info unavailable" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Windows Update Configuration:" -ForegroundColor Yellow

$wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

if (Test-Path $wuPath) {
    $wu = Get-ItemProperty -Path $wuPath -ErrorAction SilentlyContinue
    
    if ($wu.TargetReleaseVersion) {
        Write-Host "  Target Release: $($wu.TargetReleaseVersion)" -ForegroundColor White
    }
    if ($wu.ProductVersion) {
        Write-Host "  Product Version: $($wu.ProductVersion)" -ForegroundColor White
    }
} else {
    Write-Host "  Using default update settings" -ForegroundColor Gray
}

if ($CheckUpgrade) {
    Write-Host ""
    Write-Host "Upgrade Check:" -ForegroundColor Yellow
    
    try {
        $updater = New-Object -ComObject Microsoft.Update.AutoUpdate
        $results = $updater.Results
        
        Write-Host "  Last Search Time: $($results.LastSearchSuccessDate)" -ForegroundColor White
        Write-Host "  Last Installation Date: $($results.LastInstallationSuccessDate)" -ForegroundColor White
        
        if ($results.LastInstallationResultCode -eq "succeeded") {
            Write-Host "  Last Install Result: Success" -ForegroundColor Green
        } else {
            Write-Host "  Last Install Result: $($results.LastInstallationResultCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Could not check upgrade status" -ForegroundColor Gray
    }
}

Write-Host ""

$pending = $false
if (Test-Path $pendingPath) { $pending = $true }
if ($servicing -and ($servicing.RebootPending -or $servicing.PackagesPending)) { $pending = $true }

if ($pending) {
    Write-Host "RESULT:REBOOT_REQUIRED - Feature update pending reboot" -ForegroundColor Yellow
    exit 2
} else {
    Write-Host "RESULT:OK - No pending feature updates" -ForegroundColor Green
    exit 0
}
