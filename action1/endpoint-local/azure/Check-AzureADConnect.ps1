<#
.SYNOPSIS
    Checks Azure AD Connect configuration.

.DESCRIPTION
    Reports on Azure AD Connect status and sync configuration.

.EXAMPLE
    .\Check-AzureADConnect.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Azure AD Connect Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Local AD Status:" -ForegroundColor Yellow

$cs = Get-CimInstance Win32_ComputerSystem

if ($cs.PartOfDomain) {
    Write-Host "  Domain: $($cs.Domain)" -ForegroundColor Green
    Write-Host "  Computer: $($cs.Name)" -ForegroundColor White
    
    try {
        $dc = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        Write-Host "  Forest: $($dc.Forest.Name)" -ForegroundColor Gray
    } catch {
        Write-Host "  AD Info: Could not retrieve" -ForegroundColor Gray
    }
} else {
    Write-Host "  Workgroup: $($cs.Workgroup)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Azure AD Sync Components:" -ForegroundColor Yellow

$syncServices = @(
    "ADSync",
    "Microsoft Directory Synchronization",
    "Azure AD Connect"
)

foreach ($service in $syncServices) {
    $svc = Get-Service -Name "*$service*" -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($svc) {
        Write-Host "  $($svc.Name): $($svc.Status)" -ForegroundColor $(if ($svc.Status -eq "Running") { "Green" } else { "Yellow" })
    }
}

Write-Host ""
Write-Host "Sync Configuration:" -ForegroundColor Yellow

$syncConfig = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Azure AD Connect" -ErrorAction SilentlyContinue

if ($syncConfig) {
    Write-Host "  Azure AD Connect: Installed" -ForegroundColor Green
    
    if ($syncConfig.UpgradedFromPreviousVersion) {
        Write-Host "  Previous Version: $($syncConfig.UpgradedFromPreviousVersion)" -ForegroundColor Gray
    }
    
    if ($syncConfig.InstallPath) {
        Write-Host "  Install Path: $($syncConfig.InstallPath)" -ForegroundColor Gray
    }
} else {
    Write-Host "  Azure AD Connect: Not installed on this machine" -ForegroundColor Gray
    Write-Host "  Note: Usually installed on dedicated sync server" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Password Write-back:" -ForegroundColor Yellow

$writeback = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\PasswordResetService" -ErrorAction SilentlyContinue

if ($writeback) {
    Write-Host "  Password Reset: Enabled" -ForegroundColor Green
} else {
    Write-Host "  Password Reset: Not configured" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Device Write-back:" -ForegroundColor Yellow

$deviceWriteback = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\DeviceWriteback" -ErrorAction SilentlyContinue

if ($deviceWriteback) {
    Write-Host "  Device Write-back: Enabled" -ForegroundColor Green
} else {
    Write-Host "  Device Write-back: Not configured" -ForegroundColor Gray
}

Write-Host ""
Write-Host "DirSync Configuration:" -ForegroundColor Yellow

$dirSync = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\DirSync" -ErrorAction SilentlyContinue

if ($dirSync) {
    Write-Host "  DirSync: Present" -ForegroundColor Green
} else {
    Write-Host "  DirSync: Not present" -ForegroundColor Gray
}

Write-Host ""

if ($cs.PartOfDomain) {
    Write-Host "RESULT:OK - AD domain member" -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT:WARNING - Not domain joined" -ForegroundColor Yellow
    exit 1
}
