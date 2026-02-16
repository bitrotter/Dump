import axios from 'axios';
import { createLogger } from '../utils/logger.js';

const logger = createLogger('M365 Service');

let accessToken = null;
let tokenExpiry = null;

const graphEndpoint = 'https://graph.microsoft.com/v1.0';

export async function getAccessToken() {
  try {
    // Check if token is still valid
    if (accessToken && tokenExpiry && Date.now() < tokenExpiry) {
      return accessToken;
    }

    const response = await axios.post(
      `https://login.microsoftonline.com/${process.env.AZURE_TENANT_ID}/oauth2/v2.0/token`,
      {
        grant_type: 'client_credentials',
        client_id: process.env.AZURE_CLIENT_ID,
        client_secret: process.env.AZURE_CLIENT_SECRET,
        scope: 'https://graph.microsoft.com/.default',
      }
    );

    accessToken = response.data.access_token;
    tokenExpiry = Date.now() + response.data.expires_in * 1000;

    logger.info('M365 access token acquired');
    return accessToken;
  } catch (error) {
    logger.error('Error getting access token:', error);
    throw error;
  }
}

export async function getUsers() {
  try {
    const token = await getAccessToken();
    const response = await axios.get(`${graphEndpoint}/users`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
      params: {
        $select: 'id,userPrincipalName,displayName,mail,accountEnabled',
      },
    });

    return response.data.value;
  } catch (error) {
    logger.error('Error fetching users:', error);
    throw error;
  }
}

export async function disableUserM365(userId) {
  try {
    const token = await getAccessToken();
    await axios.patch(
      `${graphEndpoint}/users/${userId}`,
      { accountEnabled: false },
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      }
    );

    logger.info(`M365 user ${userId} disabled`);
    return true;
  } catch (error) {
    logger.error('Error disabling M365 user:', error);
    throw error;
  }
}

export async function getUserLicenses(userId) {
  try {
    const token = await getAccessToken();
    const response = await axios.get(`${graphEndpoint}/users/${userId}/licenseDetails`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    return response.data.value;
  } catch (error) {
    logger.error('Error fetching user licenses:', error);
    throw error;
  }
}

export async function getOrganizationLicenseSummary() {
  try {
    const token = await getAccessToken();
    const response = await axios.get(`${graphEndpoint}/subscribedSkus`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    return response.data.value.map((sku) => ({
      skuId: sku.skuId,
      skuPartNumber: sku.skuPartNumber,
      totalLicenses: sku.prepaidUnits.enabled,
      usedLicenses: sku.consumedUnits,
      availableLicenses: sku.prepaidUnits.enabled - sku.consumedUnits,
    }));
  } catch (error) {
    logger.error('Error fetching license summary:', error);
    throw error;
  }
}

export async function getUserOneDriveUsage(userId) {
  try {
    const token = await getAccessToken();
    const response = await axios.get(`${graphEndpoint}/users/${userId}/drive`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
      params: {
        $select: 'id,quota',
      },
    });

    return {
      driveId: response.data.id,
      totalQuota: response.data.quota.total,
      usedStorage: response.data.quota.used,
      remainingStorage: response.data.quota.remaining,
    };
  } catch (error) {
    logger.error('Error fetching OneDrive usage:', error);
    throw error;
  }
}

export async function getUserGroups(userId) {
  try {
    const token = await getAccessToken();
    const response = await axios.get(`${graphEndpoint}/users/${userId}/memberOf`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
      params: {
        $select: 'id,displayName,groupTypes',
      },
    });

    return response.data.value;
  } catch (error) {
    logger.error('Error fetching user groups:', error);
    throw error;
  }
}

export async function checkUserPermissions(userId, resourceId) {
  try {
    const token = await getAccessToken();
    // This would check permissions in SharePoint or other M365 resources
    const response = await axios.get(
      `${graphEndpoint}/users/${userId}/drive/items/${resourceId}/permissions`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      }
    );

    return response.data.value;
  } catch (error) {
    logger.error('Error checking permissions:', error);
    throw error;
  }
}
