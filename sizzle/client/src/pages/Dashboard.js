import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './Dashboard.css';

function Dashboard() {
  const [activeTab, setActiveTab] = useState('users');
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [username, setUsername] = useState(localStorage.getItem('username'));

  const token = localStorage.getItem('token');
  const axiosConfig = {
    headers: { Authorization: `Bearer ${token}` },
  };

  useEffect(() => {
    if (activeTab === 'users') {
      fetchUsers();
    }
  }, [activeTab]);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const response = await axios.get('/api/users', axiosConfig);
      setUsers(response.data);
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setLoading(false);
    }
  };

  const disableUser = async (user) => {
    try {
      await axios.post(`/api/users/${user.sAMAccountName}/disable`, {}, axiosConfig);
      alert(`User ${user.sAMAccountName} disabled successfully`);
      fetchUsers();
    } catch (error) {
      alert('Error disabling user');
      console.error(error);
    }
  };

  const lockUser = async (user) => {
    try {
      await axios.post(`/api/users/${user.sAMAccountName}/lock`, {}, axiosConfig);
      alert(`User ${user.sAMAccountName} locked successfully`);
      fetchUsers();
    } catch (error) {
      alert('Error locking user');
      console.error(error);
    }
  };

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <div className="header-content">
          <h1>M365 Admin Portal</h1>
          <div className="user-info">
            <span>Welcome, {username}</span>
            <button onClick={() => {
              localStorage.removeItem('token');
              window.location.reload();
            }}>
              Logout
            </button>
          </div>
        </div>
      </header>

      <nav className="dashboard-nav">
        <button className={activeTab === 'users' ? 'active' : ''} onClick={() => setActiveTab('users')}>
          Users
        </button>
        <button className={activeTab === 'licenses' ? 'active' : ''} onClick={() => setActiveTab('licenses')}>
          Licenses
        </button>
        <button className={activeTab === 'onedrive' ? 'active' : ''} onClick={() => setActiveTab('onedrive')}>
          OneDrive
        </button>
        <button className={activeTab === 'groups' ? 'active' : ''} onClick={() => setActiveTab('groups')}>
          Groups
        </button>
        <button className={activeTab === 'reports' ? 'active' : ''} onClick={() => setActiveTab('reports')}>
          Reports
        </button>
      </nav>

      <main className="dashboard-content">
        {activeTab === 'users' && (
          <div className="tab-content">
            <h2>Users Management</h2>
            {loading ? (
              <p>Loading users...</p>
            ) : (
              <div className="users-table">
                <table>
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Username</th>
                      <th>Email</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {users.map((user, index) => (
                      <tr key={index}>
                        <td>{user.cn}</td>
                        <td>{user.sAMAccountName}</td>
                        <td>{user.mail || 'N/A'}</td>
                        <td>
                          <button onClick={() => disableUser(user)} className="btn-danger">
                            Disable
                          </button>
                          <button onClick={() => lockUser(user)} className="btn-warning">
                            Lock
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {activeTab === 'licenses' && (
          <div className="tab-content">
            <h2>License Management</h2>
            <p>License information and reporting</p>
          </div>
        )}

        {activeTab === 'onedrive' && (
          <div className="tab-content">
            <h2>OneDrive Usage</h2>
            <p>OneDrive storage usage and quotas</p>
          </div>
        )}

        {activeTab === 'groups' && (
          <div className="tab-content">
            <h2>Group Memberships</h2>
            <p>User group memberships and permissions</p>
          </div>
        )}

        {activeTab === 'reports' && (
          <div className="tab-content">
            <h2>Reports</h2>
            <p>Generate and view reports</p>
          </div>
        )}
      </main>
    </div>
  );
}

export default Dashboard;
