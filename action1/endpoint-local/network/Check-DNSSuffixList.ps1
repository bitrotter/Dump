<#
.SYNOPSIS
    Checks DNS suffix list and connection-specific DNS.

.DESCRIPTION
    Reports DNS suffixes configured on network adapters.

.EXAMPLE
    .\Check-DNSSuffixList.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== DNS Suffix List ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "DNS Suffix Search List:" -ForegroundColor Yellow

$dnsSuffix = [System.Net.Dns]::GetHostEntry([String]::Empty).HostName

Write-Host "  Primary DNS Suffix: $dnsSuffix" -ForegroundColor White

$adapterSuffixes = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
    $ipConfig = Get-NetIPConfiguration -InterfaceIndex $_.ifIndex -ErrorAction SilentlyContinue
    
    if ($ipConfig.IPv4Settings.DNSServer) {
        $suffix = $ipConfig.IPv4Settings.DNSServer.ConnectionSpecificSuffix
        if ($suffix) { $suffix }
    }
}

$uniqueSuffixes = $adapterSuffixes | Sort-Object -Unique

Write-Host ""
Write-Host "Connection-Specific Suffixes:" -ForegroundColor Yellow

if ($uniqueSuffixes) {
    foreach ($suffix in $uniqueSuffixes) {
        Write-Host "  $suffix" -ForegroundColor Green
    }
} else {
    Write-Host "  None configured" -ForegroundColor Gray
}

Write-Host ""
Write-Host "DNS Suffix Search List (Registry):" -ForegroundColor Yellow

$dnsSearchPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"

$searchList = (Get-ItemProperty -Path $dnsSearchPath -Name "SearchList" -ErrorAction SilentlyContinue).SearchList

if ($searchList) {
    $searchList -split "," | ForEach-Object {
        Write-Host "  $_" -ForegroundColor White
    }
} else {
    Write-Host "  Using default (domain-based)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Adapter DNS Configuration:" -ForegroundColor Yellow

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($adapter in $adapters) {
    $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue | Where-Object { $_.AddressFamily -eq 2 }
    
    Write-Host ""
    Write-Host "  $($adapter.Name):" -ForegroundColor Cyan
    
    if ($dns.ServerAddresses) {
        Write-Host "    DNS Servers: $($dns.ServerAddresses -join ', ')" -ForegroundColor White
    } else {
        Write-Host "    DNS Servers: Not configured" -ForegroundColor Gray
    }
    
    $suffix = Get-NetAdapterAdvancedProperty -InterfaceIndex $adapter.ifIndex -RegistryKeyword "DnsSuffix" -ErrorAction SilentlyContinue
    if ($suffix) {
        Write-Host "    DNS Suffix: $($suffix.RegistryValue)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "RESULT:OK - DNS configuration checked" -ForegroundColor Green
exit 0
