#Requires -Version 7.0
using namespace Terminal.Gui

<#
remote-admin-tui.ps1

Terminal.Gui-based TUI admin tool for remote Windows host management.

Features:
- Real windowed interface with dialogs and nested windows
- Host connection browser with credentials prompt
- Live host data viewing
- Menu-driven operations with confirmations
- Better keyboard navigation

Requirements:
- PowerShell 7+
- Terminal.Gui NuGet package

SETUP:
Before running, install Terminal.Gui:
  Option 1: nuget install Terminal.Gui -OutputDirectory packages
  Option 2: See SETUP-TUI.md for alternatives
#>

param(
    [switch]$SkipInit = $false
)

# Try to load Terminal.Gui from common locations
$tgPaths = @(
    "./packages/Terminal.Gui*/lib/net6.0/Terminal.Gui.dll",
    "../packages/Terminal.Gui*/lib/net6.0/Terminal.Gui.dll",
    (Join-Path $PROFILE "..\packages\Terminal.Gui*\lib\net6.0\Terminal.Gui.dll")
)

$tgDll = $null
foreach ($pattern in $tgPaths) {
    $found = @(Resolve-Path $pattern -ErrorAction SilentlyContinue | Select-Object -Last 1)
    if ($found) {
        $tgDll = $found[0].Path
        break
    }
}

if (-not $tgDll) {
    Write-Host "Terminal.Gui not found. Install it first:" -ForegroundColor Red
    Write-Host ""
    Write-Host "From the tools directory, run:"
    Write-Host "  nuget install Terminal.Gui -OutputDirectory packages"
    Write-Host ""
    Write-Host "Or see SETUP-TUI.md for alternatives"
    exit 1
}

[System.Reflection.Assembly]::LoadFrom($tgDll) | Out-Null

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
        $procs = Get-Process | Sort-Object -Descending CPU | Select-Object -First 5 -Property ProcessName, @{N="CPU";E={"{0:N2}" -f $_.CPU}}, @{N="Memory(MB)";E={"{0:N0}" -f ($_.WS/1MB)}}
        $cpu = "{0:N1}%" -f ((Get-CimInstance Win32_Processor).LoadPercentage | Measure-Object -Average).Average
        @"
HOST HEALTH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Hostname:    $env:COMPUTERNAME
Uptime:      {0:dd}d {0:hh}h {0:mm}m
Last Boot:   $($os.LastBootUpTime)
CPU Load:    $cpu
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOP PROCESSES:
$($procs | Format-Table -HideTableHeaders -AutoSize | Out-String)
"@ -f $uptime
    }
    Invoke-Remote -Session $Session -Script $script
}

function Get-RemoteProcesses {
    param($Session)
    $script = { Get-Process | Sort-Object -Descending CPU | Select-Object -First 20 ProcessName, @{N="CPU";E={"{0:N2}" -f $_.CPU}}, @{N="Memory(MB)";E={"{0:N0}" -f ($_.WS/1MB)}} }
    @"
TOP 20 PROCESSES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$((Invoke-Remote -Session $Session -Script $script | Format-Table -AutoSize | Out-String))
"@
}

function Get-RemoteServices {
    param($Session)
    $script = { Get-Service | Where-Object { $_.Status -ne 'Running' } | Select-Object -First 20 Name, Status }
    @"
STOPPED SERVICES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$((Invoke-Remote -Session $Session -Script $script | Format-Table -AutoSize | Out-String))
"@
}

function Get-RemoteUsers {
    param($Session)
    $script = { 
        try { 
            quser 
        } catch { 
            "No users logged on (or quser unavailable)"
        } 
    }
    @"
LOGGED-ON USERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$((Invoke-Remote -Session $Session -Script $script | Out-String))
"@
}

function Show-MessageDialog {
    param([string]$Title, [string]$Text)
    
    $dlg = [Dialog]::new()
    $dlg.Title = $Title
    $dlg.Width = 70
    $dlg.Height = 15
    
    $view = [TextView]::new()
    $view.X = 0
    $view.Y = 0
    $view.Width = [Dim]::Fill()
    $view.Height = [Dim]::Fill() - 1
    $view.ReadOnly = $true
    $view.Text = $Text
    $dlg.Add($view)
    
    $btn = [Button]::new("Close")
    $btn.X = [Pos]::Center()
    $btn.Y = [Pos]::Bottom($dlg) - 1
    $btn.Clicked += { [Application]::RequestStop() }
    $dlg.Add($btn)
    
    [Application]::Run($dlg)
}

function Show-StatusDialog {
    param([string]$Message, [string]$Title = "Host Selector")
    
    $dlg = [Dialog]::new()
    $dlg.Title = $Title
    $dlg.Width = 60
    $dlg.Height = 8
    
    $lbl = [Label]::new($Message)
    $lbl.X = 2
    $lbl.Y = 1
    $lbl.Width = [Dim]::Fill() - 2
    $dlg.Add($lbl)
    
    $btn = [Button]::new("OK")
    $btn.X = [Pos]::Center()
    $btn.Y = [Pos]::Bottom($dlg) - 1
    $btn.Clicked += { [Application]::RequestStop() }
    $dlg.Add($btn)
    
    [Application]::Run($dlg)
}

function Start-RemoteAdminTUI {
    # Initialize Terminal.Gui
    [Application]::Init()
    
    try {
        while ($script:IsRunning) {
            # Host Selector Window
            $hostDialog = [Dialog]::new()
            $hostDialog.Title = "Remote Admin - Select Host"
            $hostDialog.Width = 60
            $hostDialog.Height = 12
            
            $hostLabel = [Label]::new("Enter hostname or IP address:")
            $hostLabel.X = 2
            $hostLabel.Y = 1
            $hostDialog.Add($hostLabel)
            
            $hostField = [TextField]::new()
            $hostField.X = 2
            $hostField.Y = 2
            $hostField.Width = [Dim]::Fill() - 2
            $hostDialog.Add($hostField)
            
            $statusLabel = [Label]::new("")
            $statusLabel.X = 2
            $statusLabel.Y = 4
            $statusLabel.Width = [Dim]::Fill() - 2
            $hostDialog.Add($statusLabel)
            
            $connectBtn = [Button]::new("Connect")
            $connectBtn.X = 5
            $connectBtn.Y = [Pos]::Bottom($hostDialog) - 2
            
            $quitBtn = [Button]::new("Quit")
            $quitBtn.X = 20
            $quitBtn.Y = [Pos]::Bottom($hostDialog) - 2
            
            $connectBtn.Clicked += {
                $host = $hostField.Text.Trim()
                if ([string]::IsNullOrEmpty($host)) {
                    $statusLabel.Text = "Please enter a hostname or IP"
                } else {
                    $statusLabel.Text = "Testing connectivity..."
                    if (Test-RemoteConnectivity -ComputerName $host) {
                        $script:CurrentHost = $host
                        [Application]::RequestStop()
                    } else {
                        $statusLabel.Text = "Failed to reach host"
                    }
                }
            }
            
            $quitBtn.Clicked += { $script:IsRunning = $false; [Application]::RequestStop() }
            
            $hostDialog.Add($connectBtn)
            $hostDialog.Add($quitBtn)
            
            [Application]::Run($hostDialog)
            
            if (-not $script:IsRunning -or [string]::IsNullOrEmpty($script:CurrentHost)) { break }
            
            # Get credentials
            $cred = Get-Credential -Message "Credentials for $($script:CurrentHost)"
            if ($null -eq $cred) { continue }
            
            # Create session
            $script:CurrentSession = New-RemoteSession -ComputerName $script:CurrentHost -Credential $cred
            if ($null -eq $script:CurrentSession) {
                Show-StatusDialog "Failed to create remote session."
                continue
            }
            
            # Main Menu Loop
            while ($script:IsRunning -and $null -ne $script:CurrentSession) {
                $menuDialog = [Dialog]::new()
                $menuDialog.Title = "Remote Admin - $($script:CurrentHost)"
                $menuDialog.Width = 50
                $menuDialog.Height = 18
                
                $menuList = [ListView]::new(@(
                    "1 - Quick Health Check",
                    "2 - Show Top Processes",
                    "3 - Show Stopped Services",
                    "4 - Show Logged-on Users",
                    "5 - Disconnect",
                    "6 - Exit"
                ))
                $menuList.X = 2
                $menuList.Y = 1
                $menuList.Width = [Dim]::Fill() - 2
                $menuList.Height = [Dim]::Fill() - 3
                
                $menuList.SelectedItemChanged += {
                    $idx = $menuList.SelectedItem
                    switch ($idx) {
                        0 {
                            $data = Get-RemoteHealth -Session $script:CurrentSession
                            Show-MessageDialog "Quick Health" $data
                        }
                        1 {
                            $data = Get-RemoteProcesses -Session $script:CurrentSession
                            Show-MessageDialog "Top Processes" $data
                        }
                        2 {
                            $data = Get-RemoteServices -Session $script:CurrentSession
                            Show-MessageDialog "Stopped Services" $data
                        }
                        3 {
                            $data = Get-RemoteUsers -Session $script:CurrentSession
                            Show-MessageDialog "Logged-on Users" $data
                        }
                        4 {
                            Remove-PSSession -Session $script:CurrentSession -ErrorAction SilentlyContinue
                            $script:CurrentSession = $null
                            $script:CurrentHost = $null
                            [Application]::RequestStop()
                        }
                        5 {
                            $script:IsRunning = $false
                            Remove-PSSession -Session $script:CurrentSession -ErrorAction SilentlyContinue
                            [Application]::RequestStop()
                        }
                    }
                }
                
                $menuDialog.Add($menuList)
                
                $backBtn = [Button]::new("Back")
                $backBtn.X = 2
                $backBtn.Y = [Pos]::Bottom($menuDialog) - 1
                $backBtn.Clicked += { [Application]::RequestStop() }
                $menuDialog.Add($backBtn)
                
                [Application]::Run($menuDialog)
            }
        }
    } finally {
        if ($null -ne $script:CurrentSession) {
            Remove-PSSession -Session $script:CurrentSession -ErrorAction SilentlyContinue
        }
        [Application]::Shutdown()
    }
}

if (-not $SkipInit) {
    Start-RemoteAdminTUI
}
