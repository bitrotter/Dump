<#
.SYNOPSIS
    Tests SSL certificate on a website.

.DESCRIPTION
    Checks SSL certificate validity and expiration.

.PARAMETER Hostname
    Website to test.

.PARAMETER Port
    SSL port. Default: 443.

.EXAMPLE
    .\Test-SSLCertificate.ps1 -Hostname "google.com"

.EXAMPLE
    .\Test-SSLCertificate.ps1 -Hostname "mail.company.com" -Port 993
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Hostname = "google.com",

    [Parameter(Mandatory=$false)]
    [int]$Port = 443
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== SSL Certificate Test ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Testing: $Hostname`:$Port" -ForegroundColor Gray
Write-Host ""

try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect($Hostname, $Port)
    $tcp.Close()
    
    Write-Host "Connection: Success" -ForegroundColor Green
    
} catch {
    Write-Host "Connection: Failed - $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "RESULT:CRITICAL - Cannot connect" -ForegroundColor Red
    exit 2
}

try {
    $cert = Get-ChildItem -Path "Cert:\LocalMachine\My" -ErrorAction SilentlyContinue | Where-Object { $_.Subject -match $Hostname }
    
    if (-not $cert) {
        Write-Host "Local cert: Not found, fetching from server..." -ForegroundColor Yellow
        
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect($Hostname, $Port)
        
        $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, { $true })
        $ssl.AuthenticateAsClient($Hostname)
        
        $cert = $ssl.RemoteCertificate
        
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cert)
        
        $ssl.Close()
        $tcp.Close()
    }
    
    Write-Host ""
    Write-Host "Certificate Details:" -ForegroundColor Yellow
    Write-Host "  Subject: $($cert.Subject)" -ForegroundColor White
    Write-Host "  Issuer: $($cert.Issuer)" -ForegroundColor Gray
    Write-Host "  Valid From: $($cert.NotBefore)" -ForegroundColor Gray
    Write-Host "  Valid To: $($cert.NotAfter)" -ForegroundColor White
    
    $daysLeft = ($cert.NotAfter - (Get-Date)).Days
    
    Write-Host "  Days Remaining: $daysLeft" -ForegroundColor $(if ($daysLeft -lt 30) { "Red" } elseif ($daysLeft -lt 60) { "Yellow" } else { "Green" })
    
    Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Certificate Chain:" -ForegroundColor Yellow
    
    if ($cert.Verify()) {
        Write-Host "  Valid: Yes" -ForegroundColor Green
    } else {
        Write-Host "  Valid: No (may be self-signed)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    if ($daysLeft -lt 0) {
        Write-Host "RESULT:CRITICAL - Certificate expired" -ForegroundColor Red
        exit 2
    } elseif ($daysLeft -lt 30) {
        Write-Host "RESULT:WARNING - Certificate expires in $daysLeft days" -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "RESULT:OK - Certificate valid" -ForegroundColor Green
        exit 0
    }
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "RESULT:UNKNOWN - Could not verify certificate" -ForegroundColor Yellow
    exit 1
}
