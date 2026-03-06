<#
.SYNOPSIS
    Gets Windows update history.

.DESCRIPTION
    Lists all installed Windows updates with details.

.PARAMETER Days
    Days to look back (default: 90).

.EXAMPLE
    .\Get-WindowsUpdateHistory.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Days = 90
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows Update History ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Last $Days days" -ForegroundColor Gray
Write-Host ""

$startDate = (Get-Date).AddDays(-$Days)

$updates = Get-HotFix | Where-Object { $_.InstalledOn -gt $startDate } | Sort-Object InstalledOn -Descending

Write-Host "Installed Updates:" -ForegroundColor Yellow

$total = 0

foreach ($update in $updates) {
    $date = $update.InstalledOn.ToString("yyyy-MM-dd")
    Write-Host "  $date - $($update.HotFixID)" -ForegroundColor White
    Write-Host "    $($update.Description)" -ForegroundColor Gray
    $total++
}

Write-Host ""
Write-Host "Total: $total updates" -ForegroundColor White

Write-Host ""
Write-Host "RESULT:OK - History retrieved" -ForegroundColor Green
exit 0
