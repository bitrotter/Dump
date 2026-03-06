<#
.SYNOPSIS
    Checks Windows activation status.

.DESCRIPTION
    Reports Windows and Office activation status.

.EXAMPLE
    .\Check-WindowsActivation.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Windows Activation ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Windows Status:" -ForegroundColor Yellow

$slmgr = cscript //nologo $env:SystemRoot\System32\slmgr.vbs /xpr 2>&1

if ($slmgr -match "licensed") {
    Write-Host "  Status: Licensed" -ForegroundColor Green
} elseif ($slmgr -match "trial") {
    Write-Host "  Status: Trial" -ForegroundColor Yellow
} else {
    Write-Host "  Status: Unlicensed" -ForegroundColor Red
}

$slmgrDtls = cscript //nologo $env:SystemRoot\System32\slmgr.vbs /dlv 2>&1 | Select-Object -First 20

foreach ($line in $slmgrDtls) {
    if ($line -match "Partial Product Key") {
        Write-Host "  Partial Key: $($line.Split(':')[1].Trim())" -ForegroundColor Gray
    }
    if ($line -match "Activation ID") {
        Write-Host "  Activation ID: $($line.Split(':')[1].Trim())" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Office Status:" -ForegroundColor Yellow

$officePaths = @(
    "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration",
    "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot"
)

foreach ($path in $officePaths) {
    if (Test-Path $path) {
        $config = Get-ItemProperty -Path $path
        
        if ($config.Platform) {
            Write-Host "  Office 365: Detected" -ForegroundColor Green
            
            try {
                $office = "$env:ProgramFiles\Microsoft Office\root\Office16\OSPPREARM.EXE"
                if (Test-Path $office) {
                    Write-Host "  License Tool: Present" -ForegroundColor Gray
                }
            } catch { }
        }
    }
}

Write-Host ""
Write-Host "RESULT:OK - Activation checked" -ForegroundColor Green
exit 0
