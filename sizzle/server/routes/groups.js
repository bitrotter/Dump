import express from 'express';
import * as m365Service from '../services/m365Service.js';
import * as ldapService from '../services/ldapService.js';
import { authenticate } from '../middleware/auth.js';
import { createLogger } from '../utils/logger.js';

const router = express.Router();
const logger = createLogger('Groups Routes');

router.use(authenticate);

// Get user groups
router.get('/:username', async (req, res) => {
  try {
    const groups = await ldapService.getUserGroups(req.params.username);
    res.json(groups);
  } catch (error) {
    logger.error('Error fetching user groups:', error);
    res.status(500).json({ message: 'Error fetching user groups' });
  }
});

// Get user M365 groups
router.get('/:userId/m365', async (req, res) => {
  try {
    const groups = await m365Service.getUserGroups(req.params.userId);
    res.json(groups);
  } catch (error) {
    logger.error('Error fetching M365 groups:', error);
    res.status(500).json({ message: 'Error fetching M365 groups' });
  }
});

export default router;
