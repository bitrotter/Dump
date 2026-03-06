<#
.SYNOPSIS
    Checks disk quota status.

.DESCRIPTION
    Reports if disk quotas are enabled and usage.

.EXAMPLE
    .\Check-DiskQuota.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Disk Quota Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Quota Settings:" -ForegroundColor Yellow

$quota = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Disk" -ErrorAction SilentlyContinue

if ($quota.QuotaEnabled) {
    Write-Host "  Quotas Enabled: Yes" -ForegroundColor Green
} else {
    Write-Host "  Quotas Enabled: No" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Disk Space by User (if quotas enabled):" -ForegroundColor Yellow

$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne null }

foreach ($drive in $drives) {
    $totalGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    $usedGB = [math]::Round($drive.Used / 1GB, 2)
    $percent = [math]::Round(($drive.Used / ($drive.Used + $drive.Free)) * 100, 1)
    
    Write-Host "  Drive $($drive.Name):" -ForegroundColor White
    Write-Host "    Used: $usedGB GB ($percent%)" -ForegroundColor $(if ($percent -gt 90) { "Red" } elseif ($percent -gt 75) { "Yellow" } else { "Green" })
    Write-Host "    Free: $freeGB GB" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - Quota check complete" -ForegroundColor Green
exit 0
