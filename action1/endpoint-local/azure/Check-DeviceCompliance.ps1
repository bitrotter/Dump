<#
.SYNOPSIS
    Checks Intune device compliance status.

.DESCRIPTION
    Reports device compliance state from local registry
    and any compliance policies applied.

.PARAMETER ShowDetails
    Show detailed compliance policy status.

.EXAMPLE
    .\Check-DeviceCompliance.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Device Compliance Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Compliance Information:" -ForegroundColor Yellow

$compliancePath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\Device"

$encryption = Get-ItemProperty -Path "$compliancePath\StorageEncryption" -ErrorAction SilentlyContinue
$bitlocker = Get-BitLockerVolume -MountPoint C: -ErrorAction SilentlyContinue

Write-Host "BitLocker:" -NoNewline -ForegroundColor White
if ($bitlocker -and $bitlocker.ProtectionStatus -eq "On") {
    Write-Host " Enabled" -ForegroundColor Green
} else {
    Write-Host " Not Enabled" -ForegroundColor Red
}

$secureboot = bcdedit /enum firmware 2>$null
Write-Host "Secure Boot:" -NoNewline -ForegroundColor White
if ($secureboot -match "secureboot") {
    Write-Host " Supported" -ForegroundColor Green
} else {
    Write-Host " Unknown" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Windows Defender:" -ForegroundColor Yellow

try {
    $defender = Get-MpComputerStatus
    
    Write-Host "  Real-Time Protection: " -NoNewline
    Write-Host $(if ($defender.RealTimeProtectionEnabled) { "Enabled" } else { "Disabled" }) -ForegroundColor $(if ($defender.RealTimeProtectionEnabled) { "Green" } else { "Red" })
    
    Write-Host "  Antivirus: " -NoNewline
    Write-Host $(if ($defender.AntivirusEnabled) { "Enabled" } else { "Disabled" }) -ForegroundColor $(if ($defender.AntivirusEnabled) { "Green" } else { "Red" })
    
    Write-Host "  Firewall: " -NoNewline
    $fw = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    if ($fw -and ($fw | Where-Object { $_.Enabled }).Count -eq 3) {
        Write-Host "Enabled" -ForegroundColor Green
    } else {
        Write-Host "Disabled" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  Could not get Defender status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "OS Version:" -ForegroundColor Yellow

$os = Get-CimInstance Win32_OperatingSystem
Write-Host "  Build: $($os.BuildNumber)" -ForegroundColor White
Write-Host "  Version: $($os.Version)" -ForegroundColor White

$supported = @("10.0.19041", "10.0.19042", "10.0.19043", "10.0.19044", "10.0.19045", "10.0.22000", "10.0.22621", "10.0.22631")
if ($os.BuildNumber -in $supported) {
    Write-Host "  Supported: Yes" -ForegroundColor Green
} else {
    Write-Host "  Supported: May be outdated" -ForegroundColor Yellow
}

Write-Host ""

if ($ShowDetails) {
    Write-Host "Detailed MDM Status:" -ForegroundColor Cyan
    
    $mdmPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MDM"
    if (Test-Path $mdmPath) {
        Get-ChildItem $mdmPath -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            if ($props.PSObject.Properties.Name -match "State") {
                $state = $props.State
                if ($state) {
                    Write-Host "  $($_.Name): $state" -ForegroundColor White
                }
            }
        }
    }
}

$issues = @()

if (-not $bitlocker -or $bitlocker.ProtectionStatus -ne "On") { $issues += "BitLocker not enabled" }
if (-not $defender.RealTimeProtectionEnabled) { $issues += "RTP disabled" }
if (($fw | Where-Object { $_.Enabled }).Count -lt 3) { $issues += "Firewall not fully enabled" }

if ($issues.Count -gt 0) {
    Write-Host "RESULT:WARNING - Non-compliant: $($issues -join ', ')" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Device appears compliant" -ForegroundColor Green
    exit 0
}
