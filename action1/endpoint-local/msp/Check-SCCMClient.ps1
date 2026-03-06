<#
.SYNOPSIS
    Checks SCCM/ConfigMgr client status.

.DESCRIPTION
    Reports SCCM client health and configuration.

.EXAMPLE
    .\Check-SCCMClient.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== SCCM/Intune Client Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "SCCM Client:" -ForegroundColor Yellow

$sccm = Get-Service -Name "SMS Agent Host" -ErrorAction SilentlyContinue

if ($sccm) {
    Write-Host "  Service: $($sccm.DisplayName)" -ForegroundColor White
    Write-Host "  Status: $($sccm.Status)" -ForegroundColor $(if ($sccm.Status -eq "Running") { "Green" } else { "Red" })
    
    $sccmPath = "C:\Windows\CCM"
    
    if (Test-Path $sccmPath) {
        Write-Host "  Client installed: Yes" -ForegroundColor Green
        
        $clientSettings = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\CCM\Setup" -ErrorAction SilentlyContinue
        
        if ($clientSettings) {
            Write-Host "  Version: $($clientSettings.Version)" -ForegroundColor White
        }
    }
} else {
    Write-Host "  Service not found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Intune/MDM:" -ForegroundColor Yellow

$mdmPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MDM"

if (Test-Path $mdmPath) {
    Write-Host "  MDM configured: Yes" -ForegroundColor Green
    
    $mdmDiag = Get-ItemProperty -Path "$mdmPath\Diag" -ErrorAction SilentlyContinue
    
    if ($mdmDiag) {
        Write-Host "  Machine ID: $($mdmDiag.MachineID)" -ForegroundColor Gray
    }
    
    $autoEnroll = Get-ItemProperty -Path "$mdmPath\AutoMDMEnrollments" -ErrorAction SilentlyContinue
    
    if ($autoEnroll) {
        Write-Host "  Auto-enrollment: Enabled" -ForegroundColor Green
    }
} else {
    Write-Host "  MDM not configured" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Policy Manager:" -ForegroundColor Yellow

$pmPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager"

if (Test-Path $pmPath) {
    Write-Host "  Policy Manager: Installed" -ForegroundColor Green
    
    $current = Get-ItemProperty -Path "$pmPath\current\Device" -ErrorAction SilentlyContinue
    
    if ($current) {
        Write-Host "  Config Present" -ForegroundColor Gray
    }
} else {
    Write-Host "  Policy Manager: Not installed" -ForegroundColor Gray
}

Write-Host ""

if ($sccm -and $sccm.Status -eq "Running") {
    Write-Host "RESULT:OK - SCCM client running" -ForegroundColor Green
    exit 0
} elseif (Test-Path $mdmPath) {
    Write-Host "RESULT:OK - MDM configured" -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT:WARNING - No management agent found" -ForegroundColor Yellow
    exit 1
}
