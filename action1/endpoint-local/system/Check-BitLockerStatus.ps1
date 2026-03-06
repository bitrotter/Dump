<#
.SYNOPSIS
    Checks BitLocker encryption status.

.DESCRIPTION
    Reports BitLocker status for all fixed drives.

.PARAMETER EncryptAll
    Enable BitLocker on unprotected drives (requires admin).

.EXAMPLE
    .\Check-BitLockerStatus.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$EncryptAll
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== BitLocker Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$drives = Get-BitLockerVolume -ErrorAction SilentlyContinue

if (-not $drives) {
    Write-Host "BitLocker not available or no drives found" -ForegroundColor Yellow
    
    $bitlockerPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\BitLocker"
    if (Test-Path $bitlockerPath) {
        Write-Host "  BitLocker is installed" -ForegroundColor Green
    } else {
        Write-Host "  BitLocker may not be installed" -ForegroundColor Red
    }
    
    Write-Host "RESULT:UNKNOWN - Cannot determine BitLocker status" -ForegroundColor Yellow
    exit 1
}

$unprotected = @()
$protected = @()

foreach ($drive in $drives) {
    $mountPoint = $drive.MountPoint
    $protection = $drive.ProtectionStatus
    $encryption = $drive.EncryptionPercentage
    
    if ($protection -eq "On") {
        $protected += $mountPoint
        $color = "Green"
        $status = "Encrypted ($encryption%)"
    } else {
        $unprotected += $mountPoint
        $color = "Red"
        $status = "Not Encrypted"
    }
    
    Write-Host "Drive $mountPoint :" -ForegroundColor White
    Write-Host "  Status: $status" -ForegroundColor $color
    Write-Host "  Volume Type: $($drive.VolumeType)" -ForegroundColor Gray
    
    if ($drive.KeyProtectors) {
        Write-Host "  Key Protectors:" -ForegroundColor Gray
        foreach ($kp in $drive.KeyProtectors) {
            Write-Host "    - $($kp.KeyProtectorType)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Protected: $($protected.Count)" -ForegroundColor Green
Write-Host "  Unprotected: $($unprotected.Count)" -ForegroundColor Red

if ($EncryptAll -and $unprotected.Count -gt 0) {
    Write-Host ""
    Write-Host "Note: BitLocker encryption requires TPM or manual password." -ForegroundColor Gray
    Write-Host "Use: Enable-BitLocker -MountPoint C: ..." -ForegroundColor Gray
}

Write-Host ""

if ($unprotected.Count -gt 0) {
    Write-Host "RESULT:WARNING - $($unprotected.Count) drive(s) not encrypted" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - All drives encrypted" -ForegroundColor Green
    exit 0
}
