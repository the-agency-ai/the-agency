'use client';

import { useState, useEffect, useCallback } from 'react';

type VaultStatus = 'uninitialized' | 'locked' | 'unlocked';
type SecretType = 'api_key' | 'token' | 'password' | 'certificate' | 'ssh_key' | 'env_var' | 'generic';

interface Secret {
  id: string;
  name: string;
  secretType: SecretType;
  ownerType: 'principal' | 'agent';
  ownerName: string;
  serviceName?: string;
  description?: string;
  expiresAt?: string;
  createdAt: string;
  updatedAt: string;
}

interface VaultStatusResponse {
  status: VaultStatus;
  secretCount?: number;
  createdAt?: string;
  hasRecoveryCodes?: boolean;
}

interface AuditLog {
  id: number;
  secretId: string;
  secretName: string;
  accessorType: string;
  accessorName: string;
  action: string;
  toolContext?: string;
  timestamp: string;
}

const SECRET_TYPE_LABELS: Record<SecretType, string> = {
  api_key: 'API Key',
  token: 'Token',
  password: 'Password',
  certificate: 'Certificate',
  ssh_key: 'SSH Key',
  env_var: 'Env Variable',
  generic: 'Generic',
};

const SECRET_TYPE_COLORS: Record<SecretType, string> = {
  api_key: 'bg-blue-100 text-blue-700',
  token: 'bg-purple-100 text-purple-700',
  password: 'bg-red-100 text-red-700',
  certificate: 'bg-green-100 text-green-700',
  ssh_key: 'bg-yellow-100 text-yellow-700',
  env_var: 'bg-cyan-100 text-cyan-700',
  generic: 'bg-gray-100 text-gray-700',
};

export default function SecretsPage() {
  const [vaultStatus, setVaultStatus] = useState<VaultStatusResponse | null>(null);
  const [secrets, setSecrets] = useState<Secret[]>([]);
  const [selectedSecret, setSelectedSecret] = useState<Secret | null>(null);
  const [revealedValue, setRevealedValue] = useState<string | null>(null);
  const [revealingValue, setRevealingValue] = useState(false);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [passphrase, setPassphrase] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [activeTab, setActiveTab] = useState<'secrets' | 'audit'>('secrets');

  const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3141/api';

  // Get auth headers including principal from localStorage
  const getHeaders = useCallback((includeJson = false): HeadersInit => {
    const headers: HeadersInit = {};
    const principal = typeof window !== 'undefined'
      ? localStorage.getItem('agencybench-principal')
      : null;

    if (principal) {
      headers['X-Agency-User'] = `principal:${principal}`;
    }

    if (includeJson) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }, []);

  const loadVaultStatus = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE}/secret/vault/status`, {
        headers: getHeaders(),
      });
      if (!response.ok) throw new Error('Failed to load vault status');
      const data = await response.json();
      setVaultStatus(data);
      return data;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load vault status');
      return null;
    }
  }, [API_BASE, getHeaders]);

  const loadSecrets = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE}/secret/list`, {
        headers: getHeaders(),
      });
      if (!response.ok) throw new Error('Failed to load secrets');
      const data = await response.json();
      setSecrets(data.secrets || []);
    } catch (err) {
      console.error('Failed to load secrets:', err);
    }
  }, [API_BASE, getHeaders]);

  const loadAuditLogs = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE}/secret/audit?limit=50`, {
        headers: getHeaders(),
      });
      if (!response.ok) throw new Error('Failed to load audit logs');
      const data = await response.json();
      setAuditLogs(data.logs || []);
    } catch (err) {
      console.error('Failed to load audit logs:', err);
    }
  }, [API_BASE, getHeaders]);

  useEffect(() => {
    const init = async () => {
      setLoading(true);
      const status = await loadVaultStatus();
      if (status?.status === 'unlocked') {
        await loadSecrets();
        await loadAuditLogs();
      }
      setLoading(false);
    };
    init();
  }, [loadVaultStatus, loadSecrets, loadAuditLogs]);

  const initVault = async () => {
    if (!passphrase || passphrase.length < 8) {
      setError('Passphrase must be at least 8 characters');
      return;
    }
    try {
      const response = await fetch(`${API_BASE}/secret/vault/init`, {
        method: 'POST',
        headers: getHeaders(true),
        body: JSON.stringify({ passphrase }),
      });
      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to initialize vault');
      }
      setPassphrase('');
      await loadVaultStatus();
      await loadSecrets();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to initialize vault');
    }
  };

  const unlockVault = async () => {
    if (!passphrase) {
      setError('Passphrase is required');
      return;
    }
    try {
      const response = await fetch(`${API_BASE}/secret/vault/unlock`, {
        method: 'POST',
        headers: getHeaders(true),
        body: JSON.stringify({ passphrase }),
      });
      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to unlock vault');
      }
      setPassphrase('');
      setError(null);
      await loadVaultStatus();
      await loadSecrets();
      await loadAuditLogs();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to unlock vault');
    }
  };

  const lockVault = async () => {
    try {
      await fetch(`${API_BASE}/secret/vault/lock`, { method: 'POST', headers: getHeaders() });
      setSecrets([]);
      setAuditLogs([]);
      setSelectedSecret(null);
      await loadVaultStatus();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to lock vault');
    }
  };

  const deleteSecret = async (secretId: string) => {
    if (!confirm('Are you sure you want to delete this secret?')) return;
    try {
      const response = await fetch(`${API_BASE}/secret/delete/${secretId}`, {
        method: 'POST',
        headers: getHeaders(),
      });
      if (!response.ok) throw new Error('Failed to delete secret');
      setSelectedSecret(null);
      setRevealedValue(null);
      await loadSecrets();
      await loadAuditLogs();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete secret');
    }
  };

  const fetchSecretValue = async (secretId: string) => {
    setRevealingValue(true);
    try {
      const response = await fetch(`${API_BASE}/secret/fetch/${secretId}`, {
        headers: getHeaders(),
      });
      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to fetch secret value');
      }
      const data = await response.json();
      setRevealedValue(data.value);
      // Refresh audit logs since we just fetched
      await loadAuditLogs();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch secret value');
    } finally {
      setRevealingValue(false);
    }
  };

  const handleSelectSecret = (secret: Secret) => {
    setSelectedSecret(secret);
    setRevealedValue(null); // Clear revealed value when selecting different secret
  };

  const formatTime = (ts: string) => {
    const date = new Date(ts);
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  // Create Secret Modal Component
  const CreateSecretModal = () => {
    const [name, setName] = useState('');
    const [value, setValue] = useState('');
    const [showValue, setShowValue] = useState(false);
    const [secretType, setSecretType] = useState<SecretType>('api_key');
    const [serviceName, setServiceName] = useState('');
    const [description, setDescription] = useState('');
    const [creating, setCreating] = useState(false);

    const handleCreate = async () => {
      if (!name || !value) return;
      setCreating(true);
      try {
        const response = await fetch(`${API_BASE}/secret/create`, {
          method: 'POST',
          headers: getHeaders(true),
          body: JSON.stringify({
            name,
            value,
            secretType,
            serviceName: serviceName || undefined,
            description: description || undefined,
          }),
        });
        if (!response.ok) {
          const data = await response.json();
          throw new Error(data.error || 'Failed to create secret');
        }
        setShowCreateModal(false);
        await loadSecrets();
        await loadAuditLogs();
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to create secret');
      } finally {
        setCreating(false);
      }
    };

    return (
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div className="bg-white rounded-xl p-6 w-full max-w-md">
          <h3 className="text-lg font-semibold mb-4">Create Secret</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="my-api-key"
                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-agency-500 focus:border-agency-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Value</label>
              <div className="relative">
                <input
                  type={showValue ? 'text' : 'password'}
                  value={value}
                  onChange={(e) => setValue(e.target.value)}
                  placeholder="Enter secret value"
                  autoComplete="off"
                  data-1p-ignore
                  data-lpignore="true"
                  className="w-full px-3 py-2 pr-16 border border-gray-200 rounded-lg focus:ring-agency-500 focus:border-agency-500"
                />
                <button
                  type="button"
                  onClick={() => setShowValue(!showValue)}
                  className="absolute right-2 top-1/2 -translate-y-1/2 px-2 py-1 text-xs text-gray-500 hover:text-gray-700 bg-gray-100 rounded"
                >
                  {showValue ? 'Hide' : 'Show'}
                </button>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
              <select
                value={secretType}
                onChange={(e) => setSecretType(e.target.value as SecretType)}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-agency-500 focus:border-agency-500"
              >
                {Object.entries(SECRET_TYPE_LABELS).map(([value, label]) => (
                  <option key={value} value={value}>{label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Service (optional)</label>
              <input
                type="text"
                value={serviceName}
                onChange={(e) => setServiceName(e.target.value)}
                placeholder="GitHub, AWS, etc."
                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-agency-500 focus:border-agency-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Description (optional)</label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="What is this secret for?"
                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-agency-500 focus:border-agency-500"
                rows={2}
              />
            </div>
          </div>
          <div className="flex gap-3 mt-6">
            <button
              onClick={() => setShowCreateModal(false)}
              className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200"
            >
              Cancel
            </button>
            <button
              onClick={handleCreate}
              disabled={!name || !value || creating}
              className="flex-1 px-4 py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700 disabled:opacity-50"
            >
              {creating ? 'Creating...' : 'Create'}
            </button>
          </div>
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center">
        <div className="text-gray-400">Loading vault status...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
          <p className="font-medium">Error</p>
          <p className="text-sm mt-1">{error}</p>
          <button
            onClick={() => { setError(null); loadVaultStatus(); }}
            className="mt-3 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  // Vault uninitialized or locked - show unlock/init UI
  if (vaultStatus?.status !== 'unlocked') {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh]">
        <div className="bg-white rounded-xl border border-gray-200 p-8 w-full max-w-md">
          <div className="text-center mb-6">
            <div className="text-4xl mb-4">
              {vaultStatus?.status === 'uninitialized' ? '🔐' : '🔒'}
            </div>
            <h2 className="text-xl font-semibold text-gray-900">
              {vaultStatus?.status === 'uninitialized' ? 'Initialize Vault' : 'Unlock Vault'}
            </h2>
            <p className="text-sm text-gray-500 mt-2">
              {vaultStatus?.status === 'uninitialized'
                ? 'Create a passphrase to secure your secrets'
                : 'Enter your passphrase to access secrets'}
            </p>
          </div>

          <div className="space-y-4">
            <input
              type="password"
              value={passphrase}
              onChange={(e) => setPassphrase(e.target.value)}
              placeholder={vaultStatus?.status === 'uninitialized' ? 'Create passphrase (min 8 chars)' : 'Enter passphrase'}
              className="w-full px-4 py-3 border border-gray-200 rounded-lg focus:ring-agency-500 focus:border-agency-500"
              onKeyDown={(e) => e.key === 'Enter' && (vaultStatus?.status === 'uninitialized' ? initVault() : unlockVault())}
            />
            <button
              onClick={vaultStatus?.status === 'uninitialized' ? initVault : unlockVault}
              className="w-full px-4 py-3 bg-agency-600 text-white rounded-lg hover:bg-agency-700 font-medium"
            >
              {vaultStatus?.status === 'uninitialized' ? 'Initialize Vault' : 'Unlock'}
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Vault unlocked - show secrets management
  return (
    <div className="flex flex-col h-[calc(100vh-8rem)]">
      {/* Header with tabs and actions */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex gap-2">
          <button
            onClick={() => setActiveTab('secrets')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              activeTab === 'secrets'
                ? 'bg-agency-600 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            Secrets ({secrets.length})
          </button>
          <button
            onClick={() => setActiveTab('audit')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              activeTab === 'audit'
                ? 'bg-agency-600 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            Audit Log
          </button>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setShowCreateModal(true)}
            className="px-4 py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700 text-sm font-medium"
          >
            + New Secret
          </button>
          <button
            onClick={lockVault}
            className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 text-sm font-medium"
          >
            Lock Vault
          </button>
        </div>
      </div>

      {activeTab === 'secrets' ? (
        <div className="flex flex-1 gap-4 min-h-0">
          {/* Secret List */}
          <div className="w-96 bg-white rounded-xl border border-gray-200 flex flex-col">
            <div className="flex-1 overflow-y-auto">
              {secrets.length === 0 ? (
                <div className="text-center py-8 text-gray-400">No secrets stored</div>
              ) : (
                secrets.map((secret) => (
                  <button
                    key={secret.id}
                    onClick={() => handleSelectSecret(secret)}
                    className={`w-full text-left p-3 border-b border-gray-100 hover:bg-gray-50 ${
                      selectedSecret?.id === secret.id ? 'bg-agency-50' : ''
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="font-mono text-sm text-gray-900">{secret.name}</span>
                          <span className={`text-xs px-1.5 py-0.5 rounded ${SECRET_TYPE_COLORS[secret.secretType]}`}>
                            {SECRET_TYPE_LABELS[secret.secretType]}
                          </span>
                        </div>
                        {secret.serviceName && (
                          <div className="text-xs text-gray-500 mt-1">{secret.serviceName}</div>
                        )}
                      </div>
                      <div className="text-xs text-gray-400 whitespace-nowrap">
                        {formatTime(secret.createdAt)}
                      </div>
                    </div>
                  </button>
                ))
              )}
            </div>
          </div>

          {/* Secret Detail */}
          <div className="flex-1 bg-white rounded-xl border border-gray-200 flex flex-col">
            {selectedSecret ? (
              <>
                <div className="p-4 border-b border-gray-200">
                  <div className="flex items-start justify-between">
                    <div>
                      <h2 className="text-lg font-medium text-gray-900">{selectedSecret.name}</h2>
                      <div className="flex items-center gap-2 mt-1">
                        <span className={`text-xs px-2 py-0.5 rounded ${SECRET_TYPE_COLORS[selectedSecret.secretType]}`}>
                          {SECRET_TYPE_LABELS[selectedSecret.secretType]}
                        </span>
                        {selectedSecret.serviceName && (
                          <span className="text-xs px-2 py-0.5 rounded bg-gray-100 text-gray-600">
                            {selectedSecret.serviceName}
                          </span>
                        )}
                      </div>
                    </div>
                    <button
                      onClick={() => deleteSecret(selectedSecret.id)}
                      className="px-3 py-1 text-sm text-red-600 hover:bg-red-50 rounded"
                    >
                      Delete
                    </button>
                  </div>
                </div>
                <div className="flex-1 p-4 overflow-y-auto">
                  {selectedSecret.description && (
                    <div className="mb-4">
                      <div className="text-xs font-medium text-gray-500 uppercase mb-1">Description</div>
                      <div className="text-sm text-gray-700">{selectedSecret.description}</div>
                    </div>
                  )}
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <div className="text-xs font-medium text-gray-500 uppercase mb-1">Owner</div>
                      <div className="text-gray-700">{selectedSecret.ownerType}:{selectedSecret.ownerName}</div>
                    </div>
                    <div>
                      <div className="text-xs font-medium text-gray-500 uppercase mb-1">Created</div>
                      <div className="text-gray-700">{formatTime(selectedSecret.createdAt)}</div>
                    </div>
                    <div>
                      <div className="text-xs font-medium text-gray-500 uppercase mb-1">Updated</div>
                      <div className="text-gray-700">{formatTime(selectedSecret.updatedAt)}</div>
                    </div>
                    {selectedSecret.expiresAt && (
                      <div>
                        <div className="text-xs font-medium text-gray-500 uppercase mb-1">Expires</div>
                        <div className="text-gray-700">{formatTime(selectedSecret.expiresAt)}</div>
                      </div>
                    )}
                  </div>

                  {/* Secret Value Section */}
                  <div className="mt-6 pt-4 border-t border-gray-200">
                    <div className="text-xs font-medium text-gray-500 uppercase mb-2">Secret Value</div>
                    {revealedValue !== null ? (
                      <div className="space-y-2">
                        <div className="bg-gray-50 rounded-lg p-3 font-mono text-sm text-gray-800 break-all">
                          {revealedValue}
                        </div>
                        <button
                          onClick={() => setRevealedValue(null)}
                          className="text-sm text-gray-500 hover:text-gray-700"
                        >
                          Hide Value
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => fetchSecretValue(selectedSecret.id)}
                        disabled={revealingValue}
                        className="px-4 py-2 bg-yellow-100 text-yellow-800 rounded-lg hover:bg-yellow-200 text-sm font-medium disabled:opacity-50"
                      >
                        {revealingValue ? 'Fetching...' : 'Reveal Value'}
                      </button>
                    )}
                    <p className="text-xs text-gray-400 mt-2">
                      Note: Revealing the value will be logged in the audit trail.
                    </p>
                  </div>
                </div>
              </>
            ) : (
              <div className="flex-1 flex items-center justify-center text-gray-400">
                Select a secret to view details
              </div>
            )}
          </div>
        </div>
      ) : (
        /* Audit Log Tab */
        <div className="flex-1 bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="overflow-y-auto h-full">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 sticky top-0">
                <tr>
                  <th className="text-left px-4 py-2 font-medium text-gray-600">Time</th>
                  <th className="text-left px-4 py-2 font-medium text-gray-600">Action</th>
                  <th className="text-left px-4 py-2 font-medium text-gray-600">Secret</th>
                  <th className="text-left px-4 py-2 font-medium text-gray-600">Accessor</th>
                  <th className="text-left px-4 py-2 font-medium text-gray-600">Context</th>
                </tr>
              </thead>
              <tbody>
                {auditLogs.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="text-center py-8 text-gray-400">No audit logs</td>
                  </tr>
                ) : (
                  auditLogs.map((log) => (
                    <tr key={log.id} className="border-t border-gray-100 hover:bg-gray-50">
                      <td className="px-4 py-2 text-gray-500">{formatTime(log.timestamp)}</td>
                      <td className="px-4 py-2">
                        <span className={`px-2 py-0.5 rounded text-xs ${
                          log.action === 'fetch' ? 'bg-yellow-100 text-yellow-700' :
                          log.action === 'create' ? 'bg-green-100 text-green-700' :
                          log.action === 'delete' ? 'bg-red-100 text-red-700' :
                          'bg-gray-100 text-gray-700'
                        }`}>
                          {log.action}
                        </span>
                      </td>
                      <td className="px-4 py-2 font-mono text-gray-700">{log.secretName}</td>
                      <td className="px-4 py-2 text-gray-600">{log.accessorType}:{log.accessorName}</td>
                      <td className="px-4 py-2 text-gray-500">{log.toolContext || '-'}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {showCreateModal && <CreateSecretModal />}
    </div>
  );
}
