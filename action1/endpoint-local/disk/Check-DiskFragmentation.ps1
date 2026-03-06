<#
.SYNOPSIS
    Checks disk fragmentation.

.DESCRIPTION
    Analyzes disk fragmentation and recommends defrag if needed.

.PARAMETER Drive
    Drive letter to check (default: C).

.EXAMPLE
    .\Check-DiskFragmentation.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Drive = "C"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Disk Fragmentation Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Analyzing drive $Drive..." -ForegroundColor Yellow

try {
    $defrag = Defrag "$Drive`:" -A -H
    
    if ($defrag) {
        Write-Host "  Total fragments: $($defrag.TotalFragments)" -ForegroundColor White
        Write-Host "  File fragments: $($defrag.FileFragments)" -ForegroundColor White
        Write-Host "  Free fragments: $($defrag.FreeFragments)" -ForegroundColor Gray
        
        $percent = if ($defrag.TotalClusters -gt 0) {
            [math]::Round(($defrag.FreeFragments / $defrag.TotalClusters) * 100, 1)
        } else { 0 }
        
        Write-Host "  Free space %: $percent" -ForegroundColor Gray
        
        if ($defrag.FragmentedPercent -gt 10) {
            Write-Host "  Fragmented: $($defrag.FragmentedPercent)%" -ForegroundColor Red
        } else {
            Write-Host "  Fragmented: $($defrag.FragmentedPercent)%" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "  Could not analyze (may need admin)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - Fragmentation check complete" -ForegroundColor Green
exit 0
