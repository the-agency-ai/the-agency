'use client';

import { useState, useEffect, useCallback } from 'react';

// ─────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────

interface VaultStatus {
  initialized: boolean;
  locked: boolean;
  autoLockInMs?: number;
}

interface Secret {
  id: string;
  name: string;
  type: 'api_key' | 'oauth_token' | 'password' | 'certificate' | 'ssh_key' | 'generic';
  service?: string;
  owner: string;
  ownerType: 'agent' | 'principal' | 'system';
  expiresAt?: string;
  rotatedAt?: string;
  createdAt: string;
  updatedAt: string;
  tags?: string[];
  grants?: Grant[];
}

interface Grant {
  granteeId: string;
  granteeType: 'agent' | 'principal' | 'system';
  permissions: ('read' | 'rotate' | 'manage')[];
  expiresAt?: string;
}

interface AuditEntry {
  id: number;
  secretId: string;
  action: 'created' | 'accessed' | 'updated' | 'rotated' | 'deleted' | 'grant_added' | 'grant_removed';
  actorId: string;
  actorType: 'agent' | 'principal' | 'system';
  timestamp: string;
  details?: Record<string, unknown>;
}

interface SecretStats {
  total: number;
  byType: Record<string, number>;
  expiringIn7Days: number;
  accessesLast24h: number;
}

// ─────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3456/api/secret';

const TYPE_COLORS: Record<string, { bg: string; text: string }> = {
  api_key: { bg: 'bg-blue-100', text: 'text-blue-700' },
  oauth_token: { bg: 'bg-purple-100', text: 'text-purple-700' },
  password: { bg: 'bg-orange-100', text: 'text-orange-700' },
  certificate: { bg: 'bg-green-100', text: 'text-green-700' },
  ssh_key: { bg: 'bg-teal-100', text: 'text-teal-700' },
  generic: { bg: 'bg-gray-100', text: 'text-gray-700' },
};

const SECRET_TYPES = ['api_key', 'oauth_token', 'password', 'certificate', 'ssh_key', 'generic'] as const;

// ─────────────────────────────────────────────────────────────
// Utility Functions
// ─────────────────────────────────────────────────────────────

function formatTime(ts: string) {
  const date = new Date(ts);
  return date.toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function formatTimeUntil(ms: number) {
  if (ms <= 0) return 'now';
  const seconds = Math.floor(ms / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);

  if (hours > 0) return `${hours}h ${minutes % 60}m`;
  if (minutes > 0) return `${minutes}m ${seconds % 60}s`;
  return `${seconds}s`;
}

function isExpiringSoon(expiresAt?: string): boolean {
  if (!expiresAt) return false;
  const expiryDate = new Date(expiresAt);
  const sevenDaysFromNow = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  return expiryDate <= sevenDaysFromNow;
}

// ─────────────────────────────────────────────────────────────
// Components
// ─────────────────────────────────────────────────────────────

function TypeBadge({ type }: { type: string }) {
  const colors = TYPE_COLORS[type] || TYPE_COLORS.generic;
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${colors.bg} ${colors.text}`}>
      {type.replace('_', ' ')}
    </span>
  );
}

function StatCard({ label, value, sublabel, variant = 'default' }: {
  label: string;
  value: number | string;
  sublabel?: string;
  variant?: 'default' | 'error' | 'warning' | 'success';
}) {
  const variants = {
    default: 'bg-white border-gray-200',
    error: 'bg-red-50 border-red-200',
    warning: 'bg-yellow-50 border-yellow-200',
    success: 'bg-green-50 border-green-200',
  };

  return (
    <div className={`rounded-lg border p-4 ${variants[variant]}`}>
      <div className="text-sm text-gray-500">{label}</div>
      <div className="text-2xl font-semibold mt-1">{value}</div>
      {sublabel && <div className="text-xs text-gray-400 mt-1">{sublabel}</div>}
    </div>
  );
}

function VaultStatusIndicator({
  status,
  onUnlock,
  onLock
}: {
  status: VaultStatus;
  onUnlock: () => void;
  onLock: () => void;
}) {
  const [timeLeft, setTimeLeft] = useState<number>(status.autoLockInMs || 0);

  useEffect(() => {
    if (!status.locked && status.autoLockInMs) {
      setTimeLeft(status.autoLockInMs);
      const interval = setInterval(() => {
        setTimeLeft((prev) => Math.max(0, prev - 1000));
      }, 1000);
      return () => clearInterval(interval);
    }
  }, [status.locked, status.autoLockInMs]);

  if (!status.initialized) {
    return (
      <div className="flex items-center gap-2 px-3 py-1.5 bg-gray-100 rounded-lg">
        <span className="w-2 h-2 rounded-full bg-gray-400" />
        <span className="text-sm text-gray-600">Not initialized</span>
      </div>
    );
  }

  if (status.locked) {
    return (
      <button
        onClick={onUnlock}
        className="flex items-center gap-2 px-3 py-1.5 bg-red-100 hover:bg-red-200 rounded-lg transition-colors"
      >
        <svg className="w-4 h-4 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
        </svg>
        <span className="text-sm font-medium text-red-700">Vault Locked</span>
      </button>
    );
  }

  return (
    <div className="flex items-center gap-2">
      <div className="flex items-center gap-2 px-3 py-1.5 bg-green-100 rounded-lg">
        <svg className="w-4 h-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z" />
        </svg>
        <span className="text-sm font-medium text-green-700">Unlocked</span>
        {timeLeft > 0 && (
          <span className="text-xs text-green-600">
            (locks in {formatTimeUntil(timeLeft)})
          </span>
        )}
      </div>
      <button
        onClick={onLock}
        className="px-2 py-1 text-xs text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded transition-colors"
      >
        Lock now
      </button>
    </div>
  );
}

function UnlockModal({
  onUnlock,
  onCancel,
  error
}: {
  onUnlock: (passphrase: string) => void;
  onCancel: () => void;
  error?: string;
}) {
  const [passphrase, setPassphrase] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onUnlock(passphrase);
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-2 bg-agency-100 rounded-lg">
            <svg className="w-6 h-6 text-agency-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
          </div>
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Unlock Vault</h2>
            <p className="text-sm text-gray-500">Enter your passphrase to access secrets</p>
          </div>
        </div>

        <form onSubmit={handleSubmit}>
          <input
            type="password"
            value={passphrase}
            onChange={(e) => setPassphrase(e.target.value)}
            placeholder="Passphrase"
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500 mb-3"
            autoFocus
          />

          {error && (
            <div className="text-sm text-red-600 mb-3">{error}</div>
          )}

          <div className="flex gap-3">
            <button
              type="button"
              onClick={onCancel}
              className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 px-4 py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700"
            >
              Unlock
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function InitVaultModal({
  onInit,
  onCancel,
  error
}: {
  onInit: (passphrase: string) => void;
  onCancel: () => void;
  error?: string;
}) {
  const [passphrase, setPassphrase] = useState('');
  const [confirm, setConfirm] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (passphrase !== confirm) return;
    onInit(passphrase);
  };

  const passwordsMatch = passphrase === confirm;
  const isValid = passphrase.length >= 8 && passwordsMatch;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-2 bg-agency-100 rounded-lg">
            <svg className="w-6 h-6 text-agency-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
            </svg>
          </div>
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Initialize Vault</h2>
            <p className="text-sm text-gray-500">Create a new encrypted vault</p>
          </div>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="space-y-3 mb-4">
            <input
              type="password"
              value={passphrase}
              onChange={(e) => setPassphrase(e.target.value)}
              placeholder="Passphrase (min 8 characters)"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
              autoFocus
            />
            <input
              type="password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              placeholder="Confirm passphrase"
              className={`w-full px-3 py-2 border rounded-lg focus:ring-agency-500 focus:border-agency-500 ${
                confirm && !passwordsMatch ? 'border-red-300' : 'border-gray-300'
              }`}
            />
          </div>

          {confirm && !passwordsMatch && (
            <div className="text-sm text-red-600 mb-3">Passphrases do not match</div>
          )}

          {error && (
            <div className="text-sm text-red-600 mb-3">{error}</div>
          )}

          <div className="flex gap-3">
            <button
              type="button"
              onClick={onCancel}
              className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={!isValid}
              className="flex-1 px-4 py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Initialize
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function CreateSecretModal({
  onSubmit,
  onCancel,
  error
}: {
  onSubmit: (secret: { name: string; value: string; type: string; service?: string; owner: string; ownerType: string; expiresAt?: string; tags?: string[] }) => void;
  onCancel: () => void;
  error?: string;
}) {
  const [name, setName] = useState('');
  const [value, setValue] = useState('');
  const [type, setType] = useState<string>('api_key');
  const [service, setService] = useState('');
  const [owner, setOwner] = useState('');
  const [ownerType, setOwnerType] = useState<string>('principal');
  const [expiresAt, setExpiresAt] = useState('');
  const [tags, setTags] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({
      name,
      value,
      type,
      service: service || undefined,
      owner,
      ownerType,
      expiresAt: expiresAt || undefined,
      tags: tags ? tags.split(',').map(t => t.trim()) : undefined,
    });
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-lg p-6 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900">Create Secret</h2>
          <button onClick={onCancel} className="text-gray-400 hover:text-gray-600">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Name *</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g., OPENAI_API_KEY"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Value *</label>
            <textarea
              value={value}
              onChange={(e) => setValue(e.target.value)}
              placeholder="Secret value (will be encrypted)"
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500 font-mono text-sm"
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Type *</label>
              <select
                value={type}
                onChange={(e) => setType(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
              >
                {SECRET_TYPES.map((t) => (
                  <option key={t} value={t}>{t.replace('_', ' ')}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Service</label>
              <input
                type="text"
                value={service}
                onChange={(e) => setService(e.target.value)}
                placeholder="e.g., openai, github"
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Owner *</label>
              <input
                type="text"
                value={owner}
                onChange={(e) => setOwner(e.target.value)}
                placeholder="Owner name"
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Owner Type *</label>
              <select
                value={ownerType}
                onChange={(e) => setOwnerType(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
              >
                <option value="principal">Principal</option>
                <option value="agent">Agent</option>
                <option value="system">System</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Expires At</label>
            <input
              type="datetime-local"
              value={expiresAt}
              onChange={(e) => setExpiresAt(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Tags</label>
            <input
              type="text"
              value={tags}
              onChange={(e) => setTags(e.target.value)}
              placeholder="Comma-separated tags"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-agency-500 focus:border-agency-500"
            />
          </div>

          {error && (
            <div className="text-sm text-red-600">{error}</div>
          )}

          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={onCancel}
              className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 px-4 py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700"
            >
              Create Secret
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function SecretDetailPanel({
  secret,
  vaultLocked,
  onClose,
  onReveal,
  onRotate,
  onDelete,
  onAddGrant,
  onRemoveGrant,
  revealedValue,
  revealError,
  auditLog,
}: {
  secret: Secret;
  vaultLocked: boolean;
  onClose: () => void;
  onReveal: () => void;
  onRotate: () => void;
  onDelete: () => void;
  onAddGrant: (grant: Omit<Grant, 'expiresAt'> & { expiresAt?: string }) => void;
  onRemoveGrant: (granteeId: string) => void;
  revealedValue?: string;
  revealError?: string;
  auditLog: AuditEntry[];
}) {
  const [showRevealWarning, setShowRevealWarning] = useState(false);
  const [showAddGrant, setShowAddGrant] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [newGranteeId, setNewGranteeId] = useState('');
  const [newGranteeType, setNewGranteeType] = useState<'agent' | 'principal' | 'system'>('agent');
  const [newGrantPermissions, setNewGrantPermissions] = useState<('read' | 'rotate' | 'manage')[]>(['read']);
  const [activeTab, setActiveTab] = useState<'details' | 'grants' | 'audit'>('details');

  const handleRevealClick = () => {
    if (!revealedValue) {
      setShowRevealWarning(true);
    }
  };

  const handleConfirmReveal = () => {
    setShowRevealWarning(false);
    onReveal();
  };

  const handleAddGrant = () => {
    if (newGranteeId) {
      onAddGrant({
        granteeId: newGranteeId,
        granteeType: newGranteeType,
        permissions: newGrantPermissions,
      });
      setShowAddGrant(false);
      setNewGranteeId('');
      setNewGrantPermissions(['read']);
    }
  };

  const togglePermission = (perm: 'read' | 'rotate' | 'manage') => {
    setNewGrantPermissions((prev) =>
      prev.includes(perm) ? prev.filter((p) => p !== perm) : [...prev, perm]
    );
  };

  return (
    <div className="bg-white rounded-xl border border-gray-200 flex flex-col h-full">
      {/* Header */}
      <div className="p-4 border-b border-gray-200">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-2">
              <TypeBadge type={secret.type} />
              {secret.service && (
                <span className="text-xs px-2 py-0.5 bg-gray-100 text-gray-600 rounded">
                  {secret.service}
                </span>
              )}
              {isExpiringSoon(secret.expiresAt) && (
                <span className="text-xs px-2 py-0.5 bg-yellow-100 text-yellow-700 rounded">
                  Expiring soon
                </span>
              )}
            </div>
            <h2 className="text-lg font-semibold text-gray-900 mt-1 font-mono">{secret.name}</h2>
            <div className="text-xs text-gray-500 mt-0.5">
              Owner: {secret.ownerType}:{secret.owner}
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1 text-gray-400 hover:text-gray-600 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Tabs */}
        <div className="flex gap-4 mt-4 border-b border-gray-100">
          {(['details', 'grants', 'audit'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`pb-2 px-1 text-sm font-medium capitalize border-b-2 transition-colors ${
                activeTab === tab
                  ? 'border-agency-600 text-agency-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4">
        {activeTab === 'details' && (
          <div className="space-y-4">
            {/* Secret Value Section */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="text-xs font-medium text-gray-500 uppercase">Secret Value</div>
                {!vaultLocked && !revealedValue && (
                  <button
                    onClick={handleRevealClick}
                    className="text-xs px-2 py-1 text-yellow-700 bg-yellow-100 hover:bg-yellow-200 rounded transition-colors"
                  >
                    Reveal Value
                  </button>
                )}
              </div>
              {vaultLocked ? (
                <div className="bg-gray-100 rounded-lg p-3 text-sm text-gray-500 italic">
                  Vault is locked. Unlock to view or reveal value.
                </div>
              ) : revealedValue ? (
                <div className="bg-gray-900 rounded-lg p-3">
                  <code className="text-sm text-green-400 font-mono break-all">{revealedValue}</code>
                </div>
              ) : (
                <div className="bg-gray-100 rounded-lg p-3 text-sm text-gray-500 font-mono">
                  ••••••••••••••••••••••••
                </div>
              )}
              {revealError && (
                <div className="text-sm text-red-600 mt-1">{revealError}</div>
              )}
            </div>

            {/* Metadata */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <div className="text-xs font-medium text-gray-500 uppercase mb-1">Created</div>
                <div className="text-sm text-gray-700">{formatTime(secret.createdAt)}</div>
              </div>
              <div>
                <div className="text-xs font-medium text-gray-500 uppercase mb-1">Updated</div>
                <div className="text-sm text-gray-700">{formatTime(secret.updatedAt)}</div>
              </div>
              {secret.expiresAt && (
                <div>
                  <div className="text-xs font-medium text-gray-500 uppercase mb-1">Expires</div>
                  <div className={`text-sm ${isExpiringSoon(secret.expiresAt) ? 'text-yellow-700 font-medium' : 'text-gray-700'}`}>
                    {formatTime(secret.expiresAt)}
                  </div>
                </div>
              )}
              {secret.rotatedAt && (
                <div>
                  <div className="text-xs font-medium text-gray-500 uppercase mb-1">Last Rotated</div>
                  <div className="text-sm text-gray-700">{formatTime(secret.rotatedAt)}</div>
                </div>
              )}
            </div>

            {/* Tags */}
            {secret.tags && secret.tags.length > 0 && (
              <div>
                <div className="text-xs font-medium text-gray-500 uppercase mb-2">Tags</div>
                <div className="flex flex-wrap gap-1">
                  {secret.tags.map((tag) => (
                    <span key={tag} className="px-2 py-0.5 bg-gray-100 text-gray-700 text-xs rounded">
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Actions */}
            <div className="flex gap-2 pt-4 border-t border-gray-100">
              <button
                onClick={onRotate}
                disabled={vaultLocked}
                className="px-3 py-1.5 text-sm bg-blue-100 text-blue-700 rounded hover:bg-blue-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Rotate
              </button>
              <button
                onClick={() => setShowDeleteConfirm(true)}
                className="px-3 py-1.5 text-sm bg-red-100 text-red-700 rounded hover:bg-red-200 transition-colors"
              >
                Delete
              </button>
            </div>
          </div>
        )}

        {activeTab === 'grants' && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="text-xs font-medium text-gray-500 uppercase">Access Grants</div>
              <button
                onClick={() => setShowAddGrant(true)}
                className="text-xs px-2 py-1 bg-agency-100 text-agency-700 rounded hover:bg-agency-200 transition-colors"
              >
                + Add Grant
              </button>
            </div>

            {secret.grants && secret.grants.length > 0 ? (
              <div className="space-y-2">
                {secret.grants.map((grant) => (
                  <div
                    key={grant.granteeId}
                    className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                  >
                    <div>
                      <div className="text-sm font-medium text-gray-900">
                        {grant.granteeType}:{grant.granteeId}
                      </div>
                      <div className="flex gap-1 mt-1">
                        {grant.permissions.map((perm) => (
                          <span key={perm} className="px-1.5 py-0.5 bg-gray-200 text-gray-600 text-xs rounded">
                            {perm}
                          </span>
                        ))}
                      </div>
                    </div>
                    <button
                      onClick={() => onRemoveGrant(grant.granteeId)}
                      className="p-1 text-gray-400 hover:text-red-600 transition-colors"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-sm text-gray-400 italic py-4 text-center">
                No grants configured
              </div>
            )}

            {/* Add Grant Form */}
            {showAddGrant && (
              <div className="p-3 bg-gray-50 rounded-lg space-y-3">
                <div className="grid grid-cols-2 gap-2">
                  <input
                    type="text"
                    value={newGranteeId}
                    onChange={(e) => setNewGranteeId(e.target.value)}
                    placeholder="Grantee ID"
                    className="px-2 py-1.5 border border-gray-300 rounded text-sm focus:ring-agency-500 focus:border-agency-500"
                  />
                  <select
                    value={newGranteeType}
                    onChange={(e) => setNewGranteeType(e.target.value as 'agent' | 'principal' | 'system')}
                    className="px-2 py-1.5 border border-gray-300 rounded text-sm focus:ring-agency-500 focus:border-agency-500"
                  >
                    <option value="agent">Agent</option>
                    <option value="principal">Principal</option>
                    <option value="system">System</option>
                  </select>
                </div>
                <div className="flex gap-2">
                  {(['read', 'rotate', 'manage'] as const).map((perm) => (
                    <button
                      key={perm}
                      type="button"
                      onClick={() => togglePermission(perm)}
                      className={`px-2 py-1 text-xs rounded transition-colors ${
                        newGrantPermissions.includes(perm)
                          ? 'bg-agency-600 text-white'
                          : 'bg-gray-200 text-gray-600 hover:bg-gray-300'
                      }`}
                    >
                      {perm}
                    </button>
                  ))}
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => setShowAddGrant(false)}
                    className="px-3 py-1.5 text-sm text-gray-600 hover:bg-gray-200 rounded transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleAddGrant}
                    className="px-3 py-1.5 text-sm bg-agency-600 text-white rounded hover:bg-agency-700 transition-colors"
                  >
                    Add Grant
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

        {activeTab === 'audit' && (
          <div className="space-y-2">
            <div className="text-xs font-medium text-gray-500 uppercase mb-3">Audit Log</div>
            {auditLog.length > 0 ? (
              auditLog.map((entry) => (
                <div key={entry.id} className="flex items-start gap-3 p-2 hover:bg-gray-50 rounded">
                  <div className="text-xs text-gray-400 font-mono whitespace-nowrap">
                    {formatTime(entry.timestamp)}
                  </div>
                  <div className="flex-1">
                    <div className="text-sm text-gray-900">
                      <span className="font-medium">{entry.actorType}:{entry.actorId}</span>
                      {' '}
                      <span className={`${
                        entry.action === 'accessed' ? 'text-yellow-600' :
                        entry.action === 'deleted' ? 'text-red-600' :
                        entry.action === 'rotated' ? 'text-blue-600' :
                        'text-gray-600'
                      }`}>
                        {entry.action}
                      </span>
                    </div>
                    {entry.details && (
                      <div className="text-xs text-gray-500 mt-0.5">
                        {JSON.stringify(entry.details)}
                      </div>
                    )}
                  </div>
                </div>
              ))
            ) : (
              <div className="text-sm text-gray-400 italic py-4 text-center">
                No audit entries
              </div>
            )}
          </div>
        )}
      </div>

      {/* Reveal Warning Modal */}
      {showRevealWarning && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-yellow-100 rounded-lg">
                <svg className="w-6 h-6 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              </div>
              <div>
                <h3 className="text-lg font-semibold text-gray-900">Reveal Secret Value</h3>
                <p className="text-sm text-gray-500">This action will be logged</p>
              </div>
            </div>
            <p className="text-sm text-gray-600 mb-4">
              Revealing a secret value is an audited operation. The access will be recorded in the audit log with your identity and timestamp.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowRevealWarning(false)}
                className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmReveal}
                className="flex-1 px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700"
              >
                Reveal Value
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2 bg-red-100 rounded-lg">
                <svg className="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </div>
              <div>
                <h3 className="text-lg font-semibold text-gray-900">Delete Secret</h3>
                <p className="text-sm text-gray-500">This action cannot be undone</p>
              </div>
            </div>
            <p className="text-sm text-gray-600 mb-4">
              Are you sure you want to delete <span className="font-mono font-medium">{secret.name}</span>? This will permanently remove the secret and all associated grants.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowDeleteConfirm(false)}
                className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  setShowDeleteConfirm(false);
                  onDelete();
                }}
                className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
              >
                Delete Secret
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Main Page
// ─────────────────────────────────────────────────────────────

export default function SecretsPage() {
  // Vault state
  const [vaultStatus, setVaultStatus] = useState<VaultStatus>({ initialized: false, locked: true });
  const [showUnlockModal, setShowUnlockModal] = useState(false);
  const [showInitModal, setShowInitModal] = useState(false);
  const [unlockError, setUnlockError] = useState<string>();
  const [initError, setInitError] = useState<string>();

  // Secrets state
  const [secrets, setSecrets] = useState<Secret[]>([]);
  const [stats, setStats] = useState<SecretStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedSecret, setSelectedSecret] = useState<Secret | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [createError, setCreateError] = useState<string>();

  // Detail panel state
  const [revealedValue, setRevealedValue] = useState<string>();
  const [revealError, setRevealError] = useState<string>();
  const [auditLog, setAuditLog] = useState<AuditEntry[]>([]);

  // Filters
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [searchText, setSearchText] = useState('');

  // ─────────────────────────────────────────────────────────────
  // Data Fetching
  // ─────────────────────────────────────────────────────────────

  const fetchVaultStatus = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE}/vault/status`);
      if (!response.ok) throw new Error('Failed to fetch vault status');
      const data: VaultStatus = await response.json();
      setVaultStatus(data);
    } catch (err) {
      console.error('Failed to fetch vault status:', err);
    }
  }, []);

  const fetchSecrets = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await fetch(`${API_BASE}/list`);
      if (!response.ok) throw new Error('Failed to fetch secrets');
      const data = await response.json();
      setSecrets(data.secrets || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load secrets');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchStats = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE}/stats`);
      if (!response.ok) throw new Error('Failed to fetch stats');
      const data: SecretStats = await response.json();
      setStats(data);
    } catch (err) {
      console.error('Failed to fetch stats:', err);
    }
  }, []);

  const fetchAuditLog = useCallback(async (secretId: string) => {
    try {
      const response = await fetch(`${API_BASE}/audit/${secretId}`);
      if (!response.ok) throw new Error('Failed to fetch audit log');
      const data = await response.json();
      setAuditLog(data.entries || []);
    } catch (err) {
      console.error('Failed to fetch audit log:', err);
      setAuditLog([]);
    }
  }, []);

  // ─────────────────────────────────────────────────────────────
  // Effects
  // ─────────────────────────────────────────────────────────────

  useEffect(() => {
    fetchVaultStatus();
    fetchSecrets();
    fetchStats();
  }, [fetchVaultStatus, fetchSecrets, fetchStats]);

  useEffect(() => {
    if (selectedSecret) {
      fetchAuditLog(selectedSecret.id);
      setRevealedValue(undefined);
      setRevealError(undefined);
    }
  }, [selectedSecret, fetchAuditLog]);

  // Poll vault status to update auto-lock timer
  useEffect(() => {
    const interval = setInterval(fetchVaultStatus, 30000);
    return () => clearInterval(interval);
  }, [fetchVaultStatus]);

  // ─────────────────────────────────────────────────────────────
  // Handlers
  // ─────────────────────────────────────────────────────────────

  const handleUnlock = async (passphrase: string) => {
    try {
      setUnlockError(undefined);
      const response = await fetch(`${API_BASE}/vault/unlock`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Failed to unlock vault');
      }

      setShowUnlockModal(false);
      fetchVaultStatus();
      fetchSecrets();
    } catch (err) {
      setUnlockError(err instanceof Error ? err.message : 'Failed to unlock vault');
    }
  };

  const handleLock = async () => {
    try {
      await fetch(`${API_BASE}/vault/lock`, { method: 'POST' });
      fetchVaultStatus();
    } catch (err) {
      console.error('Failed to lock vault:', err);
    }
  };

  const handleInit = async (passphrase: string) => {
    try {
      setInitError(undefined);
      const response = await fetch(`${API_BASE}/vault/init`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Failed to initialize vault');
      }

      setShowInitModal(false);
      fetchVaultStatus();
    } catch (err) {
      setInitError(err instanceof Error ? err.message : 'Failed to initialize vault');
    }
  };

  const handleCreateSecret = async (secretData: Parameters<typeof CreateSecretModal>[0]['onSubmit'] extends (data: infer T) => void ? T : never) => {
    try {
      setCreateError(undefined);
      const response = await fetch(`${API_BASE}/create`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(secretData),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Failed to create secret');
      }

      setShowCreateModal(false);
      fetchSecrets();
      fetchStats();
    } catch (err) {
      setCreateError(err instanceof Error ? err.message : 'Failed to create secret');
    }
  };

  const handleReveal = async () => {
    if (!selectedSecret) return;

    try {
      setRevealError(undefined);
      const response = await fetch(`${API_BASE}/fetch/${selectedSecret.id}`);

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Failed to fetch secret');
      }

      const data = await response.json();
      setRevealedValue(data.value);
      fetchAuditLog(selectedSecret.id);
    } catch (err) {
      setRevealError(err instanceof Error ? err.message : 'Failed to reveal secret');
    }
  };

  const handleRotate = async () => {
    if (!selectedSecret) return;

    try {
      const response = await fetch(`${API_BASE}/rotate/${selectedSecret.id}`, {
        method: 'POST',
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Failed to rotate secret');
      }

      fetchSecrets();
      fetchAuditLog(selectedSecret.id);
    } catch (err) {
      console.error('Failed to rotate secret:', err);
    }
  };

  const handleDelete = async () => {
    if (!selectedSecret) return;

    try {
      const response = await fetch(`${API_BASE}/delete/${selectedSecret.id}`, {
        method: 'POST',
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Failed to delete secret');
      }

      setSelectedSecret(null);
      fetchSecrets();
      fetchStats();
    } catch (err) {
      console.error('Failed to delete secret:', err);
    }
  };

  const handleAddGrant = async (grant: Omit<Grant, 'expiresAt'> & { expiresAt?: string }) => {
    if (!selectedSecret) return;

    try {
      const response = await fetch(`${API_BASE}/update/${selectedSecret.id}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          grants: [...(selectedSecret.grants || []), grant],
        }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Failed to add grant');
      }

      fetchSecrets();
      fetchAuditLog(selectedSecret.id);

      // Update selected secret with new grants
      const updated = await response.json();
      setSelectedSecret(updated.secret || { ...selectedSecret, grants: [...(selectedSecret.grants || []), grant] });
    } catch (err) {
      console.error('Failed to add grant:', err);
    }
  };

  const handleRemoveGrant = async (granteeId: string) => {
    if (!selectedSecret) return;

    try {
      const newGrants = (selectedSecret.grants || []).filter(g => g.granteeId !== granteeId);
      const response = await fetch(`${API_BASE}/update/${selectedSecret.id}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ grants: newGrants }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Failed to remove grant');
      }

      fetchSecrets();
      fetchAuditLog(selectedSecret.id);
      setSelectedSecret({ ...selectedSecret, grants: newGrants });
    } catch (err) {
      console.error('Failed to remove grant:', err);
    }
  };

  // ─────────────────────────────────────────────────────────────
  // Filtering
  // ─────────────────────────────────────────────────────────────

  const filteredSecrets = secrets.filter((s) => {
    if (typeFilter !== 'all' && s.type !== typeFilter) return false;
    if (searchText && !s.name.toLowerCase().includes(searchText.toLowerCase()) &&
        !s.service?.toLowerCase().includes(searchText.toLowerCase())) return false;
    return true;
  });

  // ─────────────────────────────────────────────────────────────
  // Render
  // ─────────────────────────────────────────────────────────────

  if (error) {
    return (
      <div className="p-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
          <p className="font-medium">Error loading secrets</p>
          <p className="text-sm mt-1">{error}</p>
          <p className="text-sm mt-2">Make sure agency-service is running on port 3456</p>
          <button
            onClick={() => fetchSecrets()}
            className="mt-3 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-[calc(100vh-8rem)] gap-4">
      {/* Stats Panel */}
      <div className="grid grid-cols-4 gap-4">
        <StatCard
          label="Total Secrets"
          value={stats?.total ?? '-'}
          sublabel="Across all services"
        />
        <StatCard
          label="Expiring Soon"
          value={stats?.expiringIn7Days ?? 0}
          variant={stats?.expiringIn7Days && stats.expiringIn7Days > 0 ? 'warning' : 'default'}
          sublabel="Within 7 days"
        />
        <StatCard
          label="Accesses (24h)"
          value={stats?.accessesLast24h ?? 0}
          sublabel="Logged fetches"
        />
        <div className="rounded-lg border bg-white border-gray-200 p-4 flex items-center justify-between">
          <div>
            <div className="text-sm text-gray-500">Vault Status</div>
            <div className="mt-1">
              <VaultStatusIndicator
                status={vaultStatus}
                onUnlock={() => {
                  if (!vaultStatus.initialized) {
                    setShowInitModal(true);
                  } else {
                    setShowUnlockModal(true);
                  }
                }}
                onLock={handleLock}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Filters Bar */}
      <div className="bg-white rounded-xl border border-gray-200 p-4">
        <div className="flex flex-wrap items-center gap-4">
          {/* Type Filter */}
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-600">Type:</label>
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:ring-agency-500 focus:border-agency-500"
            >
              <option value="all">All</option>
              {SECRET_TYPES.map((type) => (
                <option key={type} value={type}>
                  {type.replace('_', ' ')}
                </option>
              ))}
            </select>
          </div>

          {/* Search */}
          <div className="flex-1 min-w-[200px]">
            <input
              type="text"
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              placeholder="Search secrets..."
              className="w-full px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:ring-agency-500 focus:border-agency-500"
            />
          </div>

          {/* Create Button */}
          <button
            onClick={() => setShowCreateModal(true)}
            disabled={vaultStatus.locked}
            className="px-4 py-1.5 bg-agency-600 text-white text-sm rounded-lg hover:bg-agency-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            + Create Secret
          </button>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex gap-4 min-h-0">
        {/* Secret List */}
        <div className={`bg-white rounded-xl border border-gray-200 flex flex-col ${selectedSecret ? 'w-1/2' : 'flex-1'}`}>
          {/* Table Header */}
          <div className="grid grid-cols-[1fr_100px_100px_100px_120px] gap-2 px-4 py-2 bg-gray-50 border-b border-gray-200 text-xs font-medium text-gray-500 uppercase">
            <div>Name</div>
            <div>Type</div>
            <div>Service</div>
            <div>Owner</div>
            <div>Expires</div>
          </div>

          {/* Secret Rows */}
          <div className="flex-1 overflow-y-auto">
            {loading ? (
              <div className="flex items-center justify-center h-32 text-gray-400">
                <svg className="animate-spin h-6 w-6 mr-2" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                Loading secrets...
              </div>
            ) : filteredSecrets.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-32 text-gray-400">
                <svg className="w-12 h-12 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
                <span>No secrets found</span>
                <span className="text-xs mt-1">
                  {vaultStatus.locked ? 'Unlock vault to view secrets' : 'Create a secret to get started'}
                </span>
              </div>
            ) : (
              filteredSecrets.map((secret) => {
                const isSelected = selectedSecret?.id === secret.id;
                const expiring = isExpiringSoon(secret.expiresAt);

                return (
                  <button
                    key={secret.id}
                    onClick={() => setSelectedSecret(secret)}
                    className={`w-full text-left grid grid-cols-[1fr_100px_100px_100px_120px] gap-2 px-4 py-2 border-b border-gray-100 hover:bg-gray-50 transition-colors ${
                      isSelected ? 'bg-agency-50' : ''
                    }`}
                  >
                    {/* Name */}
                    <div className="min-w-0">
                      <div className="text-sm text-gray-900 font-mono truncate" title={secret.name}>
                        {secret.name}
                      </div>
                      {secret.tags && secret.tags.length > 0 && (
                        <div className="flex gap-1 mt-0.5">
                          {secret.tags.slice(0, 2).map((tag) => (
                            <span key={tag} className="text-xs text-gray-400">
                              #{tag}
                            </span>
                          ))}
                          {secret.tags.length > 2 && (
                            <span className="text-xs text-gray-400">+{secret.tags.length - 2}</span>
                          )}
                        </div>
                      )}
                    </div>

                    {/* Type */}
                    <div>
                      <TypeBadge type={secret.type} />
                    </div>

                    {/* Service */}
                    <div className="text-xs text-gray-600 truncate" title={secret.service}>
                      {secret.service || '-'}
                    </div>

                    {/* Owner */}
                    <div className="text-xs text-gray-600 truncate" title={`${secret.ownerType}:${secret.owner}`}>
                      {secret.owner}
                    </div>

                    {/* Expires */}
                    <div className={`text-xs ${expiring ? 'text-yellow-600 font-medium' : 'text-gray-500'}`}>
                      {secret.expiresAt ? formatTime(secret.expiresAt) : '-'}
                    </div>
                  </button>
                );
              })
            )}
          </div>

          {/* Footer */}
          <div className="px-4 py-2 border-t border-gray-200 bg-gray-50 text-xs text-gray-500">
            Showing {filteredSecrets.length} of {secrets.length} secrets
          </div>
        </div>

        {/* Detail Panel */}
        {selectedSecret && (
          <div className="w-1/2">
            <SecretDetailPanel
              secret={selectedSecret}
              vaultLocked={vaultStatus.locked}
              onClose={() => setSelectedSecret(null)}
              onReveal={handleReveal}
              onRotate={handleRotate}
              onDelete={handleDelete}
              onAddGrant={handleAddGrant}
              onRemoveGrant={handleRemoveGrant}
              revealedValue={revealedValue}
              revealError={revealError}
              auditLog={auditLog}
            />
          </div>
        )}
      </div>

      {/* Modals */}
      {showUnlockModal && (
        <UnlockModal
          onUnlock={handleUnlock}
          onCancel={() => {
            setShowUnlockModal(false);
            setUnlockError(undefined);
          }}
          error={unlockError}
        />
      )}

      {showInitModal && (
        <InitVaultModal
          onInit={handleInit}
          onCancel={() => {
            setShowInitModal(false);
            setInitError(undefined);
          }}
          error={initError}
        />
      )}

      {showCreateModal && (
        <CreateSecretModal
          onSubmit={handleCreateSecret}
          onCancel={() => {
            setShowCreateModal(false);
            setCreateError(undefined);
          }}
          error={createError}
        />
      )}
    </div>
  );
}
