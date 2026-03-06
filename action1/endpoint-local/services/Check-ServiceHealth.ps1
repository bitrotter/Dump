<#
.SYNOPSIS
    Checks health of critical Windows services.

.DESCRIPTION
    Checks status of important Windows services and reports any that are stopped.
    Can optionally auto-start stopped services.

.PARAMETER ServiceNames
    Comma-separated list of services to check. Defaults to common critical services.

.PARAMETER AutoStart
    Attempt to start any stopped services automatically.

.EXAMPLE
    .\Check-ServiceHealth.ps1

.EXAMPLE
    .\Check-ServiceHealth.ps1 -AutoStart
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceNames = "wuauserv,Spooler,EventLog,W32Time,DNSCache,Netlogon,PlugPlay,BITS",

    [Parameter(Mandatory=$false)]
    [switch]$AutoStart
)

$ErrorActionPreference = 'SilentlyContinue'

$services = $ServiceNames -split ","

Write-Host "=== Service Health Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$results = @()
$stopped = @()

foreach ($svcName in $services) {
    $svcName = $svcName.Trim()
    $service = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    
    if ($service) {
        $status = if ($service.Status -eq "Running") { "Running" } else { "Stopped" }
        $color = if ($service.Status -eq "Running") { "Green" } else { "Red" }
        
        if ($service.Status -ne "Running") {
            $stopped += $svcName
            
            if ($AutoStart) {
                Write-Host "Starting $svcName..." -ForegroundColor Yellow
                Start-Service -Name $svcName -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 1
                
                $service = Get-Service -Name $svcName
                if ($service.Status -eq "Running") {
                    $status = "Running (Started)"
                    $color = "Green"
                } else {
                    $status = "Stopped (Failed to start)"
                }
            }
        }
        
        $results += [PSCustomObject]@{
            Service     = $svcName
            DisplayName = $service.DisplayName
            Status     = $status
        }
    } else {
        $results += [PSCustomObject]@{
            Service     = $svcName
            DisplayName = "Not Found"
            Status     = "Not Found"
        }
    }
}

$results | Format-Table -AutoSize | Out-String | Write-Host

Write-Host ""

if ($stopped.Count -gt 0) {
    if ($AutoStart) {
        Write-Host "RESULT:WARNING - $($stopped.Count) service(s) required restart: $($stopped -join ', ')" -ForegroundColor Yellow
    } else {
        Write-Host "RESULT:WARNING - $($stopped.Count) service(s) are stopped: $($stopped -join ', ')" -ForegroundColor Yellow
    }
    exit 1
} else {
    Write-Host "RESULT:OK - All critical services running" -ForegroundColor Green
    exit 0
}
