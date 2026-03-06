<#
.SYNOPSIS
    Sets service startup type.

.DESCRIPTION
    Configures service startup type (Automatic, Manual, Disabled).

.PARAMETER ServiceName
    Service name.

.PARAMETER StartupType
    Startup type: Automatic, Manual, Disabled.

.EXAMPLE
    .\Set-ServiceStartup.ps1 -ServiceName "Spooler" -StartupType Automatic
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName,

    [Parameter(Mandatory=$false)]
    [ValidateSet("Automatic", "Manual", "Disabled")]
    [string]$StartupType
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Set Service Startup ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $ServiceName -or -not $StartupType) {
    Write-Host "Usage: Set-ServiceStartup -ServiceName <name> -StartupType <type>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Example: Set-ServiceStartup -ServiceName Spooler -StartupType Automatic" -ForegroundColor Gray
    exit 0
}

Write-Host "Setting $ServiceName to $StartupType..." -ForegroundColor Yellow

try {
    Set-Service -Name $ServiceName -StartupType $StartupType -ErrorAction Stop
    
    $svc = Get-Service -Name $ServiceName
    Write-Host "  New startup type: $($svc.StartType)" -ForegroundColor Green
    
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "RESULT:OK - Startup type set" -ForegroundColor Green
exit 0
