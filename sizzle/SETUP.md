# M365 Admin Portal - Setup Guide

## Prerequisites

Before starting the installation, ensure you have the following installed:

### 1. Node.js and npm
- **Download**: Visit [nodejs.org](https://nodejs.org/)
- **Version**: Node.js 16+ with npm 8+
- **Installation**: Run the installer and follow the prompts
- **Verify**: Open PowerShell and run:
  ```powershell
  node --version
  npm --version
  ```

### 2. SQL Server
- Download and install [SQL Server Express](https://www.microsoft.com/en-us/sql-server/sql-server-editions-express)
- Or use existing SQL Server instance
- Note the server name and credentials

### 3. Active Directory / LDAP
- Ensure you have access to an LDAP server or Active Directory
- Have admin credentials for LDAP bind operations

### 4. Microsoft 365 Admin Account
- M365 tenant admin access
- Azure application registration with permissions:
  - User.ReadWrite.All
  - Directory.ReadWrite.All
  - Organization.Read.All
  - Files.Read.All

### 5. PowerShell Requirements
- PowerShell 5.0+ (comes with Windows 10+)
- Required modules:
  - ActiveDirectory (for AD operations)
  - MSOnline (for M365 operations)
  - PnP.PowerShell (for SharePoint/OneDrive operations)

## Installation Steps

### Step 1: Install Node.js

1. Download from [nodejs.org](https://nodejs.org/)
2. Run the installer
3. Accept default options for most settings
4. Ensure "npm package manager" is checked
5. Complete installation
6. Restart your terminal/PowerShell

### Step 2: Clone or Extract Project

Navigate to the project directory in PowerShell.

### Step 3: Install Server Dependencies

```powershell
# From the project root directory
npm install
```

### Step 4: Install Client Dependencies

```powershell
cd client
npm install
cd ..
```

### Step 5: Configure Environment Variables

1. Copy `.env.example` to `.env`:
   ```powershell
   Copy-Item .env.example .env
   ```

2. Edit `.env` with your actual values:
   ```powershell
   notepad .env
   ```

3. Update the following sections:

   **Database Configuration:**
   ```
   DB_SERVER=your-server-name
   DB_PORT=1433
   DB_NAME=m365_admin_portal
   DB_USER=sa
   DB_PASSWORD=YourPassword123!
   ```

   **LDAP Configuration:**
   ```
   LDAP_URL=ldap://your-domain-controller:389
   LDAP_BASE_DN=dc=yourdomain,dc=com
   LDAP_BIND_DN=cn=Administrator,cn=users,dc=yourdomain,dc=com
   LDAP_BIND_PASSWORD=your-admin-password
   ```

   **M365 Configuration:**
   ```
   AZURE_TENANT_ID=your-tenant-id-from-azure
   AZURE_CLIENT_ID=your-client-id
   AZURE_CLIENT_SECRET=your-client-secret
   ```

   **Security:**
   ```
   JWT_SECRET=your-super-secret-key-min-32-chars
   JWT_EXPIRE=7d
   ```

### Step 6: Create Database

The application automatically creates tables on first run. Just ensure:
- SQL Server is running
- Connection string in `.env` is correct
- User has database creation permissions

### Step 7: Run the Application

**Option A: Development Mode**

Terminal 1 - Start backend:
```powershell
npm start
```

Terminal 2 - Start frontend:
```powershell
npm run client
```

**Option B: Build and Run for Production**

```powershell
npm run build
npm start
```

The application will be available at:
- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:5000`

## Getting Azure Credentials

1. Go to [Azure Portal](https://portal.azure.com/)
2. Navigate to "Azure Active Directory" → "App registrations"
3. Click "New registration"
4. Name: "M365 Admin Portal"
5. Supported account types: "Accounts in this organizational directory only"
6. Click "Register"
7. Copy and save:
   - Application (client) ID → `AZURE_CLIENT_ID`
   - Tenant ID → `AZURE_TENANT_ID`
8. Go to "Certificates & secrets"
9. Click "New client secret"
10. Set expiration and add
11. Copy the value → `AZURE_CLIENT_SECRET`
12. Go to "API permissions"
13. Click "Add a permission"
14. Select "Microsoft Graph"
15. Add the following permissions:
    - User.ReadWrite.All
    - Directory.ReadWrite.All
    - Organization.Read.All
    - Files.Read.All
16. Click "Grant admin consent"

## Installing PowerShell Modules (Windows Only)

Open PowerShell as Administrator and run:

```powershell
# For Active Directory operations
Install-Module -Name ActiveDirectory -Force

# For M365 operations
Install-Module -Name MSOnline -Force

# For SharePoint/OneDrive operations
Install-Module -Name PnP.PowerShell -Force
```

## First Login

1. Navigate to `http://localhost:3000`
2. Login with test credentials:
   - Username: `admin`
   - Password: `admin123`

**IMPORTANT**: Change these credentials in production!

## Troubleshooting

### "npm: command not found"
- Node.js is not installed or not in PATH
- Restart PowerShell or terminal after installing Node.js

### "LDAP connection refused"
- Check LDAP_URL and port in `.env`
- Verify LDAP server is running and accessible
- Check firewall settings

### "Database connection failed"
- Verify SQL Server is running
- Check connection string in `.env`
- Ensure database user exists and has permissions

### "M365 authentication failed"
- Verify Azure credentials in `.env`
- Check that app has the required permissions
- Ensure client secret hasn't expired

### PowerShell script errors
- Install required modules using commands above
- Check PowerShell execution policy: `Get-ExecutionPolicy`
- Set if needed: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Support

Refer to the main [README.md](../README.md) for more information.
