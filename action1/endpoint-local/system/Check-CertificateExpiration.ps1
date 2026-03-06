<#
.SYNOPSIS
    Checks certificates expiring soon.

.DESCRIPTION
    Checks local machine and user certificates expiring within specified days.
    Useful for monitoring SSL certs, code signing certs, etc.

.PARAMETER Days
    Warn if cert expires within this many days. Default: 30.

.PARAMETER Store
    Certificate store to check. Default: My (Personal).

.EXAMPLE
    .\Check-CertificateExpiration.ps1

.EXAMPLE
    .\Check-CertificateExpiration.ps1 -Days 60
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Days = 30,

    [Parameter(Mandatory=$false)]
    [string]$Store = "My"
)

$ErrorActionPreference = 'SilentlyContinue'

$warningDate = (Get-Date).AddDays($Days)

Write-Host "=== Certificate Expiration Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Warning Threshold: $Days days" -ForegroundColor Gray
Write-Host ""

$expiring = @()
$expired = @()

$stores = @("LocalMachine\$Store", "CurrentUser\$Store")

foreach ($storePath in $stores) {
    $certs = Get-ChildItem -Path "Cert:\$storePath" -ErrorAction SilentlyContinue
    
    if ($certs) {
        foreach ($cert in $certs) {
            if ($cert.NotAfter -lt $warningDate) {
                $storeType = if ($storePath -like "LocalMachine*") { "Machine" } else { "User" }
                
                $obj = [PSCustomObject]@{
                    Subject    = $cert.Subject -replace "CN=", ""
                    Issuer     = $cert.Issuer -replace "CN=", ""
                    Expires    = $cert.NotAfter
                    DaysLeft   = ($cert.NotAfter - (Get-Date)).Days
                    Store      = $storeType
                    Thumbprint = $cert.Thumbprint
                }
                
                if ($cert.NotAfter -lt (Get-Date)) {
                    $expired += $obj
                } else {
                    $expiring += $obj
                }
            }
        }
    }
}

if ($expired.Count -gt 0) {
    Write-Host "EXPIRED CERTIFICATES:" -ForegroundColor Red
    $expired | Sort-Object Expires | Format-Table Subject, Expires, Store, Thumbprint -AutoSize | Out-String | Write-Host
}

if ($expiring.Count -gt 0) {
    Write-Host "EXPIRING SOON (within $Days days):" -ForegroundColor Yellow
    $expiring | Sort-Object DaysLeft | Format-Table Subject, Expires, DaysLeft, Store -AutoSize | Out-String | Write-Host
}

if ($expired.Count -eq 0 -and $expiring.Count -eq 0) {
    Write-Host "No certificates expiring within $Days days" -ForegroundColor Green
}

Write-Host ""
Write-Host "Summary: $expired.Count expired, $($expiring.Count) expiring soon" -ForegroundColor White

if ($expired.Count -gt 0) {
    Write-Host "RESULT:CRITICAL - $($expired.Count) certificate(s) expired" -ForegroundColor Red
    exit 2
} elseif ($expiring.Count -gt 0) {
    Write-Host "RESULT:WARNING - $($expiring.Count) certificate(s) expiring soon" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - All certificates OK" -ForegroundColor Green
    exit 0
}
