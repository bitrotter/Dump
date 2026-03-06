<#
.SYNOPSIS
    Formats and mounts a disk.

.DESCRIPTION
    Formats a disk with specified filesystem.

.PARAMETER DiskNumber
    Disk number to format.

.PARAMETER DriveLetter
    Drive letter to assign.

.PARAMETER FileSystem
    File system (NTFS, ReFS).

.PARAMETER Label
    Volume label.

.EXAMPLE
    .\Format-Disk.ps1 -DiskNumber 1 -DriveLetter E -Label "Data"
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$DiskNumber,

    [Parameter(Mandatory=$false)]
    [char]$DriveLetter,

    [Parameter(Mandatory=$false)]
    [ValidateSet("NTFS", "ReFS")]
    [string]$FileSystem = "NTFS",

    [Parameter(Mandatory=$false)]
    [string]$Label = "New Volume"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Format Disk ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $DiskNumber -or -not $DriveLetter) {
    Write-Host "Available Disks:" -ForegroundColor Yellow
    
    $disks = Get-Disk
    
    foreach ($disk in $disks) {
        Write-Host "  Disk $($disk.Number): $($disk.FriendlyName) - $([math]::Round($disk.Size/1GB, 0)) GB" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "RESULT:INFO - Specify -DiskNumber and -DriveLetter" -ForegroundColor Cyan
    exit 0
}

Write-Host "Formatting Disk $DiskNumber as $DriveLetter..." -ForegroundColor Yellow

try {
    $disk = Get-Disk -Number $DiskNumber
    
    if ($disk.PartitionStyle -eq "RAW") {
        Initialize-Disk -Number $DiskNumber -PartitionStyle GPT
    }
    
    $partition = New-Partition -DiskNumber $DiskNumber -DriveLetter $DriveLetter -UseMaximumSize
    
    Format-Volume -Partition $partition -FileSystem $FileSystem -NewFileSystemLabel $Label -Confirm:$false
    
    Write-Host "  Formatted successfully" -ForegroundColor Green
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "RESULT:OK - Disk formatted" -ForegroundColor Green
exit 0
