import ldap from 'ldapjs';
import { createLogger } from '../utils/logger.js';

const logger = createLogger('LDAP Service');

let ldapClient = null;

export function initializeLDAP() {
  return new Promise((resolve, reject) => {
    ldapClient = ldap.createClient({
      url: process.env.LDAP_URL,
      timeout: 5000,
    });

    ldapClient.on('error', (err) => {
      logger.error('LDAP client error:', err);
      reject(err);
    });

    ldapClient.bind(process.env.LDAP_BIND_DN, process.env.LDAP_BIND_PASSWORD, (err) => {
      if (err) {
        logger.error('LDAP bind error:', err);
        reject(err);
      } else {
        logger.info('LDAP connected and bound successfully');
        resolve(ldapClient);
      }
    });
  });
}

export async function searchUsers(filter = '(objectClass=user)', attributes = ['cn', 'mail', 'userAccountControl', 'sAMAccountName']) {
  return new Promise((resolve, reject) => {
    const opts = {
      filter,
      scope: 'sub',
      attributes,
      sizeLimit: 0,
    };

    ldapClient.search(process.env.LDAP_BASE_DN, opts, (err, res) => {
      if (err) {
        logger.error('LDAP search error:', err);
        reject(err);
        return;
      }

      const users = [];
      res.on('searchEntry', (entry) => {
        users.push(entry.object);
      });

      res.on('error', (err) => {
        logger.error('LDAP search error:', err);
        reject(err);
      });

      res.on('end', () => {
        resolve(users);
      });
    });
  });
}

export async function findUserByUsername(username) {
  try {
    const filter = `(&(objectClass=user)(sAMAccountName=${username}))`;
    const users = await searchUsers(filter, ['cn', 'mail', 'userAccountControl', 'sAMAccountName', 'distinguishedName']);
    return users.length > 0 ? users[0] : null;
  } catch (error) {
    logger.error('Error finding user:', error);
    throw error;
  }
}

export async function disableUser(username) {
  try {
    const user = await findUserByUsername(username);
    if (!user) {
      throw new Error('User not found');
    }

    return new Promise((resolve, reject) => {
      const change = new ldap.Change({
        operation: 'replace',
        modification: {
          userAccountControl: [514], // Disabled account
        },
      });

      ldapClient.modify(user.distinguishedName, change, (err) => {
        if (err) {
          logger.error('Error disabling user:', err);
          reject(err);
        } else {
          logger.info(`User ${username} disabled successfully`);
          resolve(true);
        }
      });
    });
  } catch (error) {
    logger.error('Error disabling user:', error);
    throw error;
  }
}

export async function enableUser(username) {
  try {
    const user = await findUserByUsername(username);
    if (!user) {
      throw new Error('User not found');
    }

    return new Promise((resolve, reject) => {
      const change = new ldap.Change({
        operation: 'replace',
        modification: {
          userAccountControl: [512], // Enabled account
        },
      });

      ldapClient.modify(user.distinguishedName, change, (err) => {
        if (err) {
          logger.error('Error enabling user:', err);
          reject(err);
        } else {
          logger.info(`User ${username} enabled successfully`);
          resolve(true);
        }
      });
    });
  } catch (error) {
    logger.error('Error enabling user:', error);
    throw error;
  }
}

export async function getUserGroups(username) {
  try {
    const user = await findUserByUsername(username);
    if (!user) {
      throw new Error('User not found');
    }

    const filter = `(member=${user.distinguishedName})`;
    const groups = await searchUsers(filter, ['cn', 'mail', 'objectClass']);
    return groups;
  } catch (error) {
    logger.error('Error getting user groups:', error);
    throw error;
  }
}

export function closeLDAP() {
  if (ldapClient) {
    ldapClient.unbind((err) => {
      if (err) logger.error('Error closing LDAP connection:', err);
      else logger.info('LDAP connection closed');
    });
  }
}
