/**
 * Secret Repository Tests
 *
 * Tests for secret data access layer including encryption, vault management,
 * and CRUD operations.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { SecretRepository } from '../../src/embedded/secret-service/repository/secret.repository';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Secret Repository', () => {
  let db: DatabaseAdapter;
  let repo: SecretRepository;
  const testDbPath = '/tmp/agency-test-secrets';
  const testDbFile = `${testDbPath}/secrets.db`;
  const testPassphrase = 'test-secure-passphrase-123!';

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'secrets.db',
    });
    await db.initialize();
    repo = new SecretRepository(db);
    await repo.initialize();
  });

  afterEach(async () => {
    // Lock vault before cleanup
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

  describe('Vault Management', () => {
    test('should start uninitialized', async () => {
      const status = await repo.getVaultStatus();
      expect(status).toBe('uninitialized');
    });

    test('should initialize vault with passphrase', async () => {
      const result = await repo.initVault(testPassphrase);

      expect(result.recoveryCodes).toHaveLength(8);
      // Recovery codes are 32 hex chars in 8 groups of 4
      expect(result.recoveryCodes[0]).toMatch(/^[A-F0-9]{4}(-[A-F0-9]{4}){7}$/);

      const status = await repo.getVaultStatus();
      expect(status).toBe('unlocked');
    });

    test('should not allow double initialization', async () => {
      await repo.initVault(testPassphrase);

      await expect(repo.initVault('another-passphrase')).rejects.toThrow('already initialized');
    });

    test('should lock and unlock vault', async () => {
      await repo.initVault(testPassphrase);
      expect(repo.isUnlocked()).toBe(true);

      repo.lockVault();
      expect(repo.isUnlocked()).toBe(false);

      const status = await repo.getVaultStatus();
      expect(status).toBe('locked');

      const unlocked = await repo.unlockVault(testPassphrase);
      expect(unlocked).toBe(true);
      expect(repo.isUnlocked()).toBe(true);
    });

    test('should reject wrong passphrase', async () => {
      await repo.initVault(testPassphrase);
      repo.lockVault();

      const unlocked = await repo.unlockVault('wrong-passphrase');
      expect(unlocked).toBe(false);
      expect(repo.isUnlocked()).toBe(false);
    });

    test('should throw when unlocking uninitialized vault', async () => {
      await expect(repo.unlockVault(testPassphrase)).rejects.toThrow('Vault not initialized');
    });

    test('should track auto-lock timeout', async () => {
      await repo.initVault(testPassphrase);

      const timeLeft = repo.getTimeUntilAutoLock();
      expect(timeLeft).not.toBeNull();
      expect(timeLeft).toBeGreaterThan(0);
      expect(timeLeft).toBeLessThanOrEqual(30 * 60 * 1000);
    });

    test('should return null for auto-lock when locked', async () => {
      await repo.initVault(testPassphrase);
      repo.lockVault();

      const timeLeft = repo.getTimeUntilAutoLock();
      expect(timeLeft).toBeNull();
    });
  });

  describe('Secret CRUD', () => {
    beforeEach(async () => {
      await repo.initVault(testPassphrase);
    });

    test('should create secret with encryption', async () => {
      const secret = await repo.create({
        name: 'my-api-key',
        value: 'sk-secret-key-12345',
        secretType: 'api_key',
        ownerType: 'principal',
        ownerName: 'jordan',
        serviceName: 'OpenAI',
        description: 'Test API key',
      });

      expect(secret.name).toBe('my-api-key');
      expect(secret.secretType).toBe('api_key');
      expect(secret.ownerName).toBe('jordan');
      expect(secret.serviceName).toBe('OpenAI');
      expect(secret.id).toBeTruthy();
      // Value should not be in the returned object (only encrypted in DB)
      expect((secret as any).value).toBeUndefined();
      expect((secret as any).encryptedValue).toBeUndefined();
    });

    test('should fetch and decrypt secret value', async () => {
      await repo.create({
        name: 'test-secret',
        value: 'my-secret-value-123',
        ownerType: 'principal',
        ownerName: 'jordan',
      });

      const value = await repo.fetchValue('test-secret');
      expect(value).toBe('my-secret-value-123');
    });

    test('should require vault to be unlocked for create', async () => {
      repo.lockVault();

      await expect(
        repo.create({
          name: 'locked-secret',
          value: 'cannot-store',
          ownerType: 'principal',
          ownerName: 'jordan',
        })
      ).rejects.toThrow('Vault is locked');
    });

    test('should require vault to be unlocked for fetch', async () => {
      await repo.create({
        name: 'test-fetch',
        value: 'secret-value',
        ownerType: 'principal',
        ownerName: 'jordan',
      });

      repo.lockVault();

      await expect(repo.fetchValue('test-fetch')).rejects.toThrow('Vault is locked');
    });

    test('should get secret by ID or name', async () => {
      const created = await repo.create({
        name: 'findable-secret',
        value: 'find-me',
        ownerType: 'principal',
        ownerName: 'jordan',
      });

      // By name
      const byName = await repo.getById('findable-secret');
      expect(byName).not.toBeNull();
      expect(byName!.name).toBe('findable-secret');

      // By ID
      const byId = await repo.getById(created.id);
      expect(byId).not.toBeNull();
      expect(byId!.id).toBe(created.id);
    });

    test('should return null for non-existent secret', async () => {
      const found = await repo.getById('non-existent');
      expect(found).toBeNull();
    });

    test('should update secret metadata', async () => {
      await repo.create({
        name: 'updatable',
        value: 'original-value',
        ownerType: 'principal',
        ownerName: 'jordan',
      });

      const updated = await repo.update('updatable', {
        serviceName: 'NewService',
        description: 'Updated description',
      });

      expect(updated).not.toBeNull();
      expect(updated!.serviceName).toBe('NewService');
      expect(updated!.description).toBe('Updated description');
    });

    test('should rotate secret value', async () => {
      await repo.create({
        name: 'rotatable',
        value: 'original-secret',
        ownerType: 'principal',
        ownerName: 'jordan',
      });

      const rotated = await repo.rotate('rotatable', 'new-secret-value');
      expect(rotated).not.toBeNull();

      const fetched = await repo.fetchValue('rotatable');
      expect(fetched).toBe('new-secret-value');
    });

    test('should delete secret', async () => {
      await repo.create({
        name: 'deletable',
        value: 'to-be-deleted',
        ownerType: 'principal',
        ownerName: 'jordan',
      });

      const deleted = await repo.delete('deletable');
      expect(deleted).toBe(true);

      const found = await repo.getById('deletable');
      expect(found).toBeNull();
    });

    test('should return false when deleting non-existent', async () => {
      const deleted = await repo.delete('non-existent');
      expect(deleted).toBe(false);
    });
  });

  describe('Secret Listing', () => {
    beforeEach(async () => {
      await repo.initVault(testPassphrase);

      // Create test secrets
      await repo.create({
        name: 'github-token',
        value: 'ghp_xxx',
        secretType: 'token',
        ownerType: 'principal',
        ownerName: 'jordan',
        serviceName: 'GitHub',
      });

      await repo.create({
        name: 'aws-key',
        value: 'AKIA...',
        secretType: 'api_key',
        ownerType: 'principal',
        ownerName: 'jordan',
        serviceName: 'AWS',
      });

      await repo.create({
        name: 'db-password',
        value: 'super-secret',
        secretType: 'password',
        ownerType: 'agent',
        ownerName: 'housekeeping',
      });
    });

    test('should list all secrets', async () => {
      const { secrets, total } = await repo.list({ limit: 50, offset: 0 });
      expect(total).toBe(3);
      expect(secrets.length).toBe(3);
    });

    test('should filter by secret type', async () => {
      const { secrets, total } = await repo.list({
        secretType: 'token',
        limit: 50,
        offset: 0,
      });
      expect(total).toBe(1);
      expect(secrets[0].name).toBe('github-token');
    });

    test('should filter by service name', async () => {
      const { secrets, total } = await repo.list({
        serviceName: 'AWS',
        limit: 50,
        offset: 0,
      });
      expect(total).toBe(1);
      expect(secrets[0].name).toBe('aws-key');
    });

    test('should filter by owner', async () => {
      const { secrets, total } = await repo.list({
        owner: 'housekeeping',
        limit: 50,
        offset: 0,
      });
      expect(total).toBe(1);
      expect(secrets[0].name).toBe('db-password');
    });

    test('should paginate results', async () => {
      const { secrets: page1 } = await repo.list({ limit: 2, offset: 0 });
      const { secrets: page2 } = await repo.list({ limit: 2, offset: 2 });

      expect(page1.length).toBe(2);
      expect(page2.length).toBe(1);
    });
  });

  describe('Tags', () => {
    beforeEach(async () => {
      await repo.initVault(testPassphrase);
      await repo.create({
        name: 'taggable',
        value: 'tag-me',
        ownerType: 'principal',
        ownerName: 'jordan',
      });
    });

    test('should add tag to secret', async () => {
      const tag = await repo.addTag('taggable', {
        tagType: 'tool',
        tagValue: 'gh',
        permission: 'read',
      });

      expect(tag).not.toBeNull();
      expect(tag!.tagType).toBe('tool');
      expect(tag!.tagValue).toBe('gh');
    });

    test('should get tags for secret', async () => {
      await repo.addTag('taggable', { tagType: 'tool', tagValue: 'gh' });
      await repo.addTag('taggable', { tagType: 'env', tagValue: 'production' });

      const tags = await repo.getTags('taggable');
      expect(tags.length).toBe(2);
    });

    test('should find secrets by tag', async () => {
      await repo.addTag('taggable', { tagType: 'tool', tagValue: 'gh' });

      const secrets = await repo.findByTag('tool', 'gh');
      expect(secrets.length).toBe(1);
      expect(secrets[0].name).toBe('taggable');
    });

    test('should remove tag from secret', async () => {
      await repo.addTag('taggable', { tagType: 'tool', tagValue: 'gh' });

      const removed = await repo.removeTag('taggable', 'tool', 'gh');
      expect(removed).toBe(true);

      const tags = await repo.getTags('taggable');
      expect(tags.length).toBe(0);
    });

    test('should not add duplicate tags', async () => {
      await repo.addTag('taggable', { tagType: 'tool', tagValue: 'gh' });
      const duplicate = await repo.addTag('taggable', { tagType: 'tool', tagValue: 'gh' });

      expect(duplicate).toBeNull();

      const tags = await repo.getTags('taggable');
      expect(tags.length).toBe(1);
    });
  });

  describe('Grants', () => {
    beforeEach(async () => {
      await repo.initVault(testPassphrase);
      await repo.create({
        name: 'grantable',
        value: 'grant-me',
        ownerType: 'principal',
        ownerName: 'jordan',
      });
    });

    test('should add grant to secret', async () => {
      const grant = await repo.addGrant(
        'grantable',
        {
          granteeType: 'agent',
          granteeName: 'housekeeping',
          permission: 'read',
        },
        'principal:jordan'
      );

      expect(grant).not.toBeNull();
      expect(grant!.granteeName).toBe('housekeeping');
      expect(grant!.permission).toBe('read');
    });

    test('should get grants for secret', async () => {
      await repo.addGrant(
        'grantable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'read' },
        'principal:jordan'
      );
      await repo.addGrant(
        'grantable',
        { granteeType: 'agent', granteeName: 'agent-manager', permission: 'write' },
        'principal:jordan'
      );

      const grants = await repo.getGrants('grantable');
      expect(grants.length).toBe(2);
    });

    test('should update existing grant', async () => {
      await repo.addGrant(
        'grantable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'read' },
        'principal:jordan'
      );

      // Add same grantee with different permission
      await repo.addGrant(
        'grantable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'admin' },
        'principal:jordan'
      );

      const grants = await repo.getGrants('grantable');
      expect(grants.length).toBe(1);
      expect(grants[0].permission).toBe('admin');
    });

    test('should remove grant from secret', async () => {
      await repo.addGrant(
        'grantable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'read' },
        'principal:jordan'
      );

      const removed = await repo.removeGrant('grantable', 'agent', 'housekeeping');
      expect(removed).toBe(true);

      const grants = await repo.getGrants('grantable');
      expect(grants.length).toBe(0);
    });

    test('should check access for owner', async () => {
      const hasAccess = await repo.hasAccess('grantable', 'principal', 'jordan', 'admin');
      expect(hasAccess).toBe(true);
    });

    test('should check access for grantee with sufficient permission', async () => {
      await repo.addGrant(
        'grantable',
        { granteeType: 'agent', granteeName: 'housekeeping', permission: 'write' },
        'principal:jordan'
      );

      const readAccess = await repo.hasAccess('grantable', 'agent', 'housekeeping', 'read');
      expect(readAccess).toBe(true);

      const writeAccess = await repo.hasAccess('grantable', 'agent', 'housekeeping', 'write');
      expect(writeAccess).toBe(true);

      const adminAccess = await repo.hasAccess('grantable', 'agent', 'housekeeping', 'admin');
      expect(adminAccess).toBe(false);
    });

    test('should deny access without grant', async () => {
      const hasAccess = await repo.hasAccess('grantable', 'agent', 'unknown', 'read');
      expect(hasAccess).toBe(false);
    });
  });

  describe('Audit Logging', () => {
    beforeEach(async () => {
      await repo.initVault(testPassphrase);
    });

    test('should log access', async () => {
      await repo.logAccess(
        'secret-id',
        'my-secret',
        'principal',
        'jordan',
        'fetch',
        'gh',
        '127.0.0.1'
      );

      const { logs, total } = await repo.getAuditLogs({ limit: 50, offset: 0 });
      expect(total).toBe(1);
      expect(logs[0].action).toBe('fetch');
      expect(logs[0].accessorName).toBe('jordan');
      expect(logs[0].toolContext).toBe('gh');
    });

    test('should filter audit logs by secret ID', async () => {
      await repo.logAccess('secret-1', 'secret-one', 'principal', 'jordan', 'read');
      await repo.logAccess('secret-2', 'secret-two', 'principal', 'jordan', 'read');

      const { logs, total } = await repo.getAuditLogs({ secretId: 'secret-1', limit: 50, offset: 0 });
      expect(total).toBe(1);
      expect(logs[0].secretId).toBe('secret-1');
    });

    test('should filter audit logs by action', async () => {
      await repo.logAccess('secret-1', 'my-secret', 'principal', 'jordan', 'read');
      await repo.logAccess('secret-1', 'my-secret', 'principal', 'jordan', 'fetch');
      await repo.logAccess('secret-1', 'my-secret', 'principal', 'jordan', 'rotate');

      const { logs, total } = await repo.getAuditLogs({ action: 'fetch', limit: 50, offset: 0 });
      expect(total).toBe(1);
      expect(logs[0].action).toBe('fetch');
    });

    test('should filter audit logs by accessor', async () => {
      await repo.logAccess('secret-1', 'my-secret', 'principal', 'jordan', 'read');
      await repo.logAccess('secret-1', 'my-secret', 'agent', 'housekeeping', 'read');

      const { logs, total } = await repo.getAuditLogs({
        accessorName: 'housekeeping',
        limit: 50,
        offset: 0,
      });
      expect(total).toBe(1);
      expect(logs[0].accessorName).toBe('housekeeping');
    });
  });

  describe('Recovery Codes', () => {
    test('should generate new recovery codes', async () => {
      await repo.initVault(testPassphrase);

      const codes = await repo.generateRecoveryCodes();
      expect(codes.length).toBe(8);
      // Recovery codes are 32 hex chars in 8 groups of 4
      expect(codes[0]).toMatch(/^[A-F0-9]{4}(-[A-F0-9]{4}){7}$/);
    });

    test('should use recovery code to reset vault', async () => {
      const { recoveryCodes } = await repo.initVault(testPassphrase);

      // Create a secret first
      await repo.create({
        name: 'will-be-lost',
        value: 'goodbye',
        ownerType: 'principal',
        ownerName: 'jordan',
      });

      repo.lockVault();

      // Use recovery code
      const newPassphrase = 'new-secure-passphrase-456!';
      const success = await repo.useRecoveryCode(recoveryCodes[0], newPassphrase);
      expect(success).toBe(true);

      // Vault should be unlocked with new passphrase
      expect(repo.isUnlocked()).toBe(true);

      // Old secrets should be gone
      const { total } = await repo.list({ limit: 50, offset: 0 });
      expect(total).toBe(0);

      // Should be able to lock and unlock with new passphrase
      repo.lockVault();
      const unlocked = await repo.unlockVault(newPassphrase);
      expect(unlocked).toBe(true);
    });

    test('should reject invalid recovery code', async () => {
      await repo.initVault(testPassphrase);

      const success = await repo.useRecoveryCode('FAKE-CODE-1234-5678', 'new-pass');
      expect(success).toBe(false);
    });

    test('should reject already used recovery code', async () => {
      const { recoveryCodes } = await repo.initVault(testPassphrase);
      repo.lockVault();

      // Use code once - this resets the vault and reinitializes
      const success1 = await repo.useRecoveryCode(recoveryCodes[0], 'new-pass-1');
      expect(success1).toBe(true);

      repo.lockVault();

      // Try to use the same code again - should fail because codes are invalidated
      // after a successful reset (the old codes are from the previous vault)
      const success2 = await repo.useRecoveryCode(recoveryCodes[0], 'new-pass-2');
      expect(success2).toBe(false);
    });
  });

  describe('Statistics', () => {
    beforeEach(async () => {
      await repo.initVault(testPassphrase);
    });

    test('should return empty stats for empty vault', async () => {
      const stats = await repo.getStats();
      expect(stats.total).toBe(0);
      expect(stats.byType.api_key).toBe(0);
      expect(stats.expiringSoon).toBe(0);
      expect(stats.expired).toBe(0);
    });

    test('should return correct type counts', async () => {
      await repo.create({ name: 'key1', value: 'v', secretType: 'api_key', ownerType: 'principal', ownerName: 'x' });
      await repo.create({ name: 'key2', value: 'v', secretType: 'api_key', ownerType: 'principal', ownerName: 'x' });
      await repo.create({ name: 'token1', value: 'v', secretType: 'token', ownerType: 'principal', ownerName: 'x' });
      await repo.create({ name: 'pass1', value: 'v', secretType: 'password', ownerType: 'principal', ownerName: 'x' });

      const stats = await repo.getStats();
      expect(stats.total).toBe(4);
      expect(stats.byType.api_key).toBe(2);
      expect(stats.byType.token).toBe(1);
      expect(stats.byType.password).toBe(1);
    });

    test('should count expiring secrets', async () => {
      const now = new Date();

      // Expires in 10 days
      const expiringSoon = new Date(now);
      expiringSoon.setDate(expiringSoon.getDate() + 10);

      // Expires in 60 days
      const expiresLater = new Date(now);
      expiresLater.setDate(expiresLater.getDate() + 60);

      // Already expired
      const expired = new Date(now);
      expired.setDate(expired.getDate() - 5);

      await repo.create({
        name: 'expiring-soon',
        value: 'v',
        secretType: 'token',
        ownerType: 'principal',
        ownerName: 'x',
        expiresAt: expiringSoon.toISOString(),
      });

      await repo.create({
        name: 'expires-later',
        value: 'v',
        secretType: 'token',
        ownerType: 'principal',
        ownerName: 'x',
        expiresAt: expiresLater.toISOString(),
      });

      await repo.create({
        name: 'already-expired',
        value: 'v',
        secretType: 'token',
        ownerType: 'principal',
        ownerName: 'x',
        expiresAt: expired.toISOString(),
      });

      const stats = await repo.getStats();
      expect(stats.total).toBe(3);
      expect(stats.expiringSoon).toBe(1);
      expect(stats.expired).toBe(1);
    });
  });

  describe('Edge Cases', () => {
    beforeEach(async () => {
      await repo.initVault(testPassphrase);
    });

    test('should handle special characters in secret value', async () => {
      const specialValue = '{"key": "value", "special": "\'\"\\n\\t"}';

      await repo.create({
        name: 'special-chars',
        value: specialValue,
        ownerType: 'principal',
        ownerName: 'jordan',
      });

      const fetched = await repo.fetchValue('special-chars');
      expect(fetched).toBe(specialValue);
    });

    test('should handle unicode in secret value', async () => {
      const unicodeValue = 'Password: 密码 🔐';

      await repo.create({
        name: 'unicode-secret',
        value: unicodeValue,
        ownerType: 'principal',
        ownerName: 'jordan',
      });

      const fetched = await repo.fetchValue('unicode-secret');
      expect(fetched).toBe(unicodeValue);
    });

    test('should handle large secret value', async () => {
      const largeValue = 'x'.repeat(10000);

      await repo.create({
        name: 'large-secret',
        value: largeValue,
        ownerType: 'principal',
        ownerName: 'jordan',
      });

      const fetched = await repo.fetchValue('large-secret');
      expect(fetched).toBe(largeValue);
    });

    test('should return null for update on non-existent', async () => {
      const updated = await repo.update('non-existent', { description: 'test' });
      expect(updated).toBeNull();
    });

    test('should return null for rotate on non-existent', async () => {
      const rotated = await repo.rotate('non-existent', 'new-value');
      expect(rotated).toBeNull();
    });

    test('should handle empty grants list', async () => {
      await repo.create({
        name: 'no-grants',
        value: 'v',
        ownerType: 'principal',
        ownerName: 'jordan',
      });

      const grants = await repo.getGrants('no-grants');
      expect(grants).toEqual([]);
    });

    test('should handle empty tags list', async () => {
      await repo.create({
        name: 'no-tags',
        value: 'v',
        ownerType: 'principal',
        ownerName: 'jordan',
      });

      const tags = await repo.getTags('no-tags');
      expect(tags).toEqual([]);
    });
  });
});
