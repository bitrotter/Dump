# AD Sync Checker Tool

A PowerShell utility to verify that user attributes are correctly synced between local Active Directory and Azure AD.

## Features

- ✓ **Email** - Compares mail attributes
- ✓ **Phone** - Compares mobile phone numbers  
- ✓ **Department** - Compares department assignments
- ✓ **Job Title** - Compares job titles
- ✓ **Account Status** - Compares enabled/disabled state
- ✓ **Password Status** - Tracks password sync timing
- ✓ **Group Memberships** - Lists groups in both systems
- ✓ **Color-coded output** - Easy visual identification of sync issues
- ✓ **Detailed reports** - Shows exactly what's synced vs. mismatched

## Requirements

### Local Requirements
- **PowerShell 5.0 or higher**
- **Active Directory module** (RSAT - Remote Server Administration Tools)
  - Windows Server: `Add-WindowsFeature RSAT-AD-PowerShell`
  - Windows Client: Install RSAT from Microsoft or use `Add-WindowsCapability`
- **Domain membership** (must be run from a domain-joined computer)

### Azure AD Requirements
- **Azure AD App Registration** with delegated or application permissions:
  - `User.Read.All`
  - `Group.Read.All`
  - `Directory.Read.All`

## Setup

### 1. Create Azure AD App Registration

```powershell
# Using Azure CLI (recommended)
az ad app create --display-name "ADSyncChecker"

# Get the Application ID (Client ID) and Tenant ID
# Then create a client secret
az ad app credential create --id <app-id> --years 1

# Or manually in Azure Portal:
# 1. Go to Azure AD > App registrations
# 2. Create new registration
# 3. Add API permissions: Microsoft Graph > User.Read.All, Group.Read.All
# 4. Create a client secret
```

### 2. Set Environment Variables

You can set these permanently for your system:

**PowerShell (persistent):**
```powershell
[Environment]::SetEnvironmentVariable('AZURE_TENANT_ID', '<your-tenant-id>', 'User')
[Environment]::SetEnvironmentVariable('AZURE_CLIENT_ID', '<your-client-id>', 'User')
[Environment]::SetEnvironmentVariable('AZURE_CLIENT_SECRET', '<your-client-secret>', 'User')
```

**Command Prompt (persistent):**
```cmd
setx AZURE_TENANT_ID <your-tenant-id>
setx AZURE_CLIENT_ID <your-client-id>
setx AZURE_CLIENT_SECRET <your-client-secret>
```

**Or set temporarily in PowerShell session:**
```powershell
$env:AZURE_TENANT_ID = '<your-tenant-id>'
$env:AZURE_CLIENT_ID = '<your-client-id>'
$env:AZURE_CLIENT_SECRET = '<your-client-secret>'
```

## Usage

### Basic Usage
```powershell
.\check-ad-sync.ps1 -Username "john.doe"
```

### Using UPN (User Principal Name)
```powershell
.\check-ad-sync.ps1 -Username "john.doe@company.com"
```

### With Explicit Credentials (bypassing environment variables)
```powershell
.\check-ad-sync.ps1 -Username "jane.smith" `
    -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
    -ClientId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
    -ClientSecret "your-secret-key"
```

### Specifying Custom Attributes
```powershell
# Check only email and phone
.\check-ad-sync.ps1 -Username "john.doe" `
    -Attributes "email,phone"
```

## Output Example

```
================================================================================
Sync Status Report for: john.doe
================================================================================

Email
-----
Local AD                                ✓ john.doe@company.com
Azure AD                                ✓ john.doe@company.com

Phone
-----
Local AD                                ✓ +1-555-0123
Azure AD                                ✓ +1-555-0123

Department
----------
Local AD                                ✓ Engineering
Azure AD                                ✓ Engineering

Job Title
---------
Local AD                                ✓ Senior Developer
Azure AD                                ✓ Senior Developer

Account Status
--------------
Local AD                                ✓ Enabled
Azure AD                                ✓ Enabled

Password Status
---------------
Local AD Last Set                       2024-02-28 14:32:15
Azure AD Last Set                       2024-02-28 14:32:15
Password Sync Gap                       ✓ 0.0 hours

Group Memberships
-----------------
Local AD Groups (5):
  • Domain Users
  • Sales Team
  • All Staff
  • Engineering
  • VPN Users

Azure AD Groups (4):
  • All Staff
  • Sales Team
  • Engineering
  • VPN Users

================================================================================
Summary
================================================================================

Synced Attributes                       8
Mismatched Attributes                   0
Missing/Incomplete Data                 0

✓ All attributes are properly synced!
```

## Troubleshooting

### "Active Directory module not found"
- Install RSAT: `Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"`
- Restart PowerShell after installation

### "User not found in local Active Directory"
- Verify the username spelling
- Check that you're running on a domain-joined computer
- Verify domain connectivity with `nltest /dsgetdc:`

### "User not found in Azure AD"
- Verify the upn (user@company.com format)
- Check that Azure AD Connect (or similar) has synced the user
- Verify the user exists in Azure AD: `https://portal.azure.com` > Users

### "Failed to get Azure AD token"
- Verify credentials are correct in environment variables (no spaces)
- Ensure the App Registration has the required permissions granted
- Grant admin consent to the application
- Check that you're not using expired credentials

### "Permission denied" errors
- Ensure your app registration has the `User.Read.All` permission
- May need tenant administrator to grant admin consent
- In Azure Portal: App registration > API permissions > Grant admin consent

### Groups showing different counts
- Azure AD Connect doesn't sync all group types (only security groups by default)
- Distribution groups, M365 groups, and dynamic groups appear in Azure but not local AD
- This is expected behavior

## API Permissions Required (App Registration)

```
Microsoft Graph
  - User.Read.All (Application permission)
  - Group.Read.All (Application permission)
  - Directory.Read.All (Application permission)
```

## Security Notes

- ⚠️ **Never commit credentials to source control**
- Store secrets in Azure Key Vault in production
- Rotate secrets regularly (at least annually)
- Use certificate-based auth instead of secrets when possible
- Restrict app registration permissions to minimum required
- Only grant to trusted administrators

## Advanced Usage

### Checking Multiple Users
```powershell
@("john.doe", "jane.smith", "bob.johnson") | ForEach-Object {
    .\check-ad-sync.ps1 -Username $_
    Write-Host ""
}
```

### Batch Checking from CSV
```powershell
$users = Import-Csv "users.csv" | Select-Object -ExpandProperty Username
$users | ForEach-Object {
    Write-Host "Checking $_..." -ForegroundColor Cyan
    .\check-ad-sync.ps1 -Username $_ 2>$null
}
```

### Integrating with Monitoring
```powershell
# Run from Task Scheduler with logged output
.\check-ad-sync.ps1 -Username "user@company.com" | Tee-Object -FilePath ".\logs\sync-check-$(Get-Date -f yyyy-MM-dd).log"
```

## Related Tools

- **remote-admin.ps1** - Comprehensive remote administration tool
- **check-ad-sync.ps1** - This sync verification tool
- **Sizzle** - Web-based M365/Azure integration platform

## Support

For issues or enhancements, check:
1. Verify environment variables are properly set
2. Test Azure connection: `Invoke-RestMethod "https://graph.microsoft.com/v1.0/me" -Headers @{Authorization = "Bearer $token"}`
3. Check Azure permissions in Portal
4. Review script error messages for specific issues

---
Last Updated: March 2026
