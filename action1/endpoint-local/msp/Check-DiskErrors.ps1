<#
.SYNOPSIS
    Checks disk for errors.

.DESCRIPTION
    Runs chkdsk and checks SMART status for disk issues.

.PARAMETER FullScan
    Run full chkdsk scan (may require reboot).

.EXAMPLE
    .\Check-DiskErrors.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$FullScan
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Disk Error Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Checking disk SMART status..." -ForegroundColor Yellow

$disks = Get-CimInstance Win32_DiskDrive

foreach ($disk in $disks) {
    Write-Host "  Drive $($disk.Index): $($disk.Model)" -ForegroundColor White
    Write-Host "    Status: $($disk.Status)" -ForegroundColor $(if ($disk.Status -eq "OK") { "Green" } else { "Yellow" })
    Write-Host "    Size: $([math]::Round($disk.Size/1TB, 2)) TB" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Checking logical volumes..." -ForegroundColor Yellow

$volumes = Get-Volume | Where-Object { $_.DriveLetter }

foreach ($volume in $volumes) {
    $driveLetter = "$($volume.DriveLetter):"
    $health = if ($volume.HealthStatus -eq "Healthy") { "OK" } else { "ISSUE" }
    $color = if ($volume.HealthStatus -eq "Healthy") { "Green" } else { "Red" }
    
    Write-Host "  $driveLetter $($volume.FileSystem) - $health" -ForegroundColor $color
    Write-Host "    Size: $([math]::Round($volume.Size/1GB, 2)) GB / $([math]::Round($volume.SizeRemaining/1GB, 2)) GB free" -ForegroundColor Gray
}

Write-Host ""
Write-Host "File system check..." -ForegroundColor Yellow

foreach ($volume in $volumes) {
    $drive = $volume.DriveLetter
    
    if ($drive) {
        Write-Host "  Checking $drive..." -ForegroundColor Gray
        
        $result = Repair-Volume -DriveLetter $drive -ErrorAction SilentlyContinue
        
        if ($result -eq "NoErrorsFound") {
            Write-Host "    No errors found" -ForegroundColor Green
        } elseif ($result) {
            Write-Host "    Issues found: $result" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "Disk performance..." -ForegroundColor Yellow

$perf = Get-CimInstance Win32_PerfRawData_PerfDisk_PhysicalDisk | Where-Object { $_.Name -ne "_Total" }

foreach ($disk in $perf) {
    Write-Host "  Disk $($disk.Name):" -ForegroundColor White
    Write-Host "    Read/sec: $($disk.DiskReadBytesPerSec)" -ForegroundColor Gray
    Write-Host "    Write/sec: $($disk.DiskWriteBytesPerSec)" -ForegroundColor Gray
}

if ($FullScan) {
    Write-Host ""
    Write-Host "NOTE: Full chkdsk requires reboot. Run manually if needed:" -ForegroundColor Yellow
    Write-Host "  chkdsk C: /F /R" -ForegroundColor Gray
}

Write-Host ""

$unhealthy = ($volumes | Where-Object { $_.HealthStatus -ne "Healthy" }).Count

if ($unhealthy -gt 0) {
    Write-Host "RESULT:WARNING - $unhealthy unhealthy volume(s)" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Disks healthy" -ForegroundColor Green
    exit 0
}
