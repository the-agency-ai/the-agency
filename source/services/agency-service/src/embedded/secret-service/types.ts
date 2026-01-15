/**
 * Secret Service Types
 *
 * Types for secret management - passwords, API keys, tokens, certificates.
 * Supports encryption at rest, access control, tagging, and audit logging.
 */

import { z } from 'zod';

// ─────────────────────────────────────────────────────────────────────────────
// Enums and Constants
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Types of secrets that can be stored
 */
export type SecretType = 'api_key' | 'token' | 'password' | 'certificate' | 'ssh_key' | 'env_var' | 'generic';

/**
 * Tag types for categorizing secrets
 */
export type TagType = 'tool' | 'local-tool' | 'env' | 'service';

/**
 * Permission levels
 */
export type Permission = 'read' | 'write' | 'admin';

/**
 * Audit action types
 */
export type AuditAction = 'create' | 'read' | 'update' | 'delete' | 'rotate' | 'grant' | 'revoke' | 'fetch';

/**
 * Vault status
 */
export type VaultStatus = 'uninitialized' | 'locked' | 'unlocked';

// ─────────────────────────────────────────────────────────────────────────────
// Core Entities
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Secret entity (metadata only, value is encrypted)
 */
export interface Secret {
  id: string;
  name: string;
  secretType: SecretType;
  ownerType: 'principal' | 'agent';
  ownerName: string;
  serviceName?: string; // GitHub, AWS, Anthropic
  description?: string;
  expiresAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Secret with encrypted value (internal use)
 */
export interface SecretWithValue extends Secret {
  encryptedValue: Buffer;
  iv: Buffer;
}

/**
 * Secret with decrypted value (returned from fetch)
 */
export interface SecretDecrypted extends Secret {
  value: string;
}

/**
 * Tag attached to a secret
 */
export interface SecretTag {
  id: number;
  secretId: string;
  tagType: TagType;
  tagValue: string;
  permission: Permission;
  createdAt: Date;
}

/**
 * Access grant for a secret
 */
export interface SecretGrant {
  id: number;
  secretId: string;
  granteeType: 'principal' | 'agent';
  granteeName: string;
  permission: Permission;
  grantedBy: string;
  grantedAt: Date;
}

/**
 * Audit log entry
 */
export interface SecretAuditLog {
  id: number;
  secretId: string;
  secretName: string;
  accessorType: 'principal' | 'agent' | 'system';
  accessorName: string;
  action: AuditAction;
  toolContext?: string;
  ipAddress?: string;
  timestamp: Date;
}

/**
 * Recovery code (hashed)
 */
export interface RecoveryCode {
  id: number;
  recoveryCodeHash: string;
  used: boolean;
  usedAt?: Date;
  createdAt: Date;
}

/**
 * Vault configuration
 */
export interface VaultConfig {
  encryptedMasterKey: string;
  salt: string;
  version: number;
  createdAt: Date;
}

// ─────────────────────────────────────────────────────────────────────────────
// Composite Types
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Secret with all related data
 */
export interface SecretWithDetails extends Secret {
  tags: SecretTag[];
  grants: SecretGrant[];
}

/**
 * Vault status response
 */
export interface VaultStatusResponse {
  status: VaultStatus;
  secretCount?: number;
  createdAt?: Date;
  hasRecoveryCodes?: boolean;
  autoLockInMs?: number;        // Time until auto-lock in milliseconds
  autoLockTimeoutMs?: number;   // Total auto-lock timeout (30 minutes)
  autoLockDisabled?: boolean;   // True if auto-lock disabled (active session tokens)
  activeSessionCount?: number;  // Number of active session tokens
}

// ─────────────────────────────────────────────────────────────────────────────
// Request/Response Types
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Create secret request
 */
export interface CreateSecretRequest {
  name: string;
  value: string;
  secretType?: SecretType;
  serviceName?: string;
  description?: string;
  expiresAt?: string;
  ownerType?: 'principal' | 'agent';
  ownerName?: string;
}

/**
 * Update secret request
 */
export interface UpdateSecretRequest {
  serviceName?: string;
  description?: string;
  expiresAt?: string | null;
}

/**
 * Rotate secret request
 */
export interface RotateSecretRequest {
  newValue: string;
}

/**
 * List secrets query
 */
export interface ListSecretsQuery {
  secretType?: SecretType;
  serviceName?: string;
  owner?: string;
  tool?: string;
  env?: string;
  limit?: number;
  offset?: number;
}

/**
 * Add tag request
 */
export interface AddTagRequest {
  tagType: TagType;
  tagValue: string;
  permission?: Permission;
}

/**
 * Remove tag request
 */
export interface RemoveTagRequest {
  tagType: TagType;
  tagValue: string;
}

/**
 * Grant access request
 */
export interface GrantAccessRequest {
  granteeType: 'principal' | 'agent';
  granteeName: string;
  permission?: Permission;
}

/**
 * Revoke access request
 */
export interface RevokeAccessRequest {
  granteeType: 'principal' | 'agent';
  granteeName: string;
}

/**
 * Initialize vault request
 */
export interface InitVaultRequest {
  passphrase: string;
}

/**
 * Unlock vault request
 */
export interface UnlockVaultRequest {
  passphrase: string;
}

/**
 * Use recovery code request
 */
export interface UseRecoveryCodeRequest {
  recoveryCode: string;
  newPassphrase: string;
}

/**
 * Recovery codes response
 */
export interface RecoveryCodesResponse {
  codes: string[];
  message: string;
}

/**
 * List audit logs query
 */
export interface ListAuditLogsQuery {
  secretId?: string;
  accessorName?: string;
  action?: AuditAction;
  since?: string;
  limit?: number;
  offset?: number;
}

/**
 * Secret stats
 */
export interface SecretStats {
  total: number;
  byType: Record<SecretType, number>;
  expiringSoon: number; // within 30 days
  expired: number;
}

// ─────────────────────────────────────────────────────────────────────────────
// Zod Schemas
// ─────────────────────────────────────────────────────────────────────────────

export const secretTypeSchema = z.enum(['api_key', 'token', 'password', 'certificate', 'ssh_key', 'env_var', 'generic']);
export const tagTypeSchema = z.enum(['tool', 'local-tool', 'env', 'service']);
export const permissionSchema = z.enum(['read', 'write', 'admin']);
export const auditActionSchema = z.enum(['create', 'read', 'update', 'delete', 'rotate', 'grant', 'revoke', 'fetch']);

export const createSecretSchema = z.object({
  name: z.string().min(1).max(100).regex(/^[a-zA-Z0-9_-]+$/, 'Name must be alphanumeric with dashes/underscores'),
  value: z.string().min(1).max(65536),
  secretType: secretTypeSchema.optional().default('generic'),
  serviceName: z.string().max(100).optional(),
  description: z.string().max(500).optional(),
  expiresAt: z.string().datetime().optional(),
  ownerType: z.enum(['principal', 'agent']).optional(),
  ownerName: z.string().optional(),
});

export const updateSecretSchema = z.object({
  serviceName: z.string().max(100).optional(),
  description: z.string().max(500).optional(),
  expiresAt: z.string().datetime().nullable().optional(),
});

export const rotateSecretSchema = z.object({
  newValue: z.string().min(1).max(65536),
});

export const listSecretsQuerySchema = z.object({
  secretType: secretTypeSchema.optional(),
  serviceName: z.string().optional(),
  owner: z.string().optional(),
  tool: z.string().optional(),
  env: z.string().optional(),
  limit: z.coerce.number().min(1).max(100).optional().default(50),
  offset: z.coerce.number().min(0).optional().default(0),
});

export const addTagSchema = z.object({
  tagType: tagTypeSchema,
  tagValue: z.string().min(1).max(200),
  permission: permissionSchema.optional().default('read'),
});

export const removeTagSchema = z.object({
  tagType: tagTypeSchema,
  tagValue: z.string().min(1).max(200),
});

export const grantAccessSchema = z.object({
  granteeType: z.enum(['principal', 'agent']),
  granteeName: z.string().min(1).max(100),
  permission: permissionSchema.optional().default('read'),
});

export const revokeAccessSchema = z.object({
  granteeType: z.enum(['principal', 'agent']),
  granteeName: z.string().min(1).max(100),
});

export const initVaultSchema = z.object({
  passphrase: z.string().min(12).max(256), // 12 chars minimum for security
});

export const unlockVaultSchema = z.object({
  passphrase: z.string().min(1).max(256),
});

export const useRecoveryCodeSchema = z.object({
  recoveryCode: z.string().min(1),
  newPassphrase: z.string().min(12).max(256), // 12 chars minimum for security
  confirmDataLoss: z.boolean(), // Must explicitly confirm data loss
});

export const listAuditLogsQuerySchema = z.object({
  secretId: z.string().optional(),
  accessorName: z.string().optional(),
  action: auditActionSchema.optional(),
  since: z.string().optional(),
  limit: z.coerce.number().min(1).max(1000).optional().default(100),
  offset: z.coerce.number().min(0).optional().default(0),
});

export const findByTagQuerySchema = z.object({
  tagType: tagTypeSchema,
  tagValue: z.string().min(1),
});
