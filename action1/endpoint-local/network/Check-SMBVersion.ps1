<#
.SYNOPSIS
    Checks SMB protocol version and settings.

.DESCRIPTION
    Reports SMB version, status, and security settings.

.PARAMETER ShowDetails
    Show detailed SMB configuration.

.EXAMPLE
    .\Check-SMBVersion.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== SMB Version Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "SMB1 Status:" -ForegroundColor Yellow

$smb1 = (Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol).State

if ($smb1 -eq "Enabled") {
    Write-Host "  SMB1: Enabled (INSECURE)" -ForegroundColor Red
} else {
    Write-Host "  SMB1: Disabled" -ForegroundColor Green
}

Write-Host ""
Write-Host "SMB2/3 Status:" -ForegroundColor Yellow

$smb2 = (Get-SmbServerConfiguration).EnableSMB2Protocol

if ($smb2) {
    Write-Host "  SMB2: Enabled" -ForegroundColor Green
} else {
    Write-Host "  SMB2: Disabled" -ForegroundColor Red
}

Write-Host ""
Write-Host "SMB Configuration:" -ForegroundColor Yellow

$smbServer = Get-SmbServerConfiguration

Write-Host "  Max Protocol: $($smbServer.MaxSMB2ProtocolVersion)" -ForegroundColor White
Write-Host "  Min Protocol: $($smbServer.MinSMB2ProtocolVersion)" -ForegroundColor Gray
Write-Host "  Encrypt Data: $($smbServer.EncryptData)" -ForegroundColor $(if ($smbServer.EncryptData) { "Green" } else { "Yellow" })
Write-Host "  Require Security Signatures: $($smbServer.RequireSecuritySignatures)" -ForegroundColor $(if ($smbServer.RequireSecuritySignatures) { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "SMB Shares:" -ForegroundColor Yellow

$shares = Get-SmbShare -ErrorAction SilentlyContinue

if ($shares) {
    foreach ($share in $shares) {
        $encrypt = if ($share.EncryptData) { "Yes" } else { "No" }
        $color = if ($share.EncryptData) { "Green" } else { "Gray" }
        
        Write-Host "  $($share.Name) -> $($share.Path) (Encrypted: $encrypt)" -ForegroundColor $color
    }
} else {
    Write-Host "  No shares configured" -ForegroundColor Gray
}

if ($ShowDetails) {
    Write-Host ""
    Write-Host "Detailed Settings:" -ForegroundColor Cyan
    
    $smbServer.PSObject.Properties | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor Gray
    }
}

Write-Host ""

if ($smb1 -eq "Enabled") {
    Write-Host "RESULT:CRITICAL - SMB1 is enabled (security risk)" -ForegroundColor Red
    exit 2
} elseif (-not $smb2) {
    Write-Host "RESULT:WARNING - SMB2 is disabled" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - SMB configured securely" -ForegroundColor Green
    exit 0
}
