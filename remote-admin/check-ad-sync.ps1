<#
.SYNOPSIS
    Checks if a user's attributes are correctly synced between local AD and Azure AD.

.DESCRIPTION
    This tool compares user attributes between local Active Directory and Azure AD.
    It highlights discrepancies and provides a sync status report.

.PARAMETER Username
    The username or UPN of the user to check (e.g., 'john.doe' or 'john.doe@company.com')

.PARAMETER Attributes
    Comma-separated list of attributes to compare. 
    Defaults to: email, phone, department, jobTitle, accountStatus, passwordSync, groups

.PARAMETER TenantId
    Azure AD Tenant ID. Falls back to $env:AZURE_TENANT_ID if not provided.

.PARAMETER ClientId
    Azure AD App Registration Client ID. Falls back to $env:AZURE_CLIENT_ID if not provided.

.PARAMETER ClientSecret
    Azure AD App Registration Client Secret. Falls back to $env:AZURE_CLIENT_SECRET if not provided.

.EXAMPLE
    .\check-ad-sync.ps1 -Username "john.doe"
    
.EXAMPLE
    .\check-ad-sync.ps1 -Username "jane.smith@company.com" -Attributes "email, phone, department, accountStatus"
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="Username or UPN (e.g., 'john.doe' or 'john.doe@company.com')")]
    [string]$Username,

    [Parameter(Mandatory=$false)]
    [string]$Attributes = "email,phone,department,jobTitle,accountStatus,passwordSync,groups",

    [Parameter(Mandatory=$false)]
    [string]$TenantId = $env:AZURE_TENANT_ID,

    [Parameter(Mandatory=$false)]
    [string]$ClientId = $env:AZURE_CLIENT_ID,

    [Parameter(Mandatory=$false)]
    [string]$ClientSecret = $env:AZURE_CLIENT_SECRET
)

# Color codes for output
$colors = @{
    'Good'       = 'Green'
    'Warning'    = 'Yellow'
    'Error'      = 'Red'
    'Info'       = 'Cyan'
    'Muted'      = 'Gray'
}

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host ""
}

function Write-Subheader {
    param([string]$Text)
    Write-Host ""
    Write-Host $Text -ForegroundColor Yellow
    Write-Host ("-" * $Text.Length) -ForegroundColor Yellow
}

function Write-Status {
    param([string]$Title, [string]$Value, [string]$Status = 'Info')
    $padLength = 40
    $paddedTitle = $Title.PadRight($padLength)
    Write-Host $paddedTitle -NoNewline
    if ($Status -eq 'Synced') {
        Write-Host "✓ $Value" -ForegroundColor Green
    } elseif ($Status -eq 'Mismatch') {
        Write-Host "✗ $Value" -ForegroundColor Red
    } elseif ($Status -eq 'Missing') {
        Write-Host "⚠ $Value" -ForegroundColor Yellow
    } else {
        Write-Host "$Value" -ForegroundColor $colors[$Status]
    }
}

function Test-PrerequisiteModules {
    Write-Host "Checking prerequisites..." -ForegroundColor Cyan
    
    # Check for Active Directory module
    try {
        Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false | Out-Null
        Write-Host "  ✓ Active Directory module loaded" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ FATAL: Active Directory module not found!" -ForegroundColor Red
        Write-Host "    Install RSAT (Remote Server Administration Tools) and enable AD module" -ForegroundColor Gray
        exit 1
    }
}

function Get-AzureADToken {
    param([string]$TenantId, [string]$ClientId, [string]$ClientSecret)
    
    if (-not $TenantId -or -not $ClientId -or -not $ClientSecret) {
        Write-Host "ERROR: Azure AD credentials not provided." -ForegroundColor Red
        Write-Host "  Set environment variables:" -ForegroundColor Gray
        Write-Host "    AZURE_TENANT_ID" -ForegroundColor Gray
        Write-Host "    AZURE_CLIENT_ID" -ForegroundColor Gray
        Write-Host "    AZURE_CLIENT_SECRET" -ForegroundColor Gray
        Write-Host "  Or pass them as parameters." -ForegroundColor Gray
        exit 1
    }

    try {
        $tokenBody = @{
            Grant_Type    = "client_credentials"
            Scope         = "https://graph.microsoft.com/.default"
            Client_Id     = $ClientId
            Client_Secret = $ClientSecret
        }
        
        $response = Invoke-RestMethod `
            -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
            -Method POST `
            -Body $tokenBody `
            -ErrorAction Stop
        
        return $response.access_token
    } catch {
        Write-Host "ERROR: Failed to get Azure AD token: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

function Get-LocalADUser {
    param([string]$Username)
    
    try {
        # Try to find by SAM account name first (e.g., 'john.doe')
        $user = Get-ADUser -Filter "SamAccountName -eq '$Username'" `
            -Properties Mail, MobilePhone, Department, Title, Enabled, PasswordLastSet, MemberOf `
            -ErrorAction Stop
        
        if (-not $user) {
            # Try by UPN (e.g., 'john.doe@company.com')
            $user = Get-ADUser -Filter "UserPrincipalName -eq '$Username'" `
                -Properties Mail, MobilePhone, Department, Title, Enabled, PasswordLastSet, MemberOf `
                -ErrorAction Stop
        }
        
        return $user
    } catch {
        return $null
    }
}

function Get-AzureADUser {
    param([string]$Token, [string]$Username)
    
    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
            "Content-Type"  = "application/json"
        }
        
        # Try by UPN first
        $upn = if ($Username -like "*@*") { $Username } else { "$Username@*" }
        
        $uri = "https://graph.microsoft.com/v1.0/users?`$filter=userPrincipalName eq '$($upn.Replace('@*', ''))'&`$select=userPrincipalName,mail,mobilePhone,department,jobTitle,accountEnabled,passwordLastSet,id"
        
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
        
        if ($response.value -and $response.value.Count -gt 0) {
            return $response.value[0]
        }
        
        # Try by mail/email
        if ($Username -like "*@*") {
            $uri = "https://graph.microsoft.com/v1.0/users?`$filter=mail eq '$Username'&`$select=userPrincipalName,mail,mobilePhone,department,jobTitle,accountEnabled,passwordLastSet,id"
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
            if ($response.value -and $response.value.Count -gt 0) {
                return $response.value[0]
            }
        }
        
        return $null
    } catch {
        return $null
    }
}

function Get-AzureADUserGroups {
    param([string]$Token, [string]$UserId)
    
    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
            "Content-Type"  = "application/json"
        }
        
        $uri = "https://graph.microsoft.com/v1.0/users/$UserId/memberOf?`$select=displayName,mail"
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET -ErrorAction Stop
        
        return $response.value
    } catch {
        return @()
    }
}

function Compare-Users {
    param($LocalUser, $AzureUser, $Token)
    
    $syncStatus = @{
        'Synced'    = 0
        'Mismatch'  = 0
        'Missing'   = 0
    }
    
    Write-Header "Sync Status Report for: $Username"
    
    # Email comparison
    Write-Subheader "Email"
    $localEmail = $LocalUser.Mail
    $azureEmail = $AzureUser.mail
    
    if ($localEmail -and $azureEmail) {
        if ($localEmail -eq $azureEmail) {
            Write-Status "Local AD" $localEmail "Synced"
            Write-Status "Azure AD" $azureEmail "Synced"
            $syncStatus['Synced']++
        } else {
            Write-Status "Local AD" $localEmail "Mismatch"
            Write-Status "Azure AD" $azureEmail "Mismatch"
            $syncStatus['Mismatch']++
        }
    } elseif (-not $localEmail) {
        Write-Status "Local AD" "Not set" "Missing"
        Write-Status "Azure AD" $azureEmail "Info"
        $syncStatus['Missing']++
    } else {
        Write-Status "Local AD" $localEmail "Info"
        Write-Status "Azure AD" "Not set" "Missing"
        $syncStatus['Missing']++
    }
    
    # Phone comparison
    Write-Subheader "Phone"
    $localPhone = $LocalUser.MobilePhone
    $azurePhone = $AzureUser.mobilePhone
    
    if ($localPhone -and $azurePhone) {
        if ($localPhone -eq $azurePhone) {
            Write-Status "Local AD" $localPhone "Synced"
            Write-Status "Azure AD" $azurePhone "Synced"
            $syncStatus['Synced']++
        } else {
            Write-Status "Local AD" $localPhone "Mismatch"
            Write-Status "Azure AD" $azurePhone "Mismatch"
            $syncStatus['Mismatch']++
        }
    } elseif ($localPhone -or $azurePhone) {
        Write-Status "Local AD" ($localPhone -or "Not set") "Warning"
        Write-Status "Azure AD" ($azurePhone -or "Not set") "Warning"
        $syncStatus['Missing']++
    } else {
        Write-Status "Both" "Not set" "Muted"
    }
    
    # Department comparison
    Write-Subheader "Department"
    $localDept = $LocalUser.Department
    $azureDept = $AzureUser.department
    
    if ($localDept -and $azureDept) {
        if ($localDept -eq $azureDept) {
            Write-Status "Local AD" $localDept "Synced"
            Write-Status "Azure AD" $azureDept "Synced"
            $syncStatus['Synced']++
        } else {
            Write-Status "Local AD" $localDept "Mismatch"
            Write-Status "Azure AD" $azureDept "Mismatch"
            $syncStatus['Mismatch']++
        }
    } elseif ($localDept -or $azureDept) {
        Write-Status "Local AD" ($localDept -or "Not set") "Warning"
        Write-Status "Azure AD" ($azureDept -or "Not set") "Warning"
        $syncStatus['Missing']++
    } else {
        Write-Status "Both" "Not set" "Muted"
    }
    
    # Job Title comparison
    Write-Subheader "Job Title"
    $localTitle = $LocalUser.Title
    $azureTitle = $AzureUser.jobTitle
    
    if ($localTitle -and $azureTitle) {
        if ($localTitle -eq $azureTitle) {
            Write-Status "Local AD" $localTitle "Synced"
            Write-Status "Azure AD" $azureTitle "Synced"
            $syncStatus['Synced']++
        } else {
            Write-Status "Local AD" $localTitle "Mismatch"
            Write-Status "Azure AD" $azureTitle "Mismatch"
            $syncStatus['Mismatch']++
        }
    } elseif ($localTitle -or $azureTitle) {
        Write-Status "Local AD" ($localTitle -or "Not set") "Warning"
        Write-Status "Azure AD" ($azureTitle -or "Not set") "Warning"
        $syncStatus['Missing']++
    } else {
        Write-Status "Both" "Not set" "Muted"
    }
    
    # Account Status comparison
    Write-Subheader "Account Status"
    $localEnabled = $LocalUser.Enabled
    $azureEnabled = $AzureUser.accountEnabled
    
    if ($localEnabled -eq $azureEnabled) {
        $statusStr = if ($localEnabled) { "Enabled" } else { "Disabled" }
        Write-Status "Local AD" $statusStr "Synced"
        Write-Status "Azure AD" $statusStr "Synced"
        $syncStatus['Synced']++
    } else {
        Write-Status "Local AD" (if ($localEnabled) { "Enabled" } else { "Disabled" }) "Mismatch"
        Write-Status "Azure AD" (if ($azureEnabled) { "Enabled" } else { "Disabled" }) "Mismatch"
        $syncStatus['Mismatch']++
    }
    
    # Password sync status
    Write-Subheader "Password Status"
    $localPwdLastSet = $LocalUser.PasswordLastSet
    $azurePwdLastSet = $AzureUser.passwordLastSet
    
    if ($localPwdLastSet) {
        Write-Status "Local AD Last Set" $localPwdLastSet.ToString("yyyy-MM-dd HH:mm:ss") "Info"
    } else {
        Write-Status "Local AD Last Set" "Never set" "Warning"
    }
    
    if ($azurePwdLastSet) {
        Write-Status "Azure AD Last Set" $azurePwdLastSet.ToString("yyyy-MM-dd HH:mm:ss") "Info"
    } else {
        Write-Status "Azure AD Last Set" "Never set / Not available" "Muted"
    }
    
    if ($localPwdLastSet -and $azurePwdLastSet) {
        $diff = [math]::Abs(($localPwdLastSet - $azurePwdLastSet).TotalHours)
        if ($diff -lt 24) {
            Write-Status "Password Sync Gap" "$($diff.ToString('F1')) hours" "Synced"
            $syncStatus['Synced']++
        } else {
            Write-Status "Password Sync Gap" "$($diff.ToString('F1')) hours (>24h)" "Warning"
            $syncStatus['Missing']++
        }
    } else {
        Write-Status "Password Last Set" "Incomplete data in one or both systems" "Warning"
        $syncStatus['Missing']++
    }
    
    # Group Memberships
    Write-Subheader "Group Memberships"
    
    $localGroupNames = $LocalUser.MemberOf | ForEach-Object {
        $group = Get-ADGroup $_ -ErrorAction SilentlyContinue
        if ($group) { $group.Name }
    }
    
    $azureGroups = Get-AzureADUserGroups -Token $Token -UserId $AzureUser.id
    
    if ($localGroupNames -or $azureGroups) {
        Write-Host "Local AD Groups ($($localGroupNames.Count)):" -ForegroundColor Yellow
        if ($localGroupNames) {
            $localGroupNames | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }
        } else {
            Write-Host "  (None)" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "Azure AD Groups ($($azureGroups.Count)):" -ForegroundColor Yellow
        if ($azureGroups) {
            $azureGroups | ForEach-Object { Write-Host "  • $($_.displayName)" -ForegroundColor Gray }
        } else {
            Write-Host "  (None)" -ForegroundColor Gray
        }
        
        # This is informational only, groups are often not synced directly
        if ($localGroupNames.Count -eq $azureGroups.Count) {
            $syncStatus['Synced']++
        } else {
            $syncStatus['Missing']++
        }
    }
    
    # Summary
    Write-Header "Summary"
    Write-Status "Synced Attributes" $syncStatus['Synced'] "Good"
    Write-Status "Mismatched Attributes" $syncStatus['Mismatch'] (if ($syncStatus['Mismatch'] -gt 0) { 'Error' } else { 'Good' })
    Write-Status "Missing/Incomplete Data" $syncStatus['Missing'] (if ($syncStatus['Missing'] -gt 0) { 'Warning' } else { 'Good' })
    
    Write-Host ""
    if ($syncStatus['Mismatch'] -eq 0 -and $syncStatus['Missing'] -eq 0) {
        Write-Host "✓ All attributes are properly synced!" -ForegroundColor Green
    } elseif ($syncStatus['Mismatch'] -gt 0) {
        Write-Host "✗ There are mismatched attributes - manual verification may be needed" -ForegroundColor Red
    } else {
        Write-Host "⚠ Some attributes are missing or incomplete" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Main execution
Set-ErrorActionPreference -ErrorAction Continue
Test-PrerequisiteModules

Write-Host "Searching for user: $Username" -ForegroundColor Cyan
Write-Host ""

# Get local AD user
$localUser = Get-LocalADUser -Username $Username
if (-not $localUser) {
    Write-Host "ERROR: User '$Username' not found in local Active Directory" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Found in Local AD: $($localUser.SamAccountName)" -ForegroundColor Green

# Get Azure token
Write-Host "Authenticating to Azure AD..." -ForegroundColor Cyan
$token = Get-AzureADToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
Write-Host "✓ Azure AD authentication successful" -ForegroundColor Green

# Get Azure AD user
Write-Host "Searching in Azure AD..." -ForegroundColor Cyan
$azureUser = Get-AzureADUser -Token $token -Username $Username

if (-not $azureUser) {
    Write-Host "ERROR: User '$Username' not found in Azure AD" -ForegroundColor Red
    Write-Host "  This may indicate a sync issue" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Found in Azure AD: $($azureUser.userPrincipalName)" -ForegroundColor Green

# Compare users
Compare-Users -LocalUser $localUser -AzureUser $azureUser -Token $token
