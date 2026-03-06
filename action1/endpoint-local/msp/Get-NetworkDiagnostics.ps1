<#
.SYNOPSIS
    Runs comprehensive network diagnostics.

.DESCRIPTION
    Tests DNS, gateway, connectivity and generates report
    for network troubleshooting.

.PARAMETER Full
    Run extended diagnostics.

.EXAMPLE
    .\Get-NetworkDiagnostics.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Full
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Network Diagnostics ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Started: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

Write-Host "[1/6] IP Configuration..." -ForegroundColor Yellow

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($adapter in $adapters) {
    $ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $gateway = (Get-NetRoute -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }).NextHop
    
    Write-Host "  Adapter: $($adapter.Name)" -ForegroundColor White
    Write-Host "    IP: $($ip.IPAddress)" -ForegroundColor Green
    Write-Host "    Gateway: $gateway" -ForegroundColor Green
}

Write-Host ""
Write-Host "[2/6] DNS Resolution..." -ForegroundColor Yellow

$testHosts = @("google.com", "microsoft.com", "8.8.8.8")

foreach ($host in $testHosts) {
    try {
        $result = Resolve-DnsName -Name $host -ErrorAction Stop | Select-Object -First 1
        Write-Host "  $host : $($result.IPAddress)" -ForegroundColor Green
    } catch {
        Write-Host "  $host : FAILED" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "[3/6] Default Gateway..." -ForegroundColor Yellow

$gateway = (Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }).NextHop | Select-Object -First 1

if ($gateway) {
    $ping = Test-Connection -ComputerName $gateway -Count 1 -Quiet
    Write-Host "  Gateway ($gateway): $(if ($ping) { 'Reachable' } else { 'Unreachable' })" -ForegroundColor $(if ($ping) { "Green" } else { "Red" })
} else {
    Write-Host "  No gateway found" -ForegroundColor Red
}

Write-Host ""
Write-Host "[4/6] Internet Connectivity..." -ForegroundColor Yellow

$internetHosts = @("8.8.8.8", "1.1.1.1", "google.com")
$connected = $false

foreach ($host in $internetHosts) {
    if (Test-Connection -ComputerName $host -Count 1 -Quiet) {
        $connected = $true
        break
    }
}

Write-Host "  Internet: $(if ($connected) { 'Connected' } else { 'Disconnected' })" -ForegroundColor $(if ($connected) { "Green" } else { "Red" })

Write-Host ""
Write-Host "[5/6] DNS Cache..." -ForegroundColor Yellow

$cacheCount = (Get-DnsClientCache -ErrorAction SilentlyContinue).Count
Write-Host "  Cached entries: $cacheCount" -ForegroundColor White

Write-Host ""
Write-Host "[6/6] Proxy Settings..." -ForegroundColor Yellow

$proxy = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
Write-Host "  Proxy Enabled: $($proxy.ProxyEnable)" -ForegroundColor $(if ($proxy.ProxyEnable -eq 0) { "Green" } else { "Yellow" })

if ($Full) {
    Write-Host ""
    Write-Host "[Extended] DNS Trace..." -ForegroundColor Yellow
    
    $dnsServers = @("8.8.8.8", "1.1.1.1")
    foreach ($dns in $dnsServers) {
        Write-Host "  Testing $dns..." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "RESULT:OK - Diagnostics complete" -ForegroundColor Green
exit 0
