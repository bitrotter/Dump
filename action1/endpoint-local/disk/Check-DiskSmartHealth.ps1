<#
.SYNOPSIS
    Checks disk SMART health status.

.DESCRIPTION
    Uses WMI to query disk SMART attributes and reports health status.
    Works with physical disks that support SMART.

.PARAMETER Drive
    Drive letter to check. Default: C

.EXAMPLE
    .\Check-DiskSmartHealth.ps1

.EXAMPLE
    .\Check-DiskSmartHealth.ps1 -Drive D
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Drive = "C"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Disk SMART Health Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$driveInfo = Get-PSDrive -Name $Drive.TrimEnd(':')

Write-Host "Drive: $Drive" -ForegroundColor Yellow
Write-Host "  Label: $($driveInfo.Used) used / $($driveInfo.Free) free" -ForegroundColor White

try {
    $disk = Get-CimInstance -ClassName Win32_DiskDrive | Where-Object { $_.InterfaceType -ne "USB" } | Select-Object -First 1
    
    if ($disk) {
        Write-Host "  Model: $($disk.Model)" -ForegroundColor White
        Write-Host "  Media Type: $($disk.MediaType)" -ForegroundColor White
        Write-Host "  Serial: $($disk.SerialNumber)" -ForegroundColor Gray
        
        $health = $disk.Status
        $healthColor = if ($health -match "OK") { "Green" } elseif ($health -match "Warning") { "Yellow" } else { "Red" }
        
        Write-Host "  SMART Status: $health" -ForegroundColor $healthColor
        
        if ($disk.PredictiveFailure -and $disk.PredictiveFailure -ne "0") {
            Write-Host "  Predictive Failure: Yes" -ForegroundColor Red
        }
        
        Write-Host ""
        Write-Host "Disk Details:" -ForegroundColor Yellow
        Write-Host "  Size: $([math]::Round($disk.Size / 1TB, 2)) TB" -ForegroundColor White
        Write-Host "  Firmware: $($disk.FirmwareRevision)" -ForegroundColor Gray
        Write-Host "  Bytes Per Sector: $($disk.BytesPerSector)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Could not query disk SMART data" -ForegroundColor Yellow
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "SMART Attributes:" -ForegroundColor Yellow

try {
    $smartData = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue
    
    if ($smartData) {
        $predictStatus = $smartData.PredictFailure
        $reason = $smartData.Reason
        
        if ($predictStatus -eq $false) {
            Write-Host "  Prediction: Healthy" -ForegroundColor Green
        } else {
            Write-Host "  Prediction: Failure Predicted" -ForegroundColor Red
            Write-Host "  Reason: $reason" -ForegroundColor Red
        }
    } else {
        Write-Host "  SMART data not available" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  SMART not available for this disk type" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Checking for recent disk events..." -ForegroundColor Yellow

$diskEvents = Get-WinEvent -FilterHashtable @{
    LogName = "System"
    ProviderName = "Disk"
    StartTime = (Get-Date).AddDays(-7)
} -MaxEvents 5 -ErrorAction SilentlyContinue

if ($diskEvents) {
    Write-Host "Recent Disk Events:" -ForegroundColor Gray
    $diskEvents | ForEach-Object {
        Write-Host "  $($_.TimeCreated) - $($_.Message.Substring(0, [Math]::Min(80, $_.Message.Length)))..." -ForegroundColor Gray
    }
} else {
    Write-Host "  No recent disk events" -ForegroundColor Green
}

Write-Host ""

if ($disk -and $health -match "OK" -and $predictStatus -eq $false) {
    Write-Host "RESULT:OK - Disk health OK" -ForegroundColor Green
    exit 0
} elseif ($disk -and $health -match "Warning") {
    Write-Host "RESULT:WARNING - Disk needs attention" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:CRITICAL - Disk health issue detected" -ForegroundColor Red
    exit 2
}
