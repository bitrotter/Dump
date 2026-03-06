<#
.SYNOPSIS
    Exports PowerShell history.

.DESCRIPTION
    Exports command history from current session.

.PARAMETER OutputPath
    Path to save history file.

.EXAMPLE
    .\Export-PowerShellHistory.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$env:TEMP\PSHistory_$env:COMPUTERNAME.txt"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== PowerShell History ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$history = Get-History

Write-Host "Commands in history: $($history.Count)" -ForegroundColor White

$history | ForEach-Object {
    "$($_.ExecutionTime) - $($_.CommandLine)"
} | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Saved to: $OutputPath" -ForegroundColor Green

Write-Host ""
Write-Host "RESULT:OK - History exported" -ForegroundColor Green
exit 0
