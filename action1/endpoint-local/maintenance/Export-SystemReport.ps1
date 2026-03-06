<#
.SYNOPSIS
    Exports system info to text file.

.DESCRIPTION
    Generates comprehensive system report for support.

.PARAMETER OutputPath
    Path to save report.

.EXAMPLE
    .\Export-SystemReport.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$env:TEMP\SystemReport_$env:COMPUTERNAME.txt"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== System Report ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$report = @()

$report += "=== SYSTEM REPORT ==="
$report += "Computer: $env:COMPUTERNAME"
$report += "Date: $(Get-Date)"
$report += ""

$report += "=== OPERATING SYSTEM ==="
$os = Get-CimInstance Win32_OperatingSystem
$report += "$($os.Caption) Build $($os.BuildNumber)"
$report += "Last Boot: $($os.LastBootUpTime)"
$report += ""

$report += "=== HARDWARE ==="
$cs = Get-CimInstance Win32_ComputerSystem
$report += "Manufacturer: $($cs.Manufacturer)"
$report += "Model: $($cs.Model)"
$report += "RAM: $([math]::Round($cs.TotalPhysicalMemory/1GB, 2)) GB"

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$report += "CPU: $($cpu.Name)"
$report += ""

$report += "=== DISK ==="
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null } | ForEach-Object {
    $report += "$($_.Name): $([math]::Round($_.Free/1GB, 2)) GB free / $([math]::Round(($_.Used+$_.Free)/1GB, 2)) GB total"
}
$report += ""

$report += "=== NETWORK ==="
Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
    $ip = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
    $report += "$($_.Name): $($_.IPAddress) - $($_.Status)"
}
$report += ""

$report += "=== SERVICES ==="
$services = @("wuauserv", "BITS", "EventLog", "Spooler", "WinDefend")
foreach ($svc in $services) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        $report += "$($svc): $($s.Status)"
    }
}
$report += ""

$report += "=== SECURITY ==="
$report += "Firewall: $(Get-NetFirewallProfile | Where-Object { $_.Enabled } | Measure-Object).Count profiles enabled"
$report += "BitLocker: $((Get-BitLockerVolume -MountPoint C: -ErrorAction SilentlyContinue).ProtectionStatus)"
$report += ""

$report += "=== USERS ==="
$report += "Current User: $env:USERNAME"
$report += "Computer Name: $env:COMPUTERNAME"
$report += ""

$report | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Report saved to: $OutputPath" -ForegroundColor Green

Write-Host ""
Write-Host "RESULT:OK - Report exported" -ForegroundColor Green
exit 0
