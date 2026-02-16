import express from 'express';
import * as ldapService from '../services/ldapService.js';
import * as m365Service from '../services/m365Service.js';
import * as powershellService from '../services/powershellService.js';
import { authenticate } from '../middleware/auth.js';
import { createLogger } from '../utils/logger.js';

const router = express.Router();
const logger = createLogger('Users Routes');

router.use(authenticate);

// Get all users
router.get('/', async (req, res) => {
  try {
    const users = await ldapService.searchUsers();
    res.json(users);
  } catch (error) {
    logger.error('Error fetching users:', error);
    res.status(500).json({ message: 'Error fetching users' });
  }
});

// Get user by username
router.get('/:username', async (req, res) => {
  try {
    const user = await ldapService.findUserByUsername(req.params.username);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    logger.error('Error fetching user:', error);
    res.status(500).json({ message: 'Error fetching user' });
  }
});

// Disable user
router.post('/:username/disable', async (req, res) => {
  try {
    await ldapService.disableUser(req.params.username);
    await m365Service.disableUserM365(req.params.username);
    logger.info(`User ${req.params.username} disabled`);
    res.json({ message: 'User disabled successfully' });
  } catch (error) {
    logger.error('Error disabling user:', error);
    res.status(500).json({ message: 'Error disabling user' });
  }
});

// Enable user
router.post('/:username/enable', async (req, res) => {
  try {
    await ldapService.enableUser(req.params.username);
    logger.info(`User ${req.params.username} enabled`);
    res.json({ message: 'User enabled successfully' });
  } catch (error) {
    logger.error('Error enabling user:', error);
    res.status(500).json({ message: 'Error enabling user' });
  }
});

// Lock user
router.post('/:username/lock', async (req, res) => {
  try {
    await powershellService.lockUser(req.params.username);
    logger.info(`User ${req.params.username} locked`);
    res.json({ message: 'User locked successfully' });
  } catch (error) {
    logger.error('Error locking user:', error);
    res.status(500).json({ message: 'Error locking user' });
  }
});

// Unlock user
router.post('/:username/unlock', async (req, res) => {
  try {
    await powershellService.unlockUser(req.params.username);
    logger.info(`User ${req.params.username} unlocked`);
    res.json({ message: 'User unlocked successfully' });
  } catch (error) {
    logger.error('Error unlocking user:', error);
    res.status(500).json({ message: 'Error unlocking user' });
  }
});

// Reset password
router.post('/:username/reset-password', async (req, res) => {
  try {
    const { newPassword } = req.body;
    if (!newPassword) {
      return res.status(400).json({ message: 'New password required' });
    }

    await powershellService.resetUserPassword(req.params.username, newPassword);
    logger.info(`Password reset for ${req.params.username}`);
    res.json({ message: 'Password reset successfully' });
  } catch (error) {
    logger.error('Error resetting password:', error);
    res.status(500).json({ message: 'Error resetting password' });
  }
});

// Get user groups
router.get('/:username/groups', async (req, res) => {
  try {
    const groups = await ldapService.getUserGroups(req.params.username);
    res.json(groups);
  } catch (error) {
    logger.error('Error fetching user groups:', error);
    res.status(500).json({ message: 'Error fetching user groups' });
  }
});

export default router;
