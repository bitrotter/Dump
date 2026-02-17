<#
remote-admin.ps1

Console-based remote admin tool using PowerShell remoting.

Features:
- Connect to remote host(s) with credentials
- Show processes, services, uptime, logged on users
- Check for pending updates (uses PSWindowsUpdate if available)
- Apply updates (optional) and reboot
- Start interactive session (Enter-PSSession)
- Run one-off commands

Notes:
- Requires PowerShell remoting (WinRM) enabled on targets, or use SSH remoting.
- For update checks/apply, the PSWindowsUpdate module is recommended on the remote host(s).
#>

function Write-BoxedText {
    param([string]$Text)
    $width = ($Text.Length + 4)
    Write-Host ('+' + ('-' * ($width -2)) + '+') -ForegroundColor Cyan
    Write-Host ('| ' + $Text + ' |') -ForegroundColor Cyan
    Write-Host ('+' + ('-' * ($width -2)) + '+') -ForegroundColor Cyan
}

function Get-Choice {
    param([string]$prompt)
    Write-Host -NoNewline "$prompt `n> " -ForegroundColor Yellow
    return Read-Host
}

function Test-RemoteConnectivity {
    param($ComputerName)
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
        Write-Host "Failed to create PSSession: $_" -ForegroundColor Red
        return $null
    }
}

function Invoke-Remote {
    param($Session, [scriptblock]$Script)
    Invoke-Command -Session $Session -ScriptBlock $Script -ErrorAction Stop
}

function Get-RemoteHealth {
    param($Session)
    $script = {
        $os = Get-CimInstance Win32_OperatingSystem
        $uptime = (Get-Date) - $os.LastBootUpTime
        $procs = Get-Process | Sort-Object -Descending CPU | Select-Object -First 8 -Property Id, ProcessName, CPU, WS
        $services = Get-Service | Where-Object { $_.Status -ne 'Running' } | Select-Object -First 10 Name, Status
        $users = try { quser 2>$null } catch { (whoami) }
        $hotfixes = Get-HotFix | Select-Object -First 10 -Property HotFixID, InstalledOn
        [PSCustomObject]@{
            Uptime = "{0:dd}d {0:hh}h {0:mm}m" -f $uptime
            LastBoot = $os.LastBootUpTime
            Processes = $procs
            StoppedServices = $services
            Users = $users
            RecentHotFixes = $hotfixes
        }
    }
    Invoke-Remote -Session $Session -Script $script
}

function Get-RemoteProcesses {
    param($Session)
    $script = { Get-Process | Sort-Object -Descending CPU | Select-Object -First 25 Id, ProcessName, CPU, WS }
    Invoke-Remote -Session $Session -Script $script | Format-Table -AutoSize
}

function Get-RemoteServices {
    param($Session)
    $script = { Get-Service | Sort-Object Status,Name | Select-Object -First 200 Name, Status }
    Invoke-Remote -Session $Session -Script $script | Format-Table -AutoSize
}

function Get-RemoteUsers {
    param($Session)
    $script = { try { quser } catch { Get-CimInstance Win32_ComputerSystem | Select-Object -Property UserName } }
    Invoke-Remote -Session $Session -Script $script
}

function Get-PendingUpdates {
    param($Session)
    $script = {
        if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
            Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue
            $pending = Get-WindowsUpdate -IsInstalled:$false -AcceptAll -IgnoreReboot -ErrorAction SilentlyContinue
            if ($pending) { $pending | Select-Object -Property KB, Title, Size } else { 'No pending updates found or module returned no results' }
        } else {
            'PSWindowsUpdate not installed on target. Cannot enumerate pending updates from here.'
        }
    }
    Invoke-Remote -Session $Session -Script $script
}

function Install-RemoteUpdates {
    param($Session)
    $script = {
        if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
            Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue
            Install-WindowsUpdate -AcceptAll -AutoReboot -IgnoreReboot -ErrorAction SilentlyContinue
        } else {
            'PSWindowsUpdate not installed on target. Install it first: Install-Module PSWindowsUpdate -Force'
        }
    }
    Invoke-Remote -Session $Session -Script $script
}

function Restart-Remote {
    param($Session, [switch]$Force)
    $script = { Restart-Computer -Force }
    if ($Force) { Invoke-Remote -Session $Session -Script $script } else { Invoke-Remote -Session $Session -Script $script }
}

function Invoke-RemoteLogoff {
    param($Session)
    $script = { shutdown /l }
    Invoke-Remote -Session $Session -Script $script
}

function Invoke-RemoteCommand {
    param($Session, $Command)
    $script = [scriptblock]::Create($Command)
    Invoke-Remote -Session $Session -Script $script
}

function Enter-RemoteSession {
    param($Session)
    Enter-PSSession -Session $Session
}

function Start-RemoteAdmin {
    while ($true) {
        Clear-Host
        Write-BoxedText "Remote Admin Console"
        $computer = (Get-Choice "Target computer (hostname or IP)").Trim()
        if (-not $computer) { Write-Host "No target provided. Exiting."; return }
        $credential = Get-Credential -Message "Enter credentials for $computer"

        Write-Host "Testing connectivity to $computer..." -ForegroundColor Cyan
        if (-not (Test-RemoteConnectivity -ComputerName $computer)) {
            Write-Host "WinRM not reachable or target not responding. Ensure PowerShell Remoting is configured." -ForegroundColor Red
            continue
        }

        $session = New-RemoteSession -ComputerName $computer -Credential $credential
        if (-not $session) { continue }

        $connected = $true
        while ($connected) {
            Write-Host "`nConnected to: $computer" -ForegroundColor Green
            Write-Host "1) Quick Health"
            Write-Host "2) Show Processes"
            Write-Host "3) Show Services (non-running)"
            Write-Host "4) Show Logged-on Users"
            Write-Host "5) Check Pending Updates"
            Write-Host "6) Apply Updates (install + reboot)"
            Write-Host "7) Reboot"
            Write-Host "8) Logoff (console session)"
            Write-Host "9) Run Command"
            Write-Host "10) Enter Interactive Session"
            Write-Host "d) Disconnect session"
            Write-Host "x) Exit tool"

            $choice = (Get-Choice "Select an option").Trim().ToLower()
            switch ($choice) {
                '1' {
                    $res = Get-RemoteHealth -Session $session
                    $res | Format-List -Force
                }
                '2' { Get-RemoteProcesses -Session $session }
                '3' { Get-RemoteServices -Session $session }
                '4' { Get-RemoteUsers -Session $session }
                '5' { Get-PendingUpdates -Session $session }
                '6' {
                    $confirm = (Get-Choice "Install updates and reboot if required? (y/N)").Trim().ToLower()
                    if ($confirm -eq 'y') { Install-RemoteUpdates -Session $session }
                }
                '7' {
                    $confirm = (Get-Choice "Reboot remote host now? (y/N)").Trim().ToLower()
                    if ($confirm -eq 'y') { Restart-Remote -Session $session -Force }
                }
                '8' {
                    $confirm = (Get-Choice "Log off console session? (y/N)").Trim().ToLower()
                    if ($confirm -eq 'y') { Invoke-RemoteLogoff -Session $session }
                }
                '9' {
                    $cmd = (Get-Choice "Command to run on remote (PowerShell scriptblock or single-line)").Trim()
                    if ($cmd) { Invoke-RemoteCommand -Session $session -Command $cmd }
                }
                '10' {
                    Write-Host "Entering interactive session. Type 'Exit-PSSession' to return." -ForegroundColor Cyan
                    Enter-RemoteSession -Session $session
                }
                'd' {
                    Remove-PSSession -Session $session -ErrorAction SilentlyContinue
                    Write-Host "Disconnected." -ForegroundColor Cyan
                    $connected = $false
                }
                'x' {
                    Remove-PSSession -Session $session -ErrorAction SilentlyContinue
                    Write-Host "Goodbye." -ForegroundColor Cyan
                    return
                }
                default { Write-Host "Unknown choice." -ForegroundColor Yellow }
            }
        }
        # loop back to prompt for a new target when disconnected
    }
}

if ($MyInvocation.InvocationName -eq '.') {
    # when dot-sourced, do nothing
} else {
    Start-RemoteAdmin
}
