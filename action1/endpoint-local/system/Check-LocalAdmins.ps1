<#
.SYNOPSIS
    Lists local administrators on the system.

.DESCRIPTION
    Shows members of the Administrators group and can identify
    unauthorized admin accounts.

.PARAMETER CompareFile
    Path to file with expected admin users (one per line).

.EXAMPLE
    .\Check-LocalAdmins.ps1

.EXAMPLE
    .\Check-LocalAdmins.ps1 -CompareFile "C:\expected_admins.txt"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$CompareFile
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Local Administrators ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Administrators Group Members:" -ForegroundColor Yellow

$adminGroup = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue

if ($adminGroup) {
    foreach ($member in $adminGroup) {
        $type = $member.ObjectClass
        $source = if ($member.PrincipalSource -eq "Local") { "Local" } elseif ($member.PrincipalSource -eq "ActiveDirectory") { "AD" } else { "Other" }
        
        $color = switch ($source) {
            "Local" { "Yellow" }
            "AD" { "Green" }
            default { "Gray" }
        }
        
        Write-Host "  $($member.Name)" -ForegroundColor White
        Write-Host "    Type: $type | Source: $source" -ForegroundColor $color
    }
} else {
    Write-Host "  Could not retrieve members" -ForegroundColor Red
}

Write-Host ""
Write-Host "Remote Desktop Users Group:" -ForegroundColor Yellow

$rdpGroup = Get-LocalGroupMember -Group "Remote Desktop Users" -ErrorAction SilentlyContinue

if ($rdpGroup) {
    foreach ($member in $rdpGroup) {
        Write-Host "  $($member.Name)" -ForegroundColor White
    }
} else {
    Write-Host "  No members or group not found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Remote Management Users:" -ForegroundColor Yellow

$remoteMgmt = Get-LocalGroupMember -Group "Remote Management Users" -ErrorAction SilentlyContinue

if ($remoteMgmt) {
    foreach ($member in $remoteMgmt) {
        Write-Host "  $($member.Name)" -ForegroundColor White
    }
} else {
    Write-Host "  No members" -ForegroundColor Gray
}

if ($CompareFile -and (Test-Path $CompareFile)) {
    Write-Host ""
    Write-Host "Comparison with expected admins:" -ForegroundColor Yellow
    
    $expected = Get-Content $CompareFile
    $current = $adminGroup.Name
    
    $unexpected = @()
    $missing = @()
    
    foreach ($exp in $expected) {
        if ($current -notcontains $exp) {
            $missing += $exp
        }
    }
    
    foreach ($cur in $current) {
        if ($expected -notcontains $cur) {
            $unexpected += $cur
        }
    }
    
    if ($unexpected.Count -gt 0) {
        Write-Host "  Unexpected admins: $($unexpected -join ', ')" -ForegroundColor Red
    }
    
    if ($missing.Count -gt 0) {
        Write-Host "  Missing expected: $($missing -join ', ')" -ForegroundColor Yellow
    }
    
    if ($unexpected.Count -eq 0 -and $missing.Count -eq 0) {
        Write-Host "  All expected admins present" -ForegroundColor Green
    }
}

Write-Host ""

$localAdmins = ($adminGroup | Where-Object { $_.PrincipalSource -eq "Local" }).Count

if ($localAdmins -gt 3) {
    Write-Host "RESULT:WARNING - High number of local admins ($localAdmins)" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Admin count normal" -ForegroundColor Green
    exit 0
}
