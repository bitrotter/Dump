<#
.SYNOPSIS
    Checks proxy configuration.

.DESCRIPTION
    Reports system and browser proxy settings.

.PARAMETER Reset
    Reset proxy settings to automatic.

.EXAMPLE
    .\Check-ProxySettings.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Reset
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Proxy Settings ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Internet Explorer / System Proxy:" -ForegroundColor Yellow

$proxy = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

Write-Host "  Proxy Enable: $($proxy.ProxyEnable)" -ForegroundColor White

if ($proxy.ProxyServer) {
    Write-Host "  Proxy Server: $($proxy.ProxyServer)" -ForegroundColor Yellow
} else {
    Write-Host "  Proxy Server: Not configured"
}

if -ForegroundColor Gray ($proxy.ProxyOverride) {
    Write-Host "  Override: $($proxy.ProxyOverride)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Auto-Config URL:" -ForegroundColor Yellow

if ($proxy.AutoConfigURL) {
    Write-Host "  PAC URL: $($proxy.AutoConfigURL)" -ForegroundColor Yellow
} else {
    Write-Host "  PAC URL: Not configured" -ForegroundColor Gray
}

Write-Host ""
Write-Host "WinHTTP Proxy:" -ForegroundColor Yellow

$winhttp = netsh winhttp show proxy

if ($winhttp -match "Direct access") {
    Write-Host "  WinHTTP: Direct access" -ForegroundColor Green
} else {
    Write-Host "  WinHTTP: $winhttp" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Environment Variables:" -ForegroundColor Yellow

$httpProxy = [Environment]::GetEnvironmentVariable("HTTP_PROXY", "User")
$httpsProxy = [Environment]::GetEnvironmentVariable("HTTPS_PROXY", "User")

if ($httpProxy) {
    Write-Host "  HTTP_PROXY: $httpProxy" -ForegroundColor Yellow
}
if ($httpsProxy) {
    Write-Host "  HTTPS_PROXY: $httpsProxy" -ForegroundColor Yellow
}
if (-not $httpProxy -and -not $httpsProxy) {
    Write-Host "  No proxy variables set" -ForegroundColor Gray
}

if ($Reset) {
    Write-Host ""
    Write-Host "Resetting proxy settings..." -ForegroundColor Yellow
    
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "ProxyEnable" -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "ProxyServer" -Value ""
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "AutoConfigURL" -Value ""
    
    netsh winhttp reset proxy | Out-Null
    
    Write-Host "  Proxy reset complete" -ForegroundColor Green
}

Write-Host ""

if ($proxy.ProxyEnable -eq 1 -and $proxy.ProxyServer) {
    Write-Host "RESULT:WARNING - Manual proxy configured" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Proxy settings normal" -ForegroundColor Green
    exit 0
}
