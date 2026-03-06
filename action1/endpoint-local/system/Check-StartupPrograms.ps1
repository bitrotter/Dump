<#
.SYNOPSIS
    Lists programs that run at startup.

.DESCRIPTION
    Shows all startup entries including registry,
    startup folder, and scheduled tasks.

.PARAMETER Disable
    Disable non-Microsoft startup items.

.EXAMPLE
    .\Check-StartupPrograms.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Disable
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Startup Programs ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$startupItems = @()

Write-Host "Registry - Current User:" -ForegroundColor Yellow

$hkcuRun = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue

if ($hkcuRun) {
    $hkcuRun.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor White
        $startupItems += [PSCustomObject]@{ Name = $_.Name; Location = "HKCU Run"; Command = $_.Value }
    }
}

Write-Host ""
Write-Host "Registry - Local Machine:" -ForegroundColor Yellow

$hklmRun = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue

if ($hklmRun) {
    $hklmRun.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor White
        $startupItems += [PSCustomObject]@{ Name = $_.Name; Location = "HKLM Run"; Command = $_.Value }
    }
}

Write-Host ""
Write-Host "Startup Folder:" -ForegroundColor Yellow

$startupFolder = [Environment]::GetFolderPath("Startup")

if (Test-Path $startupFolder) {
    Get-ChildItem $startupFolder -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "  $($_.Name)" -ForegroundColor White
        $startupItems += [PSCustomObject]@{ Name = $_.Name; Location = "Startup Folder"; Command = $_.FullName }
    }
}

Write-Host ""
Write-Host "Scheduled Task Startup:" -ForegroundColor Yellow

$tasks = Get-ScheduledTask | Where-Object { $_.Settings.Enabled -and $_.Triggers | Where-Object { $_ -is [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.CimTriggers+StartupTrigger] } }

foreach ($task in $tasks) {
    Write-Host "  $($task.TaskName)" -ForegroundColor White
    $startupItems += [PSCustomObject]@{ Name = $task.TaskName; Location = "Scheduled Task"; Command = $task.State }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Total Startup Items: $($startupItems.Count)" -ForegroundColor White

$msftCount = ($startupItems | Where-Object { $_.Name -match "Microsoft|Windows" }).Count
$thirdParty = $startupItems.Count - $msftCount

Write-Host "  Microsoft/Windows: $msftCount" -ForegroundColor Green
Write-Host "  Third-Party: $thirdParty" -ForegroundColor $(if ($thirdParty -gt 5) { "Yellow" } else { "Green" })

Write-Host ""

if ($thirdParty -gt 10) {
    Write-Host "RESULT:WARNING - Many third-party startup items ($thirdParty)" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Startup items normal" -ForegroundColor Green
    exit 0
}
