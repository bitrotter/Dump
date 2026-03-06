<#
.SYNOPSIS
    Gets system environment variables.

.DESCRIPTION
    Lists all system and user environment variables.

.PARAMETER Scope
    Machine, User, or Process.

.EXAMPLE
    .\Get-EnvironmentVariables.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Machine", "User", "Process")]
    [string]$Scope = "Machine"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Environment Variables ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Scope: $Scope" -ForegroundColor Gray
Write-Host ""

$vars = [Environment]::GetEnvironmentVariables($Scope)

Write-Host "System Variables:" -ForegroundColor Yellow

foreach ($key in $vars.Keys | Sort-Object) {
    $value = $vars[$key]
    
    if ($value.Length -gt 80) {
        $value = $value.Substring(0, 80) + "..."
    }
    
    Write-Host "  $key = $value" -ForegroundColor White
}

Write-Host ""
Write-Host "RESULT:OK - Variables listed" -ForegroundColor Green
exit 0
