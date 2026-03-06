<#
.SYNOPSIS
    Gets recent Windows updates.

.DESCRIPTION
    Lists recently installed updates and their status.

.PARAMETER Days
    Days to look back. Default: 30.

.EXAMPLE
    .\Get-RecentUpdates.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Days = 30
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Recent Windows Updates ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Last $Days days" -ForegroundColor Gray
Write-Host ""

$startDate = (Get-Date).AddDays(-$Days)

Write-Host "Installed Updates:" -ForegroundColor Yellow

$updates = Get-HotFix | Where-Object { $_.InstalledOn -gt $startDate } | Sort-Object InstalledOn -Descending

if ($updates) {
    foreach ($update in $updates) {
        $date = $update.InstalledOn.ToString("yyyy-MM-dd")
        Write-Host "  $date - $($update.HotFixID)" -ForegroundColor White
        Write-Host "    $($update.Description)" -ForegroundColor Gray
    }
} else {
    Write-Host "  No updates found in last $Days days" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Update Summary:" -ForegroundColor Yellow

$total = ($updates | Measure-Object).Count
$kb = ($updates | Where-Object { $_.HotFixID -match "KB" }).Count

Write-Host "  Total installed: $total" -ForegroundColor White

Write-Host ""
Write-Host "Pending Updates:" -ForegroundColor Yellow

try {
    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $pending = $searcher.Search("IsInstalled=0")
    
    Write-Host "  Available: $($pending.Updates.Count)" -ForegroundColor $(if ($pending.Updates.Count -gt 0) { "Yellow" } else { "Green" })
    
    if ($pending.Updates.Count -gt 0 -and $pending.Updates.Count -lt 10) {
        foreach ($update in $pending.Updates) {
            Write-Host "    - $($update.Title)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  Could not check" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Windows Update Service:" -ForegroundColor Yellow

$wu = Get-Service -Name wuauserv
Write-Host "  Status: $($wu.Status)" -ForegroundColor $(if ($wu.Status -eq "Running") { "Green" } else { "Red" })

Write-Host ""

if ($pending.Updates.Count -gt 10) {
    Write-Host "RESULT:WARNING - Many pending updates" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Updates OK" -ForegroundColor Green
    exit 0
}
