<#
.SYNOPSIS
    Checks Remote Desktop settings and status.

.DESCRIPTION
    Reports RDP enablement, NLA settings, port, and firewall rules.

.PARAMETER EnableRDP
    Enable RDP if disabled.

.EXAMPLE
    .\Check-RDPSettings.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$EnableRDP
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== RDP Settings Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Remote Desktop Status:" -ForegroundColor Yellow

$rdpEnabled = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server").fDenyTSConnections

if ($rdpEnabled -eq 0) {
    Write-Host "  RDP Enabled: Yes" -ForegroundColor Green
} else {
    Write-Host "  RDP Enabled: No" -ForegroundColor Red
    
    if ($EnableRDP) {
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        Write-Host "  RDP has been enabled" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Network Level Authentication:" -ForegroundColor Yellow

$nla = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp").UserAuthentication

if ($nla -eq 1) {
    Write-Host "  NLA Required: Yes" -ForegroundColor Green
} else {
    Write-Host "  NLA Required: No" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "RDP Port:" -ForegroundColor Yellow

$port = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp").PortNumber
Write-Host "  Port: $port" -ForegroundColor White

Write-Host ""
Write-Host "Firewall Rules:" -ForegroundColor Yellow

$rules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*Remote Desktop*" }

foreach ($rule in $rules) {
    $status = if ($rule.Enabled) { "Enabled" } else { "Disabled" }
    $color = if ($rule.Enabled) { "Green" } else { "Gray" }
    Write-Host "  $($rule.DisplayName): $status" -ForegroundColor $color
}

Write-Host ""
Write-Host "RDP Sessions:" -ForegroundColor Yellow

try {
    $sessions = query user /fo csv | ConvertFrom-Csv
    
    if ($sessions) {
        $sessions | ForEach-Object {
            $user = $_.'USERNAME' -replace ">", ""
            $state = $_.'STATE'
            Write-Host "  $user - $state" -ForegroundColor White
        }
    } else {
        Write-Host "  No active sessions" -ForegroundColor Green
    }
} catch {
    Write-Host "  Could not query sessions" -ForegroundColor Gray
}

Write-Host ""

if ($rdpEnabled -ne 0) {
    Write-Host "RESULT:WARNING - RDP is disabled" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - RDP is enabled" -ForegroundColor Green
    exit 0
}
