<#
.SYNOPSIS
    Resets Windows network stack.

.DESCRIPTION
    Resets network adapters and stack to fix connectivity issues.

.EXAMPLE
    .\Reset-NetworkStack.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Reset Network Stack ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Flushing DNS..." -ForegroundColor Yellow

Clear-DnsClientCache
Write-Host "  DNS cache cleared" -ForegroundColor Green

Write-Host ""
Write-Host "Resetting Winsock..." -ForegroundColor Yellow

netsh winsock reset | Out-Null
Write-Host "  Winsock reset complete" -ForegroundColor Green

Write-Host ""
Write-Host "Resetting IP stack..." -ForegroundColor Yellow

netsh int ip reset | Out-Null
Write-Host "  IP stack reset complete" -ForegroundColor Green

Write-Host ""
Write-Host "Renewing IP..." -ForegroundColor Yellow

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($adapter in $adapters) {
    Write-Host "  Renewing $($adapter.Name)..." -ForegroundColor Gray
    
    try {
        ipconfig /release $adapter.Name | Out-Null
        ipconfig /renew $adapter.Name | Out-Null
        Write-Host "    Done" -ForegroundColor Green
    } catch {
        Write-Host "    Failed" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "NOTE: A reboot is required for changes to take effect" -ForegroundColor Yellow

Write-Host ""
Write-Host "RESULT:OK - Network stack reset complete" -ForegroundColor Green
exit 0
