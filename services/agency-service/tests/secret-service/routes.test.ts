/**
 * Secret Routes Tests
 *
 * Tests for secret HTTP API endpoints.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { Hono } from 'hono';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { SecretRepository } from '../../src/embedded/secret-service/repository/secret.repository';
import { SecretService } from '../../src/embedded/secret-service/service/secret.service';
import { createSecretRoutes } from '../../src/embedded/secret-service/routes/secret.routes';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Secret Routes', () => {
  let db: DatabaseAdapter;
  let repo: SecretRepository;
  let service: SecretService;
  let app: Hono;
  const testDbPath = '/tmp/agency-test-secrets-routes';
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
    service = new SecretService(repo);

    // Create Hono app with auth middleware mock
    app = new Hono();

    // Mock auth middleware - set user in context
    app.use('*', async (c, next) => {
      c.set('user', { type: 'principal', name: 'jordan' });
      await next();
    });

    const routes = createSecretRoutes(service);
    app.route('/secret', routes);
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

  describe('Vault Endpoints', () => {
    test('GET /vault/status - should return uninitialized', async () => {
      const res = await app.request('/secret/vault/status');
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.status).toBe('uninitialized');
    });

    test('POST /vault/init - should initialize vault', async () => {
      const res = await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      expect(res.status).toBe(201);

      const body = await res.json();
      expect(body.codes).toHaveLength(8);
      expect(body.message).toContain('Store these recovery codes');
    });

    test('POST /vault/init - should reject short passphrase', async () => {
      const res = await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: 'short' }),
      });

      expect(res.status).toBe(400);
    });

    test('POST /vault/init - should reject double init', async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      const res = await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: 'another-passphrase' }),
      });

      expect(res.status).toBe(409);
    });

    test('POST /vault/unlock - should unlock vault', async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      await app.request('/secret/vault/lock', { method: 'POST' });

      const res = await app.request('/secret/vault/unlock', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.success).toBe(true);
    });

    test('POST /vault/unlock - should reject wrong passphrase', async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      await app.request('/secret/vault/lock', { method: 'POST' });

      const res = await app.request('/secret/vault/unlock', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: 'wrong-passphrase' }),
      });

      expect(res.status).toBe(401);
    });

    test('POST /vault/lock - should lock vault', async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      const res = await app.request('/secret/vault/lock', { method: 'POST' });

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.success).toBe(true);

      const statusRes = await app.request('/secret/vault/status');
      const status = await statusRes.json();
      expect(status.status).toBe('locked');
    });
  });

  describe('Secret CRUD Endpoints', () => {
    beforeEach(async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });
    });

    test('POST /create - should create secret', async () => {
      const res = await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: 'my-api-key',
          value: 'sk-12345',
          secretType: 'api_key',
          serviceName: 'OpenAI',
        }),
      });

      expect(res.status).toBe(201);

      const body = await res.json();
      expect(body.name).toBe('my-api-key');
      expect(body.secretType).toBe('api_key');
      expect(body.ownerName).toBe('jordan');
    });

    test('POST /create - should validate name format', async () => {
      const res = await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: 'invalid name with spaces!',
          value: 'v',
        }),
      });

      expect(res.status).toBe(400);
    });

    test('GET /list - should list secrets', async () => {
      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'secret-1', value: 'v' }),
      });

      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'secret-2', value: 'v' }),
      });

      const res = await app.request('/secret/list');
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.secrets.length).toBe(2);
      expect(body.total).toBe(2);
    });

    test('GET /list - should filter by type', async () => {
      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'token-1', value: 'v', secretType: 'token' }),
      });

      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'key-1', value: 'v', secretType: 'api_key' }),
      });

      const res = await app.request('/secret/list?secretType=token');
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.secrets.length).toBe(1);
      expect(body.secrets[0].name).toBe('token-1');
    });

    test('GET /get/:id - should get secret metadata', async () => {
      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'gettable', value: 'v', description: 'My secret' }),
      });

      const res = await app.request('/secret/get/gettable');
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.name).toBe('gettable');
      expect(body.description).toBe('My secret');
      expect(body.value).toBeUndefined();
    });

    test('GET /get/:id - should return 404 for non-existent', async () => {
      const res = await app.request('/secret/get/non-existent');
      expect(res.status).toBe(404);
    });

    test('GET /fetch/:id - should fetch secret value', async () => {
      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'fetchable', value: 'my-secret-value' }),
      });

      const res = await app.request('/secret/fetch/fetchable');
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.name).toBe('fetchable');
      expect(body.value).toBe('my-secret-value');
    });

    test('GET /fetch/:id - should include tool context', async () => {
      const createRes = await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'fetchable', value: 'v' }),
      });
      const created = await createRes.json();

      const res = await app.request('/secret/fetch/fetchable?tool=gh');
      expect(res.status).toBe(200);

      // Check audit log using the secret's UUID
      const auditRes = await app.request(`/secret/audit/${created.id}`);
      const audit = await auditRes.json();
      const fetchLog = audit.logs.find((l: any) => l.action === 'fetch');
      expect(fetchLog.toolContext).toBe('gh');
    });

    test('POST /update/:id - should update secret', async () => {
      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'updatable', value: 'v' }),
      });

      const res = await app.request('/secret/update/updatable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ description: 'Updated desc', serviceName: 'NewService' }),
      });

      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.description).toBe('Updated desc');
      expect(body.serviceName).toBe('NewService');
    });

    test('POST /rotate/:id - should rotate secret value', async () => {
      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'rotatable', value: 'old-value' }),
      });

      const res = await app.request('/secret/rotate/rotatable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ newValue: 'new-value' }),
      });

      expect(res.status).toBe(200);

      // Verify new value
      const fetchRes = await app.request('/secret/fetch/rotatable');
      const fetched = await fetchRes.json();
      expect(fetched.value).toBe('new-value');
    });

    test('POST /delete/:id - should delete secret', async () => {
      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'deletable', value: 'v' }),
      });

      const res = await app.request('/secret/delete/deletable', {
        method: 'POST',
      });

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.success).toBe(true);

      // Verify deleted
      const getRes = await app.request('/secret/get/deletable');
      expect(getRes.status).toBe(404);
    });
  });

  describe('Tag Endpoints', () => {
    beforeEach(async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'taggable', value: 'v' }),
      });
    });

    test('POST /tag/:id - should add tag', async () => {
      const res = await app.request('/secret/tag/taggable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tagType: 'tool', tagValue: 'gh' }),
      });

      expect(res.status).toBe(201);

      const body = await res.json();
      expect(body.tagType).toBe('tool');
      expect(body.tagValue).toBe('gh');
    });

    test('POST /untag/:id - should remove tag', async () => {
      await app.request('/secret/tag/taggable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tagType: 'tool', tagValue: 'gh' }),
      });

      const res = await app.request('/secret/untag/taggable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tagType: 'tool', tagValue: 'gh' }),
      });

      expect(res.status).toBe(200);
    });

    test('GET /tags/:id - should list tags', async () => {
      await app.request('/secret/tag/taggable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tagType: 'tool', tagValue: 'gh' }),
      });

      await app.request('/secret/tag/taggable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tagType: 'env', tagValue: 'production' }),
      });

      const res = await app.request('/secret/tags/taggable');
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.tags.length).toBe(2);
      expect(body.count).toBe(2);
    });

    test('GET /by-tag - should find secrets by tag', async () => {
      await app.request('/secret/tag/taggable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tagType: 'tool', tagValue: 'gh' }),
      });

      const res = await app.request('/secret/by-tag?tagType=tool&tagValue=gh');
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.secrets.length).toBe(1);
      expect(body.secrets[0].name).toBe('taggable');
    });
  });

  describe('Grant Endpoints', () => {
    beforeEach(async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'grantable', value: 'v' }),
      });
    });

    test('POST /grant/:id - should grant access', async () => {
      const res = await app.request('/secret/grant/grantable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          granteeType: 'agent',
          granteeName: 'housekeeping',
          permission: 'read',
        }),
      });

      expect(res.status).toBe(201);

      const body = await res.json();
      expect(body.granteeName).toBe('housekeeping');
      expect(body.permission).toBe('read');
    });

    test('POST /revoke/:id - should revoke access', async () => {
      await app.request('/secret/grant/grantable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          granteeType: 'agent',
          granteeName: 'housekeeping',
        }),
      });

      const res = await app.request('/secret/revoke/grantable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          granteeType: 'agent',
          granteeName: 'housekeeping',
        }),
      });

      expect(res.status).toBe(200);
    });

    test('GET /grants/:id - should list grants', async () => {
      await app.request('/secret/grant/grantable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          granteeType: 'agent',
          granteeName: 'housekeeping',
        }),
      });

      const res = await app.request('/secret/grants/grantable');
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.grants.length).toBe(1);
      expect(body.count).toBe(1);
    });
  });

  describe('Audit Endpoints', () => {
    beforeEach(async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'audited', value: 'v' }),
      });

      await app.request('/secret/fetch/audited');
    });

    test('GET /audit/:id - should get audit logs for secret', async () => {
      // Get the secret's UUID first
      const getRes = await app.request('/secret/get/audited');
      const secret = await getRes.json();

      const res = await app.request(`/secret/audit/${secret.id}`);
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.logs.length).toBeGreaterThan(0);
      expect(body.count).toBeGreaterThan(0);
    });

    test('GET /audit - should get all audit logs', async () => {
      const res = await app.request('/secret/audit');
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.logs.length).toBeGreaterThan(0);
      expect(body.total).toBeGreaterThan(0);
    });

    test('GET /audit - should filter by action', async () => {
      const res = await app.request('/secret/audit?action=fetch');
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.logs.every((l: any) => l.action === 'fetch')).toBe(true);
    });
  });

  describe('Stats Endpoint', () => {
    test('GET /stats - should return statistics', async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 's1', value: 'v', secretType: 'api_key' }),
      });

      await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 's2', value: 'v', secretType: 'token' }),
      });

      const res = await app.request('/secret/stats');
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.total).toBe(2);
      expect(body.byType.api_key).toBe(1);
      expect(body.byType.token).toBe(1);
    });
  });

  describe('Error Handling', () => {
    test('should return 423 when vault is locked', async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      await app.request('/secret/vault/lock', { method: 'POST' });

      const res = await app.request('/secret/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'test', value: 'v' }),
      });

      expect(res.status).toBe(423);
    });

    test('should return 404 for operations on non-existent secret', async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      const updateRes = await app.request('/secret/update/non-existent', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ description: 'x' }),
      });
      expect(updateRes.status).toBe(404);

      const rotateRes = await app.request('/secret/rotate/non-existent', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ newValue: 'x' }),
      });
      expect(rotateRes.status).toBe(404);

      const deleteRes = await app.request('/secret/delete/non-existent', {
        method: 'POST',
      });
      expect(deleteRes.status).toBe(404);
    });
  });

  describe('Recovery Endpoints', () => {
    test('POST /vault/recovery/generate - should generate codes', async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      const res = await app.request('/secret/vault/recovery/generate', {
        method: 'POST',
      });

      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.codes).toHaveLength(8);
    });

    test('POST /vault/recovery/use - should reset vault', async () => {
      const initRes = await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      const { codes } = await initRes.json();

      await app.request('/secret/vault/lock', { method: 'POST' });

      const res = await app.request('/secret/vault/recovery/use', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          recoveryCode: codes[0],
          newPassphrase: 'new-passphrase-123',
        }),
      });

      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.success).toBe(true);
    });

    test('POST /vault/recovery/use - should reject invalid code', async () => {
      await app.request('/secret/vault/init', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ passphrase: testPassphrase }),
      });

      const res = await app.request('/secret/vault/recovery/use', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          recoveryCode: 'FAKE-CODE-1234-5678',
          newPassphrase: 'new-passphrase-123',
        }),
      });

      expect(res.status).toBe(400);
    });
  });
});
