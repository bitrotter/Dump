<#
.SYNOPSIS
    Checks local audit policy settings.

.DESCRIPTION
    Reports configured audit policies for security compliance.

.EXAMPLE
    .\Check-AuditPolicy.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Audit Policy Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Audit Policy Settings:" -ForegroundColor Yellow

$audit = auditpol /get /category:* 2>&1 | Out-String

$lines = $audit -split "`n"

$currentCategory = ""

foreach ($line in $lines) {
    if ($line -match "^[^a-zA-Z]*(.+):$") {
        $currentCategory = $Matches[1].Trim()
    } elseif ($line -match "Success and Failure") {
        Write-Host "  $currentCategory : Success and Failure" -ForegroundColor Green
    } elseif ($line -match "Success") {
        Write-Host "  $currentCategory : Success" -ForegroundColor Yellow
    } elseif ($line -match "Failure") {
        Write-Host "  $currentCategory : Failure" -ForegroundColor Yellow
    } elseif ($line -match "No Auditing") {
        Write-Host "  $currentCategory : No Auditing" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Key Policies:" -ForegroundColor Yellow

$keyPol = @(
    "Logon",
    "Object Access",
    "Policy Change",
    "Account Management"
)

foreach ($pol in $keyPol) {
    $result = auditpol /get /subcategory:"$pol" 2>&1
    
    if ($result -match "Success and Failure") {
        Write-Host "  $pol : Enabled" -ForegroundColor Green
    } elseif ($result -match "Success") {
        Write-Host "  $pol : Success Only" -ForegroundColor Yellow
    } else {
        Write-Host "  $pol : Not Configured" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "RESULT:OK - Audit policy checked" -ForegroundColor Green
exit 0
