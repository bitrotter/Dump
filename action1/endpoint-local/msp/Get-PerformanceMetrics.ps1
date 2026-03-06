<#
.SYNOPSIS
    Collects performance metrics.

.DESCRIPTION
    Gets CPU, memory, disk, and network performance data.

.PARAMETER Quick
    Run quick check only.

.EXAMPLE
    .\Get-PerformanceMetrics.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Quick
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Performance Metrics ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "CPU:" -ForegroundColor Yellow

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
Write-Host "  Name: $($cpu.Name)" -ForegroundColor White
Write-Host "  Cores: $($cpu.NumberOfCores)" -ForegroundColor Gray
Write-Host "  Logical Processors: $($cpu.NumberOfLogicalProcessors)" -ForegroundColor Gray

$cpuUsage = (Get-CimInstance Win32_Processor).LoadPercentage
Write-Host "  Current Load: $cpuUsage%" -ForegroundColor $(if ($cpuUsage -gt 80) { "Red" } elseif ($cpuUsage -gt 50) { "Yellow" } else { "Green" })

Write-Host ""
Write-Host "Memory:" -ForegroundColor Yellow

$os = Get-CimInstance Win32_OperatingSystem
$totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedMem = $totalMem - $freeMem
$usedPct = [math]::Round(($usedMem / $totalMem) * 100, 1)

Write-Host "  Total: $totalMem GB" -ForegroundColor White
Write-Host "  Used: $usedMem GB ($usedPct%)" -ForegroundColor $(if ($usedPct -gt 90) { "Red" } elseif ($usedPct -gt 75) { "Yellow" } else { "Green" })
Write-Host "  Free: $freeMem GB" -ForegroundColor Gray

Write-Host ""
Write-Host "Disk:" -ForegroundColor Yellow

$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }

foreach ($drive in $drives) {
    $totalGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    $usedGB = [math]::Round($drive.Used / 1GB, 2)
    $freePct = [math]::Round(($drive.Free / ($drive.Used + $drive.Free)) * 100, 1)
    
    Write-Host "  Drive $($drive.Name):" -ForegroundColor White
    Write-Host "    Total: $totalGB GB" -ForegroundColor Gray
    Write-Host "    Used: $usedGB GB" -ForegroundColor Gray
    Write-Host "    Free: $freeGB GB ($freePct%)" -ForegroundColor $(if ($freePct -lt 10) { "Red" } elseif ($freePct -lt 20) { "Yellow" } else { "Green" })
}

if (-not $Quick) {
    Write-Host ""
    Write-Host "Top Processes by Memory:" -ForegroundColor Yellow
    
    $procs = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10
    
    foreach ($proc in $procs) {
        $memMB = [math]::Round($proc.WorkingSet64 / 1MB, 0)
        Write-Host "  $($proc.Name): $memMB MB" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Top Processes by CPU:" -ForegroundColor Yellow
    
    $procs = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
    
    foreach ($proc in $procs) {
        Write-Host "  $($proc.Name): $([math]::Round($proc.CPU, 1)) sec" -ForegroundColor White
    }
}

Write-Host ""

if ($usedPct -gt 90 -or $cpuUsage -gt 90) {
    Write-Host "RESULT:CRITICAL - High resource usage" -ForegroundColor Red
    exit 2
} elseif ($usedPct -gt 75 -or $cpuUsage -gt 75) {
    Write-Host "RESULT:WARNING - Elevated resource usage" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Performance normal" -ForegroundColor Green
    exit 0
}
