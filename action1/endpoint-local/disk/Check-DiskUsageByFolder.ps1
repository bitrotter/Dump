<#
.SYNOPSIS
    Shows largest folders by disk usage.

.DESCRIPTION
    Scans specified paths and reports largest folders.
    Useful for finding disk space hogs.

.PARAMETER Path
    Path to scan. Default: C:\

.PARAMETER Top
    Number of top folders to show. Default: 10

.PARAMETER MinSizeGB
    Only show folders larger than this (GB). Default: 1

.EXAMPLE
    .\Check-DiskUsageByFolder.ps1 -Path "C:\" -Top 15

.EXAMPLE
    .\Check-DiskUsageByFolder.ps1 -Path "D:\" -MinSizeGB 5
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Path = "C:\",

    [Parameter(Mandatory=$false)]
    [int]$Top = 10,

    [Parameter(Mandatory=$false)]
    [int]$MinSizeGB = 1
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Disk Usage by Folder ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Path: $Path" -ForegroundColor Gray
Write-Host ""

$MinSizeBytes = $MinSizeGB * 1GB

Write-Host "Scanning... (this may take a while)" -ForegroundColor Yellow

$folders = Get-ChildItem -Path $Path -Directory -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        if ($size -gt $MinSizeBytes) {
            [PSCustomObject]@{
                Path = $_.FullName
                SizeGB = [math]::Round($size / 1GB, 2)
                SizeMB = [math]::Round($size / 1MB, 0)
            }
        }
    } catch { }
}

$largest = $folders | Sort-Object SizeGB -Descending | Select-Object -First $Top

Write-Host ""
Write-Host "Top $Top Folders (>$MinSizeGB GB):" -ForegroundColor Cyan
$largest | Format-Table @{Label="Size (GB)"; Expression={$_.SizeGB}}, Path -AutoSize | Out-String | Write-Host

$totalGB = ($largest | Measure-Object SizeGB -Sum).Sum
Write-Host "Total in top $Top folders: $([math]::Round($totalGB, 2)) GB" -ForegroundColor White

$drive = Get-PSDrive -Name $Path.TrimEnd(':').TrimEnd('\') -ErrorAction SilentlyContinue
if ($drive) {
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    Write-Host "Drive free space: $freeGB GB" -ForegroundColor $(if ($freeGB -lt 10) { "Red" } elseif ($freeGB -lt 20) { "Yellow" } else { "Green" })
}

Write-Host ""
Write-Host "RESULT:OK - Scan complete" -ForegroundColor Green
exit 0
