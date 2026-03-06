<#
.SYNOPSIS
    Checks Windows Update status on the endpoint.

.DESCRIPTION
    Reports pending updates, last update time, and update service status.

.PARAMETER ShowDetails
    Show detailed list of pending updates.

.EXAMPLE
    .\Check-WindowsUpdate.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows Update Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$updateSession = New-Object -ComObject Microsoft.Update.Session
$updateSearcher = $updateSession.CreateUpdateSearcher()

$searchResult = $updateSearcher.Search("IsInstalled=0")

$hotfixes = Get-HotFix | Sort-Object InstalledOn -Descending
$lastHotfix = $hotfixes | Select-Object -First 1

Write-Host "Last Installed Update: " -NoNewline -ForegroundColor Yellow
if ($lastHotfix) {
    $installedDate = if ($lastHotfix.InstalledOn) { $lastHotfix.InstalledOn.ToString("yyyy-MM-dd") } else { "Unknown" }
    Write-Host "$($lastHotfix.HotFixID) ($installedDate)" -ForegroundColor White
} else {
    Write-Host "Unknown" -ForegroundColor Gray
}

Write-Host "Pending Updates: " -NoNewline -ForegroundColor Yellow
Write-Host $searchResult.Updates.Count -ForegroundColor White

if ($searchResult.Updates.Count -gt 0 -and $ShowDetails) {
    Write-Host ""
    Write-Host "Pending Update List:" -ForegroundColor Cyan
    
    foreach ($update in $searchResult.Updates) {
        $severity = if ($update.MsrcSeverity) { $update.MsrcSeverity } else { "Normal" }
        
        $color = switch ($severity) {
            "Critical" { "Red" }
            "Important" { "Yellow" }
            default { "White" }
        }
        
        Write-Host "  [$severity] $($update.Title)" -ForegroundColor $color
    }
}

$wuauserv = Get-Service -Name wuauserv
Write-Host ""
Write-Host "Windows Update Service: " -NoNewline -ForegroundColor Yellow
Write-Host $wuauserv.Status -ForegroundColor $(if ($wuauserv.Status -eq "Running") { "Green" } else { "Red" })

$autoUpdate = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update").EnableService

Write-Host "Automatic Updates: " -NoNewline -ForegroundColor Yellow
Write-Host $(if ($autoUpdate -eq 1) { "Enabled" } else { "Disabled" }) -ForegroundColor $(if ($autoUpdate -eq 1) { "Green" } else { "Red" })

Write-Host ""

if ($searchResult.Updates.Count -gt 0) {
    $critical = ($searchResult.Updates | Where-Object { $_.MsrcSeverity -eq "Critical" }).Count
    $important = ($searchResult.Updates | Where-Object { $_.MsrcSeverity -eq "Important" }).Count
    
    if ($critical -gt 0) {
        Write-Host "RESULT:CRITICAL - $critical critical updates pending" -ForegroundColor Red
        exit 2
    } elseif ($important -gt 0) {
        Write-Host "RESULT:WARNING - $important important updates pending" -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "RESULT:WARNING - $($searchResult.Updates.Count) updates pending" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "RESULT:OK - No pending updates" -ForegroundColor Green
    exit 0
}
