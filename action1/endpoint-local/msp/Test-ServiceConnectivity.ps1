<#
.SYNOPSIS
    Tests connectivity to common services.

.DESCRIPTION
    Pings and tests ports for common services.

.PARAMETER TestRDP
    Test RDP port.

.PARAMETER TestWinRM
    Test WinRM ports.

.EXAMPLE
    .\Test-ServiceConnectivity.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$TestRDP,

    [Parameter(Mandatory=$false)]
    [switch]$TestWinRM
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Service Connectivity Test ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Local Services:" -ForegroundColor Yellow

$services = @{
    "Windows Update" = "wuauserv"
    "BITS" = "BITS"
    "Windows Defender" = "WinDefend"
    "Windows Firewall" = "MpsSvc"
    "Remote Registry" = "RemoteRegistry"
    "Print Spooler" = "Spooler"
    "Windows Time" = "W32Time"
    "DNS Client" = "Dnscache"
}

foreach ($service in $services.GetEnumerator()) {
    $svc = Get-Service -Name $service.Value -ErrorAction SilentlyContinue
    if ($svc) {
        $status = $svc.Status
        $color = if ($status -eq "Running") { "Green" } else { "Red" }
        Write-Host "  $($service.Key): $status" -ForegroundColor $color
    }
}

Write-Host ""
Write-Host "Listening Ports:" -ForegroundColor Yellow

$ports = @(135, 445, 3389, 5985, 5986, 80, 443)

foreach ($port in $ports) {
    $listener = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    
    if ($listener) {
        $process = (Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        Write-Host "  Port $port : $process" -ForegroundColor Green
    } else {
        Write-Host "  Port $port : Not listening" -ForegroundColor Gray
    }
}

if ($TestRDP) {
    Write-Host ""
    Write-Host "RDP Test:" -ForegroundColor Yellow
    
    $rdp = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections"
    
    if ($rdp.fDenyTSConnections -eq 0) {
        Write-Host "  RDP: Enabled" -ForegroundColor Green
    } else {
        Write-Host "  RDP: Disabled" -ForegroundColor Red
    }
}

if ($TestWinRM) {
    Write-Host ""
    Write-Host "WinRM Test:" -ForegroundColor Yellow
    
    $winrm = Get-Service -Name WinRM -ErrorAction SilentlyContinue
    
    if ($winrm -and $winrm.Status -eq "Running") {
        Write-Host "  WinRM: Running" -ForegroundColor Green
        
        try {
            $result = Test-WSMan -ErrorAction SilentlyContinue
            if ($result) {
                Write-Host "  WinRM: Configured" -ForegroundColor Green
            }
        } catch {
            Write-Host "  WinRM: Not configured" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  WinRM: Not running" -ForegroundColor Red
    }
}

Write-Host ""

$stopped = ($services.Values | ForEach-Object { Get-Service -Name $_ -ErrorAction SilentlyContinue } | Where-Object { $_.Status -ne "Running" }).Count

if ($stopped -gt 0) {
    Write-Host "RESULT:WARNING - $stopped service(s) not running" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Services OK" -ForegroundColor Green
    exit 0
}
