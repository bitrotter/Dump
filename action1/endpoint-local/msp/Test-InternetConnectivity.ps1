<#
.SYNOPSIS
    Tests internet connectivity through multiple methods.

.DESCRIPTION
    Tests connectivity to various endpoints to diagnose
    internet access issues.

.EXAMPLE
    .\Test-InternetConnectivity.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Internet Connectivity Test ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Testing multiple endpoints..." -ForegroundColor Yellow
Write-Host ""

$tests = @{
    "Google DNS" = "8.8.8.8"
    "Cloudflare DNS" = "1.1.1.1"
    "Microsoft" = "microsoft.com"
    "Google" = "google.com"
    "Amazon" = "amazon.com"
    "Cloudflare" = "cloudflare.com"
    "GitHub" = "github.com"
    "Office 365" = "outlook.office365.com"
}

$passed = 0
$failed = 0

foreach ($test in $tests.GetEnumerator()) {
    $result = Test-Connection -ComputerName $test.Value -Count 1 -Quiet
    
    if ($result) {
        Write-Host "  $($test.Key): OK" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  $($test.Key): FAILED" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } elseif ($passed -gt 0) { "Yellow" } else { "Red" })

Write-Host ""
Write-Host "Web Request Test:" -ForegroundColor Yellow

$websites = @(
    "https://www.google.com",
    "https://www.microsoft.com",
    "https://www.cloudflare.com"
)

foreach ($site in $websites) {
    try {
        $response = Invoke-WebRequest -Uri $site -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Host "  $site : HTTP $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "  $site : FAILED" -ForegroundColor Red
    }
}

Write-Host ""

if ($failed -gt 5) {
    Write-Host "RESULT:CRITICAL - Major connectivity issues" -ForegroundColor Red
    exit 2
} elseif ($failed -gt 0) {
    Write-Host "RESULT:WARNING - Partial connectivity issues" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Full connectivity" -ForegroundColor Green
    exit 0
}
