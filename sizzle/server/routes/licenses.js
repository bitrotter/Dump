import express from 'express';
import * as m365Service from '../services/m365Service.js';
import { authenticate } from '../middleware/auth.js';
import { createLogger } from '../utils/logger.js';

const router = express.Router();
const logger = createLogger('Licenses Routes');

router.use(authenticate);

// Get organization license summary
router.get('/summary', async (req, res) => {
  try {
    const licenses = await m365Service.getOrganizationLicenseSummary();
    res.json(licenses);
  } catch (error) {
    logger.error('Error fetching license summary:', error);
    res.status(500).json({ message: 'Error fetching license summary' });
  }
});

// Get user licenses
router.get('/:userId', async (req, res) => {
  try {
    const licenses = await m365Service.getUserLicenses(req.params.userId);
    res.json(licenses);
  } catch (error) {
    logger.error('Error fetching user licenses:', error);
    res.status(500).json({ message: 'Error fetching user licenses' });
  }
});

export default router;
