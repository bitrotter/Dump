# M365 Admin Portal

A comprehensive web application for managing Active Directory/LDAP users and M365 operations, including user lockdown, license reporting, OneDrive usage tracking, group memberships, and permissions management.

## Features

- **User Management**: Search, disable, enable, lock, and unlock users in Active Directory and M365
- **License Management**: View and report on M365 license allocation and usage
- **OneDrive Usage**: Track storage usage and quotas for user OneDrive accounts
- **Group Memberships**: View and manage user group memberships
- **Permissions Management**: Check and manage user permissions across resources
- **PowerShell Integration**: Execute PowerShell scripts for advanced operations
- **Reporting**: Generate comprehensive reports on licenses, usage, and group memberships
- **Audit Trail**: Track all administrative actions in the database

## Technology Stack

### Backend
- **Node.js** with Express.js
- **LDAP.js** for Active Directory integration
- **Microsoft Graph API** for M365 operations
- **SQL Server** for database
- **PowerShell** script execution
- **JWT** for authentication

### Frontend
- **React** with React Router
- **Axios** for API calls
- **CSS** for styling

## Prerequisites

- Node.js 14+ and npm
- SQL Server database
- Active Directory/LDAP server
- Microsoft 365 tenant with admin access
- PowerShell 5.0+ (for Windows)

## Installation

### 1. Clone the repository

```bash
git clone <repository-url>
cd sizzle
```

### 2. Install server dependencies

```bash
npm install
```

### 3. Install client dependencies

```bash
cd client
npm install
cd ..
```

### 4. Configure environment variables

Copy `.env.example` to `.env` and update with your settings:

```bash
cp .env.example .env
```

Edit `.env` with your:
- LDAP configuration
- M365/Azure credentials
- Database connection details
- JWT secret

### 5. Set up the database

The application will automatically create tables on startup. Ensure your SQL Server connection details are correct in `.env`.

## Running the Application

### Development Mode

**Terminal 1 - Start the server:**
```bash
npm start
```

**Terminal 2 - Start the React client:**
```bash
npm run client
```

The application will be available at `http://localhost:3000`

### Production Mode

```bash
npm run build
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout

### Users
- `GET /api/users` - Get all users
- `GET /api/users/:username` - Get user details
- `POST /api/users/:username/disable` - Disable user
- `POST /api/users/:username/enable` - Enable user
- `POST /api/users/:username/lock` - Lock user account
- `POST /api/users/:username/unlock` - Unlock user account
- `POST /api/users/:username/reset-password` - Reset password
- `GET /api/users/:username/groups` - Get user groups

### Licenses
- `GET /api/licenses/summary` - Get license summary
- `GET /api/licenses/:userId` - Get user licenses

### OneDrive
- `GET /api/onedrive/:userId/usage` - Get OneDrive usage
- `GET /api/onedrive/:userId/permissions/:resourceId` - Check permissions

### Groups
- `GET /api/groups/:username` - Get user groups (LDAP)
- `GET /api/groups/:userId/m365` - Get user groups (M365)

### Reports
- `POST /api/reports/licenses` - Generate license report
- `POST /api/reports/onedrive-usage` - Generate OneDrive usage report
- `POST /api/reports/group-membership` - Generate group membership report
- `GET /api/reports` - Get all reports
- `GET /api/reports/:id` - Get report details

## Configuration

### LDAP Configuration

In `.env`:

```
LDAP_URL=ldap://your-domain-controller:389
LDAP_BASE_DN=dc=yourdomain,dc=com
LDAP_BIND_DN=cn=admin,dc=yourdomain,dc=com
LDAP_BIND_PASSWORD=your-password
```

### M365/Azure Configuration

Register an application in Azure Portal and add to `.env`:

```
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret
```

Required permissions:
- User.ReadWrite.All
- Directory.ReadWrite.All
- Organization.Read.All
- Files.Read.All

### Database Configuration

Configure SQL Server connection in `.env`:

```
DB_SERVER=your-server
DB_PORT=1433
DB_NAME=m365_admin_portal
DB_USER=sa
DB_PASSWORD=your-password
```

## Security Considerations

1. **Change default credentials** in `server/routes/auth.js`
2. **Use environment variables** for sensitive data
3. **Enable HTTPS** in production
4. **Implement rate limiting** on API endpoints
5. **Add proper CORS configuration** for production
6. **Encrypt sensitive data** in the database
7. **Use strong JWT secrets**
8. **Implement audit logging** for all administrative actions

## Logging

Logs are stored in `logs/app.log` and console output. Configure log level in `.env`:

```
LOG_LEVEL=info
LOG_FILE=logs/app.log
```

## Troubleshooting

### LDAP Connection Issues
- Verify LDAP server is accessible
- Check credentials in `.env`
- Ensure firewall allows port 389 (or configured port)

### M365 API Issues
- Verify Azure credentials are correct
- Check that app has required permissions
- Ensure tokens are being refreshed properly

### Database Connection Issues
- Verify SQL Server is running
- Check connection string in `.env`
- Ensure database exists and user has permissions

### PowerShell Errors
- Verify PowerShell is installed and accessible
- Check execution policy allows script execution
- Verify required modules are installed (MSOnline, PNPPS, etc.)

## Contributing

Please follow the existing code structure and naming conventions. Submit pull requests for review.

## License

MIT

## Support

For issues and questions, please open an issue in the repository.

## Test Credentials

For testing purposes:
- Username: `admin`
- Password: `admin123`

**Note**: Change these credentials in production!

## Architecture

```
sizzle/
├── server/
│   ├── config/
│   │   └── database.js         # Database configuration and initialization
│   ├── middleware/
│   │   ├── auth.js             # Authentication and authorization
│   │   └── errorHandler.js     # Error handling middleware
│   ├── routes/
│   │   ├── auth.js             # Authentication endpoints
│   │   ├── users.js            # User management endpoints
│   │   ├── licenses.js         # License management endpoints
│   │   ├── onedrive.js         # OneDrive endpoints
│   │   ├── groups.js           # Group management endpoints
│   │   └── reports.js          # Reporting endpoints
│   ├── services/
│   │   ├── ldapService.js      # Active Directory/LDAP integration
│   │   ├── m365Service.js      # M365/Microsoft Graph integration
│   │   └── powershellService.js # PowerShell script execution
│   ├── utils/
│   │   └── logger.js           # Logging utility
│   └── index.js                # Express server entry point
├── client/
│   ├── public/
│   │   └── index.html          # React HTML entry point
│   ├── src/
│   │   ├── pages/
│   │   │   ├── LoginPage.js    # Login page component
│   │   │   ├── Dashboard.js    # Main dashboard component
│   │   │   ├── LoginPage.css   # Login page styles
│   │   │   └── Dashboard.css   # Dashboard styles
│   │   ├── App.js              # Root React component
│   │   ├── App.css             # App styles
│   │   ├── index.js            # React DOM render
│   │   └── index.css           # Global styles
│   └── package.json            # Client dependencies
├── .env.example                # Environment variables template
├── .gitignore                  # Git ignore file
├── package.json                # Server dependencies
└── README.md                   # This file
```

## Future Enhancements

- [ ] Two-factor authentication
- [ ] Advanced reporting and analytics
- [ ] Scheduled reports
- [ ] User provisioning workflows
- [ ] Enhanced audit logging
- [ ] Mobile application
- [ ] Integration with other identity providers
- [ ] Automated compliance reporting
