<#
.SYNOPSIS
    Lists mapped network drives.

.DESCRIPTION
    Shows all mapped network drives and their status.

.PARAMETER Refresh
    Attempt to reconnect disconnected drives.

.EXAMPLE
    .\Check-MappedDrives.ps1

.EXAMPLE
    .\Check-MappedDrives.ps1 -Refresh
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Refresh
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Mapped Network Drives ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$mapped = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like "\\*" }

Write-Host "Mapped Drives:" -ForegroundColor Yellow

if ($mapped) {
    foreach ($drive in $mapped) {
        $connected = Test-Path "$($drive.Name):\"
        $status = if ($connected) { "Connected" } else { "Disconnected" }
        $color = if ($connected) { "Green" } else { "Red" }
        
        Write-Host "  $($drive.Name): -> $($drive.DisplayRoot)" -ForegroundColor White
        Write-Host "    Status: $status" -ForegroundColor $color
    }
} else {
    Write-Host "  No mapped drives found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Available Network Shares:" -ForegroundColor Yellow

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($adapter in $adapters) {
    $ipConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex
    
    if ($ipConfig.IPv4DefaultGateway) {
        $gateway = $ipConfig.IPv4DefaultGateway.NextHop
        
        try {
            $shares = Get-SmbShare -Special $false -ErrorAction SilentlyContinue
            
            foreach ($share in $shares) {
                Write-Host "  \\$env:COMPUTERNAME\$($share.Name)" -ForegroundColor Gray
            }
        } catch { }
    }
}

if ($Refresh) {
    Write-Host ""
    Write-Host "Attempting to reconnect..." -ForegroundColor Yellow
    
    foreach ($drive in $mapped) {
        $connected = Test-Path "$($drive.Name):\"
        
        if (-not $connected) {
            try {
                $unc = $drive.DisplayRoot
                New-PSDrive -Name $drive.Name -PSProvider FileSystem -Root $unc -Persist | Out-Null
                Write-Host "  Reconnected $($drive.Name):" -ForegroundColor Green
            } catch {
                Write-Host "  Failed to reconnect $($drive.Name):" -ForegroundColor Red
            }
        }
    }
}

Write-Host ""

$disconnected = ($mapped | Where-Object { -not (Test-Path "$($_.Name):\") }).Count

if ($disconnected -gt 0) {
    Write-Host "RESULT:WARNING - $disconnected drive(s) disconnected" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - All drives connected" -ForegroundColor Green
    exit 0
}
