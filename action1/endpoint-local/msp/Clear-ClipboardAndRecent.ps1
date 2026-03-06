<#
.SYNOPSIS
    Clears clipboard and recent items.

.DESCRIPTION
    Clears clipboard, recent files, and temp data.

.PARAMETER Full
    Clear all including browser history.

.EXAMPLE
    .\Clear-ClipboardAndRecent.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Full
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Clear Clipboard & Recent ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Clearing clipboard..." -ForegroundColor Yellow

Set-Clipboard -Value $null
Write-Host "  Clipboard cleared" -ForegroundColor Green

Write-Host ""
Write-Host "Clearing recent files..." -ForegroundColor Yellow

$recent = [Environment]::GetFolderPath("Recent")

$files = Get-ChildItem $recent -ErrorAction SilentlyContinue
$count = $files.Count

$files | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "  Cleared $count items" -ForegroundColor Green

Write-Host ""
Write-Host "Clearing temp folders..." -ForegroundColor Yellow

$tempPaths = @($env:TEMP, "$env:WINDIR\Temp")

foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        $tempCount = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue).Count
        Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Cleared $tempCount items from $path" -ForegroundColor Green
    }
}

if ($Full) {
    Write-Host ""
    Write-Host "Clearing browser data..." -ForegroundColor Yellow
    
    $users = Get-ChildItem C:\Users
    
    foreach ($user in $users) {
        $chrome = "$($user.FullName)\AppData\Local\Google\Chrome\User Data\Default\Cache"
        $edge = "$($user.FullName)\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
        
        foreach ($path in @($chrome, $edge)) {
            if (Test-Path $path) {
                $count = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue).Count
                Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "  Browser cache cleared" -ForegroundColor Green
}

Write-Host ""
Write-Host "RESULT:OK - Cleanup complete" -ForegroundColor Green
exit 0
