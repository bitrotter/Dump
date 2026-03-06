<#
.SYNOPSIS
    Checks network adapter status and connectivity.

.DESCRIPTION
    Reports all network adapters, their status, IP addresses,
    and connectivity.

.PARAMETER ShowDetails
    Show detailed adapter information.

.EXAMPLE
    .\Check-NetworkAdapterStatus.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Network Adapter Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$adapters = Get-NetAdapter | Sort-Object Status

Write-Host "Adapters:" -ForegroundColor Yellow

$upCount = 0
$downCount = 0

foreach ($adapter in $adapters) {
    $statusColor = if ($adapter.Status -eq "Up") { "Green" } else { "Red" }
    
    if ($adapter.Status -eq "Up") { $upCount++ } else { $downCount++ }
    
    Write-Host ""
    Write-Host "  $($adapter.Name)" -ForegroundColor White
    Write-Host "    Status: $($adapter.Status)" -ForegroundColor $statusColor
    Write-Host "    Type: $($adapter.InterfaceDescription)" -ForegroundColor Gray
    Write-Host "    MAC: $($adapter.MacAddress)" -ForegroundColor Gray
    
    if ($adapter.Status -eq "Up") {
        $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue | Where-Object { $_.AddressFamily -eq "IPv4" }
        
        if ($ipConfig) {
            Write-Host "    IPv4: $($ipConfig.IPAddress)" -ForegroundColor Green
            Write-Host "    Prefix: $($ipConfig.PrefixLength)" -ForegroundColor Gray
        }
        
        $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue | Where-Object { $_.AddressFamily -eq 2 }
        
        if ($dns.ServerAddresses) {
            Write-Host "    DNS: $($dns.ServerAddresses -join ', ')" -ForegroundColor Gray
        }
        
        if ($ShowDetails) {
            $stats = Get-NetAdapterStatistics -Name $adapter.Name -ErrorAction SilentlyContinue
            if ($stats) {
                Write-Host "    Sent: $([math]::Round($stats.SentBytes/1MB, 2)) MB" -ForegroundColor Gray
                Write-Host "    Received: $([math]::Round($stats.ReceivedBytes/1MB, 2)) MB" -ForegroundColor Gray
            }
        }
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Total Adapters: $($adapters.Count)" -ForegroundColor White
Write-Host "  Up: $upCount" -ForegroundColor Green
Write-Host "  Down: $downCount" -ForegroundColor Red

Write-Host ""
Write-Host "Connectivity Test:" -ForegroundColor Yellow

$testHosts = @("8.8.8.8", "1.1.1.1", "microsoft.com")
$connected = $false

foreach ($host in $testHosts) {
    $ping = Test-Connection -ComputerName $host -Count 1 -Quiet -ErrorAction SilentlyContinue
    
    if ($ping) {
        Write-Host "  $host : OK" -ForegroundColor Green
        $connected = $true
        break
    }
}

if (-not $connected) {
    Write-Host "  Internet connectivity: FAILED" -ForegroundColor Red
}

Write-Host ""

if ($downCount -gt 0) {
    Write-Host "RESULT:WARNING - $($downCount) adapter(s) down" -ForegroundColor Yellow
    exit 1
} elseif (-not $connected) {
    Write-Host "RESULT:WARNING - No internet connectivity" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - All adapters operational" -ForegroundColor Green
    exit 0
}
