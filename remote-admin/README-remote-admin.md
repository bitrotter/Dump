Remote Admin
============

Three versions available:

1. **CLI Menu Version** (tools/remote-admin.ps1)
   - Simple menu-driven CLI interface
   - No external dependencies
   - Good for quick checks and automation

2. **ANSI TUI Version** (tools/remote-admin-ansi.ps1)
   - DOS/Linux installer-style windowed interface
   - Box-drawing characters, ANSI colors
   - Menu navigation with arrow keys
   - No external dependencies
   - Gives you that retro DOS-era graphical feel

3. **Spectre.Console TUI Version (NEW - Recommended GUI)** (tools/remote-admin-spectre.ps1)
   - Rich styled console interface with tables and panels
   - Single DLL dependency (easy setup)
   - Much better PowerShell integration than Terminal.Gui
   - Excellent visual formatting for data
   - **See [SETUP-SPECTRE.md](SETUP-SPECTRE.md) for quick setup**

4. **Terminal.Gui TUI Version** (tools/remote-admin-tui.ps1)
   - Advanced Terminal.Gui interface (for reference)
   - Complex dependencies; Spectre.Console is recommended instead

Quick Start
-----------

### CLI Version (simple, no setup)

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\remote-admin.ps1
```

### Spectre.Console TUI Version (styled GUI, one DLL) - **RECOMMENDED**

```powershell
# First time only: install Spectre.Console
nuget install Spectre.Console -OutputDirectory packages

# Then run:
pwsh -ExecutionPolicy Bypass -File .\tools\remote-admin-spectre.ps1
```

See [SETUP-SPECTRE.md](SETUP-SPECTRE.md) for detailed setup options.

### ANSI TUI Version (retro DOS-style, no setup)

```powershell
pwsh -ExecutionPolicy Bypass -File .\tools\remote-admin-ansi.ps1
```

Preparing a Windows target for remoting
- The quickest supported method is PowerShell Remoting (WinRM). On the remote host run the following as Administrator:

```powershell
# Enable PS Remoting and configure WinRM listener
Enable-PSRemoting -Force

# Quick WSMan configuration (creates listener, firewall rules)
Set-WSManQuickConfig -Force

# Ensure WinRM service is running and set to automatic
Start-Service WinRM
Set-Service -Name WinRM -StartupType Automatic

# (Optional) Allow remote hosts via TrustedHosts when not using domain-joined Kerberos
# Replace '*' with a comma-separated list of specific hostnames/IPs when possible
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value '*' -Force

# Allow WinRM through the Windows Firewall (if Set-WSManQuickConfig didn't already)
New-NetFirewallRule -Name 'Allow-WSMan-Inbound' -DisplayName 'Allow WinRM Inbound' -Protocol TCP -LocalPort 5985 -Action Allow

# Recommended: set a safe execution policy for scripts
Set-ExecutionPolicy RemoteSigned -Force
```

Notes and security
- Avoid using `TrustedHosts` set to `*` in production — prefer specific hosts or configure HTTPS transport with proper certificates.
- For domain-joined machines, Kerberos will authenticate by default and you do not need `TrustedHosts`.
- If using WinRM over HTTPS, create/import a certificate and configure the listener accordingly (see Microsoft docs).

Installing the PSWindowsUpdate module (for update checks/apply)
- On the remote host (run as Administrator):

```powershell
# Install from PSGallery
Install-PackageProvider -Name NuGet -Force
Install-Module -Name PSWindowsUpdate -Force -AllowClobber

# Import and test
Import-Module PSWindowsUpdate
Get-WindowsUpdate -AcceptAll -IgnoreReboot
```

SSH-based remoting (alternative)
- Windows 10/Server 2019+ supports OpenSSH Server as an alternative to WinRM. On the remote host run as Administrator:

```powershell
# Install OpenSSH Server capability
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start and set to automatic
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Allow SSH through firewall
New-NetFirewallRule -Name 'Allow-SSH-Inbound' -DisplayName 'Allow SSH Inbound' -Protocol TCP -LocalPort 22 -Action Allow

# Then enable PowerShell SSH remoting on the client by specifying -HostName when creating sessions:
# New-PSSession -HostName remote.example.com -UserName user
```

Quick verification from the admin workstation
- From your admin machine you can test connectivity:

```powershell
# Test WinRM (WSMan) reachability
Test-WSMan -ComputerName remote-hostname

# Create a PSSession (you will be prompted for credentials)
$s = New-PSSession -ComputerName remote-hostname -Credential (Get-Credential)
Invoke-Command -Session $s -ScriptBlock { hostname; whoami }
Remove-PSSession -Session $s

# For SSH remoting
New-PSSession -HostName remote-hostname -UserName user
Enter-PSSession -HostName remote-hostname -UserName user
```

Notes
- Targets must have PowerShell Remoting enabled (`Enable-PSRemoting`) or an SSH server installed.
- For update enumeration and install, the `PSWindowsUpdate` module on the remote host is recommended.
- The tool uses `New-PSSession`/`Invoke-Command` and will prompt for credentials; use least-privilege accounts where possible.

Security
- Use this tool on trusted networks. Credentials are used to open remote sessions — handle with care.

Examples
- Connect to a host, view processes and services, check pending updates, install updates, reboot.
