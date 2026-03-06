<#
.SYNOPSIS
    Checks Intune device policy status.

.DESCRIPTION
    Reports Intune management policies applied to the device.

.EXAMPLE
    .\Check-IntunePolicy.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Intune Policy Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Device Management:" -ForegroundColor Yellow

$dmPath = "HKLM:\SOFTWARE\Microsoft\Enrollments"

if (Test-Path $dmPath) {
    $enrollments = Get-ChildItem $dmPath -Recurse -ErrorAction SilentlyContinue
    
    $intuneEnrollment = $enrollments | Where-Object { 
        $_.GetValue("ProviderID") -match "Intune" -or 
        $_.GetValue("EntDeviceOwner") -or 
        $_.GetValue("MDMService")
    }
    
    if ($intuneEnrollment) {
        Write-Host "  Intune Enrolled: Yes" -ForegroundColor Green
        
        foreach ($enroll in $intuneEnrollment) {
            $type = $enroll.GetValue("EnrollmentType")
            $provider = $enroll.GetValue("ProviderID")
            
            Write-Host "    Type: $type" -ForegroundColor Gray
            Write-Host "    Provider: $provider" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Intune Enrolled: No" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Device Config Policies:" -ForegroundColor Yellow

$configPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current"

if (Test-Path $configPath) {
    $policies = Get-ChildItem $configPath -ErrorAction SilentlyContinue
    
    Write-Host "  Policy Categories: $($policies.Count)" -ForegroundColor White
    
    foreach ($policy in $policies | Select-Object -First 5) {
        $name = $policy.PSChildName
        Write-Host "    - $name" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Compliance Policies:" -ForegroundColor Yellow

$compliancePath = "$configPath\DeviceCompliance"

if (Test-Path $compliancePath) {
    $compliance = Get-ItemProperty -Path $compliancePath -ErrorAction SilentlyContinue
    
    if ($compliance) {
        Write-Host "  Compliance Policies: Applied" -ForegroundColor Green
    }
} else {
    Write-Host "  Compliance Policies: Not applied" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Device Configuration:" -ForegroundColor Yellow

$devConfigPath = "$configPath\Device"

if (Test-Path $devConfigPath) {
    Write-Host "  Device Config: Present" -ForegroundColor Green
}

Write-Host ""
Write-Host "Security Policies:" -ForegroundColor Yellow

$securityPath = "$configPath\DeviceSecurity"

if (Test-Path $securityPath) {
    $security = Get-ChildItem $securityPath -ErrorAction SilentlyContinue
    
    Write-Host "  Security Policies: $($security.Count) configured" -ForegroundColor White
}

Write-Host ""
Write-Host "Endpoint Protection:" -ForegroundColor Yellow

$epPath = "$configPath\EndpointProtection"

if (Test-Path $epPath) {
    Write-Host "  Endpoint Protection: Configured" -ForegroundColor Green
} else {
    Write-Host "  Endpoint Protection: Not configured" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Last Check-in:" -ForegroundColor Yellow

$healthPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceManagement\Health"

if (Test-Path $healthPath) {
    $lastCheck = Get-ItemProperty -Path $healthPath -ErrorAction SilentlyContinue
    
    if ($lastCheck.LastHealthCheck) {
        Write-Host "  Last Check: $($lastCheck.LastHealthCheck)" -ForegroundColor White
    }
}

Write-Host ""

$intuneEnrolled = $enrollments | Where-Object { $_.GetValue("ProviderID") -match "Intune" }

if ($intuneEnrolled) {
    Write-Host "RESULT:OK - Intune policies applied" -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT:WARNING - Device not managed by Intune" -ForegroundColor Yellow
    exit 1
}
