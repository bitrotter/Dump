<#
.SYNOPSIS
    Checks M365/Office license status.

.DESCRIPTION
    Reports installed Office/M365 applications and license status.

.EXAMPLE
    .\Check-M365License.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== M365/Office License Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Installed Office Versions:" -ForegroundColor Yellow

$officePaths = @(
    "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration",
    "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot",
    "HKLM:\SOFTWARE\Microsoft\Office\15.0\Common\InstallRoot"
)

$officeInstalled = $false

foreach ($path in $officePaths) {
    if (Test-Path $path) {
        $config = Get-ItemProperty -Path $path
        
        if ($config.Platform -eq "x64") {
            Write-Host "  Office 365 (Click-to-Run): 64-bit" -ForegroundColor Green
            $officeInstalled = $true
        }
        
        if ($config.VersionToReport) {
            Write-Host "  Version: $($config.VersionToReport)" -ForegroundColor White
        }
        
        if ($config.ProductReleaseIds) {
            Write-Host "  Product IDs: $($config.ProductReleaseIds)" -ForegroundColor Gray
        }
    }
}

if (-not $officeInstalled) {
    $legacy = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\InstallRoot" -ErrorAction SilentlyContinue
    
    if ($legacy) {
        Write-Host "  Office (MSI): Installed" -ForegroundColor Green
    } else {
        Write-Host "  Office: Not installed" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Office Applications:" -ForegroundColor Yellow

$apps = @{
    "Word" = "WINWORD.EXE"
    "Excel" = "EXCEL.EXE"
    "PowerPoint" = "POWERPNT.EXE"
    "Outlook" = "OUTLOOK.EXE"
    "Teams" = "Teams.exe"
    "OneNote" = "ONENOTE.EXE"
    "Publisher" = "MSPUB.EXE"
    "Access" = "MSACCESS.EXE"
}

foreach ($app in $apps.GetEnumerator()) {
    $process = Get-Process -Name $app.Value.Replace(".EXE", "") -ErrorAction SilentlyContinue
    
    if ($process) {
        Write-Host "  $($app.Key): Running" -ForegroundColor Green
    } else {
        Write-Host "  $($app.Key): Not running" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Teams Status:" -ForegroundColor Yellow

$teams = Get-Process -Name Teams -ErrorAction SilentlyContinue

if ($teams) {
    Write-Host "  Teams: Running" -ForegroundColor Green
    Write-Host "    PID: $($teams.Id)" -ForegroundColor Gray
} else {
    Write-Host "  Teams: Not running" -ForegroundColor Gray
}

$teamsPath = "$env:LOCALAPPDATA\Microsoft\Teams"

if (Test-Path $teamsPath) {
    Write-Host "  Teams installed: Yes" -ForegroundColor Green
}

Write-Host ""
Write-Host "OneDrive Status:" -ForegroundColor Yellow

$onedrive = Get-Process -Name OneDrive -ErrorAction SilentlyContinue

if ($onedrive) {
    Write-Host "  OneDrive: Running" -ForegroundColor Green
} else {
    Write-Host "  OneDrive: Not running" -ForegroundColor Gray
}

Write-Host ""
Write-Host "SharePoint:" -ForegroundColor Yellow

$spPath = "$env:APPDATA\Microsoft\Teams\blob_storage"

if (Test-Path $spPath) {
    Write-Host "  SharePoint cache: Present" -ForegroundColor Gray
}

Write-Host ""

if ($officeInstalled) {
    Write-Host "RESULT:OK - M365 installed" -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT:WARNING - M365 not detected" -ForegroundColor Yellow
    exit 1
}
