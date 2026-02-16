import sql from 'mssql';
import { createLogger } from '../utils/logger.js';

const logger = createLogger('Database');

const config = {
  server: process.env.DB_SERVER,
  port: parseInt(process.env.DB_PORT) || 1433,
  database: process.env.DB_NAME,
  authentication: {
    type: 'default',
    options: {
      userName: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
    },
  },
  options: {
    encrypt: true,
    trustServerCertificate: true,
    enableKeepAlive: true,
  },
};

let pool = null;

export async function initializeDatabase() {
  try {
    pool = new sql.ConnectionPool(config);
    await pool.connect();
    logger.info('Database connected successfully');
    await createTables();
    return pool;
  } catch (error) {
    logger.error('Database connection error:', error);
    throw error;
  }
}

export async function createTables() {
  if (!pool) return;

  const request = pool.request();

  // Users table
  await request.query(`
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='users' AND xtype='U')
    CREATE TABLE users (
      id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
      username NVARCHAR(255) NOT NULL UNIQUE,
      email NVARCHAR(255) NOT NULL,
      displayName NVARCHAR(255),
      accountStatus NVARCHAR(50),
      lastModified DATETIME DEFAULT GETUTCDATE(),
      createdAt DATETIME DEFAULT GETUTCDATE()
    )
  `);

  // Licenses table
  await request.query(`
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='licenses' AND xtype='U')
    CREATE TABLE licenses (
      id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
      userId UNIQUEIDENTIFIER,
      licenseType NVARCHAR(100),
      sku NVARCHAR(100),
      status NVARCHAR(50),
      assignedDate DATETIME,
      expiryDate DATETIME,
      createdAt DATETIME DEFAULT GETUTCDATE(),
      FOREIGN KEY (userId) REFERENCES users(id)
    )
  `);

  // OneDrive Usage table
  await request.query(`
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='onedrive_usage' AND xtype='U')
    CREATE TABLE onedrive_usage (
      id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
      userId UNIQUEIDENTIFIER,
      storageUsedBytes BIGINT,
      storageQuotaBytes BIGINT,
      lastUpdated DATETIME,
      createdAt DATETIME DEFAULT GETUTCDATE(),
      FOREIGN KEY (userId) REFERENCES users(id)
    )
  `);

  // Group Memberships table
  await request.query(`
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='group_memberships' AND xtype='U')
    CREATE TABLE group_memberships (
      id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
      userId UNIQUEIDENTIFIER,
      groupName NVARCHAR(255),
      groupType NVARCHAR(50),
      joinedDate DATETIME,
      createdAt DATETIME DEFAULT GETUTCDATE(),
      FOREIGN KEY (userId) REFERENCES users(id)
    )
  `);

  // Reports table
  await request.query(`
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='reports' AND xtype='U')
    CREATE TABLE reports (
      id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
      reportType NVARCHAR(100),
      reportName NVARCHAR(255),
      generatedBy NVARCHAR(255),
      generatedAt DATETIME DEFAULT GETUTCDATE(),
      reportData NVARCHAR(MAX),
      status NVARCHAR(50)
    )
  `);

  logger.info('Database tables initialized');
}

export function getPool() {
  return pool;
}

export async function closeDatabase() {
  if (pool) {
    await pool.close();
    logger.info('Database connection closed');
  }
}
