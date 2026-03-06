<#
.SYNOPSIS
    Clears temporary files to free up disk space.

.DESCRIPTION
    Removes temp files from various locations:
    - Windows Temp folder
    - User Temp folders
    - Browser caches (optional)
    - Windows Update cache (optional)

.PARAMETER CleanBrowserCache
    Include browser cache cleanup.

.PARAMETER CleanUpdateCache
    Clear Windows Update download cache.

.EXAMPLE
    .\Clear-TempFiles.ps1

.EXAMPLE
    .\Clear-TempFiles.ps1 -CleanBrowserCache -CleanUpdateCache
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$CleanBrowserCache,

    [Parameter(Mandatory=$false)]
    [switch]$CleanUpdateCache
)

$ErrorActionPreference = 'SilentlyContinue'

$totalFreed = 0

function Clear-Folder {
    param([string]$Path, [string]$Description)
    
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $count = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue).Count
        
        Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        
        $freedMB = [math]::Round($size / 1MB, 2)
        Write-Host "  $Description : $freedMB MB ($count files)" -ForegroundColor Green
        return $size
    }
    return 0
}

Write-Host "=== Temp File Cleanup ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Cleaning Windows Temp..." -ForegroundColor Yellow
$totalFreed += Clear-Folder -Path "$env:WINDIR\Temp" -Description "Windows Temp"

Write-Host "Cleaning User Temp..." -ForegroundColor Yellow
$totalFreed += Clear-Folder -Path "$env:TEMP" -Description "User Temp"

foreach ($user in Get-ChildItem C:\Users) {
    Write-Host "Cleaning $($user.Name) temp..." -ForegroundColor Yellow
    $totalFreed += Clear-Folder -Path "$($user.FullName)\AppData\Local\Temp" -Description "  User Temp"
}

if ($CleanBrowserCache) {
    Write-Host "Cleaning Browser Caches..." -ForegroundColor Yellow
    
    foreach ($user in Get-ChildItem C:\Users) {
        $paths = @(
            "$($user.FullName)\AppData\Local\Google\Chrome\User Data\Default\Cache",
            "$($user.FullName)\AppData\Local\Microsoft\Edge\User Data\Default\Cache",
            "$($user.FullName)\AppData\Local\Mozilla\Firefox\Profiles\*\cache2"
        )
        
        foreach ($path in $paths) {
            if (Test-Path $path) {
                $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
                $totalFreed += $size
            }
        }
    }
    Write-Host "  Browser caches cleared" -ForegroundColor Green
}

if ($CleanUpdateCache) {
    Write-Host "Cleaning Windows Update Cache..." -ForegroundColor Yellow
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    $totalFreed += Clear-Folder -Path "$env:WINDIR\SoftwareDistribution\Download" -Description "  Update Cache"
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
}

$freedMB = [math]::Round($totalFreed / 1MB, 2)
$freedGB = [math]::Round($totalFreed / 1GB, 2)

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total space freed: $freedMB MB ($freedGB GB)" -ForegroundColor Green

Write-Host "RESULT:OK - Cleanup complete, freed $freedMB MB" -ForegroundColor Green
exit 0
