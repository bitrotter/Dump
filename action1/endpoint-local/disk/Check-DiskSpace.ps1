<#
.SYNOPSIS
    Checks disk space and reports on low disk warnings.

.DESCRIPTION
    Checks all fixed drives and reports free space percentage.
    Outputs JSON for Action1 reporting.

.PARAMETER Threshold
    Free space percentage threshold for warning. Default: 10.

.EXAMPLE
    .\Check-DiskSpace.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Threshold = 10
)

$ErrorActionPreference = 'SilentlyContinue'

$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }

$results = @()

foreach ($drive in $drives) {
    $totalGB = [math]::Round($drive.Used / 1GB + $drive.Free / 1GB, 2)
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    $usedGB = [math]::Round($drive.Used / 1GB, 2)
    $freePercent = [math]::Round(($drive.Free / ($drive.Used + $drive.Free)) * 100, 1)

    $status = "OK"
    if ($freePercent -lt 5) {
        $status = "CRITICAL"
    } elseif ($freePercent -lt $Threshold) {
        $status = "WARNING"
    }

    $results += [PSCustomObject]@{
        Drive       = $drive.Name
        TotalGB     = $totalGB
        FreeGB      = $freeGB
        UsedGB      = $usedGB
        FreePercent = $freePercent
        Status      = $status
    }
}

$critical = ($results | Where-Object { $_.Status -eq "CRITICAL" }).Count
$warning = ($results | Where-Object { $_.Status -eq "WARNING" }).Count

Write-Host "=== Disk Space Report ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$results | Format-Table -AutoSize | Out-String | Write-Host

Write-Host ""
if ($critical -gt 0) {
    Write-Host "RESULT:CRITICAL - $critical drive(s) critically low on disk space" -ForegroundColor Red
    exit 2
} elseif ($warning -gt 0) {
    Write-Host "RESULT:WARNING - $warning drive(s) below $Threshold% free" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - All drives have adequate free space" -ForegroundColor Green
    exit 0
}
