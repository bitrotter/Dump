<#
.SYNOPSIS
    Checks page file configuration.

.DESCRIPTION
    Reports page file size and settings.

.PARAMETER AutoManage
    Let Windows manage page file.

.EXAMPLE
    .\Check-PageFileSettings.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$AutoManage
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Page File Settings ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$pf = Get-CimInstance Win32_PageFile

if ($pf) {
    foreach ($file in $pf) {
        Write-Host "Page File: $($file.Name)" -ForegroundColor Yellow
        Write-Host "  Initial Size: $($file.InitialSize) MB" -ForegroundColor White
        Write-Host "  Maximum Size: $($file.MaximumSize) MB" -ForegroundColor White
        
        if (Test-Path $file.Name) {
            $size = (Get-Item $file.Name).Length
            $sizeMB = [math]::Round($size / 1MB, 2)
            Write-Host "  Current Size: $sizeMB MB" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "No page file configured" -ForegroundColor Gray
}

Write-Host ""
Write-Host "System Managed:" -ForegroundColor Yellow

$syspf = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -ErrorAction SilentlyContinue

if ($syspf.PagingFiles -match ":\\.*pagefile.sys") {
    if ($syspf.PagingFiles -match "0 0") {
        Write-Host "  System managed: Yes" -ForegroundColor Green
    } else {
        Write-Host "  Custom configuration" -ForegroundColor White
        Write-Host "  $($syspf.PagingFiles)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Memory Info:" -ForegroundColor Yellow

$os = Get-CimInstance Win32_OperatingSystem
$totalMem = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
$freeMem = [math]::Round($os.FreePhysicalMemory / 1024, 0)
$usedMem = $totalMem - $freeMem

Write-Host "  Total: $totalMem MB" -ForegroundColor White
Write-Host "  Free: $freeMem MB" -ForegroundColor Green
Write-Host "  Used: $usedMem MB" -ForegroundColor Gray

$recommendedPF = [math]::Round($totalMem * 1.5 / 1024, 0)
Write-Host "  Recommended PF: ~$recommendedPF MB" -ForegroundColor Yellow

if ($AutoManage) {
    Write-Host ""
    Write-Host "Enabling automatic page file management..." -ForegroundColor Yellow
    
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -Value ("$env:SystemDrive\pagefile.sys 0 0")
    
    Write-Host "  Enabled" -ForegroundColor Green
}

Write-Host ""

if (-not $pf) {
    Write-Host "RESULT:WARNING - No page file configured" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Page file configured" -ForegroundColor Green
    exit 0
}
