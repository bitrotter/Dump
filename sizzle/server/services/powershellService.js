import { spawn } from 'child_process';
import { createLogger } from '../utils/logger.js';

const logger = createLogger('PowerShell Service');

export async function executePowerShell(scriptContent) {
  return new Promise((resolve, reject) => {
    const ps = spawn('powershell.exe', [
      '-Command',
      scriptContent,
    ]);

    let stdoutData = '';
    let stderrData = '';

    ps.stdout.on('data', (data) => {
      stdoutData += data.toString();
    });

    ps.stderr.on('data', (data) => {
      stderrData += data.toString();
    });

    ps.on('close', (code) => {
      if (code === 0) {
        logger.info('PowerShell script executed successfully');
        resolve(stdoutData);
      } else {
        logger.error('PowerShell script error:', stderrData);
        reject(new Error(`PowerShell exited with code ${code}: ${stderrData}`));
      }
    });

    ps.on('error', (error) => {
      logger.error('PowerShell execution error:', error);
      reject(error);
    });
  });
}

export async function lockUser(username) {
  const script = `
    $user = Get-ADUser -Identity "${username}" -Properties Name, SamAccountName
    Disable-ADAccount -Identity $user.ObjectGUID
    Write-Output "User ${username} has been disabled"
  `;

  try {
    const result = await executePowerShell(script);
    logger.info(`User ${username} locked via PowerShell`);
    return result;
  } catch (error) {
    logger.error(`Error locking user ${username}:`, error);
    throw error;
  }
}

export async function unlockUser(username) {
  const script = `
    $user = Get-ADUser -Identity "${username}" -Properties Name, SamAccountName
    Enable-ADAccount -Identity $user.ObjectGUID
    Write-Output "User ${username} has been enabled"
  `;

  try {
    const result = await executePowerShell(script);
    logger.info(`User ${username} unlocked via PowerShell`);
    return result;
  } catch (error) {
    logger.error(`Error unlocking user ${username}:`, error);
    throw error;
  }
}

export async function generateLicenseReport() {
  const script = `
    Get-MsolAccountSku | Select-Object AccountSkuId, 
      @{Name="Active";Expression={$_.ActiveUnits}},
      @{Name="Consumed";Expression={$_.ConsumedUnits}},
      @{Name="Available";Expression={$_.ActiveUnits - $_.ConsumedUnits}} |
    ConvertTo-Json
  `;

  try {
    const result = await executePowerShell(script);
    logger.info('License report generated');
    return JSON.parse(result);
  } catch (error) {
    logger.error('Error generating license report:', error);
    throw error;
  }
}

export async function generateOneDriveUsageReport() {
  const script = `
    Get-SPOSite -IncludePersonalSite $true | Select-Object Url, Owner,
      @{Name="UsedGB";Expression={[math]::Round($_.StorageUsageCurrent/1024, 2)}},
      @{Name="QuotaGB";Expression={[math]::Round($_.StorageQuota/1024, 2)}} |
    ConvertTo-Json
  `;

  try {
    const result = await executePowerShell(script);
    logger.info('OneDrive usage report generated');
    return JSON.parse(result);
  } catch (error) {
    logger.error('Error generating OneDrive usage report:', error);
    throw error;
  }
}

export async function generateGroupMembershipReport(groupName) {
  const script = `
    $group = Get-ADGroup -Identity "${groupName}"
    Get-ADGroupMember -Identity $group.ObjectGUID |
    Select-Object Name, SamAccountName, ObjectClass |
    ConvertTo-Json
  `;

  try {
    const result = await executePowerShell(script);
    logger.info(`Group membership report generated for ${groupName}`);
    return JSON.parse(result);
  } catch (error) {
    logger.error(`Error generating group membership report for ${groupName}:`, error);
    throw error;
  }
}

export async function resetUserPassword(username, newPassword) {
  const script = `
    $user = Get-ADUser -Identity "${username}"
    $securePassword = ConvertTo-SecureString "${newPassword}" -AsPlainText -Force
    Set-ADAccountPassword -Identity $user.ObjectGUID -NewPassword $securePassword -Reset
    Write-Output "Password reset for ${username}"
  `;

  try {
    const result = await executePowerShell(script);
    logger.info(`Password reset for ${username}`);
    return result;
  } catch (error) {
    logger.error(`Error resetting password for ${username}:`, error);
    throw error;
  }
}

export async function unlockAdUser(username) {
  const script = `
    Get-ADUser -Identity "${username}" | Unlock-ADAccount
    Write-Output "User ${username} account unlocked"
  `;

  try {
    const result = await executePowerShell(script);
    logger.info(`User ${username} account unlocked`);
    return result;
  } catch (error) {
    logger.error(`Error unlocking user ${username} account:`, error);
    throw error;
  }
}
