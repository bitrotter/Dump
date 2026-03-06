<#
.SYNOPSIS
    Gets GPU and graphics driver information.

.DESCRIPTION
    Reports graphics card and driver details.

.EXAMPLE
    .\Get-GPUInfo.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== GPU Information ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Graphics Cards:" -ForegroundColor Yellow

$gpu = Get-CimInstance Win32_VideoController

foreach ($card in $gpu) {
    Write-Host "  Name: $($card.Name)" -ForegroundColor White
    Write-Host "    RAM: $([math]::Round($card.AdapterRAM / 1GB, 2)) GB" -ForegroundColor Gray
    
    if ($card.DriverVersion) {
        Write-Host "    Driver: $($card.DriverVersion)" -ForegroundColor Gray
    }
    
    if ($card.DriverDate) {
        Write-Host "    Driver Date: $($card.DriverDate)" -ForegroundColor Gray
    }
    
    if ($card.CurrentRefreshRate) {
        Write-Host "    Refresh Rate: $($card.CurrentRefreshRate) Hz" -ForegroundColor Gray
    }
    
    if ($card.CurrentResolution) {
        Write-Host "    Resolution: $($card.CurrentResolution)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "DirectX Version:" -ForegroundColor Yellow

$dx = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -ErrorAction SilentlyContinue

if ($dx) {
    Write-Host "  Version: $($dx.Version)" -ForegroundColor White
}

Write-Host ""
Write-Host "Display Settings:" -ForegroundColor Yellow

$displays = Get-CimInstance WMI_DesktopMonitor -ErrorAction SilentlyContinue

if ($displays) {
    foreach ($display in $displays) {
        if ($display.Name) {
            Write-Host "  $($display.Name)" -ForegroundColor White
            Write-Host "    Type: $($display.MonitorType)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  No WMI display info" -ForegroundColor Gray
}

Write-Host ""
Write-Host "NVIDIA (if installed):" -ForegroundColor Yellow

$nvidia = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm" -ErrorAction SilentlyContinue

if ($nvidia) {
    Write-Host "  NVIDIA driver installed" -ForegroundColor Green
} else {
    Write-Host "  Not detected" -ForegroundColor Gray
}

Write-Host ""
Write-Host "AMD (if installed):" -ForegroundColor Yellow

$amd = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\atikmdag" -ErrorAction SilentlyContinue

if ($amd) {
    Write-Host "  AMD driver installed" -ForegroundColor Green
} else {
    Write-Host "  Not detected" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - GPU info retrieved" -ForegroundColor Green
exit 0
