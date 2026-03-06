<#
.SYNOPSIS
    Exports WiFi profiles to XML.

.DESCRIPTION
    Lists and exports saved WiFi networks.

.PARAMETER OutputPath
    Path to export XML files.

.EXAMPLE
    .\Export-WiFiProfiles.ps1

.EXAMPLE
    .\Export-WiFiProfiles.ps1 -OutputPath "C:\temp\wifi"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$env:TEMP\WiFiProfiles"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== WiFi Profiles ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Saved WiFi Profiles:" -ForegroundColor Yellow

$profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { ($_ -split ":")[-1].Trim() }

if ($profiles) {
    foreach ($profile in $profiles) {
        $info = netsh wlan show profile name="$profile" key=clear 2>&1
        
        $auth = if ($info -match "Authentication.*:(.+)") { $Matches[1].Trim() } else { "Unknown" }
        $cipher = if ($info -match "Cipher.*:(.+)") { $Matches[1].Trim() } else { "Unknown" }
        
        Write-Host "  $profile" -ForegroundColor White
        Write-Host "    Auth: $auth" -ForegroundColor Gray
        Write-Host "    Cipher: $cipher" -ForegroundColor Gray
    }
} else {
    Write-Host "  No WiFi profiles found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Exporting profiles..." -ForegroundColor Yellow

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

foreach ($profile in $profiles) {
    $filename = "$OutputPath\$profile.xml"
    
    netsh wlan export profile name="$profile" folder="$OutputPath" 2>&1 | Out-Null
    
    Write-Host "  Exported: $profile.xml" -ForegroundColor Green
}

Write-Host ""
Write-Host "Exported to: $OutputPath" -ForegroundColor White

Write-Host ""
Write-Host "RESULT:OK - WiFi profiles exported" -ForegroundColor Green
exit 0
