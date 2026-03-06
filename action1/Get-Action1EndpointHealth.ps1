<#
.SYNOPSIS
    Checks endpoint health status in Action1 RMM.

.DESCRIPTION
    Shows online/offline status, stale endpoints (no check-in in X days),
    endpoints with agent issues, and overall fleet health metrics.

.PARAMETER OrganizationId
    Action1 Organization ID. Falls back to $env:ACTION1_ORG_ID.

.PARAMETER StaleDays
    Number of days to consider an endpoint as stale. Default: 7.

.PARAMETER OutputFile
    Export results to CSV file.

.EXAMPLE
    .\Get-Action1EndpointHealth.ps1

.EXAMPLE
    .\Get-Action1EndpointHealth.ps1 -StaleDays 14
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OrganizationId = $env:ACTION1_ORG_ID,

    [Parameter(Mandatory=$false)]
    [int]$StaleDays = 7,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
}

function Test-Prerequisites {
    try {
        Import-Module PSAction1 -ErrorAction Stop
    } catch {
        Write-Host "ERROR: PSAction1 module not found." -ForegroundColor Red
        Write-Host "  Install with: Install-Module PSAction1" -ForegroundColor Gray
        exit 1
    }

    if (-not $OrganizationId) {
        Write-Host "ERROR: Organization ID not provided." -ForegroundColor Red
        exit 1
    }

    Set-Action1 -OrganizationID $OrganizationId
}

Test-Prerequisites

Write-Header "Action1 Endpoint Health Check"

Write-Host "Retrieving endpoints..." -ForegroundColor Cyan

$endpoints = Get-Action1 -Query "Endpoints?fields=*"

$now = Get-Date
$healthData = @()

foreach ($ep in $endpoints) {
    $lastSeen = $ep.last_seen
    $minutesAgo = if ($lastSeen) { ($now - $lastSeen).TotalMinutes } else { $null }

    $status = "Unknown"
    $statusColor = "Gray"

    if ($null -eq $minutesAgo) {
        $status = "No Data"
        $statusColor = "Red"
    } elseif ($minutesAgo -lt 30) {
        $status = "Online"
        $statusColor = "Green"
    } elseif ($minutesAgo -lt 60) {
        $status = "Recent"
        $statusColor = "Yellow"
    } elseif ($minutesAgo -lt ($StaleDays * 24 * 60)) {
        $status = "Stale"
        $statusColor = "Red"
    } else {
        $status = "Offline"
        $statusColor = "DarkRed"
    }

    $healthData += [PSCustomObject]@{
        Hostname       = $ep.name
        Status         = $status
        StatusColor    = $statusColor
        LastSeen       = $lastSeen
        LastSeenAgo    = if ($lastSeen) { [math]::Round($minutesAgo, 1) } else { "N/A" }
        AgentVersion   = $ep.agent_version
        OS             = $ep.os_name
        IPAddress      = $ep.ip_address
    }
}

Write-Host "Analyzing $($endpoints.Count) endpoints..." -ForegroundColor Cyan
Write-Host ""

Write-Header "Health Summary"

$online = ($healthData | Where-Object { $_.Status -eq "Online" }).Count
$recent = ($healthData | Where-Object { $_.Status -eq "Recent" }).Count
$stale = ($healthData | Where-Object { $_.Status -eq "Stale" }).Count
$offline = ($healthData | Where-Object { $_.Status -eq "Offline" }).Count
$noData = ($healthData | Where-Object { $_.Status -eq "No Data" }).Count
$total = $healthData.Count

Write-Host "Total Endpoints : $total" -ForegroundColor White
Write-Host "Online (last 30m)   : $online" -ForegroundColor Green
Write-Host "Recent (30m-1h)     : $recent" -ForegroundColor Yellow
Write-Host "Stale ($StaleDays+ days) : $stale" -ForegroundColor Red
Write-Host "Offline             : $offline" -ForegroundColor DarkRed
Write-Host "No Data             : $noData" -ForegroundColor Red
Write-Host ""

$healthPercent = if ($total -gt 0) { [math]::Round(($online / $total) * 100, 1) } else { 0 }
Write-Host "Fleet Health: $healthPercent%" -ForegroundColor $(if ($healthPercent -ge 90) { "Green" } elseif ($healthPercent -ge 70) { "Yellow" } else { "Red" })

Write-Header "Endpoints Requiring Attention"

$attention = $healthData | Where-Object { $_.Status -eq "Stale" -or $_.Status -eq "Offline" -or $_.Status -eq "No Data" }

if ($attention) {
    $attention | Sort-Object LastSeenAgo -Descending | Format-Table -AutoSize Hostname, Status, LastSeenAgo, AgentVersion | Out-String | Write-Host
} else {
    Write-Host "✓ All endpoints are healthy!" -ForegroundColor Green
}

Write-Header "Stale Endpoints (> $StaleDays days)"

$staleEndpoints = $healthData | Where-Object { $_.Status -eq "Stale" }

if ($staleEndpoints) {
    $staleEndpoints | Format-Table -AutoSize Hostname, LastSeen, LastSeenAgo, AgentVersion, OS | Out-String | Write-Host
} else {
    Write-Host "No stale endpoints found" -ForegroundColor Green
}

if ($OutputFile) {
    $healthData | Select-Object Hostname, Status, LastSeen, LastSeenAgo, AgentVersion, OS, IPAddress | Export-Csv -Path $OutputFile -NoTypeInformation
    Write-Host "Exported to: $OutputFile" -ForegroundColor Green
}

Write-Header "Recommendations"

if ($stale -gt 0 -or $offline -gt 0) {
    Write-Host "⚠ $($stale + $offline) endpoints need investigation" -ForegroundColor Yellow
    Write-Host "  - Check network connectivity" -ForegroundColor Gray
    Write-Host "  - Verify Action1 agent service is running" -ForegroundColor Gray
    Write-Host "  - Consider reinstalling agent if offline > 30 days" -ForegroundColor Gray
} else {
    Write-Host "✓ All endpoints are checking in regularly" -ForegroundColor Green
}
