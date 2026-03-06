<#
.SYNOPSIS
    Checks remote support tool status.

.DESCRIPTION
    Detects TeamViewer, AnyDesk, VNC, and other remote support tools.

.EXAMPLE
    .\Check-RemoteSupportTools.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Remote Support Tools ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "TeamViewer:" -ForegroundColor Yellow

$teamviewer = Get-Process -Name TeamViewer -ErrorAction SilentlyContinue

if ($teamviewer) {
    Write-Host "  Running: Yes (PID: $($teamviewer.Id))" -ForegroundColor Green
} else {
    $tvPath = "C:\Program Files\TeamViewer\TeamViewer.exe"
    if (Test-Path $tvPath) {
        Write-Host "  Installed: Yes" -ForegroundColor Green
    } else {
        Write-Host "  Not detected" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "AnyDesk:" -ForegroundColor Yellow

$anydesk = Get-Process -Name AnyDesk -ErrorAction SilentlyContinue

if ($anydesk) {
    Write-Host "  Running: Yes (PID: $($anydesk.Id))" -ForegroundColor Green
} else {
    $adPath = "C:\Program Files (x86)\AnyDesk\AnyDesk.exe"
    if (Test-Path $adPath) {
        Write-Host "  Installed: Yes" -ForegroundColor Green
    } else {
        Write-Host "  Not detected" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "VNC:" -ForegroundColor Yellow

$vnc = Get-Service -Name "vncserver" -ErrorAction SilentlyContinue

if ($vnc) {
    Write-Host "  VNC Server: $($vnc.Status)" -ForegroundColor $(if ($vnc.Status -eq "Running") { "Green" } else { "Gray" })
}

Write-Host ""
Write-Host "Windows Quick Assist:" -ForegroundColor Yellow

$qa = Get-Process -Name "quickassist" -ErrorAction SilentlyContinue

if ($qa) {
    Write-Host "  Active: Yes" -ForegroundColor Green
} else {
    Write-Host "  Not active" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Remote Desktop:" -ForegroundColor Yellow

$rdp = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections"

if ($rdp.fDenyTSConnections -eq 0) {
    Write-Host "  RDP Enabled: Yes" -ForegroundColor Green
} else {
    Write-Host "  RDP Enabled: No" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Windows Remote Management:" -ForegroundColor Yellow

$winrm = Get-Service -Name WinRM -ErrorAction SilentlyContinue

if ($winrm -and $winrm.Status -eq "Running") {
    Write-Host "  WinRM: Running" -ForegroundColor Green
} else {
    Write-Host "  WinRM: Not running" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - Remote support checked" -ForegroundColor Green
exit 0
