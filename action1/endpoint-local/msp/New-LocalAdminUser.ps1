<#
.SYNOPSIS
    Creates or resets a local administrator account.

.DESCRIPTION
    Creates a new local admin user or resets an existing user's password.

.PARAMETER Username
    Username to create or reset.

.PARAMETER Password
    Password for the account (required for create).

.PARAMETER MakeAdmin
    Add user to Administrators group.

.PARAMETER RemoveAdmin
    Remove user from Administrators group.

.EXAMPLE
    .\New-LocalAdminUser.ps1 -Username "support" -Password "P@ssw0rd!" -MakeAdmin

.EXAMPLE
    .\New-LocalAdminUser.ps1 -Username "support" -ResetPassword -Password "NewP@ssw0rd!"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Username,

    [Parameter(Mandatory=$false)]
    [string]$Password,

    [Parameter(Mandatory=$false)]
    [switch]$MakeAdmin,

    [Parameter(Mandatory=$false)]
    [switch]$RemoveAdmin,

    [Parameter(Mandatory=$false)]
    [switch]$ResetPassword
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Local Admin User Management ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if (-not $Username) {
    Write-Host "Current Local Administrators:" -ForegroundColor Yellow
    
    $admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
    
    foreach ($admin in $admins) {
        $source = $admin.PrincipalSource
        $type = $admin.ObjectClass
        
        Write-Host "  $($admin.Name) ($type - $source)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "RESULT:OK - List complete (specify -Username to manage)" -ForegroundColor Green
    exit 0
}

Write-Host "Managing user: $Username" -ForegroundColor Yellow

$existingUser = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue

if ($existingUser) {
    Write-Host "  User exists: Yes" -ForegroundColor White
    
    if ($ResetPassword -and $Password) {
        Write-Host "  Resetting password..." -ForegroundColor Yellow
        
        $securePass = ConvertTo-SecureString $Password -AsPlainText -Force
        Set-LocalUser -Name $Username -Password $securePass
        
        Write-Host "  Password reset complete" -ForegroundColor Green
    }
    
    if ($MakeAdmin) {
        Write-Host "  Adding to Administrators..." -ForegroundColor Yellow
        
        Add-LocalGroupMember -Group "Administrators" -Member $Username -ErrorAction SilentlyContinue
        
        Write-Host "  Added to Administrators" -ForegroundColor Green
    }
    
    if ($RemoveAdmin) {
        Write-Host "  Removing from Administrators..." -ForegroundColor Yellow
        
        Remove-LocalGroupMember -Group "Administrators" -Member $Username -ErrorAction SilentlyContinue
        
        Write-Host "  Removed from Administrators" -ForegroundColor Green
    }
    
} else {
    Write-Host "  User exists: No" -ForegroundColor White
    
    if ($Password) {
        Write-Host "  Creating user..." -ForegroundColor Yellow
        
        $securePass = ConvertTo-SecureString $Password -AsPlainText -Force
        
        New-LocalUser -Name $Username -Password $securePass -Description "Created by MSP Script" -ErrorAction Stop
        
        Write-Host "  User created" -ForegroundColor Green
        
        if ($MakeAdmin) {
            Write-Host "  Adding to Administrators..." -ForegroundColor Yellow
            
            Add-LocalGroupMember -Group "Administrators" -Member $Username -ErrorAction SilentlyContinue
            
            Write-Host "  Added to Administrators" -ForegroundColor Green
        }
    } else {
        Write-Host "  ERROR: Password required to create user" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Final Status:" -ForegroundColor Yellow

$user = Get-LocalUser -Name $Username

Write-Host "  Username: $($user.Name)" -ForegroundColor White
Write-Host "  Enabled: $($user.Enabled)" -ForegroundColor $(if ($user.Enabled) { "Green" } else { "Red" })
Write-Host "  Last Login: $($user.LastLogon)" -ForegroundColor Gray

$isAdmin = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $Username }

if ($isAdmin) {
    Write-Host "  Admin: Yes" -ForegroundColor Green
} else {
    Write-Host "  Admin: No" -ForegroundColor Gray
}

Write-Host ""
Write-Host "RESULT:OK - User management complete" -ForegroundColor Green
exit 0
