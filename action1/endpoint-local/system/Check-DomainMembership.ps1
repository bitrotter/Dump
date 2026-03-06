<#
.SYNOPSIS
    Checks domain membership and authentication.

.DESCRIPTION
    Reports domain/workgroup status and tests authentication.

.EXAMPLE
    .\Check-DomainMembership.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Domain Membership ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$cs = Get-CimInstance Win32_ComputerSystem

Write-Host "Domain Status:" -ForegroundColor Yellow
Write-Host "  Name: $($cs.Name)" -ForegroundColor White
Write-Host "  Domain: $($cs.Domain)" -ForegroundColor White
Write-Host "  Workgroup: $($cs.Workgroup)" -ForegroundColor Gray

$partOfDomain = $cs.PartOfDomain

Write-Host "  Part of Domain: $partOfDomain" -ForegroundColor $(if ($partOfDomain) { "Green" } else { "Yellow" })

if ($partOfDomain) {
    Write-Host ""
    Write-Host "Domain Controller:" -ForegroundColor Yellow
    
    try {
        $dc = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().FindDomainController()
        Write-Host "  Name: $($dc.Name)" -ForegroundColor White
        Write-Host "  IP: $($dc.IPAddress)" -ForegroundColor Gray
    } catch {
        Write-Host "  Could not locate" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "AD Computer Info:" -ForegroundColor Yellow
    
    try {
        $adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
        Write-Host "  Created: $($adsi.CreateDate)" -ForegroundColor Gray
        Write-Host "  Description: $($adsi.Description)" -ForegroundColor Gray
    } catch {
        Write-Host "  Could not retrieve" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "DNS Domain:" -ForegroundColor Yellow

$dnsDomain = [System.Net.Dns]::GetHostEntry([String]::Empty).HostName
Write-Host "  Full Name: $dnsDomain" -ForegroundColor White

Write-Host ""

if (-not $partOfDomain) {
    Write-Host "RESULT:WARNING - Not joined to domain" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Domain membership OK" -ForegroundColor Green
    exit 0
}
