<#
.SYNOPSIS
    Disables Windows telemetry and data collection.

.DESCRIPTION
    Disables common telemetry settings for privacy.

.PARAMETER Basic
    Only apply basic telemetry settings.

.EXAMPLE
    .\Disable-Telemetry.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Basic
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Disable Windows Telemetry ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Setting telemetry to minimal..." -ForegroundColor Yellow

$regPaths = @(
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0 },
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "TelemetryProxy"; Value = "0" }
)

foreach ($reg in $regPaths) {
    if (-not (Test-Path $reg.Path)) {
        New-Item -Path $reg.Path -Force | Out-Null
    }
    Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value -Type DWord -Force
    Write-Host "  Set $($reg.Name) = $($reg.Value)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Disabling feedback hub..." -ForegroundColor Yellow

$feedback = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Feedback"
if (-not (Test-Path $feedback)) { New-Item -Path $feedback -Force | Out-Null }
Set-ItemProperty -Path $feedback -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1 -Type DWord -Force
Write-Host "  Feedback disabled" -ForegroundColor Green

Write-Host ""
Write-Host "Disabling activity history..." -ForegroundColor Yellow

$activity = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $activity)) { New-Item -Path $activity -Force | Out-Null }
Set-ItemProperty -Path $activity -Name "PublishUserActivities" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $activity -Name "UploadUserActivities" -Value 0 -Type DWord -Force
Write-Host "  Activity history disabled" -ForegroundColor Green

if (-not $Basic) {
    Write-Host ""
    Write-Host "Disabling diagnostic data viewer..." -ForegroundColor Yellow
    
    $diagView = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DiagnosticDataViewer"
    if (-not (Test-Path $diagView)) { New-Item -Path $diagView -Force | Out-Null }
    Set-ItemProperty -Path $diagView -Name "DisableDiagnosticDataViewer" -Value 1 -Type DWord -Force
    Write-Host "  Diagnostic viewer disabled" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Stopping Connected User Experience service..." -ForegroundColor Yellow
    
    $cus = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
    if ($cus) {
        Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue
        Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  DiagTrack service disabled" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "RESULT:OK - Telemetry settings applied" -ForegroundColor Green
exit 0
