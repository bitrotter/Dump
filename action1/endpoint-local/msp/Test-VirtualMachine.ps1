<#
.SYNOPSIS
    Detects if system is running in a virtual machine.

.DESCRIPTION
    Identifies virtualization platform and reports VM-specific info.

.EXAMPLE
    .\Test-VirtualMachine.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Virtual Machine Detection ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$isVM = $false

Write-Host "System Information:" -ForegroundColor Yellow

$cs = Get-CimInstance Win32_ComputerSystem

$manufacturer = $cs.Manufacturer
$model = $cs.Model

Write-Host "  Manufacturer: $manufacturer" -ForegroundColor White
Write-Host "  Model: $model" -ForegroundColor White

$vmVendors = @{
    "VMware" = "VMware"
    "VirtualBox" = "VirtualBox"
    "Hyper-V" = "Microsoft Corporation"
    "QEMU" = "QEMU"
    "KVM" = "KVM"
    "Xen" = "Xen"
    "Amazon" = "Amazon EC2"
    "Google" = "Google Compute"
    "Azure" = "Microsoft Corporation"
}

foreach ($vendor in $vmVendors.GetEnumerator()) {
    if ($manufacturer -match $vendor.Key -or $model -match $vendor.Key) {
        Write-Host ""
        Write-Host "Virtualization Platform: $($vendor.Value)" -ForegroundColor Yellow
        $isVM = $true
    }
}

if (-not $isVM) {
    Write-Host ""
    Write-Host "Platform: Physical Hardware" -ForegroundColor Green
}

Write-Host ""
Write-Host "CPU Features:" -ForegroundColor Yellow

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

$cpuName = $cpu.Name

if ($cpuName -match "Virtual") {
    Write-Host "  Virtual CPU detected" -ForegroundColor Yellow
    $isVM = $true
}

Write-Host "  Name: $cpuName" -ForegroundColor Gray

Write-Host ""
Write-Host "BIOS Information:" -ForegroundColor Yellow

$bios = Get-CimInstance Win32_BIOS

Write-Host "  Serial: $($bios.SerialNumber)" -ForegroundColor Gray
Write-Host "  Version: $($bios.SMBIOSBIOSVersion)" -ForegroundColor Gray

if ($bios.SerialNumber -match "VMWARE|VIRTUALBOX|Amazon EC2") {
    Write-Host "  VM Signature detected" -ForegroundColor Yellow
    $isVM = $true
}

Write-Host ""
Write-Host "Disk Drives:" -ForegroundColor Yellow

$disks = Get-CimInstance Win32_DiskDrive

foreach ($disk in $disks) {
    if ($disk.Model -match "Virtual|VMWare|VirtualBox") {
        Write-Host "  $($disk.Model) - Virtual disk detected" -ForegroundColor Yellow
        $isVM = $true
    } else {
        Write-Host "  $($disk.Model) - Physical" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Network Adapters:" -ForegroundColor Yellow

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($adapter in $adapters) {
    if ($adapter.InterfaceDescription -match "Virtual|VMware|VirtualBox|Hyper-V") {
        Write-Host "  $($adapter.Name) - Virtual adapter" -ForegroundColor Yellow
    }
}

Write-Host ""

if ($isVM) {
    Write-Host "RESULT:INFO - Virtual machine detected" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - Physical hardware confirmed" -ForegroundColor Green
    exit 0
}
