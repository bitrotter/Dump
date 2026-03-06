# Action1 Scripts

PowerShell scripts for Action1 RMM automation.

## Setup

1. Install PSAction1 module:
   ```powershell
   Install-Module PSAction1
   ```

2. Set up authentication:
   ```powershell
   Set-Action1 -APIKey "your_api_key" -OrganizationID "your_org_id"
   ```

   Or set environment variables:
   - `$env:ACTION1_API_KEY`
   - `$env:ACTION1_ORG_ID`

## Scripts

- `Get-Action1EndpointInventory.ps1` - List all endpoints with OS, last check-in, status
- `Get-Action1MissingPatches.ps1` - Show missing updates across all machines
- `Get-Action1EndpointHealth.ps1` - Check online/offline status and stale endpoints
- `Get-Action1PatchCompliance.ps1` - Generate patch compliance report
