#Requires -Version 7.0

<#
remote-admin-spectre.ps1

Spectre.Console-based TUI admin tool for remote Windows host management.
Rich, styled console interface with tables, menus, and progress indicators.

Features:
- Styled menus with better selection visualization
- Rich table formatting for processes, services, users
- Progress indicators for connectivity testing
- Panels for data organization
- Single DLL dependency (Spectre.Console)
- PowerShell-native event handling

Requirements:
- PowerShell 7+
- Spectre.Console NuGet package

SETUP:
From the tools directory:
  Option 1: nuget install Spectre.Console -OutputDirectory packages
  Option 2: See SETUP-SPECTRE.md

#>

param(
    [switch]$SkipInit = $false
)

# Try to load Spectre.Console from common locations
$spectrePaths = @(
    "./packages/Spectre.Console*/lib/net6.0/Spectre.Console.dll",
    "../packages/Spectre.Console*/lib/net6.0/Spectre.Console.dll",
    (Join-Path $PROFILE "..\packages\Spectre.Console*\lib\net6.0\Spectre.Console.dll")
)

$spectreDll = $null
foreach ($pattern in $spectrePaths) {
    $found = @(Resolve-Path $pattern -ErrorAction SilentlyContinue | Select-Object -Last 1)
    if ($found) {
        $spectreDll = $found[0].Path
        break
    }
}

if (-not $spectreDll) {
    Write-Host "Spectre.Console not found. Install it first:" -ForegroundColor Red
    Write-Host ""
    Write-Host "From the tools directory, run:"
    Write-Host "  nuget install Spectre.Console -OutputDirectory packages"
    Write-Host ""
    Write-Host "Or see SETUP-SPECTRE.md for alternatives"
    exit 1
}

[System.Reflection.Assembly]::LoadFrom($spectreDll) | Out-Null
Add-Type -AssemblyName System.Console

# Global state
$script:CurrentHost = $null
$script:CurrentSession = $null
$script:IsRunning = $true

function Test-RemoteConnectivity {
    param([string]$ComputerName)
    try {
        Test-WSMan -ComputerName $ComputerName -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function New-RemoteSession {
    param([string]$ComputerName, [PSCredential]$Credential)
    try {
        $s = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
        return $s
    } catch {
        return $null
    }
}

function Invoke-Remote {
    param($Session, [scriptblock]$Script)
    try {
        Invoke-Command -Session $Session -ScriptBlock $Script -ErrorAction Stop
    } catch {
        $_
    }
}

function Get-RemoteHealth {
    param($Session)
    $script = {
        $os = Get-CimInstance Win32_OperatingSystem
        $uptime = (Get-Date) - $os.LastBootUpTime
        $cpu = "{0:N1}%" -f ((Get-CimInstance Win32_Processor).LoadPercentage | Measure-Object -Average).Average
        $mem = Get-CimInstance Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory
        $memUsed = ((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize - (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory) * 1024
        $memPct = "{0:N1}%" -f (($memUsed / $mem) * 100)
        
        @{
            HostName = $env:COMPUTERNAME
            Uptime = "{0:dd}d {0:hh}h {0:mm}m" -f $uptime
            LastBoot = $os.LastBootUpTime
            CPULoad = $cpu
            MemoryUsage = $memPct
        }
    }
    Invoke-Remote -Session $Session -Script $script
}

function Get-RemoteProcesses {
    param($Session)
    $script = { 
        Get-Process | 
        Sort-Object -Descending CPU | 
        Select-Object -First 15 ProcessName, @{N="CPU %";E={"{0:N2}" -f $_.CPU}}, @{N="Memory (MB)";E={"{0:N0}" -f ($_.WS/1MB)}}
    }
    Invoke-Remote -Session $Session -Script $script
}

function Get-RemoteServices {
    param($Session)
    $script = { 
        Get-Service | 
        Where-Object { $_.Status -ne 'Running' } | 
        Select-Object -First 15 Name, Status, DisplayName
    }
    Invoke-Remote -Session $Session -Script $script
}

function Get-RemoteUsers {
    param($Session)
    $script = { 
        try { 
            quser 2>$null
        } catch { 
            Get-CimInstance Win32_ComputerSystem | Select-Object UserName 
        } 
    }
    Invoke-Remote -Session $Session -Script $script
}

function Show-HostSelector {
    [Spectre.Console.AnsiConsole]::Clear()
    
    $title = [Spectre.Console.FigletText]::new("Remote Admin")
    $title.Color = [Spectre.Console.Color]::Cyan
    [Spectre.Console.AnsiConsole]::Write($title)
    
    [Spectre.Console.AnsiConsole]::MarkupLine("")
    [Spectre.Console.AnsiConsole]::MarkupLine("[cyan]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/]")
    [Spectre.Console.AnsiConsole]::MarkupLine("")
    
    $hostname = [Spectre.Console.AnsiConsole]::Ask("[yellow]Enter hostname or IP address:[/]")
    $hostname = $hostname.Trim()
    
    if ([string]::IsNullOrWhiteSpace($hostname)) {
        [Spectre.Console.AnsiConsole]::MarkupLine("[red]Error: Hostname cannot be empty[/]")
        Start-Sleep -Seconds 2
        return $null
    }
    
    [Spectre.Console.AnsiConsole]::MarkupLine("[cyan]Testing connectivity...[/]")
    
    if (Test-RemoteConnectivity -ComputerName $hostname) {
        [Spectre.Console.AnsiConsole]::MarkupLine("[green]✓ Host reachable[/]")
        return $hostname
    } else {
        [Spectre.Console.AnsiConsole]::MarkupLine("[red]✗ Failed to reach host[/]")
        Start-Sleep -Seconds 2
        return $null
    }
}

function Show-MainMenu {
    param([string]$HostName)
    
    $choices = @(
        "Quick Health Check",
        "Show Top Processes",
        "Show Stopped Services",
        "Show Logged-on Users",
        "Disconnect",
        "Exit"
    )
    
    $table = [Spectre.Console.Table]::new()
    $table.AddColumn("[cyan]Option[/]") | Out-Null
    $table.AddColumn("[cyan]Description[/]") | Out-Null
    
    for ($i = 0; $i -lt $choices.Count; $i++) {
        $table.AddRow($($i + 1), $choices[$i]) | Out-Null
    }
    
    [Spectre.Console.AnsiConsole]::Clear()
    [Spectre.Console.AnsiConsole]::MarkupLine("[cyan]Remote Admin > [bold]$HostName[/][/]")
    [Spectre.Console.AnsiConsole]::MarkupLine("[cyan]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/]")
    [Spectre.Console.AnsiConsole]::Write($table)
    [Spectre.Console.AnsiConsole]::MarkupLine("")
    
    $choice = [Spectre.Console.AnsiConsole]::Ask("[yellow]Select option (1-6):[/]")
    return $choice.Trim()
}

function Show-HealthPanel {
    param($HealthData)
    
    [Spectre.Console.AnsiConsole]::Clear()
    
    $panel = [Spectre.Console.Panel]::new(
        "[green]Hostname:[/] $($HealthData.HostName)`n" +
        "[green]Uptime:[/] $($HealthData.Uptime)`n" +
        "[green]Last Boot:[/] $($HealthData.LastBoot)`n" +
        "[yellow]CPU Load:[/] $($HealthData.CPULoad)`n" +
        "[yellow]Memory Usage:[/] $($HealthData.MemoryUsage)",
        "Host Health"
    )
    $panel.Border = [Spectre.Console.BoxBorder]::Rounded
    $panel.BorderColor = [Spectre.Console.Color]::Cyan
    
    [Spectre.Console.AnsiConsole]::Write($panel)
    [Spectre.Console.AnsiConsole]::MarkupLine("")
    [Spectre.Console.AnsiConsole]::Ask("[cyan]Press Enter to continue...[/]") | Out-Null
}

function Show-ProcessesTable {
    param($Processes)
    
    [Spectre.Console.AnsiConsole]::Clear()
    
    $table = [Spectre.Console.Table]::new()
    $table.Title = [Spectre.Console.TableTitle]::new("Top Processes")
    $table.AddColumn("[cyan]Process Name[/]") | Out-Null
    $table.AddColumn("[yellow]CPU %[/]") | Out-Null
    $table.AddColumn("[magenta]Memory (MB)[/]") | Out-Null
    
    foreach ($proc in $Processes) {
        $table.AddRow($proc.'ProcessName', $proc.'CPU %', $proc.'Memory (MB)') | Out-Null
    }
    
    [Spectre.Console.AnsiConsole]::Write($table)
    [Spectre.Console.AnsiConsole]::MarkupLine("")
    [Spectre.Console.AnsiConsole]::Ask("[cyan]Press Enter to continue...[/]") | Out-Null
}

function Show-ServicesTable {
    param($Services)
    
    [Spectre.Console.AnsiConsole]::Clear()
    
    $table = [Spectre.Console.Table]::new()
    $table.Title = [Spectre.Console.TableTitle]::new("Stopped Services")
    $table.AddColumn("[cyan]Service Name[/]") | Out-Null
    $table.AddColumn("[yellow]Status[/]") | Out-Null
    $table.AddColumn("[magenta]Display Name[/]") | Out-Null
    
    foreach ($svc in $Services) {
        $statusColor = if ($svc.Status -eq 'Stopped') { '[red]' } else { '[yellow]' }
        $table.AddRow($svc.Name, "$statusColor$($svc.Status)[/]", $svc.DisplayName) | Out-Null
    }
    
    [Spectre.Console.AnsiConsole]::Write($table)
    [Spectre.Console.AnsiConsole]::MarkupLine("")
    [Spectre.Console.AnsiConsole]::Ask("[cyan]Press Enter to continue...[/]") | Out-Null
}

function Show-UsersPanel {
    param($Users)
    
    [Spectre.Console.AnsiConsole]::Clear()
    
    $content = if ($Users -is [string]) { $Users } else { $Users | Format-List | Out-String }
    
    $panel = [Spectre.Console.Panel]::new(
        $content,
        "Logged-on Users"
    )
    $panel.Border = [Spectre.Console.BoxBorder]::Rounded
    $panel.BorderColor = [Spectre.Console.Color]::Green
    
    [Spectre.Console.AnsiConsole]::Write($panel)
    [Spectre.Console.AnsiConsole]::MarkupLine("")
    [Spectre.Console.AnsiConsole]::Ask("[cyan]Press Enter to continue...[/]") | Out-Null
}

function Start-RemoteAdminSpectre {
    try {
        while ($script:IsRunning) {
            # Get hostname
            $script:CurrentHost = Show-HostSelector
            
            if ([string]::IsNullOrEmpty($script:CurrentHost)) { continue }
            
            # Get credentials
            $cred = Get-Credential -Message "Credentials for $($script:CurrentHost)"
            if ($null -eq $cred) { continue }
            
            # Create session
            [Spectre.Console.AnsiConsole]::MarkupLine("[cyan]Creating remote session...[/]")
            $script:CurrentSession = New-RemoteSession -ComputerName $script:CurrentHost -Credential $cred
            
            if ($null -eq $script:CurrentSession) {
                [Spectre.Console.AnsiConsole]::MarkupLine("[red]Failed to create remote session[/]")
                Start-Sleep -Seconds 2
                continue
            }
            
            [Spectre.Console.AnsiConsole]::MarkupLine("[green]✓ Connected[/]")
            Start-Sleep -Seconds 1
            
            # Main menu loop
            while ($script:IsRunning -and $null -ne $script:CurrentSession) {
                $choice = Show-MainMenu -HostName $script:CurrentHost
                
                switch ($choice) {
                    "1" {
                        $health = Get-RemoteHealth -Session $script:CurrentSession
                        Show-HealthPanel -HealthData $health
                    }
                    "2" {
                        $procs = Get-RemoteProcesses -Session $script:CurrentSession
                        Show-ProcessesTable -Processes $procs
                    }
                    "3" {
                        $svcs = Get-RemoteServices -Session $script:CurrentSession
                        Show-ServicesTable -Services $svcs
                    }
                    "4" {
                        $users = Get-RemoteUsers -Session $script:CurrentSession
                        Show-UsersPanel -Users $users
                    }
                    "5" {
                        Remove-PSSession -Session $script:CurrentSession -ErrorAction SilentlyContinue
                        $script:CurrentSession = $null
                        $script:CurrentHost = $null
                        break
                    }
                    "6" {
                        $script:IsRunning = $false
                    }
                    default {
                        [Spectre.Console.AnsiConsole]::MarkupLine("[red]Invalid choice[/]")
                        Start-Sleep -Seconds 1
                    }
                }
            }
        }
    } finally {
        if ($null -ne $script:CurrentSession) {
            Remove-PSSession -Session $script:CurrentSession -ErrorAction SilentlyContinue
        }
        [Spectre.Console.AnsiConsole]::MarkupLine("[cyan]Goodbye![/]")
    }
}

if (-not $SkipInit) {
    Start-RemoteAdminSpectre
}
