<#
.SYNOPSIS
    Checks hosts file for issues.

.DESCRIPTION
    Analyzes hosts file for malicious entries and issues.

.EXAMPLE
    .\Check-HostsFile.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Hosts File Check ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

Write-Host "Hosts File: $hostsPath" -ForegroundColor Yellow
Write-Host ""

if (Test-Path $hostsPath) {
    $hostsContent = Get-Content $hostsPath
    
    Write-Host "Total lines: $($hostsContent.Count)" -ForegroundColor White
    
    $entries = @()
    $localhost = @()
    $comments = 0
    
    foreach ($line in $hostsContent) {
        $trimmed = $line.Trim()
        
        if ($trimmed -match "^#") {
            $comments++
        } elseif ($trimmed -match "^\s*$") {
            # empty line
        } else {
            $entries += $trimmed
            
            if ($trimmed -match "127\.0\.0\.1|::1") {
                $localhost += $trimmed
            }
        }
    }
    
    Write-Host "Comment lines: $comments" -ForegroundColor Gray
    Write-Host "Active entries: $($entries.Count)" -ForegroundColor White
    
    Write-Host ""
    Write-Host "Localhost Entries:" -ForegroundColor Yellow
    
    foreach ($entry in $localhost) {
        Write-Host "  $entry" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Non-localhost Entries:" -ForegroundColor Yellow
    
    $external = $entries | Where-Object { $_ -notmatch "127\.0\.0\.1|::1|localhost" }
    
    if ($external) {
        foreach ($entry in $external) {
            Write-Host "  $entry" -ForegroundColor White
        }
    } else {
        Write-Host "  None" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Suspicious Entries:" -ForegroundColor Red
    
    $suspicious = $entries | Where-Object { 
        $_ -match "(microsoft|google|apple|amazon|facebook|windowsupdate|dns|adobe)" -and 
        $_ -notmatch "localhost" -and 
        $_ -notmatch "127\.0\.0\.1"
    }
    
    if ($suspicious) {
        foreach ($entry in $suspicious) {
            Write-Host "  $entry" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  None found" -ForegroundColor Green
    }
    
    $lastModified = (Get-Item $hostsPath).LastWriteTime
    Write-Host ""
    Write-Host "Last Modified: $lastModified" -ForegroundColor Gray
    
} else {
    Write-Host "Hosts file not found!" -ForegroundColor Red
}

Write-Host ""

if ($suspicious.Count -gt 0) {
    Write-Host "RESULT:WARNING - Suspicious entries found" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Hosts file OK" -ForegroundColor Green
    exit 0
}
