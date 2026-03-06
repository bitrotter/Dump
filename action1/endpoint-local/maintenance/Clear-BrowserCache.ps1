<#
.SYNOPSIS
    Clears browser cache for Chrome, Edge, and Firefox.

.DESCRIPTION
    Removes browser cache files, history, and cookies
    for supported browsers.

.PARAMETER Browser
    Specific browser to clear: Chrome, Edge, Firefox, or All.

.EXAMPLE
    .\Clear-BrowserCache.ps1

.EXAMPLE
    .\Clear-BrowserCache.ps1 -Browser Chrome
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Chrome", "Edge", "Firefox", "All")]
    [string]$Browser = "All"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Browser Cache Clear ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$totalFreed = 0

function Clear-BrowserData {
    param([string]$BrowserName, [string]$Path)
    
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        Remove-Item "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        $freedMB = [math]::Round($size / 1MB, 2)
        Write-Host "  $BrowserName : $freedMB MB cleared" -ForegroundColor Green
        return $size
    }
    Write-Host "  $BrowserName : Not found" -ForegroundColor Gray
    return 0
}

$chrome = ($Browser -eq "Chrome" -or $Browser -eq "All")
$edge = ($Browser -eq "Edge" -or $Browser -eq "All")
$firefox = ($Browser -eq "Firefox" -or $Browser -eq "All")

if ($chrome) {
    Write-Host "Clearing Chrome..." -ForegroundColor Yellow
    foreach ($user in Get-ChildItem C:\Users) {
        $totalFreed += Clear-BrowserData -BrowserName "Chrome" -Path "$($user.FullName)\AppData\Local\Google\Chrome\User Data\Default\Cache"
        $totalFreed += Clear-BrowserData -BrowserName "Chrome" -Path "$($user.FullName)\AppData\Local\Google\Chrome\User Data\Default\Code Cache"
    }
}

if ($edge) {
    Write-Host "Clearing Edge..." -ForegroundColor Yellow
    foreach ($user in Get-ChildItem C:\Users) {
        $totalFreed += Clear-BrowserData -BrowserName "Edge" -Path "$($user.FullName)\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
        $totalFreed += Clear-BrowserData -BrowserName "Edge" -Path "$($user.FullName)\AppData\Local\Microsoft\Edge\User Data\Default\Code Cache"
    }
}

if ($firefox) {
    Write-Host "Clearing Firefox..." -ForegroundColor Yellow
    foreach ($user in Get-ChildItem C:\Users) {
        $profilesPath = "$($user.FullName)\AppData\Local\Mozilla\Firefox\Profiles"
        if (Test-Path $profilesPath) {
            foreach ($profile in Get-ChildItem $profilesPath) {
                $totalFreed += Clear-BrowserData -BrowserName "Firefox Cache" -Path "$profile\cache2"
                $totalFreed += Clear-BrowserData -BrowserName "Firefox Startup" -Path "$profile\startupCache"
            }
        }
    }
}

$freedMB = [math]::Round($totalFreed / 1MB, 2)

Write-Host ""
Write-Host "Total cleared: $freedMB MB" -ForegroundColor Green

Write-Host ""
Write-Host "RESULT:OK - Browser cache cleared" -ForegroundColor Green
exit 0
