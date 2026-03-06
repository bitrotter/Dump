<#
.SYNOPSIS
    Checks WSUS configuration and status.

.DESCRIPTION
    Reports WSUS server configuration, update source, 
    and client status.

.EXAMPLE
    .\Check-WSUSConfiguration.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== WSUS Configuration ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

Write-Host "Windows Update Configuration:" -ForegroundColor Yellow

if (Test-Path $wuPath) {
    $wu = Get-ItemProperty -Path $wuPath
    
    if ($wu.WUServer) {
        Write-Host "  WSUS Server: $($wu.WUServer)" -ForegroundColor White
        Write-Host "  Status Server: $($wu.WUStatusServer)" -ForegroundColor Gray
    } else {
        Write-Host "  Update Source: Windows Update (Microsoft)" -ForegroundColor Green
    }
    
    if ($wu.DisableDualScan) {
        Write-Host "  Dual Scan: Disabled" -ForegroundColor Green
    }
    
    if ($wu.UpdateServiceUrlAlternate) {
        Write-Host "  Alternate URL: $($wu.UpdateServiceUrlAlternate)" -ForegroundColor Gray
    }
} else {
    Write-Host "  Using default Windows Update" -ForegroundColor Green
}

Write-Host ""
Write-Host "Auto-Update Configuration:" -ForegroundColor Yellow

$auPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"

if (Test-Path $auPath) {
    $au = Get-ItemProperty -Path $auPath
    
    if ($au.EnableService) {
        Write-Host "  Automatic Updates: Enabled" -ForegroundColor Green
    }
    
    if ($au.ConfigureWUAPIServer) {
        Write-Host "  API Server: $($au.ConfigureWUAPIServer)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "WU Service Status:" -ForegroundColor Yellow

$wuauserv = Get-Service -Name wuauserv
Write-Host "  Service: $($wuauserv.Status)" -ForegroundColor $(if ($wuauserv.Status -eq "Running") { "Green" } else { "Red" })

$bits = Get-Service -Name BITS
Write-Host "  BITS: $($bits.Status)" -ForegroundColor $(if ($bits.Status -eq "Running") { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "Last Contact:" -ForegroundColor Yellow

$resultsPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install"

if (Test-Path $resultsPath) {
    $results = Get-ItemProperty -Path $resultsPath
    
    if ($results.LastSuccessTime) {
        Write-Host "  Last Install: $($results.LastSuccessTime)" -ForegroundColor White
    }
    
    if ($results.LastErrorCode) {
        if ($results.LastErrorCode -eq 0) {
            Write-Host "  Last Error: None" -ForegroundColor Green
        } else {
            Write-Host "  Last Error: $($results.LastErrorCode)" -ForegroundColor Red
        }
    }
}

$scanPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Scan"

if (Test-Path $scanPath) {
    $scan = Get-ItemProperty -Path $scanPath
    
    if ($scan.LastSuccessTime) {
        Write-Host "  Last Scan: $($scan.LastSuccessTime)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "Pending Updates:" -ForegroundColor Yellow

try {
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult = $updateSearcher.Search("IsInstalled=0")
    
    Write-Host "  Available: $($searchResult.Updates.Count)" -ForegroundColor $(if ($searchResult.Updates.Count -eq 0) { "Green" } else { "Yellow" })
} catch {
    Write-Host "  Could not query updates" -ForegroundColor Gray
}

Write-Host ""

$issues = @()

if ($wuauserv.Status -ne "Running") { $issues += "WU service not running" }
if ($bits.Status -ne "Running") { $issues += "BITS not running" }

if ($issues.Count -gt 0) {
    Write-Host "RESULT:WARNING - $($issues -join ', ')" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - WSUS configured correctly" -ForegroundColor Green
    exit 0
}
