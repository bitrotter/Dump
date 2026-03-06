<#
.SYNOPSIS
    Retrieves endpoint inventory from Action1 RMM.

.DESCRIPTION
    Lists all endpoints with OS version, last check-in time, patch status,
    and online/offline status. Supports filtering by group and export to CSV.

.PARAMETER OrganizationId
    Action1 Organization ID. Falls back to $env:ACTION1_ORG_ID.

.PARAMETER GroupName
    Filter by endpoint group name.

.PARAMETER OutputFile
    Export results to CSV file.

.PARAMETER ShowOffline
    Include offline endpoints in the report.

.EXAMPLE
    .\Get-Action1EndpointInventory.ps1

.EXAMPLE
    .\Get-Action1EndpointInventory.ps1 -GroupName "Servers" -OutputFile "inventory.csv"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OrganizationId = $env:ACTION1_ORG_ID,

    [Parameter(Mandatory=$false)]
    [string]$GroupName,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile,

    [Parameter(Mandatory=$false)]
    [switch]$ShowOffline
)

$colors = @{
    'Online'    = 'Green'
    'Offline'    = 'Red'
    'Warning'   = 'Yellow'
    'Info'      = 'Cyan'
    'Muted'     = 'Gray'
}

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
        Write-Host "  Set ACTION1_ORG_ID environment variable or pass -OrganizationId" -ForegroundColor Gray
        exit 1
    }

    Set-Action1 -OrganizationID $OrganizationId
}

function Get-EndpointGroupId {
    param([string]$Name)
    $groups = Get-Action1 -Query "EndpointGroups" | Where-Object { $_.name -eq $Name }
    if ($groups) {
        return $groups.id
    }
    return $null
}

function Get-EndpointInventory {
    param([string]$GroupId)

    $endpoints = @()
    $page = 0
    $pageSize = 100

    do {
        $query = "Endpoints?from=$($page * $pageSize)&limit=$pageSize"
        if ($GroupId) {
            $query = "EndpointGroupMembers/$GroupId/endpoints?from=$($page * $pageSize)&limit=$pageSize"
        }

        $result = Get-Action1 -Query $query
        if ($result -and $result.items) {
            $endpoints += $result.items
            $page++
        } else {
            break
        }
    } while ($endpoints.Count -lt $result.total)

    return $endpoints
}

function Get-EndpointDetails {
    param([string]$EndpointId)

    $endpoint = Get-Action1 -Query "Endpoints/$EndpointId?fields=*"
    return $endpoint
}

Test-Prerequisites

Write-Header "Action1 Endpoint Inventory"

$groupId = $null
if ($GroupName) {
    $groupId = Get-EndpointGroupId -Name $GroupName
    if (-not $groupId) {
        Write-Host "ERROR: Endpoint group '$GroupName' not found." -ForegroundColor Red
        exit 1
    }
    Write-Host "Filtering by group: $GroupName" -ForegroundColor Yellow
}

Write-Host "Retrieving endpoints..." -ForegroundColor Cyan
$endpoints = Get-EndpointGroupId -Name $GroupName

Write-Host "Found $($endpoints.Count) endpoints" -ForegroundColor Green
Write-Host ""

$inventory = @()

foreach ($ep in $endpoints) {
    $details = Get-EndpointDetails -EndpointId $ep.id

    $onlineStatus = if ($details.last_seen -and ((Get-Date) - $details.last_seen).TotalMinutes -lt 30) {
        "Online"
    } else {
        "Offline"
    }

    if (-not $ShowOffline -and $onlineStatus -eq "Offline") {
        continue
    }

    $inventory += [PSCustomObject]@{
        Hostname         = $details.name
        OS               = $details.os_name
        OSVersion        = $details.os_version
        LastSeen         = $details.last_seen
        LastSeenAgo      = if ($details.last_seen) { [math]::Round(((Get-Date) - $details.last_seen).TotalMinutes, 1) } else { "N/A" }
        Status           = $onlineStatus
        PatchStatus      = $details.patch_status
        IPAddress        = $details.ip_address
        AgentVersion     = $details.agent_version
        Domain           = $details.domain
    }
}

if ($OutputFile) {
    $inventory | Export-Csv -Path $OutputFile -NoTypeInformation
    Write-Host "Exported to: $OutputFile" -ForegroundColor Green
}

Write-Header "Endpoint Summary"

$total = $inventory.Count
$online = ($inventory | Where-Object { $_.Status -eq "Online" }).Count
$offline = ($total - $online)

Write-Host "Total Endpoints : $total" -ForegroundColor White
Write-Host "Online          : $online" -ForegroundColor Green
Write-Host "Offline         : $offline" -ForegroundColor Red
Write-Host ""

Write-Header "Endpoint List"

$inventory | Format-Table -AutoSize Hostname, OS, Status, LastSeenAgo, PatchStatus | Out-String | Write-Host
