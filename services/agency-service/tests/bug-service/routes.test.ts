/**
 * Bug Routes Tests
 *
 * Integration tests for bug API endpoints.
 */

import { describe, test, expect, beforeAll, afterAll } from 'bun:test';
import { Hono } from 'hono';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { createBugService } from '../../src/embedded/bug-service';
import { authMiddleware } from '../../src/core/middleware';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Bug Routes', () => {
  let app: Hono;
  let db: DatabaseAdapter;
  const testDbPath = '/tmp/agency-test-bug-routes';
  const testDbFile = `${testDbPath}/bugs.db`;

  beforeAll(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'bugs.db',
    });
    await db.initialize();

    const bugService = createBugService({ db });
    await bugService.initialize();

    app = new Hono();
    // Use local auth (pass-through)
    app.use('*', async (c, next) => {
      c.set('user', { id: 'test', type: 'agent', name: 'test-agent' });
      await next();
    });
    app.route('/api/bug', bugService.routes);
  });

  afterAll(async () => {
    await db.close();
    try {
      if (existsSync(testDbFile)) await unlink(testDbFile);
      if (existsSync(`${testDbFile}-wal`)) await unlink(`${testDbFile}-wal`);
      if (existsSync(`${testDbFile}-shm`)) await unlink(`${testDbFile}-shm`);
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  describe('POST /api/bug', () => {
    test('should create bug', async () => {
      const res = await app.request('/api/bug', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'routes',
          summary: 'Bug from API test',
          reporterType: 'agent',
          reporterName: 'test-agent',
        }),
      });

      expect(res.status).toBe(201);
      const bug = await res.json();
      expect(bug.bugId).toBe('ROUTES-00001');
      expect(bug.summary).toBe('Bug from API test');
    });

    test('should return 400 for missing required fields', async () => {
      const res = await app.request('/api/bug', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'routes',
          // missing summary
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/bug', () => {
    test('should list bugs', async () => {
      const res = await app.request('/api/bug');

      expect(res.status).toBe(200);
      const result = await res.json();
      expect(result.bugs).toBeDefined();
      expect(Array.isArray(result.bugs)).toBe(true);
      expect(result.total).toBeGreaterThanOrEqual(1);
    });

    test('should filter by workstream', async () => {
      // Create a bug in a specific workstream
      await app.request('/api/bug', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'filter-test',
          summary: 'Filter test bug',
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });

      const res = await app.request('/api/bug?workstream=FILTER-TEST');
      expect(res.status).toBe(200);

      const result = await res.json();
      expect(result.bugs.every((b: any) => b.workstream === 'FILTER-TEST')).toBe(true);
    });
  });

  describe('GET /api/bug/stats', () => {
    test('should return statistics', async () => {
      const res = await app.request('/api/bug/stats');

      expect(res.status).toBe(200);
      const stats = await res.json();
      expect(typeof stats.total).toBe('number');
      expect(typeof stats.open).toBe('number');
      expect(typeof stats.inProgress).toBe('number');
      expect(typeof stats.fixed).toBe('number');
    });
  });

  describe('GET /api/bug/:bugId', () => {
    test('should get specific bug', async () => {
      // Create a bug first
      const createRes = await app.request('/api/bug', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'get-test',
          summary: 'Get test bug',
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/bug/${created.bugId}`);
      expect(res.status).toBe(200);

      const bug = await res.json();
      expect(bug.bugId).toBe(created.bugId);
    });

    test('should return 404 for non-existent bug', async () => {
      const res = await app.request('/api/bug/FAKE-99999');
      expect(res.status).toBe(404);
    });
  });

  describe('PATCH /api/bug/:bugId', () => {
    test('should update bug', async () => {
      // Create a bug first
      const createRes = await app.request('/api/bug', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'patch-test',
          summary: 'Original summary',
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/bug/${created.bugId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          summary: 'Updated summary',
          status: 'In Progress',
        }),
      });

      expect(res.status).toBe(200);
      const updated = await res.json();
      expect(updated.summary).toBe('Updated summary');
      expect(updated.status).toBe('In Progress');
    });
  });

  describe('PATCH /api/bug/:bugId/status', () => {
    test('should update status', async () => {
      // Create a bug first
      const createRes = await app.request('/api/bug', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'status-test',
          summary: 'Status test bug',
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/bug/${created.bugId}/status`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'Fixed' }),
      });

      expect(res.status).toBe(200);
      const updated = await res.json();
      expect(updated.status).toBe('Fixed');
    });

    test('should return 400 for invalid status', async () => {
      const createRes = await app.request('/api/bug', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'invalid-status',
          summary: 'Invalid status test',
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/bug/${created.bugId}/status`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'InvalidStatus' }),
      });

      expect(res.status).toBe(400);
    });
  });

  describe('PATCH /api/bug/:bugId/assign', () => {
    test('should assign bug', async () => {
      // Create a bug first
      const createRes = await app.request('/api/bug', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'assign-test',
          summary: 'Assign test bug',
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/bug/${created.bugId}/assign`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          assigneeName: 'housekeeping',
          assigneeType: 'agent',
        }),
      });

      expect(res.status).toBe(200);
      const updated = await res.json();
      expect(updated.assigneeName).toBe('housekeeping');
    });
  });

  describe('DELETE /api/bug/:bugId', () => {
    test('should delete bug', async () => {
      // Create a bug first
      const createRes = await app.request('/api/bug', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'delete-test',
          summary: 'Delete test bug',
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/bug/${created.bugId}`, {
        method: 'DELETE',
      });

      expect(res.status).toBe(200);

      // Verify it's gone
      const getRes = await app.request(`/api/bug/${created.bugId}`);
      expect(getRes.status).toBe(404);
    });
  });
});
