<#
.SYNOPSIS
    Checks and creates system restore points.

.DESCRIPTION
    Lists existing restore points and can create a new one.

.PARAMETER Create
    Create a new restore point.

.PARAMETER Days
    Warn if no restore point within this many days. Default: 7.

.EXAMPLE
    .\Check-RestorePoint.ps1

.EXAMPLE
    .\Check-RestorePoint.ps1 -Create
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Create,

    [Parameter(Mandatory=$false)]
    [int]$Days = 7
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== System Restore Point Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$restorePoints = Get-ComputerRestorePoint

Write-Host "Existing Restore Points:" -ForegroundColor Yellow

if ($restorePoints) {
    $restorePoints | Select-Object -First 10 | ForEach-Object {
        $age = (Get-Date) - $_.CreationTime
        $ageStr = "$([int]$age.TotalDays) days ago"
        
        $color = if ($age.TotalDays -gt $Days) { "Yellow" } else { "Green" }
        
        Write-Host "  [$($_.SequenceNumber)] $($_.CreationTime) - $($_.Description) ($ageStr)" -ForegroundColor $color
    }
    
    $latest = $restorePoints | Select-Object -First 1
    $age = (Get-Date) - $latest.CreationTime
    
    Write-Host ""
    Write-Host "Latest Restore Point: $($latest.CreationTime)" -ForegroundColor White
    Write-Host "Age: $([int]$age.TotalDays) days" -ForegroundColor $(if ($age.TotalDays -gt $Days) { "Yellow" } else { "Green" })
} else {
    Write-Host "  No restore points found" -ForegroundColor Red
}

$systemRestore = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "System Restore Configuration:" -ForegroundColor Yellow
Write-Host "  Disk Space Percent: $($systemRestore.DiskPercent)" -ForegroundColor White

Write-Host ""

if ($Create) {
    Write-Host "Creating new restore point..." -ForegroundColor Yellow
    
    try {
        Checkpoint-Computer -Description "Action1-Automated-RestorePoint" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "  Restore point created successfully" -ForegroundColor Green
    } catch {
        Write-Host "  Failed to create restore point: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if (-not $restorePoints) {
    Write-Host "RESULT:WARNING - No restore points exist" -ForegroundColor Yellow
    exit 1
}

$age = (Get-Date) - $latest.CreationTime
if ($age.TotalDays -gt $Days) {
    Write-Host "RESULT:WARNING - No restore point in $Days days" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Restore points available" -ForegroundColor Green
    exit 0
}
