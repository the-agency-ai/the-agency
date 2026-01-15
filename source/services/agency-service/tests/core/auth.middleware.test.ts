/**
 * Auth Middleware Tests
 *
 * Tests for authentication middleware (local and JWT modes).
 * Security-focused tests for auth bypass and token validation.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { Hono } from 'hono';
import { authMiddleware, optionalAuth, requireType } from '../../src/core/middleware/auth.middleware';
import { resetConfig } from '../../src/core/config';

describe('Auth Middleware', () => {
  let app: Hono;

  beforeEach(() => {
    resetConfig();
    app = new Hono();
  });

  afterEach(() => {
    resetConfig();
    // Cleanup env vars
    delete process.env.AGENCY_AUTH_MODE;
    delete process.env.JWT_SECRET;
  });

  describe('Local Mode', () => {
    beforeEach(() => {
      process.env.AGENCY_AUTH_MODE = 'local';
      resetConfig();
      app.use('*', authMiddleware());
      app.get('/test', (c) => c.json({ user: c.get('user') }));
    });

    test('should pass with default user when no header', async () => {
      const res = await app.request('/test');
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.user.type).toBe('principal');
      expect(data.user.name).toBe('local');
    });

    test('should parse X-Agency-User header', async () => {
      const res = await app.request('/test', {
        headers: { 'X-Agency-User': 'agent:housekeeping' },
      });
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.user.type).toBe('agent');
      expect(data.user.name).toBe('housekeeping');
    });

    test('should handle principal type', async () => {
      const res = await app.request('/test', {
        headers: { 'X-Agency-User': 'principal:jordan' },
      });
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.user.type).toBe('principal');
      expect(data.user.name).toBe('jordan');
    });

    test('should handle system type', async () => {
      const res = await app.request('/test', {
        headers: { 'X-Agency-User': 'system:cron' },
      });
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.user.type).toBe('system');
      expect(data.user.name).toBe('cron');
    });

    test('should default invalid type to agent', async () => {
      const res = await app.request('/test', {
        headers: { 'X-Agency-User': 'admin:superuser' },
      });
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.user.type).toBe('agent'); // Invalid 'admin' defaults to 'agent'
      expect(data.user.name).toBe('superuser');
    });

    test('should handle missing name in header', async () => {
      const res = await app.request('/test', {
        headers: { 'X-Agency-User': 'agent:' },
      });
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.user.name).toBe('unknown');
    });

    test('should handle malformed header (no colon)', async () => {
      const res = await app.request('/test', {
        headers: { 'X-Agency-User': 'agentonly' },
      });
      expect(res.status).toBe(200);
      // Should default type to agent, name to undefined which becomes 'unknown'
    });
  });

  describe('JWT Mode', () => {
    beforeEach(() => {
      process.env.AGENCY_AUTH_MODE = 'jwt';
      process.env.JWT_SECRET = 'test-secret-for-testing';
      resetConfig();
      app.use('*', authMiddleware());
      app.get('/test', (c) => c.json({ user: c.get('user') }));
    });

    // Helper to create a fake JWT (not signed, just encoded)
    function createFakeJwt(payload: Record<string, unknown>): string {
      const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
        .replace(/=/g, '')
        .replace(/\+/g, '-')
        .replace(/\//g, '_');
      const body = btoa(JSON.stringify(payload))
        .replace(/=/g, '')
        .replace(/\+/g, '-')
        .replace(/\//g, '_');
      // Fake signature
      const sig = btoa('fake-signature')
        .replace(/=/g, '')
        .replace(/\+/g, '-')
        .replace(/\//g, '_');
      return `${header}.${body}.${sig}`;
    }

    test('should reject request without Authorization header', async () => {
      const res = await app.request('/test');
      expect(res.status).toBe(401);
      const data = await res.json();
      expect(data.error).toBe('Unauthorized');
      expect(data.message).toContain('Missing Bearer token');
    });

    test('should reject request with invalid Authorization format', async () => {
      const res = await app.request('/test', {
        headers: { Authorization: 'Basic abc123' },
      });
      expect(res.status).toBe(401);
    });

    test('should reject JWT with missing sub claim', async () => {
      const token = createFakeJwt({ type: 'agent', name: 'test' });
      const res = await app.request('/test', {
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.status).toBe(401);
      const data = await res.json();
      expect(data.message).toContain('Invalid token claims');
    });

    test('should reject JWT with missing type claim', async () => {
      const token = createFakeJwt({ sub: 'user-123', name: 'test' });
      const res = await app.request('/test', {
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.status).toBe(401);
    });

    test('should reject JWT with missing name claim', async () => {
      const token = createFakeJwt({ sub: 'user-123', type: 'agent' });
      const res = await app.request('/test', {
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.status).toBe(401);
    });

    test('should reject JWT with invalid type value', async () => {
      const token = createFakeJwt({ sub: 'user-123', type: 'admin', name: 'test' });
      const res = await app.request('/test', {
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.status).toBe(401);
    });

    test('should accept valid JWT with all required claims', async () => {
      const token = createFakeJwt({ sub: 'user-123', type: 'agent', name: 'housekeeping' });
      const res = await app.request('/test', {
        headers: { Authorization: `Bearer ${token}` },
      });
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.user.id).toBe('user-123');
      expect(data.user.type).toBe('agent');
      expect(data.user.name).toBe('housekeeping');
    });

    test('should reject malformed JWT (not 3 parts)', async () => {
      const res = await app.request('/test', {
        headers: { Authorization: 'Bearer not.a.valid.jwt.token' },
      });
      expect(res.status).toBe(401);
    });

    test('should reject JWT with invalid base64 payload', async () => {
      const res = await app.request('/test', {
        headers: { Authorization: 'Bearer header.!!!invalid!!!.signature' },
      });
      expect(res.status).toBe(401);
    });
  });

  describe('Optional Auth', () => {
    beforeEach(() => {
      process.env.AGENCY_AUTH_MODE = 'local';
      resetConfig();
      app.use('*', optionalAuth());
      app.get('/test', (c) => {
        const user = c.get('user');
        return c.json({ hasUser: !!user, user });
      });
    });

    test('should proceed without user when no auth headers', async () => {
      const res = await app.request('/test');
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.hasUser).toBe(false);
    });

    test('should set user when X-Agency-User header present', async () => {
      const res = await app.request('/test', {
        headers: { 'X-Agency-User': 'agent:captain' },
      });
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.hasUser).toBe(true);
      expect(data.user.type).toBe('agent');
    });
  });

  describe('Require Type', () => {
    beforeEach(() => {
      process.env.AGENCY_AUTH_MODE = 'local';
      resetConfig();
      app.use('*', authMiddleware());
      app.get('/agents-only', requireType('agent'), (c) => c.json({ ok: true }));
      app.get('/principals-only', requireType('principal'), (c) => c.json({ ok: true }));
      app.get('/agents-or-principals', requireType('agent', 'principal'), (c) => c.json({ ok: true }));
    });

    test('should allow matching type', async () => {
      const res = await app.request('/agents-only', {
        headers: { 'X-Agency-User': 'agent:housekeeping' },
      });
      expect(res.status).toBe(200);
    });

    test('should reject non-matching type', async () => {
      const res = await app.request('/agents-only', {
        headers: { 'X-Agency-User': 'principal:jordan' },
      });
      expect(res.status).toBe(403);
      const data = await res.json();
      expect(data.error).toBe('Forbidden');
    });

    test('should allow any of multiple types', async () => {
      const res1 = await app.request('/agents-or-principals', {
        headers: { 'X-Agency-User': 'agent:housekeeping' },
      });
      expect(res1.status).toBe(200);

      const res2 = await app.request('/agents-or-principals', {
        headers: { 'X-Agency-User': 'principal:jordan' },
      });
      expect(res2.status).toBe(200);
    });

    test('should reject system when only agents and principals allowed', async () => {
      const res = await app.request('/agents-or-principals', {
        headers: { 'X-Agency-User': 'system:cron' },
      });
      expect(res.status).toBe(403);
    });
  });
});
