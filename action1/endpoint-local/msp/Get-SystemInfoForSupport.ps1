<#
.SYNOPSIS
    Collects system information for MSP support tickets.

.DESCRIPTION
    Generates a comprehensive system report for troubleshooting
    and support ticket documentation.

.PARAMETER OutputFile
    Save report to file.

.EXAMPLE
    .\Get-SystemInfoForSupport.ps1

.EXAMPLE
    .\Get-SystemInfoForSupport.ps1 -OutputFile "C:\temp\sysinfo.txt"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

$ErrorActionPreference = 'SilentlyContinue'

$report = @()

function Add-Report {
    param([string]$Title, [string]$Content)
    $script:report += "=== $Title ==="
    $script:report += $Content
    $script:report += ""
}

$report += "=== MSP Support Report ==="
$report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "Computer: $env:COMPUTERNAME"
$report += ""

Add-Report "Operating System" (Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture | Format-List | Out-String)

Add-Report "Hardware" (@(
    "CPU: $((Get-CimInstance Win32_Processor).Name)"
    "RAM: $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)) GB"
    "Manufacturer: $((Get-CimInstance Win32_ComputerSystem).Manufacturer)"
    "Model: $((Get-CimInstance Win32_ComputerSystem).Model)"
) -join "`n")

Add-Report "Disk" (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null } | ForEach-Object { "$($_.Name): $([math]::Round($_.Free/1GB, 2)) GB free / $([math]::Round(($_.Used+$_.Free)/1GB, 2)) GB total" } | Out-String)

Add-Report "Network" (Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object { "$($_.Name): $($_.InterfaceDescription) - $($_.MacAddress)" } | Out-String)

Add-Report "Uptime" "Last Boot: $((Get-CimInstance Win32_OperatingSystem).LastBootUpTime) - Uptime: $(((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).Days) days"

Add-Report "Services" (Get-Service | Where-Object { $_.Status -ne "Running" -and $_.StartType -eq "Automatic" } | Select-Object -First 10 | Format-Table Name, Status, StartType -AutoSize | Out-String)

Add-Report "Windows Update" (Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 3 | Format-Table HotFixID, InstalledOn, InstalledBy -AutoSize | Out-String)

Add-Report "Antivirus" ((Get-MpComputerStatus).RealTimeProtectionEnabled)

Add-Report "BitLocker" (Get-BitLockerVolume -MountPoint C: | Select-Object VolumeStatus, ProtectionStatus | Format-List | Out-String)

$output = $report | Out-String

Write-Host $output -ForegroundColor Cyan

if ($OutputFile) {
    $output | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Report saved to: $OutputFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "RESULT:OK - System info collected" -ForegroundColor Green
exit 0
