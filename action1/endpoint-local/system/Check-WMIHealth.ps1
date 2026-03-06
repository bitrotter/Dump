<#
.SYNOPSIS
    Checks WMI repository health.

.DESCRIPTION
    Tests WMI functionality and reports any issues.

.PARAMETER Fix
    Attempt to rebuild WMI repository if broken.

.EXAMPLE
    .\Check-WMIHealth.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Fix
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== WMI Health Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Testing WMI Classes:" -ForegroundColor Yellow

$tests = @(
    @{ Name = "Win32_OperatingSystem"; Class = "Win32_OperatingSystem" },
    @{ Name = "Win32_ComputerSystem"; Class = "Win32_ComputerSystem" },
    @{ Name = "Win32_Processor"; Class = "Win32_Processor" },
    @{ Name = "Win32_DiskDrive"; Class = "Win32_DiskDrive" },
    @{ Name = "Win32_NetworkAdapter"; Class = "Win32_NetworkAdapter" }
)

$failed = @()

foreach ($test in $tests) {
    try {
        $result = Get-CimInstance -ClassName $test.Class -ErrorAction Stop
        Write-Host "  $($test.Name): OK" -ForegroundColor Green
    } catch {
        Write-Host "  $($test.Name): FAILED" -ForegroundColor Red
        $failed += $test.Name
    }
}

Write-Host ""
Write-Host "WMI Service Status:" -ForegroundColor Yellow

$winmgmt = Get-Service -Name winmgmt
Write-Host "  Service: $($winmgmt.Status)" -ForegroundColor $(if ($winmgmt.Status -eq "Running") { "Green" } else { "Red" })

Write-Host ""
Write-Host "Repository Size:" -ForegroundColor Yellow

$repoPath = "$env:WINDIR\System32\Wbem\Repository"

if (Test-Path $repoPath) {
    $repoSize = (Get-ChildItem $repoPath -Recurse | Measure-Object Length -Sum).Sum
    $repoSizeMB = [math]::Round($repoSize / 1MB, 2)
    Write-Host "  Size: $repoSizeMB MB" -ForegroundColor White
}

Write-Host ""

if ($failed.Count -gt 0) {
    Write-Host "RESULT:CRITICAL - $($failed.Count) WMI classes failed" -ForegroundColor Red
    exit 2
} elseif ($winmgmt.Status -ne "Running") {
    Write-Host "RESULT:CRITICAL - WMI service not running" -ForegroundColor Red
    exit 2
} else {
    Write-Host "RESULT:OK - WMI healthy" -ForegroundColor Green
    exit 0
}
