'use client';

import { useState, useEffect } from 'react';

interface Secret {
  id: number;
  secretId: string;
  name: string;
  secretType: string;
  ownerType: string;
  ownerName: string;
  serviceName: string | null;
  description: string | null;
  expiresAt: string | null;
  createdAt: string;
  updatedAt: string;
}

interface SecretListResponse {
  secrets: Secret[];
  total: number;
}

const TYPE_COLORS: Record<string, string> = {
  'api_key': 'bg-purple-100 text-purple-700',
  'token': 'bg-blue-100 text-blue-700',
  'password': 'bg-red-100 text-red-700',
  'certificate': 'bg-green-100 text-green-700',
  'ssh_key': 'bg-yellow-100 text-yellow-700',
  'generic': 'bg-gray-100 text-gray-600',
};

export default function SecretBenchPage() {
  const [secrets, setSecrets] = useState<Secret[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedSecret, setSelectedSecret] = useState<Secret | null>(null);
  const [filter, setFilter] = useState<string>('all');
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const [newSecret, setNewSecret] = useState({
    name: '',
    secretType: 'api_key',
    value: '',
    ownerType: 'principal',
    ownerName: '',
    serviceName: '',
    description: '',
  });

  const API_BASE = process.env.NEXT_PUBLIC_API_URL?.replace('/bug', '/secret') || 'http://localhost:3456/api/secret';

  useEffect(() => {
    loadSecrets();
  }, []);

  async function loadSecrets() {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE}/list?limit=100`);
      if (!response.ok) throw new Error('Failed to load secrets');
      const data: SecretListResponse = await response.json();
      setSecrets(data.secrets);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load secrets');
    } finally {
      setLoading(false);
    }
  }

  async function createSecret() {
    if (!newSecret.name.trim() || !newSecret.value.trim() || !newSecret.ownerName.trim()) {
      setActionError('Name, value, and owner are required');
      return;
    }

    setSubmitting(true);
    setActionError(null);

    try {
      const response = await fetch(`${API_BASE}/create`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newSecret),
      });

      if (!response.ok) throw new Error('Failed to create secret');

      setShowCreateForm(false);
      setNewSecret({
        name: '',
        secretType: 'api_key',
        value: '',
        ownerType: 'principal',
        ownerName: '',
        serviceName: '',
        description: '',
      });
      loadSecrets();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to create secret');
    } finally {
      setSubmitting(false);
    }
  }

  async function deleteSecret(secretId: string) {
    if (!confirm('Are you sure you want to delete this secret?')) return;

    setSubmitting(true);
    try {
      const response = await fetch(`${API_BASE}/delete/${secretId}`, { method: 'POST' });
      if (!response.ok) throw new Error('Failed to delete secret');
      loadSecrets();
      setSelectedSecret(null);
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Failed to delete secret');
    } finally {
      setSubmitting(false);
    }
  }

  const formatTime = (ts: string) => {
    const date = new Date(ts);
    return date.toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
  };

  const types = [...new Set(secrets.map(s => s.secretType))].sort();
  const filteredSecrets = filter === 'all' ? secrets : secrets.filter(s => s.secretType === filter);

  if (error) {
    return (
      <div className="p-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
          <p className="font-medium">Error loading secrets</p>
          <p className="text-sm mt-1">{error}</p>
          <button onClick={loadSecrets} className="mt-3 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700">
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-[calc(100vh-8rem)] gap-4">
      {/* Secret List */}
      <div className="w-96 bg-white rounded-xl border border-gray-200 flex flex-col">
        <div className="p-3 border-b border-gray-200 flex justify-between items-center">
          <select
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            className="px-3 py-1.5 text-sm border border-gray-200 rounded-lg"
          >
            <option value="all">All types</option>
            {types.map(t => <option key={t} value={t}>{t}</option>)}
          </select>
          <button
            onClick={() => setShowCreateForm(true)}
            className="px-3 py-1 text-sm bg-agency-600 text-white rounded-full hover:bg-agency-700"
          >
            + New
          </button>
        </div>

        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <div className="text-center py-8 text-gray-400">Loading...</div>
          ) : filteredSecrets.length === 0 ? (
            <div className="text-center py-8 text-gray-400">No secrets found</div>
          ) : (
            filteredSecrets.map((secret) => (
              <button
                key={secret.id}
                onClick={() => setSelectedSecret(secret)}
                className={`w-full text-left p-3 border-b border-gray-100 hover:bg-gray-50 ${
                  selectedSecret?.id === secret.id ? 'bg-agency-50' : ''
                }`}
              >
                <div className="flex items-center gap-2">
                  <span className={`text-xs px-1.5 py-0.5 rounded ${TYPE_COLORS[secret.secretType] || TYPE_COLORS.generic}`}>
                    {secret.secretType}
                  </span>
                  <span className="font-mono text-sm text-gray-900 truncate">{secret.name}</span>
                </div>
                <div className="flex items-center gap-2 mt-1 text-xs text-gray-500">
                  <span>{secret.ownerType}:{secret.ownerName}</span>
                  {secret.serviceName && <span>· {secret.serviceName}</span>}
                </div>
              </button>
            ))
          )}
        </div>

        <div className="p-3 border-t border-gray-200 text-xs text-gray-500">
          {secrets.length} secrets
        </div>
      </div>

      {/* Detail or Create */}
      <div className="flex-1 bg-white rounded-xl border border-gray-200 flex flex-col">
        {showCreateForm ? (
          <div className="p-4">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-medium">Create Secret</h2>
              <button onClick={() => setShowCreateForm(false)} className="text-gray-400 hover:text-gray-600">
                Cancel
              </button>
            </div>

            {actionError && (
              <div className="mb-4 p-3 bg-red-50 text-red-700 text-sm rounded-lg">{actionError}</div>
            )}

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Name *</label>
                <input
                  type="text"
                  value={newSecret.name}
                  onChange={(e) => setNewSecret({ ...newSecret, name: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                  placeholder="GITHUB_TOKEN"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Value *</label>
                <input
                  type="password"
                  value={newSecret.value}
                  onChange={(e) => setNewSecret({ ...newSecret, value: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg font-mono"
                  placeholder="ghp_xxxx..."
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                  <select
                    value={newSecret.secretType}
                    onChange={(e) => setNewSecret({ ...newSecret, secretType: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                  >
                    <option value="api_key">API Key</option>
                    <option value="token">Token</option>
                    <option value="password">Password</option>
                    <option value="certificate">Certificate</option>
                    <option value="ssh_key">SSH Key</option>
                    <option value="generic">Generic</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Service</label>
                  <input
                    type="text"
                    value={newSecret.serviceName}
                    onChange={(e) => setNewSecret({ ...newSecret, serviceName: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                    placeholder="GitHub, AWS, etc."
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Owner *</label>
                <input
                  type="text"
                  value={newSecret.ownerName}
                  onChange={(e) => setNewSecret({ ...newSecret, ownerName: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                  placeholder="Your name"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea
                  value={newSecret.description}
                  onChange={(e) => setNewSecret({ ...newSecret, description: e.target.value })}
                  rows={2}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                />
              </div>
              <button
                onClick={createSecret}
                disabled={submitting}
                className="w-full py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700 disabled:opacity-50"
              >
                {submitting ? 'Creating...' : 'Create Secret'}
              </button>
            </div>
          </div>
        ) : selectedSecret ? (
          <>
            <div className="p-4 border-b border-gray-200">
              <div className="flex items-center gap-2">
                <span className={`text-sm px-2 py-1 rounded ${TYPE_COLORS[selectedSecret.secretType] || TYPE_COLORS.generic}`}>
                  {selectedSecret.secretType}
                </span>
                <span className="font-mono text-lg text-gray-900">{selectedSecret.name}</span>
              </div>
              <div className="mt-2 text-sm text-gray-500">
                Owner: {selectedSecret.ownerType}:{selectedSecret.ownerName}
                {selectedSecret.serviceName && ` · Service: ${selectedSecret.serviceName}`}
              </div>
            </div>
            <div className="flex-1 p-4">
              {selectedSecret.description ? (
                <p className="text-gray-700">{selectedSecret.description}</p>
              ) : (
                <p className="text-gray-400 italic">No description</p>
              )}
              <div className="mt-4 p-4 bg-gray-50 rounded-lg font-mono text-sm">
                <div className="text-gray-500">Value: ••••••••••••••••</div>
                <button className="mt-2 text-xs text-agency-600 hover:underline">
                  Copy to clipboard
                </button>
              </div>
            </div>
            <div className="p-4 border-t border-gray-200 bg-gray-50 flex justify-between">
              <div className="text-xs text-gray-500">
                Created: {formatTime(selectedSecret.createdAt)}
              </div>
              <button
                onClick={() => deleteSecret(selectedSecret.secretId)}
                disabled={submitting}
                className="px-3 py-1 text-sm text-red-600 hover:bg-red-50 rounded disabled:opacity-50"
              >
                Delete
              </button>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            Select a secret to view details
          </div>
        )}
      </div>
    </div>
  );
}
