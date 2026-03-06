<#
.SYNOPSIS
    Checks Intune/Endpoint Manager enrollment status.

.DESCRIPTION
    Reports Azure AD join status, Intune enrollment, 
    and device management state.

.EXAMPLE
    .\Check-IntuneEnrollment.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Intune/Endpoint Manager Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$azureADJoin = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo" -ErrorAction SilentlyContinue)

Write-Host "Azure AD Join Status:" -ForegroundColor Yellow

try {
    $dsregcmd = dsregcmd /status 2>$null | Out-String
    
    if ($dsregcmd -match "AzureADJoined.*YES") {
        Write-Host "  Azure AD Joined: Yes" -ForegroundColor Green
    } else {
        Write-Host "  Azure AD Joined: No" -ForegroundColor Red
    }
    
    if ($dsregcmd -match "DeviceJoined.*Yes") {
        Write-Host "  Device Joined: Yes" -ForegroundColor Green
    }
    
    if ($dsregcmd -match "TenantName.*(\w+)") {
        Write-Host "  Tenant: $($Matches[1])" -ForegroundColor White
    }
    
    if ($dsregcmd -match "UserPrincipalName.*(\S+)") {
        Write-Host "  UPN: $($Matches[1])" -ForegroundColor White
    }
} catch {
    Write-Host "  Could not determine Azure AD status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Intune Management:" -ForegroundColor Yellow

$intunePath = "HKLM:\SOFTWARE\Microsoft\Enrollments"

if (Test-Path $intunePath) {
    $enrollments = Get-ChildItem $intunePath -ErrorAction SilentlyContinue
    
    $intuneEnrolled = $false
    foreach ($enrollment in $enrollments) {
        $enrollmentType = $enrollment.GetValue("EnrollmentType")
        $provider = $enrollment.GetValue("ProviderID")
        
        if ($provider -match "Intune" -or $enrollmentType -match "Intune") {
            $intuneEnrolled = $true
            Write-Host "  Intune Enrolled: Yes" -ForegroundColor Green
            Write-Host "  Provider: $provider" -ForegroundColor White
            break
        }
    }
    
    if (-not $intuneEnrolled) {
        Write-Host "  Intune Enrolled: No" -ForegroundColor Red
    }
} else {
    Write-Host "  No enrollments found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "MDM Info:" -ForegroundColor Yellow

$mdmPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MDM"
if (Test-Path $mdmPath) {
    $mdmAuto = Get-ItemProperty -Path "$mdmPath\AutoMDMEnrollments" -ErrorAction SilentlyContinue
    $mdmDiag = Get-ItemProperty -Path "$mdmPath\Diag" -ErrorAction SilentlyContinue
    
    if ($mdmDiag.UPN) {
        Write-Host "  MDM User: $($mdmDiag.UPN)" -ForegroundColor White
    }
    if ($mdmDiag.MachineID) {
        Write-Host "  Machine ID: $($mdmDiag.MachineID)" -ForegroundColor Gray
    }
} else {
    Write-Host "  No MDM configuration" -ForegroundColor Yellow
}

Write-Host ""

$issues = @()

if ($dsregcmd -notmatch "AzureADJoined.*YES") { $issues += "Not Azure AD joined" }
if (-not $intuneEnrolled) { $issues += "Not Intune enrolled" }

if ($issues.Count -gt 0) {
    Write-Host "RESULT:WARNING - $($issues -join ', ')" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Intune enrolled and managed" -ForegroundColor Green
    exit 0
}
