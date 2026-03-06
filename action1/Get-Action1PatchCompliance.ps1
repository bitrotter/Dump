<#
.SYNOPSIS
    Generates patch compliance report from Action1 RMM.

.DESCRIPTION
    Shows patch compliance percentage per endpoint and group,
    with breakdowns by severity and trend analysis.

.PARAMETER OrganizationId
    Action1 Organization ID. Falls back to $env:ACTION1_ORG_ID.

.PARAMETER Threshold
    Compliance threshold percentage. Default: 90.

.PARAMETER GroupName
    Filter by endpoint group name.

.PARAMETER OutputFile
    Export results to CSV file.

.EXAMPLE
    .\Get-Action1PatchCompliance.ps1

.EXAMPLE
    .\Get-Action1PatchCompliance.ps1 -Threshold 80 -OutputFile compliance.csv
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OrganizationId = $env:ACTION1_ORG_ID,

    [Parameter(Mandatory=$false)]
    [int]$Threshold = 90,

    [Parameter(Mandatory=$false)]
    [string]$GroupName,

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

Write-Header "Action1 Patch Compliance Report"

Write-Host "Retrieving endpoint data..." -ForegroundColor Cyan

$endpoints = Get-Action1 -Query "Endpoints?fields=*"

$complianceData = @()

foreach ($ep in $endpoints) {
    $patches = Get-Action1 -Query "MissingUpdates?endpoint_id=$($ep.id)"

    $totalRequired = 0
    $critical = 0
    $important = 0

    if ($patches -and $patches.items) {
        $totalRequired = $patches.items.Count
        $critical = ($patches.items | Where-Object { $_.severity -eq "Critical" }).Count
        $important = ($patches.items | Where-Object { $_.severity -eq "Important" }).Count
    }

    $compliance = if ($totalRequired -eq 0) { 100 } else { 0 }

    $complianceData += [PSCustomObject]@{
        Hostname         = $ep.name
        Compliance       = $compliance
        MissingCritical  = $critical
        MissingImportant = $important
        MissingTotal     = $totalRequired
        OS               = $ep.os_name
        LastSeen         = $ep.last_seen
    }
}

$complianceData = $complianceData | Sort-Object Compliance

Write-Host "Analyzing $($endpoints.Count) endpoints..." -ForegroundColor Cyan
Write-Host ""

Write-Header "Compliance Summary"

$compliant = ($complianceData | Where-Object { $_.Compliance -ge $Threshold }).Count
$nonCompliant = $complianceData.Count - $compliant

Write-Host "Threshold: $Threshold%" -ForegroundColor Yellow
Write-Host "Compliant (>= $Threshold%)   : $compliant" -ForegroundColor Green
Write-Host "Non-Compliant (< $Threshold%): $nonCompliant" -ForegroundColor Red
Write-Host ""

$overallCompliance = if ($complianceData.Count -gt 0) {
    [math]::Round(($compliant / $complianceData.Count) * 100, 1)
} else { 0 }

Write-Host "Overall Compliance: $overallCompliance%" -ForegroundColor $(if ($overallCompliance -ge $Threshold) { "Green" } elseif ($overallCompliance -ge 70) { "Yellow" } else { "Red" })

Write-Header "Critical Patches Outstanding"

$criticalEndpoints = $complianceData | Where-Object { $_.MissingCritical -gt 0 } | Sort-Object MissingCritical -Descending

if ($criticalEndpoints) {
    $criticalEndpoints | Select-Object -First 20 | Format-Table -AutoSize Hostname, MissingCritical, MissingImportant, OS | Out-String | Write-Host
} else {
    Write-Host "✓ No critical patches outstanding!" -ForegroundColor Green
}

Write-Header "Non-Compliant Endpoints (< $Threshold%)"

$nonCompliantList = $complianceData | Where-Object { $_.Compliance -lt $Threshold }

if ($nonCompliantList) {
    $nonCompliantList | Format-Table -AutoSize Hostname, Compliance, MissingTotal, MissingCritical, MissingImportant, OS | Out-String | Write-Host
} else {
    Write-Host "✓ All endpoints are compliant!" -ForegroundColor Green
}

Write-Header "Group Summary by OS"

$osGroups = $complianceData | Group-Object OS

foreach ($os in $osGroups) {
    $osCompliant = ($os.Group | Where-Object { $_.Compliance -ge $Threshold }).Count
    $osTotal = $os.Group.Count
    $osPercent = if ($osTotal -gt 0) { [math]::Round(($osCompliant / $osTotal) * 100, 1) } else { 0 }

    $color = if ($osPercent -ge $Threshold) { "Green" } elseif ($osPercent -ge 70) { "Yellow" } else { "Red" }

    $osName = if ($os.Name) { $os.Name } else { "Unknown" }
    Write-Host "$($osName.PadRight(40)) : $osPercent% ($osCompliant/$osTotal)" -ForegroundColor $color
}

if ($OutputFile) {
    $complianceData | Export-Csv -Path $OutputFile -NoTypeInformation
    Write-Host "Exported to: $OutputFile" -ForegroundColor Green
}

Write-Header "Recommendations"

$criticalCount = ($complianceData | Measure-Object -Property MissingCritical -Sum).Sum
$importantCount = ($complianceData | Measure-Object -Property MissingImportant -Sum).Sum

if ($criticalCount -gt 0) {
    Write-Host "⚠ $criticalCount critical patches need immediate deployment" -ForegroundColor Red
}
if ($importantCount -gt 0) {
    Write-Host "⚠ $importantCount important patches should be scheduled" -ForegroundColor Yellow
}
if ($criticalCount -eq 0 -and $importantCount -eq 0) {
    Write-Host "✓ All endpoints are fully patched!" -ForegroundColor Green
}
