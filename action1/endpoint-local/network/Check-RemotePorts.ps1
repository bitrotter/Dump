<#
.SYNOPSIS
    Checks listening ports and remote connection status.

.DESCRIPTION
    Lists all listening TCP ports and checks connectivity
    to common remote management ports.

.PARAMETER CommonPorts
    Only check common management ports.

.EXAMPLE
    .\Check-RemotePorts.ps1

.EXAMPLE
    .\Check-RemotePorts.ps1 -CommonPorts
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$CommonPorts
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Remote Ports Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$commonPorts = @{
    22 = "SSH"
    23 = "Telnet"
    25 = "SMTP"
    53 = "DNS"
    80 = "HTTP"
    110 = "POP3"
    135 = "RPC"
    139 = "NetBIOS"
    143 = "IMAP"
    443 = "HTTPS"
    445 = "SMB"
    993 = "IMAPS"
    995 = "POP3S"
    1433 = "MSSQL"
    3306 = "MySQL"
    3389 = "RDP"
    5985 = "WinRM HTTP"
    5986 = "WinRM HTTPS"
    8080 = "HTTP Proxy"
    8443 = "HTTPS Alt"
}

Write-Host "Listening Ports:" -ForegroundColor Yellow

$listening = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Select-Object LocalPort, OwningProcess -Unique

$portGroups = $listening | Group-Object LocalPort | Sort-Object Name

foreach ($group in $portGroups) {
    $port = $group.Name
    $process = ($group.Group | Select-Object -First 1).OwningProcess
    
    $processName = (Get-Process -Id $process -ErrorAction SilentlyContinue).ProcessName
    
    $portInfo = $commonPorts[$port]
    $portName = if ($portInfo) { "($portInfo)" } else { "" }
    
    $color = if ($CommonPorts -and $commonPorts[$port]) { "White" } else { "Gray" }
    
    if (-not $CommonPorts -or $commonPorts[$port]) {
        Write-Host "  $port $portName - $processName" -ForegroundColor $color
    }
}

Write-Host ""
Write-Host "Open Remote Connections:" -ForegroundColor Yellow

$established = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue

$remoteConn = $established | Select-Object RemoteAddress, RemotePort -Unique | Where-Object { $_.RemoteAddress -notlike "127.*" -and $_.RemoteAddress -notlike "::*" }

$uniqueRemotes = $remoteConn | Group-Object RemoteAddress | Sort-Object Count -Descending | Select-Object -First 10

foreach ($remote in $uniqueRemotes) {
    $remoteIP = $remote.Name
    $count = $remote.Count
    
    try {
        $hostname = [System.Net.Dns]::GetHostEntry($remoteIP).HostName
    } catch {
        $hostname = $remoteIP
    }
    
    Write-Host "  $hostname ($remoteIP): $count connections" -ForegroundColor White
}

Write-Host ""
Write-Host "Firewall Status:" -ForegroundColor Yellow

$firewall = Get-NetFirewallProfile

foreach ($profile in $firewall) {
    $color = if ($profile.Enabled) { "Green" } else { "Red" }
    Write-Host "  $($profile.Name): $($profile.Enabled)" -ForegroundColor $color
}

Write-Host ""

$listeningCount = ($listening | Measure-Object).Count

Write-Host "RESULT:OK - Found $listeningCount listening ports" -ForegroundColor Green
exit 0
