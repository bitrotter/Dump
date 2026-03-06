<#
.SYNOPSIS
    Checks Windows Backup status.

.DESCRIPTION
    Reports last backup time from Windows Backup history.
    Also checks for Volume Shadow Copy status.

.PARAMETER Hours
    Warn if no backup within this many hours. Default: 48.

.EXAMPLE
    .\Check-LastBackupStatus.ps1

.EXAMPLE
    .\Check-LastBackupStatus.ps1 -Hours 24
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Hours = 48
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Backup Status Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Warning Threshold: $Hours hours" -ForegroundColor Gray
Write-Host ""

$backupOk = $false
$lastBackup = $null

try {
    $wbadmin = Get-WBJob -ErrorAction SilentlyContinue
    
    if ($wbadmin) {
        $lastBackup = $wbadmin.EndTime
        $backupType = $wbadmin.JobType
        $result = $wbadmin.Result
        
        Write-Host "Last Backup Attempt: $lastBackup" -ForegroundColor White
        Write-Host "Type: $backupType" -ForegroundColor White
        Write-Host "Result: $result" -ForegroundColor $(if ($result -eq "Success") { "Green" } else { "Yellow" })
        
        if ($result -eq "Success") {
            $backupOk = $true
        }
    }
} catch {
    Write-Host "Windows Backup: Not configured or no recent backups" -ForegroundColor Yellow
}

if (-not $lastBackup) {
    $vss = vssadmin list shadows /for=C: 2>$null
    
    if ($vss -match "Shadow Copies") {
        Write-Host "Volume Shadow Copy: Available" -ForegroundColor Green
    }
    
    $sysRestore = Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($sysRestore) {
        Write-Host "Last System Restore Point: $($sysRestore.RestorePointCreationTime)" -ForegroundColor White
        $lastBackup = $sysRestore.RestorePointCreationTime
    }
}

$drives = Get-PSDrive -PSProvider FileSystem
Write-Host ""
Write-Host "Drive Protection Status:" -ForegroundColor Cyan

foreach ($drive in $drives) {
    $shadow = vssadmin list shadows /for="$($drive.Name):" 2>$null
    if ($shadow -match "Shadow Copies") {
        Write-Host "  $($drive.Name): Shadow copies present" -ForegroundColor Green
    }
}

Write-Host ""

if ($lastBackup) {
    $hoursAgo = ((Get-Date) - $lastBackup).TotalHours
    
    if ($hoursAgo -gt $Hours) {
        Write-Host "RESULT:WARNING - Last backup $([math]::Round($hoursAgo, 1)) hours ago" -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "RESULT:OK - Backup within last $Hours hours" -ForegroundColor Green
        exit 0
    }
} else {
    Write-Host "RESULT:WARNING - No recent backup found" -ForegroundColor Yellow
    exit 1
}
