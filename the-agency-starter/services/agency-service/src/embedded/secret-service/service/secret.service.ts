/**
 * Secret Service
 *
 * Business logic for secret management with access control and audit logging.
 */

import type { SecretRepository } from '../repository/secret.repository';
import type {
  Secret,
  SecretWithDetails,
  SecretDecrypted,
  SecretTag,
  SecretGrant,
  SecretAuditLog,
  CreateSecretRequest,
  UpdateSecretRequest,
  RotateSecretRequest,
  ListSecretsQuery,
  AddTagRequest,
  RemoveTagRequest,
  GrantAccessRequest,
  RevokeAccessRequest,
  ListAuditLogsQuery,
  SecretStats,
  VaultStatus,
  VaultStatusResponse,
  RecoveryCodesResponse,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('secret-service');

interface Accessor {
  type: 'principal' | 'agent' | 'system';
  name: string;
}

export class SecretService {
  constructor(private repository: SecretRepository) {}

  // ─────────────────────────────────────────────────────────────────────────
  // Vault Operations
  // ─────────────────────────────────────────────────────────────────────────

  async getVaultStatus(): Promise<VaultStatusResponse> {
    const status = await this.repository.getVaultStatus();

    if (status === 'uninitialized') {
      return { status };
    }

    const stats = status === 'unlocked' ? await this.repository.getStats() : undefined;

    return {
      status,
      secretCount: stats?.total,
    };
  }

  async initVault(passphrase: string): Promise<RecoveryCodesResponse> {
    const { recoveryCodes } = await this.repository.initVault(passphrase);

    return {
      codes: recoveryCodes,
      message: 'Vault initialized. Store these recovery codes safely - they cannot be recovered!',
    };
  }

  async unlockVault(passphrase: string): Promise<boolean> {
    return this.repository.unlockVault(passphrase);
  }

  lockVault(): void {
    this.repository.lockVault();
  }

  isVaultUnlocked(): boolean {
    return this.repository.isUnlocked();
  }

  async generateRecoveryCodes(): Promise<RecoveryCodesResponse> {
    if (!this.repository.isUnlocked()) {
      throw new Error('Vault must be unlocked to generate recovery codes');
    }

    const codes = await this.repository.generateRecoveryCodes();

    return {
      codes,
      message: 'New recovery codes generated. Previous unused codes are now invalid.',
    };
  }

  async useRecoveryCode(code: string, newPassphrase: string): Promise<boolean> {
    return this.repository.useRecoveryCode(code, newPassphrase);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Secret CRUD
  // ─────────────────────────────────────────────────────────────────────────

  async createSecret(data: CreateSecretRequest, accessor: Accessor): Promise<Secret> {
    // Set owner from accessor if not provided
    const request: CreateSecretRequest = {
      ...data,
      ownerType: data.ownerType || accessor.type as 'principal' | 'agent',
      ownerName: data.ownerName || accessor.name,
    };

    const secret = await this.repository.create(request);

    // Log the creation
    await this.repository.logAccess(
      secret.id,
      secret.name,
      accessor.type,
      accessor.name,
      'create'
    );

    logger.info({ secretName: secret.name, owner: `${secret.ownerType}:${secret.ownerName}` }, 'Secret created');
    return secret;
  }

  async getSecret(id: string, accessor: Accessor): Promise<SecretWithDetails | null> {
    const secret = await this.repository.getById(id);

    if (!secret) return null;

    // Check access
    const hasAccess = await this.repository.hasAccess(
      secret.id,
      accessor.type,
      accessor.name,
      'read'
    );

    if (!hasAccess) {
      logger.warn({ secretId: id, accessor: `${accessor.type}:${accessor.name}` }, 'Access denied');
      throw new Error('Access denied');
    }

    // Log the read
    await this.repository.logAccess(
      secret.id,
      secret.name,
      accessor.type,
      accessor.name,
      'read'
    );

    return secret;
  }

  async fetchSecretValue(id: string, accessor: Accessor, toolContext?: string): Promise<SecretDecrypted | null> {
    const secret = await this.repository.getById(id);

    if (!secret) return null;

    // Check access
    const hasAccess = await this.repository.hasAccess(
      secret.id,
      accessor.type,
      accessor.name,
      'read'
    );

    if (!hasAccess) {
      logger.warn({ secretId: id, accessor: `${accessor.type}:${accessor.name}` }, 'Access denied for fetch');
      throw new Error('Access denied');
    }

    const value = await this.repository.fetchValue(id);
    if (!value) return null;

    // Log the fetch (more sensitive than read)
    await this.repository.logAccess(
      secret.id,
      secret.name,
      accessor.type,
      accessor.name,
      'fetch',
      toolContext
    );

    logger.info({ secretName: secret.name, accessor: `${accessor.type}:${accessor.name}`, tool: toolContext }, 'Secret fetched');

    return {
      ...secret,
      value,
    };
  }

  async updateSecret(id: string, data: UpdateSecretRequest, accessor: Accessor): Promise<Secret | null> {
    const existing = await this.repository.getById(id);

    if (!existing) return null;

    // Check write access
    const hasAccess = await this.repository.hasAccess(
      existing.id,
      accessor.type,
      accessor.name,
      'write'
    );

    if (!hasAccess) {
      logger.warn({ secretId: id, accessor: `${accessor.type}:${accessor.name}` }, 'Access denied for update');
      throw new Error('Access denied');
    }

    const updated = await this.repository.update(id, data);

    if (updated) {
      await this.repository.logAccess(
        updated.id,
        updated.name,
        accessor.type,
        accessor.name,
        'update'
      );
    }

    return updated;
  }

  async rotateSecret(id: string, data: RotateSecretRequest, accessor: Accessor): Promise<Secret | null> {
    const existing = await this.repository.getById(id);

    if (!existing) return null;

    // Check write access
    const hasAccess = await this.repository.hasAccess(
      existing.id,
      accessor.type,
      accessor.name,
      'write'
    );

    if (!hasAccess) {
      logger.warn({ secretId: id, accessor: `${accessor.type}:${accessor.name}` }, 'Access denied for rotate');
      throw new Error('Access denied');
    }

    const rotated = await this.repository.rotate(id, data.newValue);

    if (rotated) {
      await this.repository.logAccess(
        rotated.id,
        rotated.name,
        accessor.type,
        accessor.name,
        'rotate'
      );
    }

    logger.info({ secretName: existing.name, accessor: `${accessor.type}:${accessor.name}` }, 'Secret rotated');
    return rotated;
  }

  async deleteSecret(id: string, accessor: Accessor): Promise<boolean> {
    const existing = await this.repository.getById(id);

    if (!existing) return false;

    // Check admin access (only owner or admin can delete)
    const hasAccess = await this.repository.hasAccess(
      existing.id,
      accessor.type,
      accessor.name,
      'admin'
    );

    // Also allow owner to delete
    const isOwner = existing.ownerType === accessor.type && existing.ownerName === accessor.name;

    if (!hasAccess && !isOwner) {
      logger.warn({ secretId: id, accessor: `${accessor.type}:${accessor.name}` }, 'Access denied for delete');
      throw new Error('Access denied');
    }

    // Log before deletion (secret will be gone after)
    await this.repository.logAccess(
      existing.id,
      existing.name,
      accessor.type,
      accessor.name,
      'delete'
    );

    const deleted = await this.repository.delete(id);

    logger.info({ secretName: existing.name, accessor: `${accessor.type}:${accessor.name}` }, 'Secret deleted');
    return deleted;
  }

  async listSecrets(query: ListSecretsQuery, accessor: Accessor): Promise<{ secrets: Secret[]; total: number }> {
    // For now, list returns all secrets the user has access to
    // In a more sophisticated implementation, we'd filter by grants
    const result = await this.repository.list(query);

    // Filter to only secrets the accessor can see
    const accessibleSecrets: Secret[] = [];
    for (const secret of result.secrets) {
      const hasAccess = await this.repository.hasAccess(
        secret.id,
        accessor.type,
        accessor.name,
        'read'
      );
      if (hasAccess) {
        accessibleSecrets.push(secret);
      }
    }

    return {
      secrets: accessibleSecrets,
      total: accessibleSecrets.length,
    };
  }

  async findByTag(tagType: string, tagValue: string, accessor: Accessor): Promise<Secret[]> {
    const secrets = await this.repository.findByTag(tagType, tagValue);

    // Filter to only accessible secrets
    const accessible: Secret[] = [];
    for (const secret of secrets) {
      const hasAccess = await this.repository.hasAccess(
        secret.id,
        accessor.type,
        accessor.name,
        'read'
      );
      if (hasAccess) {
        accessible.push(secret);
      }
    }

    return accessible;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tags
  // ─────────────────────────────────────────────────────────────────────────

  async addTag(secretId: string, data: AddTagRequest, accessor: Accessor): Promise<SecretTag | null> {
    const existing = await this.repository.getById(secretId);

    if (!existing) return null;

    // Check write access
    const hasAccess = await this.repository.hasAccess(
      existing.id,
      accessor.type,
      accessor.name,
      'write'
    );

    if (!hasAccess) {
      throw new Error('Access denied');
    }

    return this.repository.addTag(secretId, data);
  }

  async removeTag(secretId: string, data: RemoveTagRequest, accessor: Accessor): Promise<boolean> {
    const existing = await this.repository.getById(secretId);

    if (!existing) return false;

    // Check write access
    const hasAccess = await this.repository.hasAccess(
      existing.id,
      accessor.type,
      accessor.name,
      'write'
    );

    if (!hasAccess) {
      throw new Error('Access denied');
    }

    return this.repository.removeTag(secretId, data.tagType, data.tagValue);
  }

  async getTags(secretId: string, accessor: Accessor): Promise<SecretTag[]> {
    const existing = await this.repository.getById(secretId);

    if (!existing) return [];

    // Check read access
    const hasAccess = await this.repository.hasAccess(
      existing.id,
      accessor.type,
      accessor.name,
      'read'
    );

    if (!hasAccess) {
      throw new Error('Access denied');
    }

    return this.repository.getTags(secretId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Grants
  // ─────────────────────────────────────────────────────────────────────────

  async grantAccess(secretId: string, data: GrantAccessRequest, accessor: Accessor): Promise<SecretGrant | null> {
    const existing = await this.repository.getById(secretId);

    if (!existing) return null;

    // Only owner or admin can grant access
    const hasAccess = await this.repository.hasAccess(
      existing.id,
      accessor.type,
      accessor.name,
      'admin'
    );

    const isOwner = existing.ownerType === accessor.type && existing.ownerName === accessor.name;

    if (!hasAccess && !isOwner) {
      throw new Error('Access denied - only owner or admin can grant access');
    }

    const grant = await this.repository.addGrant(secretId, data, `${accessor.type}:${accessor.name}`);

    if (grant) {
      await this.repository.logAccess(
        existing.id,
        existing.name,
        accessor.type,
        accessor.name,
        'grant'
      );
    }

    return grant;
  }

  async revokeAccess(secretId: string, data: RevokeAccessRequest, accessor: Accessor): Promise<boolean> {
    const existing = await this.repository.getById(secretId);

    if (!existing) return false;

    // Only owner or admin can revoke access
    const hasAccess = await this.repository.hasAccess(
      existing.id,
      accessor.type,
      accessor.name,
      'admin'
    );

    const isOwner = existing.ownerType === accessor.type && existing.ownerName === accessor.name;

    if (!hasAccess && !isOwner) {
      throw new Error('Access denied - only owner or admin can revoke access');
    }

    const revoked = await this.repository.removeGrant(secretId, data.granteeType, data.granteeName);

    if (revoked) {
      await this.repository.logAccess(
        existing.id,
        existing.name,
        accessor.type,
        accessor.name,
        'revoke'
      );
    }

    return revoked;
  }

  async getGrants(secretId: string, accessor: Accessor): Promise<SecretGrant[]> {
    const existing = await this.repository.getById(secretId);

    if (!existing) return [];

    // Check read access
    const hasAccess = await this.repository.hasAccess(
      existing.id,
      accessor.type,
      accessor.name,
      'read'
    );

    if (!hasAccess) {
      throw new Error('Access denied');
    }

    return this.repository.getGrants(secretId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Audit
  // ─────────────────────────────────────────────────────────────────────────

  async getAuditLogs(query: ListAuditLogsQuery, accessor: Accessor): Promise<{ logs: SecretAuditLog[]; total: number }> {
    // If querying for a specific secret, check access
    if (query.secretId) {
      const existing = await this.repository.getById(query.secretId);
      if (existing) {
        const hasAccess = await this.repository.hasAccess(
          existing.id,
          accessor.type,
          accessor.name,
          'read'
        );

        if (!hasAccess) {
          throw new Error('Access denied');
        }
      }
    }

    return this.repository.getAuditLogs(query);
  }

  async getSecretAuditLogs(secretId: string, accessor: Accessor): Promise<SecretAuditLog[]> {
    const result = await this.getAuditLogs({ secretId }, accessor);
    return result.logs;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stats
  // ─────────────────────────────────────────────────────────────────────────

  async getStats(): Promise<SecretStats> {
    return this.repository.getStats();
  }
}
