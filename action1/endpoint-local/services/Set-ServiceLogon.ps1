<#
.SYNOPSIS
    Changes service logon account.

.DESCRIPTION
    Changes the account a service runs under.

.PARAMETER ServiceName
    Service name.

.PARAMETER Username
    New username (e.g., "NT AUTHORITY\LocalService").

.PARAMETER Password
    Password (not needed for built-in accounts).

.EXAMPLE
    .\Set-ServiceLogon.ps1 -ServiceName "MyService" -Username "NT AUTHORITY\LocalSystem"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName,

    [Parameter(Mandatory=$false)]
    [string]$Username,

    [Parameter(Mandatory=$false)]
    [string]$Password
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Set Service Logon ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $ServiceName -or -not $Username) {
    Write-Host "Usage: Set-ServiceLogon -ServiceName <name> -Username <account>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common accounts:" -ForegroundColor Gray
    Write-Host "  NT AUTHORITY\LocalSystem" -ForegroundColor Gray
    Write-Host "  NT AUTHORITY\LocalService" -ForegroundColor Gray
    Write-Host "  NT AUTHORITY\NetworkService" -ForegroundColor Gray
    Write-Host "  Domain\User" -ForegroundColor Gray
    exit 0
}

Write-Host "Changing $ServiceName to $Username..." -ForegroundColor Yellow

try {
    if ($Password) {
        $secPass = ConvertTo-SecureString $Password -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($Username, $secPass)
        
        Invoke-Expression "sc.exe config `"$ServiceName`" obj= `"$Username`" password= `"$Password`""
    } else {
        Invoke-Expression "sc.exe config `"$ServiceName`" obj= `"$Username`""
    }
    
    Write-Host "  Account changed" -ForegroundColor Green
    
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "RESULT:OK - Service logon changed" -ForegroundColor Green
exit 0
