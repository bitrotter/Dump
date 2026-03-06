<#
.SYNOPSIS
    Checks cluster disk resources.

.DESCRIPTION
    Lists failover cluster disks and their status.

.EXAMPLE
    .\Check-ClusterDisks.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Cluster Disk Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

try {
    $cluster = Get-Cluster -ErrorAction Stop
    
    Write-Host "Cluster: $($cluster.Name)" -ForegroundColor White
    Write-Host "  Status: $($cluster.State)" -ForegroundColor $(if ($cluster.State -eq "Up") { "Green" } else { "Yellow" })
    
    Write-Host ""
    Write-Host "Cluster Disks:" -ForegroundColor Yellow
    
    $disks = Get-ClusterDisk -ErrorAction SilentlyContinue
    
    if ($disks) {
        foreach ($disk in $disks) {
            Write-Host "  $($disk.Name): $($disk.State)" -ForegroundColor White
        }
    } else {
        Write-Host "  No cluster disks found" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "  Not a cluster node or no cluster available" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - Cluster check complete" -ForegroundColor Green
exit 0
