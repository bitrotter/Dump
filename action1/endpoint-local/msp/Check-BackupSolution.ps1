<#
.SYNOPSIS
    Detects installed backup solutions.

.DESCRIPTION
    Checks for common backup software installations.

.EXAMPLE
    .\Check-BackupSolution.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Backup Solution Detection ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$backupSolutions = @()

Write-Host "Checking for backup solutions..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Veeam:" -ForegroundColor Yellow

$veeamServices = @("Veeam", "VBR", "VeeamBackup")
$veeamFound = $false

foreach ($svc in $veeamServices) {
    $service = Get-Service -Name "*$svc*" -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($service) {
        Write-Host "  Found: $($service.Name) - $($service.Status)" -ForegroundColor Green
        $backupSolutions += "Veeam"
        $veeamFound = $true
    }
}

if (-not $veeamFound) {
    Write-Host "  Not detected" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Acronis:" -ForegroundColor Yellow

$acronis = Get-Service -Name "*Acronis*" -ErrorAction SilentlyContinue

if ($acronis) {
    Write-Host "  Found: $($acronis.Name)" -ForegroundColor Green
    $backupSolutions += "Acronis"
} else {
    Write-Host "  Not detected" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Carbonite:" -ForegroundColor Yellow

$carbonite = Get-Service -Name "*Carbonite*" -ErrorAction SilentlyContinue

if ($carbonite) {
    Write-Host "  Found: $($carbonite.Name)" -ForegroundColor Green
    $backupSolutions += "Carbonite"
} else {
    Write-Host "  Not detected" -ForegroundColor Gray
}

Write-Host ""
Write-Host "CrashPlan:" -ForegroundColor Yellow

$crashplan = Get-Service -Name "*CrashPlan*" -ErrorAction SilentlyContinue

if ($crashplan) {
    Write-Host "  Found: $($crashplan.Name)" -ForegroundColor Green
    $backupSolutions += "CrashPlan"
} else {
    Write-Host "  Not detected" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Windows Backup:" -ForegroundColor Yellow

$wbadmin = Get-WBJob -ErrorAction SilentlyContinue

if ($wbadmin) {
    Write-Host "  Windows Backup configured" -ForegroundColor Green
    $backupSolutions += "Windows Backup"
} else {
    Write-Host "  Not configured" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Shadow Copy:" -ForegroundColor Yellow

$vss = vssadmin list shadows /for=C: 2>&1

if ($vss -match "Shadow Copies") {
    Write-Host "  Volume Shadow Copy: Enabled" -ForegroundColor Green
    $backupSolutions += "VSS"
} else {
    Write-Host "  Not available" -ForegroundColor Gray
}

Write-Host ""
Write-Host "OneDrive/Backup:" -ForegroundColor Yellow

$onedrive = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue

if ($onedrive) {
    Write-Host "  OneDrive running" -ForegroundColor Green
    $backupSolutions += "OneDrive"
} else {
    Write-Host "  OneDrive not running" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Solutions found: $($backupSolutions.Count)" -ForegroundColor White

if ($backupSolutions.Count -gt 0) {
    Write-Host "  Installed: $($backupSolutions -join ', ')" -ForegroundColor Green
}

Write-Host ""

if ($backupSolutions.Count -eq 0) {
    Write-Host "RESULT:WARNING - No backup solution detected" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Backup solution(s) present" -ForegroundColor Green
    exit 0
}
