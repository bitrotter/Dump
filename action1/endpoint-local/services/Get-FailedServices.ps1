<#
.SYNOPSIS
    Lists failed or stopped services.

.DESCRIPTION
    Shows services that are stopped but should be running.

.EXAMPLE
    .\Get-FailedServices.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Failed/Stopped Services ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Stopped Services (Automatic):" -ForegroundColor Yellow

$stopped = Get-Service | Where-Object { $_.Status -ne "Running" -and $_.StartType -eq "Automatic" }

if ($stopped) {
    foreach ($svc in $stopped) {
        Write-Host "  $($svc.Name): $($svc.Status)" -ForegroundColor Red
    }
} else {
    Write-Host "  None found" -ForegroundColor Green
}

Write-Host ""
Write-Host "Services with Errors:" -ForegroundColor Yellow

$services = Get-Service | Where-Object { $_.Status -eq "Running" }

$errorCount = 0

foreach ($svc in $services) {
    try {
        $err = Get-WinEvent -FilterHashtable @{
            LogName = "System"
            ProviderName = $svc.Name
            Level = 2
            StartTime = (Get-Date).AddHours(-24)
        } -MaxEvents 1 -ErrorAction SilentlyContinue
        
        if ($err) {
            Write-Host "  $($svc.Name): Has recent errors" -ForegroundColor Yellow
            $errorCount++
        }
    } catch { }
}

if ($errorCount -eq 0) {
    Write-Host "  No service errors found" -ForegroundColor Green
}

Write-Host ""
Write-Host "Services Not Started:" -ForegroundColor Yellow

$notStarted = Get-Service | Where-Object { $_.Status -eq "Stopped" }

foreach ($svc in $notStarted | Select-Object -First 10) {
    Write-Host "  $($svc.Name): $($svc.DisplayName)" -ForegroundColor White
}

Write-Host ""
Write-Host "RESULT:OK - Check complete" -ForegroundColor Green
exit 0
