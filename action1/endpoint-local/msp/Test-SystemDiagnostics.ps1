<#
.SYNOPSIS
    Runs common diagnostic checks and generates report.

.DESCRIPTION
    Runs multiple health checks and outputs combined report
    for quick system assessment.

.PARAMETER Quick
    Run only quick checks.

.EXAMPLE
    .\Test-SystemDiagnostics.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Quick
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== System Diagnostics ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Started: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

$issues = @()

Write-Host "[1/8] Disk Space..." -ForegroundColor Yellow
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }
foreach ($drive in $drives) {
    $freePct = [math]::Round(($drive.Free / ($drive.Used + $drive.Free)) * 100, 1)
    if ($freePct -lt 10) {
        $issues += "Low disk on $($drive.Name): $freePct%"
        Write-Host "  LOW: $($drive.Name) = $freePct%" -ForegroundColor Red
    } else {
        Write-Host "  OK: $($drive.Name) = $freePct%" -ForegroundColor Green
    }
}

Write-Host "[2/8] Windows Update..." -ForegroundColor Yellow
$wuauserv = Get-Service -Name wuauserv
if ($wuauserv.Status -eq "Running") {
    Write-Host "  OK: Service running" -ForegroundColor Green
} else {
    $issues += "WU service not running"
    Write-Host "  FAIL: Service stopped" -ForegroundColor Red
}

Write-Host "[3/8] Windows Defender..." -ForegroundColor Yellow
try {
    $defender = Get-MpComputerStatus
    if ($defender.RealTimeProtectionEnabled) {
        Write-Host "  OK: RTP enabled" -ForegroundColor Green
    } else {
        $issues += "RTP disabled"
        Write-Host "  WARN: RTP disabled" -ForegroundColor Yellow
    }
} catch {
    $issues += "Defender error"
    Write-Host "  FAIL: Cannot query" -ForegroundColor Red
}

Write-Host "[4/8] Firewall..." -ForegroundColor Yellow
$fw = Get-NetFirewallProfile
$disabled = ($fw | Where-Object { -not $_.Enabled }).Count
if ($disabled -eq 0) {
    Write-Host "  OK: All profiles enabled" -ForegroundColor Green
} else {
    $issues += "$disabled firewall profiles disabled"
    Write-Host "  WARN: $disabled disabled" -ForegroundColor Yellow
}

Write-Host "[5/8] Services..." -ForegroundColor Yellow
$criticalSvcs = @("wuauserv", "BITS", "EventLog", "Spooler")
$stopped = @()
foreach ($svc in $criticalSvcs) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s -and $s.Status -ne "Running") { $stopped += $svc }
}
if ($stopped.Count -eq 0) {
    Write-Host "  OK: All critical services running" -ForegroundColor Green
} else {
    $issues += "Stopped services: $($stopped -join ', ')"
    Write-Host "  FAIL: $($stopped -join ', ')" -ForegroundColor Red
}

Write-Host "[6/8] Event Logs..." -ForegroundColor Yellow
$errCount = (Get-WinEvent -FilterHashtable @{LogName="System"; StartTime=(Get-Date).AddHours(-24); Level=2} -MaxEvents 1 -ErrorAction SilentlyContinue).Count
if ($errCount -gt 0) {
    Write-Host "  WARN: Recent errors found" -ForegroundColor Yellow
} else {
    Write-Host "  OK: No recent errors" -ForegroundColor Green
}

Write-Host "[7/8] Uptime..." -ForegroundColor Yellow
$uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
if ($uptime.TotalDays -gt 30) {
    Write-Host "  WARN: High uptime ($([int]$uptime.TotalDays) days)" -ForegroundColor Yellow
} else {
    Write-Host "  OK: Normal uptime" -ForegroundColor Green
}

if (-not $Quick) {
    Write-Host "[8/8] Network..." -ForegroundColor Yellow
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    if ($adapters) {
        Write-Host "  OK: Adapters up" -ForegroundColor Green
    } else {
        $issues += "No active adapters"
        Write-Host "  FAIL: No active adapters" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Issues Found: $($issues.Count)" -ForegroundColor $(if ($issues.Count -gt 0) { "Red" } else { "Green" })

if ($issues.Count -gt 0) {
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

Write-Host ""
if ($issues.Count -gt 2) {
    Write-Host "RESULT:CRITICAL - Multiple issues found" -ForegroundColor Red
    exit 2
} elseif ($issues.Count -gt 0) {
    Write-Host "RESULT:WARNING - Some issues found" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - System healthy" -ForegroundColor Green
    exit 0
}
