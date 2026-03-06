<#
.SYNOPSIS
    Checks current user logon rights and last logon info.

.DESCRIPTION
    Reports who is currently logged on and last logon time for local users.

.PARAMETER ShowAllUsers
    Show all local users and their last logon.

.EXAMPLE
    .\Check-UserLogon.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowAllUsers
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== User Logon Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Currently Logged On Users:" -ForegroundColor Yellow

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
Write-Host "  Current User: $($currentUser.Name)" -ForegroundColor Green
Write-Host "  Authentication: $($currentUser.AuthenticationType)" -ForegroundColor Gray

Write-Host ""
Write-Host "Explorer Sessions:" -ForegroundColor Yellow

$explorer = Get-Process -Name explorer -ErrorAction SilentlyContinue

if ($explorer) {
    $loggedInUsers = @()
    
    foreach ($proc in $explorer) {
        try {
            $owner = $proc.GetOwner()
            $userName = "$($owner.Domain)\$($owner.User)"
            
            if ($userName -and $userName -notlike "NT AUTHORITY*") {
                $loggedInUsers += $userName
            }
        } catch { }
    }
    
    $uniqueUsers = $loggedInUsers | Sort-Object -Unique
    
    foreach ($user in $uniqueUsers) {
        Write-Host "  $user" -ForegroundColor Green
    }
} else {
    Write-Host "  No explorer sessions" -ForegroundColor Gray
}

Write-Host ""
Write-Host "User Session Query:" -ForegroundColor Yellow

try {
    $sessions = query user 2>$null
    
    if ($sessions) {
        $sessions | Select-Object -Skip 1 | ForEach-Object {
            $line = $_.Trim()
            if ($line) {
                $parts = $line -split "\s+"
                $username = $parts[1] -replace ">", ""
                $state = $parts[2]
                
                $color = if ($state -eq "Active") { "Green" } else { "Yellow" }
                Write-Host "  $username - $state" -ForegroundColor $color
            }
        }
    }
} catch {
    Write-Host "  Could not query sessions" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Last Logon Information:" -ForegroundColor Yellow

$lastLogon = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$lastLogonTime = $lastLogon.Name

Write-Host "  Current Identity: $lastLogonTime" -ForegroundColor White

try {
    $lastUser = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -ErrorAction SilentlyContinue
    
    if ($lastUser -and $lastUser.LogonUser) {
        Write-Host "  Last Explorer User: $($lastUser.LogonUser)" -ForegroundColor Gray
    }
} catch { }

if ($ShowAllUsers) {
    Write-Host ""
    Write-Host "Local Users:" -ForegroundColor Yellow
    
    $localUsers = Get-LocalUser -ErrorAction SilentlyContinue
    
    if ($localUsers) {
        foreach ($user in $localUsers) {
            $lastLogonInfo = try { 
                $adsi = [ADSI]"WinNT://$env:COMPUTERNAME/$($user.Name),user"
                $adsi.LastLogin
            } catch { "Unknown" }
            
            $status = if ($user.Enabled) { "Enabled" } else { "Disabled" }
            $color = if ($user.Enabled) { "Green" } else { "Gray" }
            
            Write-Host "  $($user.Name) - Last: $lastLogonInfo ($status)" -ForegroundColor $color
        }
    }
}

Write-Host ""
Write-Host "RESULT:OK - User check complete" -ForegroundColor Green
exit 0
