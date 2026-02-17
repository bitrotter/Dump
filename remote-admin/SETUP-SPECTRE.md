Spectre.Console Setup for Remote Admin
======================================

The `remote-admin-spectre.ps1` script uses Spectre.Console for a rich, styled console interface.
This is a better alternative to Terminal.Gui with better PowerShell integration.

TL;DR (Fastest method)
----------------------

From the tools directory, run:

```powershell
nuget install Spectre.Console -OutputDirectory packages
pwsh -ExecutionPolicy Bypass -File .\remote-admin-spectre.ps1
```

That's it! You should see a styled console interface with tables and panels.

---

Requirements
- PowerShell 7.0+
- Spectre.Console NuGet package
- .NET 6.0+ runtime

Quick Start
-----------

### Option 1: Using nuget CLI (Recommended)

1. Verify you have nuget.exe. If not, download it:
   ```powershell
   $nugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
   [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
   Invoke-WebRequest -Uri $nugetUrl -OutFile "nuget.exe"
   ```

2. Install Spectre.Console:
   ```powershell
   nuget install Spectre.Console -OutputDirectory packages
   ```

3. Run the Spectre version:
   ```powershell
   pwsh -ExecutionPolicy Bypass -File .\remote-admin-spectre.ps1
   ```

### Option 2: Manual PowerShell Download

```powershell
# Download the NuGet package
$url = "https://www.nuget.org/api/v2/package/Spectre.Console"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile "Spectre.Console.nupkg"

# Extract (it's a ZIP file)
Expand-Archive -Path "Spectre.Console.nupkg" -DestinationPath "Spectre.Console_extracted"

# Copy DLL to packages folder
mkdir "packages\Spectre.Console\lib\net6.0" -Force | Out-Null
Copy-Item "Spectre.Console_extracted\lib\net6.0\Spectre.Console.dll" "packages\Spectre.Console\lib\net6.0\" -Force

# Clean up
Remove-Item "Spectre.Console_extracted" -Recurse -Force
Remove-Item "Spectre.Console.nupkg" -Force

# Run it
pwsh -ExecutionPolicy Bypass -File .\remote-admin-spectre.ps1
```

### Option 3: Using dotnet CLI

```powershell
# Create a temp project to extract the DLL
dotnet new console -n temp_spectre
cd temp_spectre
dotnet add package Spectre.Console

# Find and copy the DLL
$dll = Get-ChildItem -Recurse -Filter "Spectre.Console.dll" | Select-Object -First 1
mkdir ..\packages\Spectre.Console\lib\net6.0 -Force | Out-Null
Copy-Item $dll.FullName ..\packages\Spectre.Console\lib\net6.0\

# Clean up
cd ..
Remove-Item temp_spectre -Recurse

# Run it
pwsh -ExecutionPolicy Bypass -File .\remote-admin-spectre.ps1
```

Features
========

Spectre.Console provides:
- **Styled Tables** - Rich formatting for processes, services, users
- **Panels** - Organized display of health information
- **Figlet Text** - Large ASCII title
- **Markup** - Colors and text styling with [color]text[/] syntax
- **Input Prompts** - User-friendly input fields
- **Progress** - Progress bars (extensible for future use)

The interface includes:
1. Host selector with connectivity testing
2. Styled main menu
3. Rich panels for health data
4. Formatted tables for processes/services
5. Clean colored output

Keyboard Tips
=============
- Type hostname and press Enter
- Select service credentials
- Enter menu numbers (1-6)
- Press Enter to continue after viewing data

Troubleshooting
===============

"Spectre.Console not found"
- Run: `Get-ChildItem -Recurse packages\` to verify the DLL is there
- Ensure: `packages\Spectre.Console\lib\net6.0\Spectre.Console.dll` exists
- Rerun installation if needed

"Requires PowerShell 7.0"
- Use `pwsh` not `powershell`
- Install from: https://github.com/PowerShell/PowerShell/releases

"nuget is not recognized"
- Use Option 2 (PowerShell download) or Option 3 (dotnet CLI)

"nuget command failed"
- Check internet connection
- Try with `-Verbose` flag: `nuget install Spectre.Console -OutputDirectory packages -Verbose`

Why Spectre.Console over Terminal.Gui?
=======================================

Spectre.Console is better for PowerShell:
- Single dependency (vs Terminal.Gui's nested deps)
- Better PowerShell event handling
- More active maintenance
- Purpose-built for console apps
- Cleaner, more intuitive API
- Better text rendering and styling

Terminal.Gui remains in tools directory but requires complex setup.

Comparison Table
================

| Feature | CLI | ANSI TUI | Spectre | Terminal.Gui |
|---------|-----|---------|---------|--------------|
| Setup required | None | None | One DLL | Complex deps |
| Visual quality | Basic | Good | Excellent | Advanced |
| Tables | Text | ASCII | Styled | Fragmented |
| Colors | Yes | ANSI | Rich | Full |
| PowerShell friendly | Excellent | Excellent | Excellent | Poor |
| Reliability | ✓ | ✓ | ✓ | ⚠ |

Next Steps
==========

1. Install Spectre.Console (see Quick Start above)
2. Run: `pwsh -ExecutionPolicy Bypass -File .\remote-admin-spectre.ps1`
3. Enter a hostname to connect
4. Select menu options to view remote data

For issues, check the [Troubleshooting](#troubleshooting) section above.
