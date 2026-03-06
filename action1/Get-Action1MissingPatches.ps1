<#
.SYNOPSIS
    Retrieves missing patches from Action1 RMM.

.DESCRIPTION
    Shows missing updates across all endpoints, with severity levels,
    patch counts, and recommendations for remediation.

.PARAMETER OrganizationId
    Action1 Organization ID. Falls back to $env:ACTION1_ORG_ID.

.PARAMETER Severity
    Filter by severity: Critical, Important, Moderate, Low

.PARAMETER Top
    Number of endpoints with most missing patches to show.

.PARAMETER OutputFile
    Export results to CSV file.

.EXAMPLE
    .\Get-Action1MissingPatches.ps1

.EXAMPLE
    .\Get-Action1MissingPatches.ps1 -Severity Critical -Top 10
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OrganizationId = $env:ACTION1_ORG_ID,

    [Parameter(Mandatory=$false)]
    [ValidateSet("Critical", "Important", "Moderate", "Low")]
    [string]$Severity,

    [Parameter(Mandatory=$false)]
    [int]$Top = 20,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

$colors = @{
    'Critical'  = 'Red'
    'Important' = 'Yellow'
    'Moderate'  = 'Cyan'
    'Low'       = 'Gray'
    'Info'      = 'White'
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
        exit 1
    }

    Set-Action1 -OrganizationID $OrganizationId
}

Test-Prerequisites

Write-Header "Action1 Missing Patches Dashboard"

Write-Host "Retrieving endpoint data..." -ForegroundColor Cyan

$endpoints = Get-Action1 -Query "Endpoints?fields=*"

$missingPatchesData = @()
$endpointPatchCounts = @{}

foreach ($ep in $endpoints) {
    $endpointName = $ep.name

    $patches = Get-Action1 -Query "MissingUpdates?endpoint_id=$($ep.id)"

    if ($patches -and $patches.items) {
        $count = $patches.items.Count
        $endpointPatchCounts[$endpointName] = $count

        foreach ($patch in $patches.items) {
            if ($Severity -and $patch.severity -ne $Severity) {
                continue
            }

            $missingPatchesData += [PSCustomObject]@{
                Hostname   = $endpointName
                KBId       = $patch.kb_id
                Title      = $patch.title
                Severity   = $patch.severity
                ReleaseDate = $patch.release_date
                PatchId    = $patch.id
            }
        }
    }
}

Write-Host "Analyzing $($endpoints.Count) endpoints..." -ForegroundColor Cyan
Write-Host ""

Write-Header "Severity Distribution"

$severityCounts = $missingPatchesData | Group-Object Severity | Sort-Object { switch($_.Name) { "Critical" {1} "Important" {2} "Moderate" {3} "Low" {4} } }

foreach ($group in $severityCounts) {
    $color = $colors[$group.Name]
    Write-Host "$($group.Name.PadRight(12)): $($group.Count)" -ForegroundColor $color
}

Write-Host ""
Write-Host "Total Missing Patches: $($missingPatchesData.Count)" -ForegroundColor White

Write-Header "Top Endpoints by Missing Patches"

$topEndpoints = $endpointPatchCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $Top

$table = @()
foreach ($item in $topEndpoints) {
    $table += [PSCustomObject]@{
        Hostname        = $item.Key
        MissingPatches  = $item.Value
    }
}

$table | Format-Table -AutoSize | Out-String | Write-Host

Write-Header "Critical Patches Detail"

if ($Severity -eq "Critical" -or -not $Severity) {
    $critical = $missingPatchesData | Where-Object { $_.Severity -eq "Critical" }
    if ($critical) {
        $critical | Group-Object KBId | ForEach-Object {
            Write-Host "KB: $($_.Name)" -ForegroundColor Red
            $_.Group | Select-Object -First 3 | ForEach-Object {
                Write-Host "  - $($_.Title)" -ForegroundColor Gray
                Write-Host "    $($_.Hostname)" -ForegroundColor Yellow
            }
            if ($_.Count -gt 3) {
                Write-Host "  ... and $($_.Count - 3) more" -ForegroundColor Gray
            }
            Write-Host ""
        }
    }
}

if ($OutputFile) {
    $missingPatchesData | Export-Csv -Path $OutputFile -NoTypeInformation
    Write-Host "Exported to: $OutputFile" -ForegroundColor Green
}

Write-Header "Recommendations"

$criticalCount = ($missingPatchesData | Where-Object { $_.Severity -eq "Critical" }).Count
$importantCount = ($missingPatchesData | Where-Object { $_.Severity -eq "Important" }).Count

if ($criticalCount -gt 0) {
    Write-Host "⚠ $criticalCount CRITICAL patches require immediate attention!" -ForegroundColor Red
}
if ($importantCount -gt 0) {
    Write-Host "⚠ $importantCount IMPORTANT patches should be scheduled" -ForegroundColor Yellow
}
if ($criticalCount -eq 0 -and $importantCount -eq 0) {
    Write-Host "✓ No critical or important patches pending" -ForegroundColor Green
}
