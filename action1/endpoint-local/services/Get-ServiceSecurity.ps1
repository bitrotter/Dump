<#
.SYNOPSIS
    Gets service permissions/security descriptor.

.DESCRIPTION
    Shows service security descriptor and permissions.

.PARAMETER ServiceName
    Service name.

.EXAMPLE
    .\Get-ServiceSecurity.ps1 -ServiceName "Spooler"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Service Security ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $ServiceName) {
    Write-Host "Usage: Get-ServiceSecurity -ServiceName <name>" -ForegroundColor Yellow
    exit 0
}

Write-Host "Service: $ServiceName" -ForegroundColor Yellow

$svc = Get-WmiObject Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue

if ($svc) {
    Write-Host "  Name: $($svc.Name)" -ForegroundColor White
    Write-Host "  Display Name: $($svc.DisplayName)" -ForegroundColor White
    Write-Host "  State: $($svc.State)" -ForegroundColor Gray
    Write-Host "  Process ID: $($svc.ProcessId)" -ForegroundColor Gray
    Write-Host "  Path: $($svc.PathName)" -ForegroundColor Gray
    Write-Host "  Started: $($svc.Started)" -ForegroundColor Gray
    Write-Host "  Start Mode: $($svc.StartMode)" -ForegroundColor Gray
    Write-Host "  System: $($svc.SystemName)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Permissions (SDDL):" -ForegroundColor Yellow

try {
    $sddl = sc.exe sdshow $ServiceName
    Write-Host "  $sddl" -ForegroundColor Gray
} catch {
    Write-Host "  Could not retrieve" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - Security info retrieved" -ForegroundColor Green
exit 0
