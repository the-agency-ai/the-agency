/**
 * Secret Service Tests
 *
 * Tests for secret business logic including access control and audit logging.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { SecretRepository } from '../../src/embedded/secret-service/repository/secret.repository';
import { SecretService } from '../../src/embedded/secret-service/service/secret.service';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Secret Service', () => {
  let db: DatabaseAdapter;
  let repo: SecretRepository;
  let service: SecretService;
  const testDbPath = '/tmp/agency-test-secrets-svc';
  const testDbFile = `${testDbPath}/secrets.db`;
  const testPassphrase = 'test-secure-passphrase-123!';

  const principalAccessor = { type: 'principal' as const, name: 'jordan' };
  const agentAccessor = { type: 'agent' as const, name: 'housekeeping' };

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'secrets.db',
    });
    await db.initialize();
    repo = new SecretRepository(db);
    await repo.initialize();
    service = new SecretService(repo);
  });

  afterEach(async () => {
    repo.lockVault();
    await db.close();
    try {
      if (existsSync(testDbFile)) await unlink(testDbFile);
      if (existsSync(`${testDbFile}-wal`)) await unlink(`${testDbFile}-wal`);
      if (existsSync(`${testDbFile}-shm`)) await unlink(`${testDbFile}-shm`);
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  describe('Vault Operations', () => {
    test('should get vault status', async () => {
      const status = await service.getVaultStatus();
      expect(status.status).toBe('uninitialized');
    });

    test('should initialize vault', async () => {
      const result = await service.initVault(testPassphrase);

      expect(result.codes).toHaveLength(8);
      expect(result.message).toContain('Store these recovery codes');

      const status = await service.getVaultStatus();
      expect(status.status).toBe('unlocked');
    });

    test('should return stats when unlocked', async () => {
      await service.initVault(testPassphrase);

      const status = await service.getVaultStatus();
      expect(status.status).toBe('unlocked');
      expect(status.secretCount).toBe(0);
      expect(status.autoLockTimeoutMs).toBe(30 * 60 * 1000);
    });

    test('should unlock and lock vault', async () => {
      await service.initVault(testPassphrase);
      service.lockVault();

      expect(service.isVaultUnlocked()).toBe(false);

      const unlocked = await service.unlockVault(testPassphrase);
      expect(unlocked).toBe(true);
      expect(service.isVaultUnlocked()).toBe(true);
    });

    test('should generate new recovery codes', async () => {
      await service.initVault(testPassphrase);

      const result = await service.generateRecoveryCodes();
      expect(result.codes).toHaveLength(8);
      expect(result.message).toContain('Previous unused codes are now invalid');
    });

    test('should require unlocked vault to generate recovery codes', async () => {
      await service.initVault(testPassphrase);
      service.lockVault();

      await expect(service.generateRecoveryCodes()).rejects.toThrow('Vault must be unlocked');
    });
  });

  describe('Secret CRUD with Access Control', () => {
    beforeEach(async () => {
      await service.initVault(testPassphrase);
    });

    test('should create secret with accessor as owner', async () => {
      const secret = await service.createSecret(
        {
          name: 'my-secret',
          value: 'secret-value',
          secretType: 'api_key',
        },
        principalAccessor
      );

      expect(secret.name).toBe('my-secret');
      expect(secret.ownerType).toBe('principal');
      expect(secret.ownerName).toBe('jordan');
    });

    test('should log secret creation', async () => {
      await service.createSecret(
        { name: 'logged-secret', value: 'v' },
        principalAccessor
      );

      const { logs } = await service.getAuditLogs({}, principalAccessor);
      expect(logs.length).toBe(1);
      expect(logs[0].action).toBe('create');
      expect(logs[0].accessorName).toBe('jordan');
    });

    test('should get secret with read access', async () => {
      await service.createSecret(
        { name: 'readable', value: 'v' },
        principalAccessor
      );

      const secret = await service.getSecret('readable', principalAccessor);
      expect(secret).not.toBeNull();
      expect(secret!.name).toBe('readable');
    });

    test('should deny read access without grant', async () => {
      await service.createSecret(
        { name: 'private', value: 'v' },
        principalAccessor
      );

      await expect(
        service.getSecret('private', agentAccessor)
      ).rejects.toThrow('Access denied');
    });

    test('should allow read access with grant', async () => {
      await service.createSecret(
        { name: 'shared', value: 'v' },
        principalAccessor
      );

      await service.grantAccess(
        'shared',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'read' },
        principalAccessor
      );

      const secret = await service.getSecret('shared', agentAccessor);
      expect(secret).not.toBeNull();
    });

    test('should fetch secret value with logging', async () => {
      await service.createSecret(
        { name: 'fetchable', value: 'my-secret-value' },
        principalAccessor
      );

      const result = await service.fetchSecretValue('fetchable', principalAccessor, 'gh');
      expect(result).not.toBeNull();
      expect(result!.value).toBe('my-secret-value');

      const { logs } = await service.getAuditLogs({}, principalAccessor);
      const fetchLog = logs.find((l) => l.action === 'fetch');
      expect(fetchLog).toBeTruthy();
      expect(fetchLog!.toolContext).toBe('gh');
    });

    test('should require write access to update', async () => {
      await service.createSecret(
        { name: 'updatable', value: 'v' },
        principalAccessor
      );

      await service.grantAccess(
        'updatable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'read' },
        principalAccessor
      );

      await expect(
        service.updateSecret('updatable', { description: 'new desc' }, agentAccessor)
      ).rejects.toThrow('Access denied');
    });

    test('should allow update with write access', async () => {
      await service.createSecret(
        { name: 'updatable', value: 'v' },
        principalAccessor
      );

      await service.grantAccess(
        'updatable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'write' },
        principalAccessor
      );

      const updated = await service.updateSecret(
        'updatable',
        { description: 'new desc' },
        agentAccessor
      );
      expect(updated).not.toBeNull();
      expect(updated!.description).toBe('new desc');
    });

    test('should require write access to rotate', async () => {
      await service.createSecret(
        { name: 'rotatable', value: 'old-value' },
        principalAccessor
      );

      await service.grantAccess(
        'rotatable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'read' },
        principalAccessor
      );

      await expect(
        service.rotateSecret('rotatable', { newValue: 'new-value' }, agentAccessor)
      ).rejects.toThrow('Access denied');
    });

    test('should require admin access to delete', async () => {
      await service.createSecret(
        { name: 'deletable', value: 'v' },
        principalAccessor
      );

      await service.grantAccess(
        'deletable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'write' },
        principalAccessor
      );

      await expect(
        service.deleteSecret('deletable', agentAccessor)
      ).rejects.toThrow('Access denied');
    });

    test('should allow owner to delete', async () => {
      await service.createSecret(
        { name: 'deletable', value: 'v' },
        principalAccessor
      );

      const deleted = await service.deleteSecret('deletable', principalAccessor);
      expect(deleted).toBe(true);
    });

    test('should allow admin to delete', async () => {
      await service.createSecret(
        { name: 'deletable', value: 'v' },
        principalAccessor
      );

      await service.grantAccess(
        'deletable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'admin' },
        principalAccessor
      );

      const deleted = await service.deleteSecret('deletable', agentAccessor);
      expect(deleted).toBe(true);
    });
  });

  describe('Secret Listing', () => {
    beforeEach(async () => {
      await service.initVault(testPassphrase);

      // Create secrets owned by different users
      await service.createSecret(
        { name: 'jordan-secret-1', value: 'v' },
        principalAccessor
      );
      await service.createSecret(
        { name: 'jordan-secret-2', value: 'v' },
        principalAccessor
      );
      await service.createSecret(
        { name: 'agent-secret', value: 'v' },
        agentAccessor
      );
    });

    test('should list only accessible secrets', async () => {
      const { secrets } = await service.listSecrets({}, principalAccessor);

      // Jordan should only see their own secrets
      expect(secrets.length).toBe(2);
      expect(secrets.every((s) => s.ownerName === 'jordan')).toBe(true);
    });

    test('should include shared secrets in list', async () => {
      await service.grantAccess(
        'agent-secret',
        { granteeType: 'principal', granteeName: 'jordan', permission: 'read' },
        agentAccessor
      );

      const { secrets } = await service.listSecrets({}, principalAccessor);
      expect(secrets.length).toBe(3);
    });
  });

  describe('Tags', () => {
    beforeEach(async () => {
      await service.initVault(testPassphrase);
      await service.createSecret(
        { name: 'taggable', value: 'v' },
        principalAccessor
      );
    });

    test('should add tag with write access', async () => {
      const tag = await service.addTag(
        'taggable',
        { tagType: 'tool', tagValue: 'gh' },
        principalAccessor
      );

      expect(tag).not.toBeNull();
      expect(tag!.tagValue).toBe('gh');
    });

    test('should require write access to add tag', async () => {
      await service.grantAccess(
        'taggable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'read' },
        principalAccessor
      );

      await expect(
        service.addTag('taggable', { tagType: 'tool', tagValue: 'gh' }, agentAccessor)
      ).rejects.toThrow('Access denied');
    });

    test('should get tags with read access', async () => {
      await service.addTag(
        'taggable',
        { tagType: 'tool', tagValue: 'gh' },
        principalAccessor
      );

      await service.grantAccess(
        'taggable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'read' },
        principalAccessor
      );

      const tags = await service.getTags('taggable', agentAccessor);
      expect(tags.length).toBe(1);
    });

    test('should find by tag with access filter', async () => {
      await service.addTag(
        'taggable',
        { tagType: 'tool', tagValue: 'gh' },
        principalAccessor
      );

      // Agent should not find secret without access
      const noAccess = await service.findByTag('tool', 'gh', agentAccessor);
      expect(noAccess.length).toBe(0);

      // Grant access
      await service.grantAccess(
        'taggable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'read' },
        principalAccessor
      );

      // Now agent should find it
      const withAccess = await service.findByTag('tool', 'gh', agentAccessor);
      expect(withAccess.length).toBe(1);
    });
  });

  describe('Grants', () => {
    beforeEach(async () => {
      await service.initVault(testPassphrase);
      await service.createSecret(
        { name: 'grantable', value: 'v' },
        principalAccessor
      );
    });

    test('should allow owner to grant access', async () => {
      const grant = await service.grantAccess(
        'grantable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'read' },
        principalAccessor
      );

      expect(grant).not.toBeNull();
      expect(grant!.granteeName).toBe('housekeeping');
    });

    test('should deny non-owner from granting access', async () => {
      await service.grantAccess(
        'grantable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'write' },
        principalAccessor
      );

      await expect(
        service.grantAccess(
          'grantable',
          { granteeType: 'agent', granteeName: 'other-agent', permission: 'read' },
          agentAccessor
        )
      ).rejects.toThrow('only owner or admin can grant');
    });

    test('should allow admin to grant access', async () => {
      await service.grantAccess(
        'grantable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'admin' },
        principalAccessor
      );

      const grant = await service.grantAccess(
        'grantable',
        { granteeType: 'agent', granteeName: 'other-agent', permission: 'read' },
        agentAccessor
      );

      expect(grant).not.toBeNull();
    });

    test('should allow owner to revoke access', async () => {
      await service.grantAccess(
        'grantable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'read' },
        principalAccessor
      );

      const revoked = await service.revokeAccess(
        'grantable',
        { granteeType: 'agent', granteeName: 'housekeeping' },
        principalAccessor
      );

      expect(revoked).toBe(true);
    });

    test('should log grant operations', async () => {
      await service.grantAccess(
        'grantable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'read' },
        principalAccessor
      );

      const { logs } = await service.getAuditLogs({}, principalAccessor);
      const grantLog = logs.find((l) => l.action === 'grant');
      expect(grantLog).toBeTruthy();
    });
  });

  describe('Audit Logs', () => {
    beforeEach(async () => {
      await service.initVault(testPassphrase);

      // Create secret and perform operations
      await service.createSecret(
        { name: 'audited', value: 'v' },
        principalAccessor
      );
      await service.getSecret('audited', principalAccessor);
      await service.fetchSecretValue('audited', principalAccessor);
      await service.updateSecret('audited', { description: 'x' }, principalAccessor);
    });

    test('should return audit logs for accessible secrets', async () => {
      const { logs } = await service.getAuditLogs({}, principalAccessor);
      expect(logs.length).toBeGreaterThan(0);
    });

    test('should filter by secret ID', async () => {
      const secret = await service.getSecret('audited', principalAccessor);
      const { logs } = await service.getAuditLogs(
        { secretId: secret!.id },
        principalAccessor
      );

      expect(logs.every((l) => l.secretId === secret!.id)).toBe(true);
    });

    test('should get audit logs for specific secret', async () => {
      // Get the secret first to get its UUID
      const secret = await service.getSecret('audited', principalAccessor);
      const logs = await service.getSecretAuditLogs(secret!.id, principalAccessor);
      expect(logs.length).toBeGreaterThan(0);
    });

    test('should require access to view secret audit logs', async () => {
      await expect(
        service.getSecretAuditLogs('audited', agentAccessor)
      ).rejects.toThrow('Access denied');
    });
  });

  describe('Statistics', () => {
    beforeEach(async () => {
      await service.initVault(testPassphrase);
    });

    test('should return statistics', async () => {
      await service.createSecret(
        { name: 's1', value: 'v', secretType: 'api_key' },
        principalAccessor
      );
      await service.createSecret(
        { name: 's2', value: 'v', secretType: 'token' },
        principalAccessor
      );

      const stats = await service.getStats();
      expect(stats.total).toBe(2);
      expect(stats.byType.api_key).toBe(1);
      expect(stats.byType.token).toBe(1);
    });
  });

  describe('Edge Cases', () => {
    beforeEach(async () => {
      await service.initVault(testPassphrase);
    });

    test('should return null for non-existent secret', async () => {
      const secret = await service.getSecret('non-existent', principalAccessor);
      expect(secret).toBeNull();
    });

    test('should return null for fetch non-existent', async () => {
      const result = await service.fetchSecretValue('non-existent', principalAccessor);
      expect(result).toBeNull();
    });

    test('should return null for update non-existent', async () => {
      const result = await service.updateSecret('non-existent', {}, principalAccessor);
      expect(result).toBeNull();
    });

    test('should return false for delete non-existent', async () => {
      const result = await service.deleteSecret('non-existent', principalAccessor);
      expect(result).toBe(false);
    });

    test('should return empty array for tags on non-existent', async () => {
      const tags = await service.getTags('non-existent', principalAccessor);
      expect(tags).toEqual([]);
    });

    test('should return empty array for grants on non-existent', async () => {
      const grants = await service.getGrants('non-existent', principalAccessor);
      expect(grants).toEqual([]);
    });
  });
});
