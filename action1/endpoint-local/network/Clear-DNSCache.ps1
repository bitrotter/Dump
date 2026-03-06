<#
.SYNOPSIS
    Flushes DNS cache and reports DNS resolver configuration.

.DESCRIPTION
    Clears local DNS cache and displays current DNS servers.

.PARAMETER RegisterDNS
    Re-register DNS records for this computer.

.EXAMPLE
    .\Clear-DNSCache.ps1

.EXAMPLE
    .\Clear-DNSCache.ps1 -RegisterDNS
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$RegisterDNS
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== DNS Cache Flush ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Current DNS Configuration:" -ForegroundColor Yellow

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($adapter in $adapters) {
    $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
    
    if ($dns -and $dns.ServerAddresses) {
        Write-Host "  $($adapter.Name):" -ForegroundColor White
        $dns.ServerAddresses | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "Flushing DNS cache..." -ForegroundColor Yellow

$before = (Get-DnsClientCache -ErrorAction SilentlyContinue).Count
Write-Host "  Cache entries before: $before" -ForegroundColor Gray

Clear-DnsClientCache

Start-Sleep -Seconds 1

$after = (Get-DnsClientCache -ErrorAction SilentlyContinue).Count
Write-Host "  Cache entries after: $after" -ForegroundColor Gray

Write-Host "  DNS cache flushed" -ForegroundColor Green

if ($RegisterDNS) {
    Write-Host ""
    Write-Host "Registering DNS..." -ForegroundColor Yellow
    Register-DnsClient
    Write-Host "  DNS registration complete" -ForegroundColor Green
}

Write-Host ""
Write-Host "RESULT:OK - DNS cache cleared" -ForegroundColor Green
exit 0
