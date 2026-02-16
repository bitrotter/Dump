import express from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { createLogger } from '../utils/logger.js';

const router = express.Router();
const logger = createLogger('Auth Routes');

// This is a placeholder - in production, validate against actual user database
const validUsers = {
  admin: '$2a$10$8P5VZP4HZt4oYz5h6vqb3OPST9/PgBkqquzi.Ss7KIUgO2T0jPMVm', // password: admin123
};

router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ message: 'Username and password required' });
    }

    const storedHash = validUsers[username];
    if (!storedHash) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const isPasswordValid = await bcrypt.compare(password, storedHash);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { username, role: 'admin' },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    logger.info(`User ${username} logged in`);
    res.json({ token, username });
  } catch (error) {
    logger.error('Login error:', error);
    res.status(500).json({ message: 'Login error' });
  }
});

router.post('/logout', (req, res) => {
  logger.info('User logged out');
  res.json({ message: 'Logged out successfully' });
});

export default router;
