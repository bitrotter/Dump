<#
.SYNOPSIS
    Checks system uptime and last boot time.

.DESCRIPTION
    Reports system uptime, last boot time, and checks for servers
    that may need reboots after long uptime.

.PARAMETER MaxDays
    Warn if uptime exceeds this many days. Default: 30.

.EXAMPLE
    .\Check-SystemUptime.ps1

.EXAMPLE
    .\Check-SystemUptime.ps1 -MaxDays 14
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$MaxDays = 30
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== System Uptime ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$os = Get-CimInstance Win32_OperatingSystem
$lastBoot = $os.LastBootUpTime
$now = Get-Date

$uptime = $now - $lastBoot

Write-Host "Last Boot Time: " -NoNewline -ForegroundColor Yellow
Write-Host $lastBoot.ToString("yyyy-MM-dd HH:mm:ss") -ForegroundColor White

Write-Host "Current Time: " -NoNewline -ForegroundColor Yellow
Write-Host $now.ToString("yyyy-MM-dd HH:mm:ss") -ForegroundColor White

Write-Host ""
Write-Host "Uptime:" -ForegroundColor Yellow
Write-Host "  Days: $($uptime.Days)" -ForegroundColor White
Write-Host "  Hours: $($uptime.Hours)" -ForegroundColor White
Write-Host "  Minutes: $($uptime.Minutes)" -ForegroundColor White
Write-Host "  Total Hours: $([math]::Round($uptime.TotalHours, 1))" -ForegroundColor White

Write-Host ""
Write-Host "Uptime Thresholds:" -ForegroundColor Yellow

$thresholds = @(1, 7, 14, 30, 60, 90)
foreach ($threshold in $thresholds) {
    $status = if ($uptime.TotalDays -gt $threshold) { "EXCEEDED" } else { "OK" }
    $color = if ($uptime.TotalDays -gt $threshold) { "Red" } else { "Green" }
    Write-Host "  $threshold days: $status" -ForegroundColor $color
}

Write-Host ""
Write-Host "System Information:" -ForegroundColor Yellow
Write-Host "  OS: $($os.Caption)" -ForegroundColor White
Write-Host "  Version: $($os.Version)" -ForegroundColor Gray
Write-Host "  Build: $($os.BuildNumber)" -ForegroundColor Gray

$isServer = $os.Caption -match "Server"

if ($isServer) {
    Write-Host "  Type: Server" -ForegroundColor Cyan
} else {
    Write-Host "  Type: Workstation" -ForegroundColor Cyan
}

Write-Host ""

if ($uptime.TotalDays -gt $MaxDays) {
    Write-Host "RESULT:WARNING - Uptime $($uptime.Days) days exceeds $MaxDays day threshold" -ForegroundColor Yellow
    exit 1
} elseif ($uptime.TotalDays -gt 60) {
    Write-Host "RESULT:WARNING - High uptime: $($uptime.Days) days" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Uptime normal" -ForegroundColor Green
    exit 0
}
