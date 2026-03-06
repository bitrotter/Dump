<#
.SYNOPSIS
    Gets detailed mapped drive information.

.DESCRIPTION
    Lists all mapped network drives with status and credentials.

.PARAMETER Refresh
    Attempt to reconnect disconnected drives.

.PARAMETER Export
    Export mapped drives to CSV.

.EXAMPLE
    .\Get-MappedDrives.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Refresh,

    [Parameter(Mandatory=$false)]
    [switch]$Export
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Mapped Drives ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Mapped Network Drives:" -ForegroundColor Yellow

$mapped = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like "\\*" }

if ($mapped) {
    $driveList = @()
    
    foreach ($drive in $mapped) {
        $letter = "$($drive.Name):"
        $unc = $drive.DisplayRoot
        $connected = Test-Path "$letter\"
        
        $status = if ($connected) { "Connected" } else { "Disconnected" }
        $color = if ($connected) { "Green" } else { "Red" }
        
        Write-Host ""
        Write-Host "Drive $letter" -ForegroundColor White
        Write-Host "  Path: $unc" -ForegroundColor Gray
        Write-Host "  Status: $status" -ForegroundColor $color
        
        try {
            $testPath = Get-ChildItem $letter -ErrorAction SilentlyContinue
            Write-Host "  Accessible: Yes" -ForegroundColor Green
        } catch {
            Write-Host "  Accessible: No" -ForegroundColor Red
        }
        
        $driveList += [PSCustomObject]@{
            DriveLetter = $letter
            UNCPath = $unc
            Status = $status
            Connected = $connected
        }
    }
} else {
    Write-Host "  No mapped drives found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Persistent Connections:" -ForegroundColor Yellow

$persistent = Get-ItemProperty -Path "HKCU:\Network" -ErrorAction SilentlyContinue

if ($persistent) {
    $persistent.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
        $drive = $_.Name
        $target = $_.Value.RemotePath
        
        Write-Host "  $drive -> $target" -ForegroundColor White
    }
} else {
    Write-Host "  No persistent connections" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Available Network Shares:" -ForegroundColor Yellow

$computer = $env:COMPUTERNAME

try {
    $shares = Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*$" }
    
    foreach ($share in $shares) {
        Write-Host "  \\$computer\$($share.Name)" -ForegroundColor Green
    }
} catch {
    Write-Host "  Could not enumerate shares" -ForegroundColor Gray
}

if ($Refresh) {
    Write-Host ""
    Write-Host "Reconnecting drives..." -ForegroundColor Yellow
    
    foreach ($drive in $mapped) {
        if (-not (Test-Path "$($drive.Name):\")) {
            try {
                $unc = $drive.DisplayRoot
                New-PSDrive -Name $drive.Name -PSProvider FileSystem -Root $unc -Persist | Out-Null
                Write-Host "  Reconnected $($drive.Name):" -ForegroundColor Green
            } catch {
                Write-Host "  Failed: $($drive.Name):" -ForegroundColor Red
            }
        }
    }
}

if ($Export -and $driveList) {
    $csvPath = "$env:TEMP\MappedDrives_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $driveList | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host ""
    Write-Host "Exported to: $csvPath" -ForegroundColor Green
}

Write-Host ""

$disconnected = ($mapped | Where-Object { -not (Test-Path "$($_.Name):\") }).Count

if ($disconnected -gt 0) {
    Write-Host "RESULT:WARNING - $disconnected disconnected" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - All drives connected" -ForegroundColor Green
    exit 0
}
