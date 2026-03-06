<#
.SYNOPSIS
    Lists installed software on the system.

.DESCRIPTION
    Reports installed software from registry and can check
    for specific applications.

.PARAMETER Search
    Search for specific software by name.

.PARAMETER Outdated
    Show potentially outdated software (older than 1 year).

.PARAMETER Top
    Number of software items to show. Default: 50.

.EXAMPLE
    .\Check-InstalledSoftware.ps1

.EXAMPLE
    .\Check-InstalledSoftware.ps1 -Search "Java"

.EXAMPLE
    .\Check-InstalledSoftware.ps1 -Outdated
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Search,

    [Parameter(Mandatory=$false)]
    [switch]$Outdated,

    [Parameter(Mandatory=$false)]
    [int]$Top = 50
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Installed Software ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$software = @()

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $regPaths) {
    $items = Get-ItemProperty $path -ErrorAction SilentlyContinue
    
    foreach ($item in $items) {
        if ($item.DisplayName) {
            $installDate = $null
            
            if ($item.InstallDate) {
                try {
                    $installDate = [datetime]::ParseExact($item.InstallDate, "yyyyMMdd", $null)
                } catch { }
            }
            
            $software += [PSCustomObject]@{
                Name        = $item.DisplayName
                Version     = $item.DisplayVersion
                Publisher   = $item.Publisher
                InstallDate = $installDate
                InstallLocation = $item.InstallLocation
                EstimatedSize = if ($item.EstimatedSize) { [math]::Round($item.EstimatedSize/1024, 2) } else { $null }
            }
        }
    }
}

$software = $software | Sort-Object Name -Unique

if ($Search) {
    Write-Host "Searching for: $Search" -ForegroundColor Gray
    $software = $software | Where-Object { $_.Name -match $Search }
}

if ($Outdated) {
    $oneYearAgo = (Get-Date).AddYears(-1)
    $software = $software | Where-Object { $_.InstallDate -and $_.InstallDate -lt $oneYearAgo }
    Write-Host "Showing software older than 1 year" -ForegroundColor Gray
}

$total = ($software | Measure-Object).Count

Write-Host ""
Write-Host "Found: $total items" -ForegroundColor White
Write-Host "Showing top $Top" -ForegroundColor Gray
Write-Host ""

$software | Select-Object -First $Top | ForEach-Object {
    $sizeStr = if ($_.EstimatedSize) { "$($_.EstimatedSize) GB" } else { "" }
    
    if ($_.InstallDate) {
        $age = (Get-Date) - $_.InstallDate
        $ageStr = "($([int]$age.TotalDays) days old)"
    } else {
        $ageStr = ""
    }
    
    Write-Host "$($_.Name)" -ForegroundColor Green
    if ($_.Version) { Write-Host "  Version: $($_.Version)" -ForegroundColor White }
    if ($_.Publisher) { Write-Host "  Publisher: $($_.Publisher)" -ForegroundColor Gray }
    if ($ageStr) { Write-Host "  $ageStr" -ForegroundColor Gray }
    if ($sizeStr) { Write-Host "  Size: $sizeStr" -ForegroundColor Gray }
    Write-Host ""
}

Write-Host "RESULT:OK - Found $total software items" -ForegroundColor Green
exit 0
