/**
 * Secret Routes
 *
 * HTTP API endpoints for secret management.
 * Uses explicit operation names (not HTTP verb semantics).
 */

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import type { SecretService } from '../service/secret.service';
import {
  createSecretSchema,
  updateSecretSchema,
  rotateSecretSchema,
  listSecretsQuerySchema,
  addTagSchema,
  removeTagSchema,
  grantAccessSchema,
  revokeAccessSchema,
  initVaultSchema,
  unlockVaultSchema,
  useRecoveryCodeSchema,
  listAuditLogsQuerySchema,
  findByTagQuerySchema,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('secret-routes');

/**
 * Get accessor from request context
 */
function getAccessor(c: any): { type: 'principal' | 'agent' | 'system'; name: string } {
  const user = c.get('user');
  if (user) {
    return { type: user.type, name: user.name };
  }
  return { type: 'system', name: 'anonymous' };
}

/**
 * Create secret routes with explicit operation names
 */
export function createSecretRoutes(secretService: SecretService): Hono {
  const app = new Hono();

  // Session token validation middleware
  // If a valid session token is provided, it keeps the vault alive
  app.use('*', async (c, next) => {
    const sessionToken = c.req.header('X-Vault-Session-Token') ||
                         c.req.header('Authorization')?.replace('Bearer ', '');

    if (sessionToken) {
      const valid = secretService.validateSessionToken(sessionToken);
      if (valid) {
        c.set('sessionTokenValid', true);
      }
    }

    await next();
  });

  // Global error handler
  app.onError((err, c) => {
    logger.error({ error: err.message, stack: err.stack }, 'Secret route error');

    if (err.message === 'Access denied' || err.message.includes('Access denied')) {
      return c.json({ error: 'Forbidden', message: 'Access denied' }, 403);
    }

    if (err.message.includes('Vault is locked')) {
      return c.json({ error: 'Locked', message: 'Vault is locked. Unlock it first.' }, 423);
    }

    return c.json(
      { error: 'Internal Server Error', message: 'An unexpected error occurred' },
      500
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Vault Operations
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * GET /secret/vault/status - Get vault status
   */
  app.get('/vault/status', async (c) => {
    const status = await secretService.getVaultStatus();
    return c.json(status);
  });

  /**
   * POST /secret/vault/init - Initialize vault
   */
  app.post('/vault/init', zValidator('json', initVaultSchema), async (c) => {
    const { passphrase } = c.req.valid('json');

    try {
      const result = await secretService.initVault(passphrase);
      logger.info('Vault initialized via API');
      return c.json(result, 201);
    } catch (error) {
      if (error instanceof Error && error.message.includes('already initialized')) {
        return c.json({ error: 'Conflict', message: 'Vault already initialized' }, 409);
      }
      throw error;
    }
  });

  /**
   * POST /secret/vault/unlock - Unlock vault
   */
  app.post('/vault/unlock', zValidator('json', unlockVaultSchema), async (c) => {
    const { passphrase } = c.req.valid('json');

    const success = await secretService.unlockVault(passphrase);

    if (!success) {
      return c.json({ error: 'Unauthorized', message: 'Invalid passphrase' }, 401);
    }

    logger.info('Vault unlocked via API');
    return c.json({ success: true, message: 'Vault unlocked' });
  });

  /**
   * POST /secret/vault/lock - Lock vault
   */
  app.post('/vault/lock', async (c) => {
    secretService.lockVault();
    logger.info('Vault locked via API');
    return c.json({ success: true, message: 'Vault locked' });
  });

  /**
   * POST /secret/vault/recovery/generate - Generate new recovery codes
   */
  app.post('/vault/recovery/generate', async (c) => {
    const result = await secretService.generateRecoveryCodes();
    logger.info('Recovery codes generated via API');
    return c.json(result);
  });

  /**
   * POST /secret/vault/recovery/use - Use recovery code to reset vault
   * WARNING: This will DELETE ALL SECRETS. Requires confirmDataLoss: true.
   */
  app.post('/vault/recovery/use', zValidator('json', useRecoveryCodeSchema), async (c) => {
    const { recoveryCode, newPassphrase, confirmDataLoss } = c.req.valid('json');

    // Require explicit confirmation of data loss
    if (confirmDataLoss !== true) {
      return c.json({
        error: 'Confirmation Required',
        message: 'Using a recovery code will DELETE ALL SECRETS. Set confirmDataLoss: true to proceed.',
      }, 400);
    }

    const success = await secretService.useRecoveryCode(recoveryCode, newPassphrase);

    if (!success) {
      return c.json({ error: 'Bad Request', message: 'Invalid or already used recovery code' }, 400);
    }

    logger.warn('Vault reset with recovery code - all secrets deleted');
    return c.json({ success: true, message: 'Vault reset. All previous secrets have been deleted.' });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Session Token Operations
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * POST /secret/vault/session - Generate a session token
   * Requires vault to be unlocked. Returns a token that can be used for API access.
   */
  app.post('/vault/session', async (c) => {
    const body = await c.req.json().catch(() => ({}));
    const name = body.name as string | undefined;

    try {
      const token = secretService.generateSessionToken(name);
      logger.info({ tokenName: name }, 'Session token generated via API');
      return c.json({ token, message: 'Session token generated. Use as VAULT_SESSION_TOKEN.' }, 201);
    } catch (error) {
      if (error instanceof Error && error.message.includes('Vault must be unlocked')) {
        return c.json({ error: 'Locked', message: 'Vault must be unlocked to generate session token' }, 423);
      }
      throw error;
    }
  });

  /**
   * POST /secret/vault/session/validate - Validate a session token
   */
  app.post('/vault/session/validate', async (c) => {
    const body = await c.req.json().catch(() => ({}));
    const token = body.token as string | undefined;

    if (!token) {
      return c.json({ error: 'Bad Request', message: 'Token required' }, 400);
    }

    const valid = secretService.validateSessionToken(token);
    return c.json({ valid });
  });

  /**
   * POST /secret/vault/session/revoke - Revoke a session token
   */
  app.post('/vault/session/revoke', async (c) => {
    const body = await c.req.json().catch(() => ({}));
    const token = body.token as string | undefined;

    if (!token) {
      return c.json({ error: 'Bad Request', message: 'Token required' }, 400);
    }

    const revoked = secretService.revokeSessionToken(token);
    return c.json({ revoked });
  });

  /**
   * GET /secret/vault/sessions - List active session tokens (names only)
   */
  app.get('/vault/sessions', async (c) => {
    const tokens = secretService.listSessionTokens();
    return c.json({ sessions: tokens, count: tokens.length });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Secret CRUD Operations
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * POST /secret/create - Create a new secret
   */
  app.post('/create', zValidator('json', createSecretSchema), async (c) => {
    const data = c.req.valid('json');
    const accessor = getAccessor(c);

    const secret = await secretService.createSecret(data, accessor);

    logger.info({ secretName: secret.name, accessor: `${accessor.type}:${accessor.name}` }, 'Secret created via API');
    return c.json(secret, 201);
  });

  /**
   * GET /secret/list - List secrets
   */
  app.get('/list', zValidator('query', listSecretsQuerySchema), async (c) => {
    const query = c.req.valid('query');
    const accessor = getAccessor(c);

    const result = await secretService.listSecrets(query, accessor);
    return c.json(result);
  });

  /**
   * GET /secret/get/:id - Get secret metadata (not value)
   */
  app.get('/get/:id', async (c) => {
    const id = c.req.param('id');
    const accessor = getAccessor(c);

    const secret = await secretService.getSecret(id, accessor);

    if (!secret) {
      return c.json({ error: 'Not Found', message: `Secret ${id} not found` }, 404);
    }

    return c.json(secret);
  });

  /**
   * GET /secret/fetch/:id - Fetch secret value (logged)
   */
  app.get('/fetch/:id', async (c) => {
    const id = c.req.param('id');
    const toolContext = c.req.query('tool');
    const accessor = getAccessor(c);

    const secret = await secretService.fetchSecretValue(id, accessor, toolContext);

    if (!secret) {
      return c.json({ error: 'Not Found', message: `Secret ${id} not found` }, 404);
    }

    return c.json(secret);
  });

  /**
   * POST /secret/update/:id - Update secret metadata
   */
  app.post('/update/:id', zValidator('json', updateSecretSchema), async (c) => {
    const id = c.req.param('id');
    const data = c.req.valid('json');
    const accessor = getAccessor(c);

    const secret = await secretService.updateSecret(id, data, accessor);

    if (!secret) {
      return c.json({ error: 'Not Found', message: `Secret ${id} not found` }, 404);
    }

    logger.info({ secretName: secret.name }, 'Secret updated via API');
    return c.json(secret);
  });

  /**
   * POST /secret/rotate/:id - Rotate secret value
   */
  app.post('/rotate/:id', zValidator('json', rotateSecretSchema), async (c) => {
    const id = c.req.param('id');
    const data = c.req.valid('json');
    const accessor = getAccessor(c);

    const secret = await secretService.rotateSecret(id, data, accessor);

    if (!secret) {
      return c.json({ error: 'Not Found', message: `Secret ${id} not found` }, 404);
    }

    logger.info({ secretName: secret.name }, 'Secret rotated via API');
    return c.json(secret);
  });

  /**
   * POST /secret/delete/:id - Delete a secret
   */
  app.post('/delete/:id', async (c) => {
    const id = c.req.param('id');
    const accessor = getAccessor(c);

    const deleted = await secretService.deleteSecret(id, accessor);

    if (!deleted) {
      return c.json({ error: 'Not Found', message: `Secret ${id} not found` }, 404);
    }

    logger.info({ secretId: id }, 'Secret deleted via API');
    return c.json({ success: true, message: `Secret ${id} deleted` });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Tag Operations
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * POST /secret/tag/:id - Add tag to secret
   */
  app.post('/tag/:id', zValidator('json', addTagSchema), async (c) => {
    const id = c.req.param('id');
    const data = c.req.valid('json');
    const accessor = getAccessor(c);

    const tag = await secretService.addTag(id, data, accessor);

    if (!tag) {
      return c.json({ error: 'Not Found', message: `Secret ${id} not found or tag already exists` }, 404);
    }

    logger.info({ secretId: id, tag: `${data.tagType}:${data.tagValue}` }, 'Tag added via API');
    return c.json(tag, 201);
  });

  /**
   * POST /secret/untag/:id - Remove tag from secret
   */
  app.post('/untag/:id', zValidator('json', removeTagSchema), async (c) => {
    const id = c.req.param('id');
    const data = c.req.valid('json');
    const accessor = getAccessor(c);

    const removed = await secretService.removeTag(id, data, accessor);

    if (!removed) {
      return c.json({ error: 'Not Found', message: `Secret ${id} or tag not found` }, 404);
    }

    logger.info({ secretId: id, tag: `${data.tagType}:${data.tagValue}` }, 'Tag removed via API');
    return c.json({ success: true });
  });

  /**
   * GET /secret/by-tag - Find secrets by tag
   */
  app.get('/by-tag', zValidator('query', findByTagQuerySchema), async (c) => {
    const { tagType, tagValue } = c.req.valid('query');
    const accessor = getAccessor(c);

    const secrets = await secretService.findByTag(tagType, tagValue, accessor);

    return c.json({ secrets, count: secrets.length });
  });

  /**
   * GET /secret/tags/:id - Get tags for a secret
   */
  app.get('/tags/:id', async (c) => {
    const id = c.req.param('id');
    const accessor = getAccessor(c);

    const tags = await secretService.getTags(id, accessor);

    return c.json({ tags, count: tags.length });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Grant Operations
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * POST /secret/grant/:id - Grant access to a secret
   */
  app.post('/grant/:id', zValidator('json', grantAccessSchema), async (c) => {
    const id = c.req.param('id');
    const data = c.req.valid('json');
    const accessor = getAccessor(c);

    const grant = await secretService.grantAccess(id, data, accessor);

    if (!grant) {
      return c.json({ error: 'Not Found', message: `Secret ${id} not found` }, 404);
    }

    logger.info({ secretId: id, grantee: `${data.granteeType}:${data.granteeName}` }, 'Access granted via API');
    return c.json(grant, 201);
  });

  /**
   * POST /secret/revoke/:id - Revoke access to a secret
   */
  app.post('/revoke/:id', zValidator('json', revokeAccessSchema), async (c) => {
    const id = c.req.param('id');
    const data = c.req.valid('json');
    const accessor = getAccessor(c);

    const revoked = await secretService.revokeAccess(id, data, accessor);

    if (!revoked) {
      return c.json({ error: 'Not Found', message: `Secret ${id} or grant not found` }, 404);
    }

    logger.info({ secretId: id, grantee: `${data.granteeType}:${data.granteeName}` }, 'Access revoked via API');
    return c.json({ success: true });
  });

  /**
   * GET /secret/grants/:id - List grants for a secret
   */
  app.get('/grants/:id', async (c) => {
    const id = c.req.param('id');
    const accessor = getAccessor(c);

    const grants = await secretService.getGrants(id, accessor);

    return c.json({ grants, count: grants.length });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Audit Operations
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * GET /secret/audit/:id - Get audit logs for a specific secret
   */
  app.get('/audit/:id', async (c) => {
    const id = c.req.param('id');
    const accessor = getAccessor(c);

    const logs = await secretService.getSecretAuditLogs(id, accessor);

    return c.json({ logs, count: logs.length });
  });

  /**
   * GET /secret/audit - Get all audit logs
   */
  app.get('/audit', zValidator('query', listAuditLogsQuerySchema), async (c) => {
    const query = c.req.valid('query');
    const accessor = getAccessor(c);

    const result = await secretService.getAuditLogs(query, accessor);

    return c.json(result);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Stats
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * GET /secret/stats - Get secret statistics
   */
  app.get('/stats', async (c) => {
    const stats = await secretService.getStats();
    return c.json(stats);
  });

  return app;
}
