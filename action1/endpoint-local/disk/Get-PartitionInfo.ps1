<#
.SYNOPSIS
    Gets disk partition information.

.DESCRIPTION
    Lists all disk partitions and their details.

.EXAMPLE
    .\Get-PartitionInfo.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Partition Information ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Physical Disks:" -ForegroundColor Yellow

$disks = Get-Disk

foreach ($disk in $disks) {
    Write-Host ""
    Write-Host "Disk $($disk.Number): $($disk.FriendlyName)" -ForegroundColor White
    Write-Host "  Size: $([math]::Round($disk.Size/1TB, 2)) TB" -ForegroundColor Gray
    Write-Host "  Partition Style: $($disk.PartitionStyle)" -ForegroundColor Gray
    Write-Host "  Operational Status: $($disk.OperationalStatus)" -ForegroundColor Gray
    Write-Host "  Health Status: $($disk.HealthStatus)" -ForegroundColor $(if ($disk.HealthStatus -eq "Healthy") { "Green" } else { "Red" })
}

Write-Host ""
Write-Host "Partitions:" -ForegroundColor Yellow

$partitions = Get-Partition

foreach ($partition in $partitions) {
    if ($partition.DriveLetter -or $partition.Type -ne "Reserved") {
        $drive = if ($partition.DriveLetter) { "$($partition.DriveLetter):" } else { "No Letter" }
        
        Write-Host "  $drive - $($partition.Type) - $([math]::Round($partition.Size/1GB, 2)) GB" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "RESULT:OK - Partition info retrieved" -ForegroundColor Green
exit 0
