<#
.SYNOPSIS
    Checks Hyper-V status.

.DESCRIPTION
    Reports Hyper-V role and virtual machines.

.EXAMPLE
    .\Check-HyperVStatus.ps1
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Hyper-V Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

Write-Host "Hyper-V Role:" -ForegroundColor Yellow

$hyperv = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V" -ErrorAction SilentlyContinue

if ($hyperv) {
    if ($hyperv.State -eq "Enabled") {
        Write-Host "  Installed: Yes" -ForegroundColor Green
    } else {
        Write-Host "  Installed: No" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Hyper-V Services:" -ForegroundColor Yellow

$services = @("vmcompute", "vmms", "vhdsvc")

foreach ($svc in $services) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        $color = if ($service.Status -eq "Running") { "Green" } else { "Yellow" }
        Write-Host "  $svc : $($service.Status)" -ForegroundColor $color
    }
}

Write-Host ""
Write-Host "Virtual Machines:" -ForegroundColor Yellow

try {
    $vms = Get-VM -ErrorAction SilentlyContinue
    
    if ($vms) {
        foreach ($vm in $vms) {
            $state = $vm.State
            $color = if ($state -eq "Running") { "Green" } else { "Gray" }
            Write-Host "  $($vm.Name): $state" -ForegroundColor $color
        }
    } else {
        Write-Host "  No VMs found" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Cannot enumerate VMs (may need admin)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Virtual Switches:" -ForegroundColor Yellow

try {
    $switches = Get-VMSwitch -ErrorAction SilentlyContinue
    
    if ($switches) {
        foreach ($sw in $switches) {
            Write-Host "  $($sw.Name) - $($sw.SwitchType)" -ForegroundColor White
        }
    } else {
        Write-Host "  No virtual switches" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Cannot get switches" -ForegroundColor Gray
}

Write-Host ""

if ($hyperv -and $hyperv.State -eq "Enabled") {
    Write-Host "RESULT:OK - Hyper-V available" -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT:OK - Hyper-V not enabled" -ForegroundColor Green
    exit 0
}
