<#
.SYNOPSIS
    Checks currently logged in users.

.DESCRIPTION
    Lists all users currently logged into the system,
    including console and remote sessions.

.PARAMETER ShowDetails
    Show detailed session information.

.EXAMPLE
    .\Check-LoggedInUsers.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Logged In Users ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Explorer Sessions:" -ForegroundColor Yellow

$explorer = Get-Process -Name explorer -ErrorAction SilentlyContinue

if ($explorer) {
    $sessions = @()
    
    foreach ($proc in $explorer) {
        $session = Get-Process -Id $proc.SessionId -ErrorAction SilentlyContinue
        
        $user = switch ($proc.SessionId) {
            0 { "System" }
            1 { "Console" }
            2 { "RDP" }
            default { "Session $($proc.SessionId)" }
        }
        
        $sessions += [PSCustomObject]@{
            Username  = $proc.GetOwner().User
            Domain    = $proc.GetOwner().Domain
            SessionId = $proc.SessionId
            Type      = $user
        }
    }
    
    $sessions = $sessions | Sort-Object Username -Unique
    
    foreach ($s in $sessions) {
        if ($s.Username) {
            Write-Host "  $($s.Domain)\$($s.Username) ($($s.Type))" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  No explorer sessions found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "User Sessions:" -ForegroundColor Yellow

try {
    $sessions = query user /fo csv | ConvertFrom-Csv
    
    foreach ($session in $sessions) {
        $sessionName = $session.'USERNAME' -replace ">", ""
        $state = $session.'STATE'
        $id = $session.'SESSIONNAME'
        
        $color = switch ($state) {
            "Active" { "Green" }
            "Disc" { "Yellow" }
            default { "White" }
        }
        
        Write-Host "  $sessionName - $state ($id)" -ForegroundColor $color
        
        if ($ShowDetails) {
            Write-Host "    Session ID: $($session.SESSIONNAME)" -ForegroundColor Gray
            Write-Host "    Logon Time: $($session.'LOGON TIME')" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  Could not query user sessions" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Remote Desktop Sessions:" -ForegroundColor Yellow

try {
    $rdpSessions = Get-Process -Name "svchost" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle } 
    
    if ($rdpSessions) {
        $rdpSessions | ForEach-Object {
            Write-Host "  $($_.MainWindowTitle)" -ForegroundColor White
        }
    } else {
        Write-Host "  No active RDP sessions" -ForegroundColor Green
    }
} catch {
    Write-Host "  No RDP sessions detected" -ForegroundColor Green
}

Write-Host ""

$userCount = ($sessions | Measure-Object).Count

if ($userCount -gt 0) {
    Write-Host "RESULT:OK - $userCount user(s) logged in" -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT:WARNING - No users logged in" -ForegroundColor Yellow
    exit 1
}
