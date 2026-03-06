<#
.SYNOPSIS
    Checks PowerShell version and modules.

.DESCRIPTION
    Reports PowerShell version and important modules.

.EXAMPLE
    .\Check-PowerShellVersion.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== PowerShell Version ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "PowerShell:" -ForegroundColor Yellow

Write-Host "  Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host "  Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Gray
Write-Host "  CLR: $($PSVersionTable.CLRVersion)" -ForegroundColor Gray
Write-Host "  Build: $($PSVersionTable.BuildVersion)" -ForegroundColor Gray

Write-Host ""
Write-Host "Execution Policy:" -ForegroundColor Yellow

$policy = Get-ExecutionPolicy

Write-Host "  Policy: $policy" -ForegroundColor $(if ($policy -eq "Restricted") { "Red" } else { "Green" })

Write-Host ""
Write-Host "Important Modules:" -ForegroundColor Yellow

$modules = @("ActiveDirectory", "AzureAD", "ExchangeOnline", "Microsoft.Graph", "Pester")

foreach ($mod in $modules) {
    $installed = Get-Module -Name $mod -ListAvailable -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($installed) {
        Write-Host "  $mod : $($installed.Version)" -ForegroundColor Green
    } else {
        Write-Host "  $mod : Not installed" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Installed Modules:" -ForegroundColor Gray

$allModules = Get-Module -ListAvailable | Group-Object Name | Sort-Object Count -Descending | Select-Object -First 10

foreach ($mod in $allModules) {
    Write-Host "  $($mod.Name) ($($mod.Count) versions)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - PowerShell info retrieved" -ForegroundColor Green
exit 0
