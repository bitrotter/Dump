<#
.SYNOPSIS
    Checks for common authentication issues.

.DESCRIPTION
    Tests AD connectivity, credential caching, and login issues.

.EXAMPLE
    .\Check-AuthenticationIssues.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Authentication Issues Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Current User:" -ForegroundColor Yellow

$current = [System.Security.Principal.WindowsIdentity]::GetCurrent()
Write-Host "  Name: $($current.Name)" -ForegroundColor White
Write-Host "  Auth: $($current.AuthenticationType)" -ForegroundColor Gray
Write-Host "  Is Admin: $([Security.Principal.WindowsPrincipal]$current).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)" -ForegroundColor $(if ($?) { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "Domain Status:" -ForegroundColor Yellow

$cs = Get-CimInstance Win32_ComputerSystem

if ($cs.PartOfDomain) {
    Write-Host "  Domain: $($cs.Domain)" -ForegroundColor Green
    Write-Host "  Computer: $($cs.Name)" -ForegroundColor White
    
    try {
        $dc = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().FindDomainController()
        Write-Host "  DC: $($dc.Name)" -ForegroundColor White
        
        $ping = Test-Connection -ComputerName $dc.Name -Count 1 -Quiet
        Write-Host "  DC Reachable: $(if ($ping) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($ping) { "Green" } else { "Red" })
    } catch {
        Write-Host "  DC: Could not locate - $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  Workgroup: $($cs.Workgroup)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Cached Credentials:" -ForegroundColor Yellow

$cached = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue

Write-Host "  Cached Logons: $($cached.CachedLogonsCount)" -ForegroundColor Gray

Write-Host ""
Write-Host "Recent Logon Events:" -ForegroundColor Yellow

$logonEvents = Get-WinEvent -FilterHashtable @{
    LogName = "Security"
    Id = 4624
    StartTime = (Get-Date).AddHours(-24)
} -MaxEvents 5 -ErrorAction SilentlyContinue

if ($logonEvents) {
    foreach ($event in $logonEvents) {
        $user = $event.Properties[5].Value
        $time = $event.TimeCreated
        Write-Host "  $time - $user" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "Failed Logon Attempts:" -ForegroundColor Yellow

$failed = Get-WinEvent -FilterHashtable @{
    LogName = "Security"
    Id = 4625
    StartTime = (Get-Date).AddHours(-24)
} -MaxEvents 10 -ErrorAction SilentlyContinue

if ($failed) {
    Write-Host "  Failed attempts (last 24h): $($failed.Count)" -ForegroundColor $(if ($failed.Count -gt 10) { "Red" } else { "Yellow" })
    
    foreach ($event in $failed | Select-Object -First 3) {
        $user = $event.Properties[5].Value
        $time = $event.TimeCreated
        Write-Host "    $time - $user" -ForegroundColor Gray
    }
} else {
    Write-Host "  No recent failed attempts" -ForegroundColor Green
}

Write-Host ""

if ($failed.Count -gt 20) {
    Write-Host "RESULT:WARNING - Many failed logon attempts" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Authentication OK" -ForegroundColor Green
    exit 0
}
