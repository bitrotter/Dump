import express from 'express';
import * as powershellService from '../services/powershellService.js';
import { authenticate } from '../middleware/auth.js';
import { createLogger } from '../utils/logger.js';
import { getPool } from '../config/database.js';

const router = express.Router();
const logger = createLogger('Reports Routes');

router.use(authenticate);

// Generate license report
router.post('/licenses', async (req, res) => {
  try {
    const reportData = await powershellService.generateLicenseReport();
    const pool = getPool();

    if (pool) {
      await pool.request()
        .input('reportType', 'licenses')
        .input('reportName', 'License Report')
        .input('generatedBy', req.user?.username || 'system')
        .input('reportData', JSON.stringify(reportData))
        .input('status', 'completed')
        .query(`
          INSERT INTO reports (reportType, reportName, generatedBy, reportData, status)
          VALUES (@reportType, @reportName, @generatedBy, @reportData, @status)
        `);
    }

    logger.info('License report generated');
    res.json({ success: true, data: reportData });
  } catch (error) {
    logger.error('Error generating license report:', error);
    res.status(500).json({ message: 'Error generating license report' });
  }
});

// Generate OneDrive usage report
router.post('/onedrive-usage', async (req, res) => {
  try {
    const reportData = await powershellService.generateOneDriveUsageReport();
    const pool = getPool();

    if (pool) {
      await pool.request()
        .input('reportType', 'onedrive_usage')
        .input('reportName', 'OneDrive Usage Report')
        .input('generatedBy', req.user?.username || 'system')
        .input('reportData', JSON.stringify(reportData))
        .input('status', 'completed')
        .query(`
          INSERT INTO reports (reportType, reportName, generatedBy, reportData, status)
          VALUES (@reportType, @reportName, @generatedBy, @reportData, @status)
        `);
    }

    logger.info('OneDrive usage report generated');
    res.json({ success: true, data: reportData });
  } catch (error) {
    logger.error('Error generating OneDrive usage report:', error);
    res.status(500).json({ message: 'Error generating OneDrive usage report' });
  }
});

// Generate group membership report
router.post('/group-membership', async (req, res) => {
  try {
    const { groupName } = req.body;
    if (!groupName) {
      return res.status(400).json({ message: 'Group name required' });
    }

    const reportData = await powershellService.generateGroupMembershipReport(groupName);
    const pool = getPool();

    if (pool) {
      await pool.request()
        .input('reportType', 'group_membership')
        .input('reportName', `Group Membership Report - ${groupName}`)
        .input('generatedBy', req.user?.username || 'system')
        .input('reportData', JSON.stringify(reportData))
        .input('status', 'completed')
        .query(`
          INSERT INTO reports (reportType, reportName, generatedBy, reportData, status)
          VALUES (@reportType, @reportName, @generatedBy, @reportData, @status)
        `);
    }

    logger.info(`Group membership report generated for ${groupName}`);
    res.json({ success: true, data: reportData });
  } catch (error) {
    logger.error('Error generating group membership report:', error);
    res.status(500).json({ message: 'Error generating group membership report' });
  }
});

// Get all reports
router.get('/', async (req, res) => {
  try {
    const pool = getPool();
    const result = await pool.request()
      .query('SELECT id, reportType, reportName, generatedBy, generatedAt, status FROM reports ORDER BY generatedAt DESC');

    res.json(result.recordset);
  } catch (error) {
    logger.error('Error fetching reports:', error);
    res.status(500).json({ message: 'Error fetching reports' });
  }
});

// Get report by ID
router.get('/:id', async (req, res) => {
  try {
    const pool = getPool();
    const result = await pool.request()
      .input('id', req.params.id)
      .query('SELECT * FROM reports WHERE id = @id');

    if (result.recordset.length === 0) {
      return res.status(404).json({ message: 'Report not found' });
    }

    const report = result.recordset[0];
    report.reportData = JSON.parse(report.reportData);
    res.json(report);
  } catch (error) {
    logger.error('Error fetching report:', error);
    res.status(500).json({ message: 'Error fetching report' });
  }
});

export default router;
