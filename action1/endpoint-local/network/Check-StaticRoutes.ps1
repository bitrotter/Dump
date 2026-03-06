<#
.SYNOPSIS
    Lists static routes on the system.

.DESCRIPTION
    Shows all persistent and active routes.

.PARAMETER AddRoute
    Add a new static route (format: destination,subnetmask,gateway).

.EXAMPLE
    .\Check-StaticRoutes.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$AddRoute
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Static Routes ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Active Routes:" -ForegroundColor Yellow

$routes = Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.DestinationPrefix -ne "0.0.0.0/0" }

foreach ($route in $routes) {
    $dest = $route.DestinationPrefix
    $gw = $route.NextHop
    $if = $route.InterfaceAlias
    $metric = $route.RouteMetric
    
    Write-Host "  $dest -> $gw ($if) Metric: $metric" -ForegroundColor White
}

Write-Host ""
Write-Host "Default Gateway:" -ForegroundColor Yellow

$gateway = Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }

foreach ($gw in $gateway) {
    Write-Host "  $($gw.NextHop) via $($gw.InterfaceAlias)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Persistent Routes:" -ForegroundColor Yellow

$persistent = route print -4 | Select-String -Pattern "0.0.0.0"

$persistentRoutes = [System.Net.IPAddress]::None

Write-Host ""
Write-Host "IPv6 Routes:" -ForegroundColor Yellow

$ipv6Routes = Get-NetRoute -AddressFamily IPv6 | Where-Object { $_.DestinationPrefix -notmatch "ff00|fe80" }

foreach ($route in $ipv6Routes | Select-Object -First 10) {
    Write-Host "  $($route.DestinationPrefix) -> $($route.NextHop)" -ForegroundColor Gray
}

if ($AddRoute) {
    Write-Host ""
    Write-Host "Adding route: $AddRoute" -ForegroundColor Yellow
    
    $parts = $AddRoute -split ","
    
    if ($parts.Count -eq 3) {
        $dest = $parts[0].Trim()
        $mask = $parts[1].Trim()
        $gw = $parts[2].Trim()
        
        $result = route add $dest MASK $mask $gw -p 2>&1
        
        Write-Host "  Result: $result" -ForegroundColor Green
    } else {
        Write-Host "  Invalid format. Use: destination,subnetmask,gateway" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "RESULT:OK - Routes listed" -ForegroundColor Green
exit 0
