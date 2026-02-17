Terminal.Gui Setup for Remote Admin TUI
========================================

The `remote-admin-tui.ps1` script uses Terminal.Gui for a proper windowed console interface.
This guide shows how to set up the dependencies.

TL;DR (Fastest method if you don't have nuget)
-----------------------------------------------

Copy and paste this into PowerShell from the tools directory:

```powershell
$url = "https://www.nuget.org/api/v2/package/Terminal.Gui"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityPointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile "Terminal.Gui.nupkg"
Expand-Archive -Path "Terminal.Gui.nupkg" -DestinationPath "Terminal.Gui_extracted"
mkdir "packages\Terminal.Gui\lib\net6.0" -Force | Out-Null
Copy-Item "Terminal.Gui_extracted\lib\net6.0\Terminal.Gui.dll" "packages\Terminal.Gui\lib\net6.0\" -Force
Remove-Item "Terminal.Gui_extracted" -Recurse -Force
Remove-Item "Terminal.Gui.nupkg" -Force
pwsh -ExecutionPolicy Bypass -File .\remote-admin-tui.ps1
```

Done! If you see a Terminal.Gui window, it worked. Jump to [Keyboard Tips](#keyboard-tips) below.

---

Requirements
- PowerShell 7.0+
- Terminal.Gui NuGet package
- .NET 6.0+ runtime

Quick Start
-----------

Option 1: Using nuget CLI (if you have nuget.exe)
1. If you don't have nuget.exe, download it first:
   - Visit: https://www.nuget.org/downloads
   - Download the latest nuget.exe
   - Place it in your PATH or in the current directory
   
2. From the tools directory, run:
   
   ```powershell
   nuget install Terminal.Gui -OutputDirectory packages
   ```

3. Then run the TUI:
   
   ```powershell
   pwsh -ExecutionPolicy Bypass -File .\remote-admin-tui.ps1
   ```

Option 1b: Download nuget.exe without a browser
If you're working remotely or prefer command-line:

```powershell
# From tools directory, download nuget.exe directly
$nugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $nugetUrl -OutFile "nuget.exe"

# Then install Terminal.Gui
.\nuget.exe install Terminal.Gui -OutputDirectory packages
```

Option 2: Using dotnet CLI (if you have .NET SDK installed)
1. Ensure you have the .NET SDK installed (check: `dotnet --version`)
2. From the tools directory, run:
   
   ```powershell
   dotnet nuget install Terminal.Gui -OutputDirectory packages
   ```
   
   Or if that doesn't work, create a temp project:
   
   ```powershell
   dotnet new console -n temp_tui
   cd temp_tui
   dotnet add package Terminal.Gui
   
   # Find the DLL
   $dll = Get-ChildItem -Recurse -Path . -Filter "Terminal.Gui.dll" | Select-Object -First 1
   
   # Create output directory and copy
   mkdir ..\packages\Terminal.Gui\lib\net6.0 -Force
   Copy-Item $dll.FullName ..\packages\Terminal.Gui\lib\net6.0\
   
   cd ..
   Remove-Item temp_tui -Recurse
   ```

3. Then run the TUI:
   
   ```powershell
   pwsh -ExecutionPolicy Bypass -File .\remote-admin-tui.ps1
   ```

Option 3: Manual Download via PowerShell
1. From the tools directory, run this PowerShell script:
   
   ```powershell
   # Download Terminal.Gui NuGet package
   $url = "https://www.nuget.org/api/v2/package/Terminal.Gui"
   $output = "Terminal.Gui.nupkg"
   
   # Enable TLS 1.2 for downloads
   [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
   
   Write-Host "Downloading Terminal.Gui package..." -ForegroundColor Cyan
   Invoke-WebRequest -Uri $url -OutFile $output
   
   # Extract the nupkg (it's a ZIP file)
   Write-Host "Extracting..." -ForegroundColor Cyan
   Expand-Archive -Path $output -DestinationPath "Terminal.Gui_extracted"
   
   # Copy the DLL to the expected location
   mkdir "packages\Terminal.Gui\lib\net6.0" -Force | Out-Null
   Copy-Item "Terminal.Gui_extracted\lib\net6.0\Terminal.Gui.dll" "packages\Terminal.Gui\lib\net6.0\" -Force
   
   # Clean up
   Remove-Item "Terminal.Gui_extracted" -Recurse -Force
   Remove-Item $output -Force
   
   Write-Host "Installation complete!" -ForegroundColor Green
   ```

2. Then run the TUI:
   
   ```powershell
   pwsh -ExecutionPolicy Bypass -File .\remote-admin-tui.ps1
   ```

Option 3b: Manual Download via Web Browser
1. Visit: https://www.nuget.org/packages/Terminal.Gui/
2. Click the "Download package" link on the right side
3. Rename the downloaded `.nupkg` file to `.zip`
4. Extract the zip file
5. Navigate to `lib\net6.0\` inside the extracted folder
6. Copy `Terminal.Gui.dll` to: `tools\packages\Terminal.Gui\lib\net6.0\`
   (Create the folder structure if it doesn't exist)
7. Then run the TUI:
   
   ```powershell
   pwsh -ExecutionPolicy Bypass -File .\remote-admin-tui.ps1
   ```

Verify Installation
-------------------

After installing, test it:

```powershell
cd .\tools\
pwsh -ExecutionPolicy Bypass -File .\remote-admin-tui.ps1
```

You should see a Terminal.Gui window with a "Select Remote Host" dialog.

Architecture
============

The TUI uses:
- **Windows**: Frames containing UI elements
- **Dialogs**: Modal popups for confirmations and messages
- **ListView**: Menu selection with keyboard navigation
- **TextFields**: Input for hostnames and commands
- **Buttons**: Click handlers for actions
- **Status Labels**: Real-time feedback

The main flow:
1. Host selector window (enter hostname/IP)
2. Credential prompt (Get-Credential)
3. Main menu (ListView with operations)
4. Result windows (message boxes showing data)
5. Return to host selector on disconnect

Features
--------
- Real-time connection testing with visual feedback
- Nested windows and dialogs
- Keyboard navigation (arrow keys, Enter, Tab)
- Session management (auto-cleanup on exit)
- Live host data (processes, services, users, health)

Keyboard Tips
=============
- Arrow Up/Down: Navigate menu items
- Enter: Select an option
- Tab: Move between fields
- Esc: Close dialogs
- Click buttons with mouse (if supported in your terminal)

Troubleshooting
===============

"Terminal.Gui not found"
- Ensure packages/ folder is in the same directory as the script
- Verify the DLL is at: packages/Terminal.Gui*/lib/net6.0/Terminal.Gui.dll
- List your packages folder: `Get-ChildItem -Recurse packages\` to see what's there

"Requires PowerShell 7.0"
- Install PowerShell 7+ from: https://github.com/PowerShell/PowerShell/releases
- Run with: `pwsh remote-admin-tui.ps1` (not `powershell`)
- If you only have PowerShell 5.x, upgrade to pwsh (PowerShell Core)

"nuget is not recognized"
- You don't have nuget.exe in your PATH
- Use **Option 1b** (download it via PowerShell) or **Option 3** (PowerShell direct download)
- Alternatively, use **Option 2** (dotnet CLI) if you have .NET SDK installed

"dotnet is not recognized"
- You don't have the .NET SDK installed
- Download from: https://dotnet.microsoft.com/download
- Or use **Option 1b** or **Option 3** instead

"The '.nupkg' file format is not recognized"
- Windows may not have .nupkg associated with an archive tool
- Manually rename the file: `Rename-Item Terminal.Gui.nupkg Terminal.Gui.zip`
- Then right-click → Extract All, or use: `Expand-Archive Terminal.Gui.zip`

Performance
===========
On slower networks, result windows may take a few seconds to populate.
The script shows "Testing connectivity..." status while working.

Future Enhancements
===================
- Multi-host batch operations
- Tab support for multiple simultaneous connections
- Command history and saved favorites
- Custom color themes
- Scriptable actions (run preset command sequences)
