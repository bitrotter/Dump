<#
.SYNOPSIS
    Lists large files on disk.

.DESCRIPTION
    Finds largest files on specified drive.

.PARAMETER Path
    Path to search (default: C:\).

.PARAMETER Top
    Number of files to show (default: 20).

.PARAMETER MinSizeMB
    Minimum file size in MB (default: 100).

.EXAMPLE
    .\Find-LargeFiles.ps1 -Path "C:\" -Top 10
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Path = "C:\",

    [Parameter(Mandatory=$false)]
    [int]$Top = 20,

    [Parameter(Mandatory=$false)]
    [int]$MinSizeMB = 100
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Large Files Finder ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Path: $Path" -ForegroundColor Gray
Write-Host ""

Write-Host "Scanning for files > $MinSizeMB MB (this may take a while)..." -ForegroundColor Yellow

$minBytes = $MinSizeMB * 1MB
$files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.Length -gt $minBytes } | 
    Sort-Object Length -Descending | 
    Select-Object -First $Top

Write-Host ""
Write-Host "Found $($files.Count) large files:" -ForegroundColor Cyan

foreach ($file in $files) {
    $sizeMB = [math]::Round($file.Length / 1MB, 0)
    $sizeGB = [math]::Round($file.Length / 1GB, 2)
    
    $sizeStr = if ($sizeGB -gt 1) { "$sizeGB GB" } else { "$sizeMB MB" }
    
    Write-Host "  $sizeStr - $($file.FullName)" -ForegroundColor White
}

Write-Host ""
Write-Host "RESULT:OK - Scan complete" -ForegroundColor Green
exit 0
