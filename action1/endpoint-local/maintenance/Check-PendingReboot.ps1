<#
.SYNOPSIS
    Checks if the system has a pending reboot.

.DESCRIPTION
    Checks multiple sources for pending reboot:
    - Windows Update
    - Component-based Servicing
    - Pending file rename operations
    - Registry flags

.EXAMPLE
    .\Check-PendingReboot.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Pending Reboot Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$rebootPending = $false

$check1 = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install" -ErrorAction SilentlyContinue
if ($check1 -and $check1.LastSuccessTime) {
    $lastUpdate = [datetime]::Parse($check1.LastSuccessTime)
    $pending = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue
    
    if ($pending) {
        Write-Host "[X] Windows Update reboot required" -ForegroundColor Red
        $rebootPending = $true
    } else {
        Write-Host "[ ] Windows Update: OK (Last: $lastUpdate)" -ForegroundColor Green
    }
}

$check2 = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing" -ErrorAction SilentlyContinue
if ($check2 -and $check2.RebootPending) {
    Write-Host "[X] Component Based Servicing reboot required" -ForegroundColor Red
    $rebootPending = $true
} else {
    Write-Host "[ ] Component Based Servicing: OK" -ForegroundColor Green
}

$check3 = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -ErrorAction SilentlyContinue
if ($check3 -and $check3.PendingFileRenameOperations) {
    Write-Host "[X] Pending file rename operations detected" -ForegroundColor Red
    $rebootPending = $true
} else {
    Write-Host "[ ] Pending file renames: None" -ForegroundColor Green
}

$check4 = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -ErrorAction SilentlyContinue
if ($check4) {
    $runOnceKeys = $check4.PSObject.Properties.Name | Where-Object { $_ -notlike "PS*" }
    if ($runOnceKeys) {
        Write-Host "[X] RunOnce keys present: $($runOnceKeys -join ', ')" -ForegroundColor Yellow
    } else {
        Write-Host "[ ] RunOnce: OK" -ForegroundColor Green
    }
}

$check5 = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\ServicingStorage\ServerManagerCache" -ErrorAction SilentlyContinue
if ($check5 -and $check5.InstallState -eq 1) {
    Write-Host "[X] Server Manager changes pending" -ForegroundColor Yellow
}

$serviceRestart = $false
$services = @("wuauserv", "BITS", "EventLog", "PlugPlay")
foreach ($svc in $services) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Stopped" -and $svc -eq "wuauserv") {
        Write-Host "[!] Windows Update service stopped (may need reboot)" -ForegroundColor Yellow
    }
}

Write-Host ""

if ($rebootPending) {
    Write-Host "RESULT:REBOOT_REQUIRED - System has pending reboot" -ForegroundColor Red
    exit 2
} else {
    Write-Host "RESULT:OK - No pending reboot detected" -ForegroundColor Green
    exit 0
}
