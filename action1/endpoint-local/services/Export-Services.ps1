<#
.SYNOPSIS
    Exports service configuration.

.DESCRIPTION
    Exports all services to CSV.

.PARAMETER OutputFile
    Output file path.

.EXAMPLE
    .\Export-Services.ps1 -OutputFile "C:\temp\services.csv"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "$env:TEMP\Services_$(Get-Date -Format 'yyyyMMdd').csv"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Export Services ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Exporting services to $OutputFile..." -ForegroundColor Yellow

$services = Get-Service | ForEach-Object {
    $wmi = Get-WmiObject Win32_Service -Filter "Name='$($_.Name)'" -ErrorAction SilentlyContinue
    
    [PSCustomObject]@{
        Name = $_.Name
        DisplayName = $_.DisplayName
        Status = $_.Status
        StartType = $_.StartType
        Path = if ($wmi) { $wmi.PathName }
        Description = if ($wmi) { $wmi.Description }
    }
}

$services | Export-Csv -Path $OutputFile -NoTypeInformation

Write-Host "  Exported $($services.Count) services" -ForegroundColor Green

Write-Host ""
Write-Host "RESULT:OK - Services exported" -ForegroundColor Green
exit 0
