<#
.SYNOPSIS
    Checks OneDrive sync status.

.DESCRIPTION
    Reports OneDrive installation, sync status, and account info.

.PARAMETER ForceSync
    Force OneDrive to sync.

.EXAMPLE
    .\Check-OneDriveStatus.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ForceSync
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== OneDrive Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "OneDrive Process:" -ForegroundColor Yellow

$onedrive = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue

if ($onedrive) {
    Write-Host "  Running: Yes" -ForegroundColor Green
    Write-Host "  PID: $($onedrive.Id)" -ForegroundColor Gray
    Write-Host "  Memory: $([math]::Round($onedrive.WorkingSet64/1MB, 2)) MB" -ForegroundColor Gray
} else {
    Write-Host "  Running: No" -ForegroundColor Red
}

Write-Host ""
Write-Host "OneDrive Installation:" -ForegroundColor Yellow

$onedrivePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
$programFiles = "${env:ProgramFiles}\Microsoft OneDrive\OneDrive.exe"
$programFilesx86 = "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe"

$installedPath = $null

if (Test-Path $onedrivePath) { $installedPath = $onedrivePath }
elseif (Test-Path $programFiles) { $installedPath = $programFiles }
elseif (Test-Path $programFilesx86) { $installedPath = $programFilesx86 }

if ($installedPath) {
    Write-Host "  Installed: Yes" -ForegroundColor Green
    Write-Host "  Path: $installedPath" -ForegroundColor Gray
    
    $version = (Get-Item $installedPath).VersionInfo.FileVersion
    Write-Host "  Version: $version" -ForegroundColor White
} else {
    Write-Host "  Installed: No" -ForegroundColor Red
}

Write-Host ""
Write-Host "OneDrive Settings:" -ForegroundColor Yellow

$settingsPath = "$env:LOCALAPPDATA\Microsoft\OneDrive\settings"

if (Test-Path $settingsPath) {
    $business = Get-ChildItem $settingsPath -Recurse -Filter "*.dat" | Where-Object { $_.Name -match "business" }
    
    if ($business) {
        Write-Host "  Type: OneDrive for Business" -ForegroundColor Green
    } else {
        Write-Host "  Type: Personal" -ForegroundColor Gray
    }
}

$generalSettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\OneDrive" -ErrorAction SilentlyContinue

if ($generalSettings) {
    Write-Host "  User Email: $($generalSettings.UserEmail)" -ForegroundColor White
}

Write-Host ""
Write-Host "Sync Status:" -ForegroundColor Yellow

$onedriveXml = "$env:LOCALAPPDATA\Microsoft\OneDrive\settings\Personal\Settings.ini"

if (Test-Path $onedriveXml) {
    $content = Get-Content $onedriveXml -Raw
    
    if ($content -match "SILENT") {
        Write-Host "  Silent Mode: Enabled" -ForegroundColor Gray
    }
    
    if ($content -match "GPOSite") {
        Write-Host "  GPODrive: Configured" -ForegroundColor Gray
    }
}

$syncFolders = @(
    "$env:USERPROFILE\OneDrive",
    "$env:USERPROFILE\OneDrive - Personal"
)

$syncStatus = "Not Syncing"

foreach ($folder in $syncFolders) {
    if (Test-Path $folder) {
        $files = Get-ChildItem $folder -File -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($files) {
            $syncStatus = "Syncing"
            Write-Host "  Folder: $folder" -ForegroundColor Green
            Write-Host "  Status: Files present" -ForegroundColor White
        }
    }
}

Write-Host ""
Write-Host "Recent Activity:" -ForegroundColor Yellow

$logPath = "$env:LOCALAPPDATA\Microsoft\OneDrive\logs"

if (Test-Path $logPath) {
    $logs = Get-ChildItem $logPath -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if ($logs) {
        $lastWrite = $logs.LastWriteTime
        Write-Host "  Last Activity: $lastWrite" -ForegroundColor Gray
        
        $recentLog = Get-Content $logs.FullName -Tail 10 -ErrorAction SilentlyContinue
        
        if ($recentLog -match "error|failed") {
            Write-Host "  Recent Errors: Yes" -ForegroundColor Red
        }
    }
}

if ($ForceSync -and $onedrive) {
    Write-Host ""
    Write-Host "Triggering sync..." -ForegroundColor Yellow
    
    $onedrive | ForEach-Object { 
        $_.CloseMainWindow() | Out-Null
        Start-Sleep -Seconds 2
        Start-Process $installedPath
    }
    
    Write-Host "  Sync triggered" -ForegroundColor Green
}

Write-Host ""

if (-not $onedrive) {
    Write-Host "RESULT:WARNING - OneDrive not running" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - OneDrive running" -ForegroundColor Green
    exit 0
}
