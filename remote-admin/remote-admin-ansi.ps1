#Requires -Version 5.0

<#
remote-admin-ansi.ps1

ANSI-based TUI with DOS-like windowed interface.
Uses box-drawing characters and cursor positioning for retro feel.

No external dependencies — works with built-in PowerShell.

Features:
- DOS/Linux installer-style windowed interface
- Box-drawing characters for visual separation
- Menu navigation with arrow keys
- Real-time host monitoring
- Better than CLI, simpler than Terminal.Gui
#>

# ANSI Escape codes
$ESC = "$([char]27)"
$RESET = "$ESC[0m"
$CLEAR = "$ESC[2J$ESC[H"  # Clear screen and home cursor
$BOLD = "$ESC[1m"
$DIM = "$ESC[2m"
$CYAN = "$ESC[36m"
$GREEN = "$ESC[32m"
$YELLOW = "$ESC[33m"
$RED = "$ESC[31m"
$WHITE = "$ESC[37m"

# Box drawing characters
$BOX_TL = "┌"
$BOX_TR = "┐"
$BOX_BL = "└"
$BOX_BR = "┘"
$BOX_H = "─"
$BOX_V = "│"
$BOX_T = "┬"
$BOX_B = "┴"
$BOX_L = "├"
$BOX_R = "┤"
$BOX_CROSS = "┼"

function Set-CursorPosition {
    param([int]$X, [int]$Y)
    Write-Host "$ESC[$($Y);$($X)H" -NoNewline
}

function Draw-Box {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [string]$Title = "",
        [string]$Color = $WHITE
    )
    
    Set-CursorPosition $X $Y
    Write-Host "$COLOR" -NoNewline
    
    # Top border with title
    $topLine = $BOX_TL + ($BOX_H * ($Width - 2)) + $BOX_TR
    if ($Title) {
        $titlePadded = " $Title "
        if ($titlePadded.Length -le $Width - 2) {
            $leftW = [Math]::Floor(($Width - $titlePadded.Length) / 2)
            $rightW = $Width - $titlePadded.Length - $leftW - 2
            $topLine = $BOX_TL + ($BOX_H * $leftW) + $titlePadded + ($BOX_H * $rightW) + $BOX_TR
        }
    }
    Write-Host $topLine
    
    # Side borders
    for ($i = 1; $i -lt $Height - 1; $i++) {
        Set-CursorPosition $X ($Y + $i)
        $spaces = " " * ($Width - 2)
        Write-Host "$BOX_V$spaces$BOX_V" -NoNewline
    }
    
    # Bottom border
    Set-CursorPosition $X ($Y + $Height - 1)
    Write-Host ($BOX_BL + ($BOX_H * ($Width - 2)) + $BOX_BR)
    Write-Host "$RESET" -NoNewline
}

function Write-BoxText {
    param(
        [int]$X,
        [int]$Y,
        [string]$Text,
        [string]$Color = $WHITE
    )
    Set-CursorPosition $X $Y
    Write-Host "$Color$Text$RESET" -NoNewline
}

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
        Write-Error $_
    }
}

function Get-RemoteHealth {
    param($Session)
    $script = {
        $os = Get-CimInstance Win32_OperatingSystem
        $uptime = (Get-Date) - $os.LastBootUpTime
        $procs = Get-Process | Sort-Object -Descending CPU | Select-Object -First 5 -Property ProcessName, CPU, WS
        @"
Uptime:  {0:dd}d {0:hh}h {0:mm}m
LastBoot: $($os.LastBootUpTime)
Top Processes:
$($procs | Format-Table -AutoSize | Out-String)
"@ -f $uptime
    }
    Invoke-Remote -Session $Session -Script $script
}

function Get-RemoteProcesses {
    param($Session)
    $script = { Get-Process | Sort-Object -Descending CPU | Select-Object -First 15 ProcessName, CPU, WS }
    (Invoke-Remote -Session $Session -Script $script | Format-Table -AutoSize | Out-String)
}

function Get-RemoteServices {
    param($Session)
    $script = { Get-Service | Where-Object { $_.Status -ne 'Running' } | Select-Object -First 15 Name, Status }
    (Invoke-Remote -Session $Session -Script $script | Format-Table -AutoSize | Out-String)
}

function Show-Dialog {
    param(
        [string]$Title,
        [string]$Message,
        [array]$Options = @("OK")
    )
    
    Write-Host $CLEAR
    Draw-Box 10 3 60 15 $Title $CYAN
    
    $lines = $Message -split "`n"
    $startY = 5
    foreach ($line in $lines) {
        Write-BoxText 12 $startY $line $WHITE
        $startY++
    }
    
    # Show options
    Write-BoxText 12 ($startY + 2) "Choose an option:" $YELLOW
    $optY = $startY + 3
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-BoxText 14 ($optY + $i) "[$($i + 1)] $($Options[$i])" $GREEN
    }
    
    while ($true) {
        $key = [Console]::ReadKey($true)
        $num = [int]::Parse($key.KeyChar.ToString())
        if ($num -gt 0 -and $num -le $Options.Count) {
            return $num - 1
        }
    }
}

function Show-Menu {
    param(
        [string]$Title,
        [array]$Items,
        [int]$Width = 50
    )
    
    $selected = 0
    $maxHeight = [Math]::Min($Items.Count + 4, 20)
    
    while ($true) {
        Write-Host $CLEAR
        $boxHeight = $Items.Count + 4
        Draw-Box 15 2 $Width $boxHeight $Title $CYAN
        
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $y = 4 + $i
            if ($i -eq $selected) {
                Write-BoxText 17 $y "► $($Items[$i])" $GREEN
            } else {
                Write-BoxText 17 $y "  $($Items[$i])" $WHITE
            }
        }
        
        Write-BoxText 17 ($Items.Count + 5) "↑↓ Navigate, Enter Select" $DIM
        
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "UpArrow" { if ($selected -gt 0) { $selected-- } }
            "DownArrow" { if ($selected -lt $Items.Count - 1) { $selected++ } }
            "Enter" { return $selected }
            "Escape" { return -1 }
        }
    }
}

function Get-InputBox {
    param([string]$Prompt = "Enter value")
    
    Write-Host $CLEAR
    Draw-Box 15 5 50 10 "Input" $CYAN
    Write-BoxText 17 7 $Prompt $YELLOW
    Write-BoxText 17 8 "────────────────────────────────────────" $DIM
    Write-BoxText 17 9 "> " $GREEN
    
    Set-CursorPosition 19 9
    $value = Read-Host
    return $value
}

function Show-Results {
    param([string]$Title, [string]$Data)
    
    Write-Host $CLEAR
    Write-Host "$(Get-Host).WindowTitle" -ForegroundColor DarkGray
    
    # Draw top box
    Draw-Box 5 2 70 4 $Title $CYAN
    Write-BoxText 7 5 "Results (Press any key to continue):" $DIM
    
    # Show data in scrollable area
    $lines = $Data -split "`n"
    $startLine = 0
    $maxLines = 15
    
    while ($true) {
        Write-Host $CLEAR
        Draw-Box 5 2 70 22 $Title $CYAN
        
        $endLine = [Math]::Min($startLine + $maxLines, $lines.Count)
        for ($i = $startLine; $i -lt $endLine; $i++) {
            Write-BoxText 7 (4 + $i - $startLine) $lines[$i].PadRight(67) $WHITE
        }
        
        Write-BoxText 7 21 "q=Quit  ↑↓=Scroll (Ln $($startLine + 1)/$($lines.Count))" $DIM
        
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq "Q" -or $key.Key -eq "Escape") { break }
        if ($key.Key -eq "UpArrow" -and $startLine -gt 0) { $startLine-- }
        if ($key.Key -eq "DownArrow" -and $endLine -lt $lines.Count) { $startLine++ }
    }
}

function Start-RemoteAdminANSI {
    $script:CurrentHost = $null
    $script:CurrentSession = $null
    
    while ($true) {
        # Host selector
        Write-Host $CLEAR
        Draw-Box 20 5 40 8 "Remote Admin" $CYAN
        Write-BoxText 22 7 "Enter hostname or IP:" $WHITE
        
        Set-CursorPosition 22 8
        [Console]::Out.Flush()
        $host = Read-Host
        
        if ([string]::IsNullOrEmpty($host)) { continue }
        
        Write-Host $CLEAR
        Write-BoxText 25 10 "Testing connectivity..." $YELLOW
        [Console]::Out.Flush()
        
        if (-not (Test-RemoteConnectivity -ComputerName $host)) {
            Show-Dialog "Error" "Cannot reach host.`nCheck WinRM and network." @("Retry", "Exit") | Out-Null
            if ($_ -eq 1) { break }
            continue
        }
        
        # Get credentials
        $cred = Get-Credential -Message "Enter credentials for $host"
        if ($null -eq $cred) { continue }
        
        # Create session
        Write-Host $CLEAR
        Write-BoxText 25 10 "Creating session..." $YELLOW
        [Console]::Out.Flush()
        
        $script:CurrentSession = New-RemoteSession -ComputerName $host -Credential $cred
        if ($null -eq $script:CurrentSession) {
            Show-Dialog "Error" "Failed to create session." @("Retry", "Exit") | Out-Null
            continue
        }
        
        $script:CurrentHost = $host
        
        # Main menu loop
        while ($null -ne $script:CurrentSession) {
            $menuItems = @(
                "1. Quick Health Check",
                "2. Show Top Processes",
                "3. Show Stopped Services",
                "4. Show Logged-on Users",
                "5. Disconnect",
                "6. Exit"
            )
            
            $choice = Show-Menu "Remote Admin - $host" $menuItems 55
            
            switch ($choice) {
                0 {
                    $data = Get-RemoteHealth -Session $script:CurrentSession
                    Show-Results "Quick Health" $data
                }
                1 {
                    $data = Get-RemoteProcesses -Session $script:CurrentSession
                    Show-Results "Top Processes" $data
                }
                2 {
                    $data = Get-RemoteServices -Session $script:CurrentSession
                    Show-Results "Stopped Services" $data
                }
                3 {
                    Write-Host $CLEAR
                    Write-BoxText 25 10 "Fetching users..." $YELLOW
                    [Console]::Out.Flush()
                    $data = Invoke-Remote -Session $script:CurrentSession -Script { quser }
                    Show-Results "Logged-on Users" $data
                }
                4 {
                    Remove-PSSession -Session $script:CurrentSession -ErrorAction SilentlyContinue
                    $script:CurrentSession = $null
                    break
                }
                5 {
                    Remove-PSSession -Session $script:CurrentSession -ErrorAction SilentlyContinue
                    Write-Host $CLEAR
                    return
                }
                default { }
            }
        }
    }
}

# Run
Start-RemoteAdminANSI
