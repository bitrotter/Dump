# Quick Start - AD Sync Checker

## 5-Minute Setup

### Step 1: Install Active Directory Tools (if needed)
```powershell
# Run as Administrator
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
```

### Step 2: Get Azure Credentials
From your Azure Administrator or Azure Portal:
- **Tenant ID**: Azure AD > Properties > Directory ID
- **Client ID** & **Secret**: Azure AD > App registrations > Your app > Credentials

### Step 3: Set Environment Variables (one-time)
```powershell
[Environment]::SetEnvironmentVariable('AZURE_TENANT_ID', 'your-tenant-id', 'User')
[Environment]::SetEnvironmentVariable('AZURE_CLIENT_ID', 'your-client-id', 'User')
[Environment]::SetEnvironmentVariable('AZURE_CLIENT_SECRET', 'your-secret', 'User')
```
**Restart PowerShell after setting variables**

### Step 4: Run the Tool
```powershell
cd 'remote-admin' folder location
.\check-ad-sync.ps1 -Username "john.doe"
```

## Common Commands

```powershell
# By username (SAM account)
.\check-ad-sync.ps1 -Username "jsmith"

# By email (UPN)
.\check-ad-sync.ps1 -Username "john.smith@company.com"

# Check multiple users
@("user1", "user2", "user3") | % { .\check-ad-sync.ps1 -Username $_ }
```

## What the Output Means

| Symbol | Meaning |
|--------|---------|
| ✓ | Attribute is synced correctly |
| ✗ | Attribute mismatch between AD systems |
| ⚠ | Missing or incomplete data |
| (gray) | Not applicable or not set |

## If Something Goes Wrong

**Problem**: "Active Directory module not found"
```powershell
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
```

**Problem**: "Authentication failed"
```powershell
# Verify environment variables
Write-Host "Tenant: $env:AZURE_TENANT_ID"
Write-Host "Client: $env:AZURE_CLIENT_ID"
# (Don't display secret!)
```

**Problem**: "User not found"
- Check username spelling
- Try with UPN format: `user@company.com`
- Ensure user exists in both AD and Azure AD

## Integration with Sizzle

This tool pairs well with the Sizzle M365 management platform. Both use the same Azure credentials approach.

---

See **README-AD-SYNC.md** for detailed documentation
