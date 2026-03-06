<#
.SYNOPSIS
    Checks Windows 11 compatibility.

.DESCRIPTION
    Reports if PC can run Windows 11 and upgrade requirements.

.EXAMPLE
    .\Check-Windows11Compatibility.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows 11 Compatibility ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem

Write-Host "Current OS:" -ForegroundColor Yellow
Write-Host "  $($os.Caption) Build $($os.BuildNumber)" -ForegroundColor White

Write-Host ""
Write-Host "Requirements Check:" -ForegroundColor Yellow

Write-Host "  CPU Cores:" -NoNewline
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
if ($cpu.NumberOfCores -ge 2) {
    Write-Host " PASS ($($cpu.NumberOfCores) cores)" -ForegroundColor Green
} else {
    Write-Host " FAIL ($($cpu.NumberOfCores) cores)" -ForegroundColor Red
}

Write-Host "  RAM:" -NoNewline
$ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 0)
if ($ramGB -ge 4) {
    Write-Host " PASS ($ramGB GB)" -ForegroundColor Green
} else {
    Write-Host " FAIL ($ramGB GB)" -ForegroundColor Red
}

Write-Host "  Storage:" -NoNewline
$disk = Get-PSDrive C
$freeGB = [math]::Round($disk.Free / 1GB, 0)
if ($freeGB -ge 64) {
    Write-Host " PASS ($freeGB GB free)" -ForegroundColor Green
} else {
    Write-Host " FAIL ($freeGB GB free)" -ForegroundColor Red
}

Write-Host "  TPM:" -NoNewline
$tpm = Get-Tpm -ErrorAction SilentlyContinue
if ($tpm -and $tpm.TpmPresent -and $tpm.TpmReady) {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL (not detected)" -ForegroundColor Red
}

Write-Host "  Secure Boot:" -NoNewline
$secure = (Get-CimInstance Win32_ComputerSystem).BootupState
if ($secure -match "Secure Boot") {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " UNKNOWN" -ForegroundColor Yellow
}

Write-Host "  Screen:" -NoNewline
$res = Get-CimInstance WMI_DesktopMonitor | Select-Object -First 1
if ($res.ScreenWidth -ge 720) {
    Write-Host " PASS ($($res.ScreenWidth)x$($res.ScreenHeight))" -ForegroundColor Green
} else {
    Write-Host " UNKNOWN" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "CPU Info:" -ForegroundColor Yellow
Write-Host "  $($cpu.Name)" -ForegroundColor White
Write-Host "  $($cpu.Manufacturer)" -ForegroundColor Gray

Write-Host ""
Write-Host "TPM Details:" -ForegroundColor Yellow
if ($tpm) {
    Write-Host "  Present: $($tpm.TpmPresent)" -ForegroundColor Gray
    Write-Host "  Ready: $($tpm.TpmReady)" -ForegroundColor Gray
    Write-Host "  Enabled: $($tpm.TpmEnabled)" -ForegroundColor Gray
}

Write-Host ""

$issues = @()
if ($cpu.NumberOfCores -lt 2) { $issues += "CPU" }
if ($ramGB -lt 4) { $issues += "RAM" }
if ($freeGB -lt 64) { $issues += "Storage" }
if (-not ($tpm -and $tpm.TpmPresent)) { $issues += "TPM" }

if ($issues.Count -eq 0) {
    Write-Host "RESULT:OK - Windows 11 compatible" -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT:WARNING - Not compatible: $($issues -join ', ')" -ForegroundColor Yellow
    exit 1
}
