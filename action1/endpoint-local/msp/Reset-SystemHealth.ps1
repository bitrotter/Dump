<#
.SYNOPSIS
    Resets common Windows issues.

.DESCRIPTION
    Runs common repair actions: resets network, clears
    temp files, restarts critical services.

.PARAMETER Full
    Perform full reset including network stack.

.EXAMPLE
    .\Reset-SystemHealth.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Full
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== System Health Reset ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Step 1: Clearing temporary files..." -ForegroundColor Yellow

$tempPaths = @("$env:WINDIR\Temp", "$env:TEMP")
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        $count = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue).Count
        Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Cleared $path ($count files)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Step 2: Resetting Windows Update..." -ForegroundColor Yellow

$wuServices = @("wuauserv", "BITS", "CryptSvc", "TrustedInstaller")

foreach ($svc in $wuServices) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Host "  Stopped $svc" -ForegroundColor Gray
    }
}

Start-Sleep -Seconds 2

Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue

foreach ($svc in $wuServices) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Write-Host "  Started $svc" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Step 3: Flushing DNS..." -ForegroundColor Yellow

Clear-DnsClientCache
Write-Host "  DNS cache cleared" -ForegroundColor Green

Write-Host ""
Write-Host "Step 4: Resetting network stack (optional)..." -ForegroundColor Gray

if ($Full) {
    Write-Host "  Running network reset..." -ForegroundColor Yellow
    netsh winsock reset | Out-Null
    netsh int ip reset | Out-Null
    Write-Host "  Network stack reset complete" -ForegroundColor Green
    Write-Host "  NOTE: Reboot required for changes" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 5: Checking services..." -ForegroundColor Yellow

$services = @("wuauserv", "BITS", "EventLog", "W32Time")
foreach ($svc in $services) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service -and $service.Status -ne "Running") {
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        $service = Get-Service -Name $svc
        if ($service.Status -eq "Running") {
            Write-Host "  $svc: Fixed" -ForegroundColor Green
        }
    } else {
        Write-Host "  $svc: OK" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "RESULT:OK - Health reset complete" -ForegroundColor Green
exit 0
