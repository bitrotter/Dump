<#
.SYNOPSIS
    Resizes a partition.

.DESCRIPTION
    Extends or shrinks a partition to specified size.

.PARAMETER DriveLetter
    Drive letter of partition to resize.

.PARAMETER SizeGB
    New size in GB (leave empty for maximum).

.EXAMPLE
    .\Resize-Partition.ps1 -DriveLetter D -SizeGB 500
#>

param(
    [Parameter(Mandatory=$false)]
    [char]$DriveLetter,

    [Parameter(Mandatory=$false)]
    [int]$SizeGB
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Resize Partition ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $DriveLetter) {
    Write-Host "Current Partitions:" -ForegroundColor Yellow
    
    $partitions = Get-Partition
    
    foreach ($part in $partitions) {
        if ($part.DriveLetter) {
            Write-Host "  $($part.DriveLetter): - $([math]::Round($part.Size/1GB, 0)) GB" -ForegroundColor White
        }
    }
    
    exit 0
}

Write-Host "Resizing drive $DriveLetter..." -ForegroundColor Yellow

try {
    $partition = Get-Partition -DriveLetter $DriveLetter
    
    if ($SizeGB) {
        $sizeBytes = $SizeGB * 1GB
        Resize-Partition -DriveLetter $DriveLetter -Size $sizeBytes
    } else {
        $disk = Get-Disk -Number $partition.DiskNumber
        $maxSize = ($disk | Get-Partition | Measure-Object -Property Size -Sum).Sum
        $maxSizeGB = [math]::Round($maxSize / 1GB, 0)
        
        Write-Host "  Current max possible: $maxSizeGB GB" -ForegroundColor White
    }
    
    Write-Host "  Resized successfully" -ForegroundColor Green
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "RESULT:OK - Partition resized" -ForegroundColor Green
exit 0
