<#
.SYNOPSIS
    Checks antivirus/Windows Defender status.

.DESCRIPTION
    Reports antivirus real-time protection status, 
    last scan time, and definition version.

.PARAMETER EnableRTP
    Enable real-time protection if disabled.

.EXAMPLE
    .\Check-AntivirusStatus.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$EnableRTP
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Antivirus Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

try {
    $defender = Get-MpComputerStatus
    
    Write-Host "Antivirus: " -NoNewline -ForegroundColor Yellow
    Write-Host "Windows Defender" -ForegroundColor White
    
    Write-Host "Real-Time Protection: " -NoNewline -ForegroundColor Yellow
    if ($defender.RealTimeProtectionEnabled) {
        Write-Host "Enabled" -ForegroundColor Green
    } else {
        Write-Host "Disabled" -ForegroundColor Red
        
        if ($EnableRTP) {
            Write-Host "Enabling real-time protection..." -ForegroundColor Yellow
            Set-MpPreference -DisableRealtimeMonitoring $false
            Start-Sleep -Seconds 2
            
            $defender = Get-MpComputerStatus
            if ($defender.RealTimeProtectionEnabled) {
                Write-Host "Real-time protection enabled" -ForegroundColor Green
            }
        }
    }
    
    Write-Host "Antivirus Enabled: " -NoNewline -ForegroundColor Yellow
    Write-Host $defender.AntivirusEnabled -ForegroundColor $(if ($defender.AntivirusEnabled) { "Green" } else { "Red" })
    
    Write-Host "Antispyware Enabled: " -NoNewline -ForegroundColor Yellow
    Write-Host $defender.AntispywareEnabled -ForegroundColor $(if ($defender.AntispywareEnabled) { "Green" } else { "Red" })
    
    Write-Host "Behavior Monitor: " -NoNewline -ForegroundColor Yellow
    Write-Host $defender.BehaviorMonitorEnabled -ForegroundColor $(if ($defender.BehaviorMonitorEnabled) { "Green" } else { "Red" })
    
    Write-Host ""
    Write-Host "Signature Info:" -ForegroundColor Cyan
    
    $sigDate = $defender.AntivirusSignatureLastUpdated
    Write-Host "  Signature Date: $sigDate" -ForegroundColor White
    
    $sigVersion = $defender.AntivirusSignatureVersion
    Write-Host "  Signature Version: $sigVersion" -ForegroundColor White
    
    $age = (Get-Date) - $defender.AntivirusSignatureLastUpdated
    Write-Host "  Signature Age: $($age.Days) days" -ForegroundColor $(if ($age.Days -gt 7) { "Yellow" } else { "Green" })
    
    Write-Host ""
    Write-Host "Last Scan:" -ForegroundColor Cyan
    if ($defender.QuickScanEndTime) {
        Write-Host "  Quick Scan: $($defender.QuickScanEndTime)" -ForegroundColor White
    }
    if ($defender.FullScanEndTime) {
        Write-Host "  Full Scan: $($defender.FullScanEndTime)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Contamination: " -NoNewline -ForegroundColor Yellow
    Write-Host $defender.ContaminationCount -ForegroundColor White

    $issues = @()
    if (-not $defender.RealTimeProtectionEnabled) { $issues += "RTP disabled" }
    if (-not $defender.AntivirusEnabled) { $issues += "Antivirus off" }
    if ($age.Days -gt 7) { $issues += "Old definitions" }
    
    if ($issues.Count -gt 0) {
        Write-Host ""
        Write-Host "RESULT:WARNING - Issues: $($issues -join ', ')" -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host ""
        Write-Host "RESULT:OK - Antivirus healthy" -ForegroundColor Green
        exit 0
    }

} catch {
    Write-Host "ERROR: Could not get Defender status" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Gray
    Write-Host "RESULT:UNKNOWN - Could not check antivirus" -ForegroundColor Yellow
    exit 1
}
