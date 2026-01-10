/**
 * Secret Repository
 *
 * Data access layer for secrets with encryption at rest.
 * Uses AES-256-GCM for encryption and Argon2id for key derivation.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import type {
  Secret,
  SecretWithValue,
  SecretDecrypted,
  SecretTag,
  SecretGrant,
  SecretAuditLog,
  RecoveryCode,
  VaultConfig,
  SecretWithDetails,
  CreateSecretRequest,
  UpdateSecretRequest,
  ListSecretsQuery,
  AddTagRequest,
  GrantAccessRequest,
  ListAuditLogsQuery,
  SecretStats,
  SecretType,
  AuditAction,
  VaultStatus,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';
import { hashRaw as argon2HashRaw, verify as argon2Verify, Algorithm } from '@node-rs/argon2';

const logger = createServiceLogger('secret-repository');

// Argon2id configuration as per requirements
const ARGON2_CONFIG = {
  memoryCost: 65536,       // 64 MiB
  timeCost: 3,             // 3 iterations
  parallelism: 4,          // 4 parallel threads
  outputLen: 32,           // 256-bit key
};

// Auto-lock timeout in milliseconds (30 minutes)
const AUTO_LOCK_TIMEOUT_MS = 30 * 60 * 1000;

// ─────────────────────────────────────────────────────────────────────────────
// Row Types (SQLite representation)
// ─────────────────────────────────────────────────────────────────────────────

interface SecretRow {
  id: string;
  name: string;
  secret_type: string;
  encrypted_value: Buffer;
  iv: Buffer;
  owner_type: string;
  owner_name: string;
  service_name: string | null;
  description: string | null;
  expires_at: string | null;
  created_at: string;
  updated_at: string;
}

interface TagRow {
  id: number;
  secret_id: string;
  tag_type: string;
  tag_value: string;
  permission: string;
  created_at: string;
}

interface GrantRow {
  id: number;
  secret_id: string;
  grantee_type: string;
  grantee_name: string;
  permission: string;
  granted_by: string;
  granted_at: string;
}

interface AuditRow {
  id: number;
  secret_id: string;
  secret_name: string;
  accessor_type: string;
  accessor_name: string;
  action: string;
  tool_context: string | null;
  ip_address: string | null;
  timestamp: string;
}

interface RecoveryRow {
  id: number;
  recovery_code_hash: string;
  used: number;
  used_at: string | null;
  created_at: string;
}

interface ConfigRow {
  key: string;
  value: string;
}

interface CountRow {
  count: number;
}

interface TypeCountRow {
  secret_type: string;
  count: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// Row to Entity Converters
// ─────────────────────────────────────────────────────────────────────────────

function rowToSecret(row: SecretRow): Secret {
  return {
    id: row.id,
    name: row.name,
    secretType: row.secret_type as SecretType,
    ownerType: row.owner_type as 'principal' | 'agent',
    ownerName: row.owner_name,
    serviceName: row.service_name || undefined,
    description: row.description || undefined,
    expiresAt: row.expires_at ? new Date(row.expires_at) : undefined,
    createdAt: new Date(row.created_at),
    updatedAt: new Date(row.updated_at),
  };
}

function rowToSecretWithValue(row: SecretRow): SecretWithValue {
  return {
    ...rowToSecret(row),
    encryptedValue: row.encrypted_value,
    iv: row.iv,
  };
}

function rowToTag(row: TagRow): SecretTag {
  return {
    id: row.id,
    secretId: row.secret_id,
    tagType: row.tag_type as SecretTag['tagType'],
    tagValue: row.tag_value,
    permission: row.permission as SecretTag['permission'],
    createdAt: new Date(row.created_at),
  };
}

function rowToGrant(row: GrantRow): SecretGrant {
  return {
    id: row.id,
    secretId: row.secret_id,
    granteeType: row.grantee_type as 'principal' | 'agent',
    granteeName: row.grantee_name,
    permission: row.permission as SecretGrant['permission'],
    grantedBy: row.granted_by,
    grantedAt: new Date(row.granted_at),
  };
}

function rowToAudit(row: AuditRow): SecretAuditLog {
  return {
    id: row.id,
    secretId: row.secret_id,
    secretName: row.secret_name,
    accessorType: row.accessor_type as 'principal' | 'agent' | 'system',
    accessorName: row.accessor_name,
    action: row.action as AuditAction,
    toolContext: row.tool_context || undefined,
    ipAddress: row.ip_address || undefined,
    timestamp: new Date(row.timestamp),
  };
}

function rowToRecovery(row: RecoveryRow): RecoveryCode {
  return {
    id: row.id,
    recoveryCodeHash: row.recovery_code_hash,
    used: row.used === 1,
    usedAt: row.used_at ? new Date(row.used_at) : undefined,
    createdAt: new Date(row.created_at),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Encryption Helpers (using Web Crypto API + Argon2id)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Derive a 256-bit key from passphrase using Argon2id
 * Configuration: memoryCost=65536 (64 MiB), timeCost=3, parallelism=4
 */
async function deriveKeyFromPassphrase(passphrase: string, salt: Uint8Array): Promise<Uint8Array> {
  // Use Argon2id to derive a raw key from the passphrase
  const hashResult = await argon2HashRaw(passphrase, {
    salt: Buffer.from(salt),
    memoryCost: ARGON2_CONFIG.memoryCost,
    timeCost: ARGON2_CONFIG.timeCost,
    parallelism: ARGON2_CONFIG.parallelism,
    outputLen: ARGON2_CONFIG.outputLen,
    algorithm: Algorithm.Argon2id,
  });

  // hashRaw returns a Buffer directly
  return new Uint8Array(hashResult);
}

/**
 * Import raw key bytes as a CryptoKey for AES-256-GCM operations
 */
async function importAesKey(keyBytes: Uint8Array): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    'raw',
    keyBytes,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt']
  );
}

/**
 * Derive an AES-256-GCM CryptoKey from passphrase using Argon2id
 */
async function deriveKey(passphrase: string, salt: Uint8Array): Promise<CryptoKey> {
  const keyBytes = await deriveKeyFromPassphrase(passphrase, salt);
  return importAesKey(keyBytes);
}

async function encrypt(plaintext: string, key: CryptoKey): Promise<{ encrypted: Buffer; iv: Buffer }> {
  const encoder = new TextEncoder();
  const iv = crypto.getRandomValues(new Uint8Array(12));

  const encrypted = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    encoder.encode(plaintext)
  );

  return {
    encrypted: Buffer.from(encrypted),
    iv: Buffer.from(iv),
  };
}

async function decrypt(encrypted: Buffer, iv: Buffer, key: CryptoKey): Promise<string> {
  const decrypted = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: new Uint8Array(iv) },
    key,
    new Uint8Array(encrypted)
  );

  const decoder = new TextDecoder();
  return decoder.decode(decrypted);
}

function generateSalt(): Uint8Array {
  return crypto.getRandomValues(new Uint8Array(32));
}

function generateRecoveryCode(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  return Buffer.from(bytes).toString('hex').toUpperCase().match(/.{4}/g)!.join('-');
}

async function hashRecoveryCode(code: string): Promise<string> {
  const encoder = new TextEncoder();
  const hash = await crypto.subtle.digest('SHA-256', encoder.encode(code));
  return Buffer.from(hash).toString('hex');
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository Class
// ─────────────────────────────────────────────────────────────────────────────

export class SecretRepository {
  private masterKey: CryptoKey | null = null;
  private lastActivityTime: number = 0;
  private autoLockTimer: NodeJS.Timeout | null = null;

  constructor(private db: DatabaseAdapter) {}

  /**
   * Update the last activity timestamp and reset auto-lock timer
   */
  private updateActivity(): void {
    this.lastActivityTime = Date.now();

    // Clear existing timer if any
    if (this.autoLockTimer) {
      clearTimeout(this.autoLockTimer);
    }

    // Set new auto-lock timer if vault is unlocked
    if (this.masterKey) {
      this.autoLockTimer = setTimeout(() => {
        if (this.masterKey) {
          logger.info('Vault auto-locked due to inactivity');
          this.lockVault();
        }
      }, AUTO_LOCK_TIMEOUT_MS);
    }
  }

  /**
   * Get time until auto-lock in milliseconds, or null if locked
   */
  getTimeUntilAutoLock(): number | null {
    if (!this.masterKey) return null;
    const elapsed = Date.now() - this.lastActivityTime;
    return Math.max(0, AUTO_LOCK_TIMEOUT_MS - elapsed);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Schema Initialization
  // ─────────────────────────────────────────────────────────────────────────

  async initialize(): Promise<void> {
    // Secrets table
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS secrets (
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        secret_type TEXT NOT NULL DEFAULT 'generic',
        encrypted_value BLOB NOT NULL,
        iv BLOB NOT NULL,
        owner_type TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        service_name TEXT,
        description TEXT,
        expires_at TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    // Tags table
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS secret_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        secret_id TEXT NOT NULL REFERENCES secrets(id) ON DELETE CASCADE,
        tag_type TEXT NOT NULL,
        tag_value TEXT NOT NULL,
        permission TEXT NOT NULL DEFAULT 'read',
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        UNIQUE(secret_id, tag_type, tag_value)
      )
    `);

    // Grants table
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS secret_grants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        secret_id TEXT NOT NULL REFERENCES secrets(id) ON DELETE CASCADE,
        grantee_type TEXT NOT NULL,
        grantee_name TEXT NOT NULL,
        permission TEXT NOT NULL DEFAULT 'read',
        granted_by TEXT NOT NULL,
        granted_at TEXT NOT NULL DEFAULT (datetime('now')),
        UNIQUE(secret_id, grantee_type, grantee_name)
      )
    `);

    // Audit log table
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS secret_access_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        secret_id TEXT NOT NULL,
        secret_name TEXT NOT NULL,
        accessor_type TEXT NOT NULL,
        accessor_name TEXT NOT NULL,
        action TEXT NOT NULL,
        tool_context TEXT,
        ip_address TEXT,
        timestamp TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    // Recovery codes table
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS vault_recovery (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recovery_code_hash TEXT NOT NULL,
        used INTEGER DEFAULT 0,
        used_at TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    `);

    // Vault config table
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS vault_config (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    `);

    // Indexes
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_secrets_name ON secrets(name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_secrets_owner ON secrets(owner_name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_secrets_service ON secrets(service_name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_secrets_type ON secrets(secret_type)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_tags_secret ON secret_tags(secret_id)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_tags_value ON secret_tags(tag_type, tag_value)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_grants_secret ON secret_grants(secret_id)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_grants_grantee ON secret_grants(grantee_type, grantee_name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_audit_secret ON secret_access_log(secret_id)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_audit_accessor ON secret_access_log(accessor_name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON secret_access_log(timestamp)`);

    logger.info('Secret schema initialized');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Vault Management
  // ─────────────────────────────────────────────────────────────────────────

  async getVaultStatus(): Promise<VaultStatus> {
    const config = await this.db.get<ConfigRow>(
      "SELECT value FROM vault_config WHERE key = 'encrypted_master_key'"
    );

    if (!config) return 'uninitialized';
    if (!this.masterKey) return 'locked';
    return 'unlocked';
  }

  async initVault(passphrase: string): Promise<{ recoveryCodes: string[] }> {
    const existingConfig = await this.db.get<ConfigRow>(
      "SELECT value FROM vault_config WHERE key = 'encrypted_master_key'"
    );

    if (existingConfig) {
      throw new Error('Vault already initialized');
    }

    // Generate salt and derive key from passphrase
    const salt = generateSalt();
    const key = await deriveKey(passphrase, salt);

    // Generate a random master key and encrypt it with the derived key
    const masterKeyBytes = crypto.getRandomValues(new Uint8Array(32));
    const { encrypted: encryptedMasterKey, iv } = await encrypt(
      Buffer.from(masterKeyBytes).toString('hex'),
      key
    );

    // Store vault config
    const now = new Date().toISOString();
    await this.db.execute(
      "INSERT INTO vault_config (key, value) VALUES ('salt', ?)",
      [Buffer.from(salt).toString('hex')]
    );
    await this.db.execute(
      "INSERT INTO vault_config (key, value) VALUES ('iv', ?)",
      [iv.toString('hex')]
    );
    await this.db.execute(
      "INSERT INTO vault_config (key, value) VALUES ('encrypted_master_key', ?)",
      [encryptedMasterKey.toString('hex')]
    );
    await this.db.execute(
      "INSERT INTO vault_config (key, value) VALUES ('created_at', ?)",
      [now]
    );
    await this.db.execute(
      "INSERT INTO vault_config (key, value) VALUES ('version', '1')"
    );

    // Generate recovery codes
    const recoveryCodes: string[] = [];
    for (let i = 0; i < 8; i++) {
      const code = generateRecoveryCode();
      recoveryCodes.push(code);
      const hash = await hashRecoveryCode(code);
      await this.db.execute(
        'INSERT INTO vault_recovery (recovery_code_hash, created_at) VALUES (?, ?)',
        [hash, now]
      );
    }

    // Import the actual master key for use
    this.masterKey = await crypto.subtle.importKey(
      'raw',
      masterKeyBytes,
      { name: 'AES-GCM', length: 256 },
      false,
      ['encrypt', 'decrypt']
    );

    // Start the auto-lock timer
    this.updateActivity();

    logger.info('Vault initialized');
    return { recoveryCodes };
  }

  async unlockVault(passphrase: string): Promise<boolean> {
    const saltRow = await this.db.get<ConfigRow>("SELECT value FROM vault_config WHERE key = 'salt'");
    const ivRow = await this.db.get<ConfigRow>("SELECT value FROM vault_config WHERE key = 'iv'");
    const encryptedRow = await this.db.get<ConfigRow>("SELECT value FROM vault_config WHERE key = 'encrypted_master_key'");

    if (!saltRow || !ivRow || !encryptedRow) {
      throw new Error('Vault not initialized');
    }

    try {
      const salt = Buffer.from(saltRow.value, 'hex');
      const iv = Buffer.from(ivRow.value, 'hex');
      const encrypted = Buffer.from(encryptedRow.value, 'hex');

      // Derive key from passphrase
      const derivedKey = await deriveKey(passphrase, new Uint8Array(salt));

      // Decrypt master key
      const masterKeyHex = await decrypt(encrypted, iv, derivedKey);
      const masterKeyBytes = Buffer.from(masterKeyHex, 'hex');

      // Import master key
      this.masterKey = await crypto.subtle.importKey(
        'raw',
        new Uint8Array(masterKeyBytes),
        { name: 'AES-GCM', length: 256 },
        false,
        ['encrypt', 'decrypt']
      );

      // Start the auto-lock timer
      this.updateActivity();

      logger.info('Vault unlocked');
      return true;
    } catch (error) {
      logger.warn('Failed to unlock vault - incorrect passphrase');
      return false;
    }
  }

  lockVault(): void {
    this.masterKey = null;

    // Clear auto-lock timer
    if (this.autoLockTimer) {
      clearTimeout(this.autoLockTimer);
      this.autoLockTimer = null;
    }

    logger.info('Vault locked');
  }

  isUnlocked(): boolean {
    return this.masterKey !== null;
  }

  private ensureUnlocked(): void {
    if (!this.masterKey) {
      throw new Error('Vault is locked. Call unlockVault() first.');
    }
    // Update activity on any vault operation
    this.updateActivity();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Secret CRUD
  // ─────────────────────────────────────────────────────────────────────────

  async create(data: CreateSecretRequest): Promise<Secret> {
    this.ensureUnlocked();

    const id = crypto.randomUUID();
    const now = new Date().toISOString();

    // Encrypt the secret value
    const { encrypted, iv } = await encrypt(data.value, this.masterKey!);

    await this.db.execute(
      `INSERT INTO secrets (id, name, secret_type, encrypted_value, iv, owner_type, owner_name, service_name, description, expires_at, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        data.name,
        data.secretType || 'generic',
        encrypted,
        iv,
        data.ownerType || 'principal',
        data.ownerName || 'unknown',
        data.serviceName || null,
        data.description || null,
        data.expiresAt || null,
        now,
        now,
      ]
    );

    const row = await this.db.get<SecretRow>('SELECT * FROM secrets WHERE id = ?', [id]);

    logger.info({ secretId: id, name: data.name }, 'Secret created');
    return rowToSecret(row!);
  }

  async getById(id: string): Promise<SecretWithDetails | null> {
    const row = await this.db.get<SecretRow>(
      'SELECT * FROM secrets WHERE id = ? OR name = ?',
      [id, id]
    );

    if (!row) return null;

    const tags = await this.db.query<TagRow>(
      'SELECT * FROM secret_tags WHERE secret_id = ?',
      [row.id]
    );

    const grants = await this.db.query<GrantRow>(
      'SELECT * FROM secret_grants WHERE secret_id = ?',
      [row.id]
    );

    return {
      ...rowToSecret(row),
      tags: tags.map(rowToTag),
      grants: grants.map(rowToGrant),
    };
  }

  async fetchValue(id: string): Promise<string | null> {
    this.ensureUnlocked();

    const row = await this.db.get<SecretRow>(
      'SELECT * FROM secrets WHERE id = ? OR name = ?',
      [id, id]
    );

    if (!row) return null;

    return decrypt(row.encrypted_value, row.iv, this.masterKey!);
  }

  async update(id: string, data: UpdateSecretRequest): Promise<Secret | null> {
    const existing = await this.db.get<SecretRow>(
      'SELECT * FROM secrets WHERE id = ? OR name = ?',
      [id, id]
    );

    if (!existing) return null;

    const updates: string[] = ['updated_at = datetime("now")'];
    const params: unknown[] = [];

    if (data.serviceName !== undefined) {
      updates.push('service_name = ?');
      params.push(data.serviceName);
    }
    if (data.description !== undefined) {
      updates.push('description = ?');
      params.push(data.description);
    }
    if (data.expiresAt !== undefined) {
      updates.push('expires_at = ?');
      params.push(data.expiresAt);
    }

    params.push(existing.id);

    await this.db.execute(
      `UPDATE secrets SET ${updates.join(', ')} WHERE id = ?`,
      params
    );

    const row = await this.db.get<SecretRow>('SELECT * FROM secrets WHERE id = ?', [existing.id]);

    logger.info({ secretId: existing.id, name: existing.name }, 'Secret updated');
    return rowToSecret(row!);
  }

  async rotate(id: string, newValue: string): Promise<Secret | null> {
    this.ensureUnlocked();

    const existing = await this.db.get<SecretRow>(
      'SELECT * FROM secrets WHERE id = ? OR name = ?',
      [id, id]
    );

    if (!existing) return null;

    const { encrypted, iv } = await encrypt(newValue, this.masterKey!);

    await this.db.execute(
      `UPDATE secrets SET encrypted_value = ?, iv = ?, updated_at = datetime('now') WHERE id = ?`,
      [encrypted, iv, existing.id]
    );

    const row = await this.db.get<SecretRow>('SELECT * FROM secrets WHERE id = ?', [existing.id]);

    logger.info({ secretId: existing.id, name: existing.name }, 'Secret rotated');
    return rowToSecret(row!);
  }

  async delete(id: string): Promise<boolean> {
    const existing = await this.db.get<SecretRow>(
      'SELECT * FROM secrets WHERE id = ? OR name = ?',
      [id, id]
    );

    if (!existing) return false;

    await this.db.execute('DELETE FROM secrets WHERE id = ?', [existing.id]);

    logger.info({ secretId: existing.id, name: existing.name }, 'Secret deleted');
    return true;
  }

  async list(query: ListSecretsQuery): Promise<{ secrets: Secret[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];

    if (query.secretType) {
      conditions.push('s.secret_type = ?');
      params.push(query.secretType);
    }
    if (query.serviceName) {
      conditions.push('s.service_name = ?');
      params.push(query.serviceName);
    }
    if (query.owner) {
      conditions.push('s.owner_name = ?');
      params.push(query.owner);
    }
    if (query.tool) {
      conditions.push("EXISTS (SELECT 1 FROM secret_tags t WHERE t.secret_id = s.id AND t.tag_type = 'tool' AND t.tag_value = ?)");
      params.push(query.tool);
    }
    if (query.env) {
      conditions.push("EXISTS (SELECT 1 FROM secret_tags t WHERE t.secret_id = s.id AND t.tag_type = 'env' AND t.tag_value = ?)");
      params.push(query.env);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countRow = await this.db.get<CountRow>(
      `SELECT COUNT(*) as count FROM secrets s ${whereClause}`,
      params
    );
    const total = countRow?.count || 0;

    const limit = query.limit || 50;
    const offset = query.offset || 0;

    const rows = await this.db.query<SecretRow>(
      `SELECT s.* FROM secrets s ${whereClause} ORDER BY s.created_at DESC LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    );

    return {
      secrets: rows.map(rowToSecret),
      total,
    };
  }

  async findByTag(tagType: string, tagValue: string): Promise<Secret[]> {
    const rows = await this.db.query<SecretRow>(
      `SELECT s.* FROM secrets s
       JOIN secret_tags t ON t.secret_id = s.id
       WHERE t.tag_type = ? AND t.tag_value = ?`,
      [tagType, tagValue]
    );

    return rows.map(rowToSecret);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tags
  // ─────────────────────────────────────────────────────────────────────────

  async addTag(secretId: string, data: AddTagRequest): Promise<SecretTag | null> {
    const secret = await this.db.get<SecretRow>(
      'SELECT * FROM secrets WHERE id = ? OR name = ?',
      [secretId, secretId]
    );

    if (!secret) return null;

    const now = new Date().toISOString();

    try {
      await this.db.execute(
        `INSERT INTO secret_tags (secret_id, tag_type, tag_value, permission, created_at)
         VALUES (?, ?, ?, ?, ?)`,
        [secret.id, data.tagType, data.tagValue, data.permission || 'read', now]
      );
    } catch (e) {
      // Tag already exists
      return null;
    }

    const row = await this.db.get<TagRow>(
      'SELECT * FROM secret_tags WHERE secret_id = ? AND tag_type = ? AND tag_value = ?',
      [secret.id, data.tagType, data.tagValue]
    );

    logger.info({ secretId: secret.id, tag: `${data.tagType}:${data.tagValue}` }, 'Tag added');
    return rowToTag(row!);
  }

  async removeTag(secretId: string, tagType: string, tagValue: string): Promise<boolean> {
    const secret = await this.db.get<SecretRow>(
      'SELECT * FROM secrets WHERE id = ? OR name = ?',
      [secretId, secretId]
    );

    if (!secret) return false;

    await this.db.execute(
      'DELETE FROM secret_tags WHERE secret_id = ? AND tag_type = ? AND tag_value = ?',
      [secret.id, tagType, tagValue]
    );

    logger.info({ secretId: secret.id, tag: `${tagType}:${tagValue}` }, 'Tag removed');
    return true;
  }

  async getTags(secretId: string): Promise<SecretTag[]> {
    const secret = await this.db.get<SecretRow>(
      'SELECT * FROM secrets WHERE id = ? OR name = ?',
      [secretId, secretId]
    );

    if (!secret) return [];

    const rows = await this.db.query<TagRow>(
      'SELECT * FROM secret_tags WHERE secret_id = ?',
      [secret.id]
    );

    return rows.map(rowToTag);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Grants
  // ─────────────────────────────────────────────────────────────────────────

  async addGrant(secretId: string, data: GrantAccessRequest, grantedBy: string): Promise<SecretGrant | null> {
    const secret = await this.db.get<SecretRow>(
      'SELECT * FROM secrets WHERE id = ? OR name = ?',
      [secretId, secretId]
    );

    if (!secret) return null;

    const now = new Date().toISOString();

    try {
      await this.db.execute(
        `INSERT INTO secret_grants (secret_id, grantee_type, grantee_name, permission, granted_by, granted_at)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [secret.id, data.granteeType, data.granteeName, data.permission || 'read', grantedBy, now]
      );
    } catch (e) {
      // Grant already exists - update it
      await this.db.execute(
        `UPDATE secret_grants SET permission = ?, granted_by = ?, granted_at = ?
         WHERE secret_id = ? AND grantee_type = ? AND grantee_name = ?`,
        [data.permission || 'read', grantedBy, now, secret.id, data.granteeType, data.granteeName]
      );
    }

    const row = await this.db.get<GrantRow>(
      'SELECT * FROM secret_grants WHERE secret_id = ? AND grantee_type = ? AND grantee_name = ?',
      [secret.id, data.granteeType, data.granteeName]
    );

    logger.info({ secretId: secret.id, grantee: `${data.granteeType}:${data.granteeName}` }, 'Grant added');
    return rowToGrant(row!);
  }

  async removeGrant(secretId: string, granteeType: string, granteeName: string): Promise<boolean> {
    const secret = await this.db.get<SecretRow>(
      'SELECT * FROM secrets WHERE id = ? OR name = ?',
      [secretId, secretId]
    );

    if (!secret) return false;

    await this.db.execute(
      'DELETE FROM secret_grants WHERE secret_id = ? AND grantee_type = ? AND grantee_name = ?',
      [secret.id, granteeType, granteeName]
    );

    logger.info({ secretId: secret.id, grantee: `${granteeType}:${granteeName}` }, 'Grant removed');
    return true;
  }

  async getGrants(secretId: string): Promise<SecretGrant[]> {
    const secret = await this.db.get<SecretRow>(
      'SELECT * FROM secrets WHERE id = ? OR name = ?',
      [secretId, secretId]
    );

    if (!secret) return [];

    const rows = await this.db.query<GrantRow>(
      'SELECT * FROM secret_grants WHERE secret_id = ?',
      [secret.id]
    );

    return rows.map(rowToGrant);
  }

  async hasAccess(secretId: string, accessorType: string, accessorName: string, requiredPermission: string): Promise<boolean> {
    const secret = await this.db.get<SecretRow>(
      'SELECT * FROM secrets WHERE id = ? OR name = ?',
      [secretId, secretId]
    );

    if (!secret) return false;

    // Owner always has access
    if (secret.owner_type === accessorType && secret.owner_name === accessorName) {
      return true;
    }

    // Check grants
    const grant = await this.db.get<GrantRow>(
      'SELECT * FROM secret_grants WHERE secret_id = ? AND grantee_type = ? AND grantee_name = ?',
      [secret.id, accessorType, accessorName]
    );

    if (!grant) return false;

    // Check permission level
    const permissionLevels = { read: 1, write: 2, admin: 3 };
    const grantLevel = permissionLevels[grant.permission as keyof typeof permissionLevels] || 0;
    const requiredLevel = permissionLevels[requiredPermission as keyof typeof permissionLevels] || 0;

    return grantLevel >= requiredLevel;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Audit Logging
  // ─────────────────────────────────────────────────────────────────────────

  async logAccess(
    secretId: string,
    secretName: string,
    accessorType: string,
    accessorName: string,
    action: AuditAction,
    toolContext?: string,
    ipAddress?: string
  ): Promise<void> {
    await this.db.execute(
      `INSERT INTO secret_access_log (secret_id, secret_name, accessor_type, accessor_name, action, tool_context, ip_address, timestamp)
       VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))`,
      [secretId, secretName, accessorType, accessorName, action, toolContext || null, ipAddress || null]
    );
  }

  async getAuditLogs(query: ListAuditLogsQuery): Promise<{ logs: SecretAuditLog[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];

    if (query.secretId) {
      conditions.push('secret_id = ?');
      params.push(query.secretId);
    }
    if (query.accessorName) {
      conditions.push('accessor_name = ?');
      params.push(query.accessorName);
    }
    if (query.action) {
      conditions.push('action = ?');
      params.push(query.action);
    }
    if (query.since) {
      conditions.push('timestamp >= ?');
      params.push(query.since);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countRow = await this.db.get<CountRow>(
      `SELECT COUNT(*) as count FROM secret_access_log ${whereClause}`,
      params
    );
    const total = countRow?.count || 0;

    const limit = query.limit || 100;
    const offset = query.offset || 0;

    const rows = await this.db.query<AuditRow>(
      `SELECT * FROM secret_access_log ${whereClause} ORDER BY timestamp DESC LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    );

    return {
      logs: rows.map(rowToAudit),
      total,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Recovery
  // ─────────────────────────────────────────────────────────────────────────

  async generateRecoveryCodes(): Promise<string[]> {
    // Delete existing unused codes
    await this.db.execute('DELETE FROM vault_recovery WHERE used = 0');

    const now = new Date().toISOString();
    const codes: string[] = [];

    for (let i = 0; i < 8; i++) {
      const code = generateRecoveryCode();
      codes.push(code);
      const hash = await hashRecoveryCode(code);
      await this.db.execute(
        'INSERT INTO vault_recovery (recovery_code_hash, created_at) VALUES (?, ?)',
        [hash, now]
      );
    }

    logger.info('Recovery codes regenerated');
    return codes;
  }

  async useRecoveryCode(code: string, newPassphrase: string): Promise<boolean> {
    const hash = await hashRecoveryCode(code);

    const recovery = await this.db.get<RecoveryRow>(
      'SELECT * FROM vault_recovery WHERE recovery_code_hash = ? AND used = 0',
      [hash]
    );

    if (!recovery) {
      logger.warn('Invalid or used recovery code');
      return false;
    }

    // Mark code as used
    await this.db.execute(
      "UPDATE vault_recovery SET used = 1, used_at = datetime('now') WHERE id = ?",
      [recovery.id]
    );

    // Get the old encrypted master key (we need to re-encrypt with new passphrase)
    // For now, we'll generate a new master key - this means existing secrets are lost
    // In a real implementation, we'd need a more sophisticated recovery mechanism

    // Delete vault config and reinitialize
    await this.db.execute('DELETE FROM vault_config');
    await this.db.execute('DELETE FROM secrets');
    await this.db.execute('DELETE FROM secret_tags');
    await this.db.execute('DELETE FROM secret_grants');

    // Reinitialize vault with new passphrase
    await this.initVault(newPassphrase);

    logger.info('Vault reset with recovery code');
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stats
  // ─────────────────────────────────────────────────────────────────────────

  async getStats(): Promise<SecretStats> {
    const totalRow = await this.db.get<CountRow>('SELECT COUNT(*) as count FROM secrets');
    const total = totalRow?.count || 0;

    const typeRows = await this.db.query<TypeCountRow>(
      'SELECT secret_type, COUNT(*) as count FROM secrets GROUP BY secret_type'
    );

    const byType: Record<SecretType, number> = {
      api_key: 0,
      token: 0,
      password: 0,
      certificate: 0,
      ssh_key: 0,
      env_var: 0,
      generic: 0,
    };

    for (const row of typeRows) {
      byType[row.secret_type as SecretType] = row.count;
    }

    const expiringSoonRow = await this.db.get<CountRow>(
      "SELECT COUNT(*) as count FROM secrets WHERE expires_at IS NOT NULL AND expires_at <= datetime('now', '+30 days') AND expires_at > datetime('now')"
    );

    const expiredRow = await this.db.get<CountRow>(
      "SELECT COUNT(*) as count FROM secrets WHERE expires_at IS NOT NULL AND expires_at <= datetime('now')"
    );

    return {
      total,
      byType,
      expiringSoon: expiringSoonRow?.count || 0,
      expired: expiredRow?.count || 0,
    };
  }
}
