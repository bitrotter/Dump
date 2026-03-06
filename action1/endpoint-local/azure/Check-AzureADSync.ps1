<#
.SYNOPSIS
    Checks Azure AD device sync status.

.DESCRIPTION
    Reports Azure AD Connect status and last sync time.

.EXAMPLE
    .\Check-AzureADSync.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Azure AD Sync Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Azure AD Join Status:" -ForegroundColor Yellow

$dsregcmd = dsregcmd /status 2>&1 | Out-String

if ($dsregcmd -match "AzureADJoined.*YES") {
    Write-Host "  Azure AD Joined: Yes" -ForegroundColor Green
} else {
    Write-Host "  Azure AD Joined: No" -ForegroundColor Red
}

if ($dsregcmd -match "DomainJoined.*Yes") {
    Write-Host "  Domain Joined: Yes" -ForegroundColor Green
} else {
    Write-Host "  Domain Joined: No" -ForegroundColor Red
}

Write-Host ""
Write-Host "Device Info:" -ForegroundColor Yellow

if ($dsregcmd -match "DeviceId.*:") {
    $deviceId = ($dsregcmd -split "DeviceId")[1].Split("`n")[0].Trim()
    Write-Host "  Device ID: $deviceId" -ForegroundColor Gray
}

if ($dsregcmd -match "TenantName.*:") {
    $tenant = ($dsregcmd -split "TenantName")[1].Split("`n")[0].Trim()
    Write-Host "  Tenant: $tenant" -ForegroundColor White
}

if ($dsregcmd -match "UserPrincipalName.*:") {
    $upn = ($dsregcmd -split "UserPrincipalName")[1].Split("`n")[0].Trim()
    Write-Host "  UPN: $upn" -ForegroundColor White
}

Write-Host ""
Write-Host "Sync Status:" -ForegroundColor Yellow

$lastSync = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Azure AD Connect Health Sync Insights\ParameterStore" -ErrorAction SilentlyContinue

if ($lastSync) {
    Write-Host "  Last Sync: Configured" -ForegroundColor Gray
}

Write-Host ""
Write-Host "MDM Enrollment:" -ForegroundColor Yellow

$mdmPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MDM"

if (Test-Path $mdmPath) {
    Write-Host "  MDM Configured: Yes" -ForegroundColor Green
    
    $mdmDiag = Get-ItemProperty -Path "$mdmPath\Diag" -ErrorAction SilentlyContinue
    
    if ($mdmDiag) {
        Write-Host "  Machine ID: $($mdmDiag.MachineID)" -ForegroundColor Gray
    }
} else {
    Write-Host "  MDM Configured: No" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Intune Status:" -ForegroundColor Yellow

$intunePath = "HKLM:\SOFTWARE\Microsoft\Enrollments"

if (Test-Path $intunePath) {
    $intune = Get-ChildItem $intunePath -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.GetValue("ProviderID") -match "Intune" }
    
    if ($intune) {
        Write-Host "  Intune Enrolled: Yes" -ForegroundColor Green
    } else {
        Write-Host "  Intune Enrolled: No" -ForegroundColor Yellow
    }
}

Write-Host ""

if ($dsregcmd -match "AzureADJoined.*YES") {
    Write-Host "RESULT:OK - Azure AD device synced" -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT:WARNING - Device not Azure AD joined" -ForegroundColor Yellow
    exit 1
}
