<#
.SYNOPSIS
    Gets installed browser information.

.DESCRIPTION
    Lists installed browsers and their versions.

.EXAMPLE
    .\Get-BrowserInfo.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Browser Information ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$browsers = @()

Write-Host "Chrome:" -ForegroundColor Yellow

$chromePaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "C:\Program Files\Google\Chrome\Application\chrome.exe"
)

foreach ($path in $chromePaths) {
    if (Test-Path $path) {
        $version = (Get-Item $path).VersionInfo.FileVersion
        Write-Host "  Version: $version" -ForegroundColor Green
        Write-Host "  Path: $path" -ForegroundColor Gray
        $browsers += "Chrome"
        break
    }
}

if (-not ($browsers -contains "Chrome")) {
    Write-Host "  Not installed" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Edge:" -ForegroundColor Yellow

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

if (Test-Path $edgePath) {
    $version = (Get-Item $edgePath).VersionInfo.FileVersion
    Write-Host "  Version: $version" -ForegroundColor Green
    Write-Host "  Path: $edgePath" -ForegroundColor Gray
} else {
    Write-Host "  Not installed" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Firefox:" -ForegroundColor Yellow

$firefoxPath = "C:\Program Files\Mozilla Firefox\firefox.exe"

if (Test-Path $firefoxPath) {
    $version = (Get-Item $firefoxPath).VersionInfo.FileVersion
    Write-Host "  Version: $version" -ForegroundColor Green
} else {
    Write-Host "  Not installed" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Internet Explorer:" -ForegroundColor Yellow

$ie = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Internet Explorer" -ErrorAction SilentlyContinue

if ($ie) {
    Write-Host "  Version: $($ie.Version)" -ForegroundColor Green
    Write-Host "  Build: $($ie.Build)" -ForegroundColor Gray
} else {
    Write-Host "  Not available" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Default Browser:" -ForegroundColor Yellow

$default = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" -ErrorAction SilentlyContinue

if ($default) {
    Write-Host "  HTTP: $($default.ProgId)" -ForegroundColor White
}

Write-Host ""
Write-Host "Browser Cache Sizes:" -ForegroundColor Yellow

$users = Get-ChildItem C:\Users

foreach ($user in $users) {
    $chromeCache = "$($user.FullName)\AppData\Local\Google\Chrome\User Data\Default\Cache"
    $edgeCache = "$($user.FullName)\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
    
    if (Test-Path $chromeCache) {
        $size = (Get-ChildItem $chromeCache -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        $sizeMB = [math]::Round($size / 1MB, 2)
        Write-Host "  $($user.Name) Chrome: $sizeMB MB" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "RESULT:OK - Browser info collected" -ForegroundColor Green
exit 0
