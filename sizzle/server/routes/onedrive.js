import express from 'express';
import * as m365Service from '../services/m365Service.js';
import { authenticate } from '../middleware/auth.js';
import { createLogger } from '../utils/logger.js';

const router = express.Router();
const logger = createLogger('OneDrive Routes');

router.use(authenticate);

// Get user OneDrive usage
router.get('/:userId/usage', async (req, res) => {
  try {
    const usage = await m365Service.getUserOneDriveUsage(req.params.userId);
    res.json(usage);
  } catch (error) {
    logger.error('Error fetching OneDrive usage:', error);
    res.status(500).json({ message: 'Error fetching OneDrive usage' });
  }
});

// Get user permissions
router.get('/:userId/permissions/:resourceId', async (req, res) => {
  try {
    const permissions = await m365Service.checkUserPermissions(
      req.params.userId,
      req.params.resourceId
    );
    res.json(permissions);
  } catch (error) {
    logger.error('Error fetching permissions:', error);
    res.status(500).json({ message: 'Error fetching permissions' });
  }
});

export default router;
