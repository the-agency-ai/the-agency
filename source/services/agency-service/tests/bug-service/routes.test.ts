/**
 * Bug Routes Tests
 *
 * Integration tests for bug API endpoints.
 * Uses explicit operation names.
 */

import { describe, test, expect, beforeAll, afterAll } from 'bun:test';
import { Hono } from 'hono';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { createBugService } from '../../src/embedded/bug-service';
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

  describe('POST /api/bug/create', () => {
    test('should create bug', async () => {
      const res = await app.request('/api/bug/create', {
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
      const res = await app.request('/api/bug/create', {
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

  describe('GET /api/bug/list', () => {
    test('should list bugs', async () => {
      const res = await app.request('/api/bug/list');

      expect(res.status).toBe(200);
      const result = await res.json();
      expect(result.bugs).toBeDefined();
      expect(Array.isArray(result.bugs)).toBe(true);
      expect(result.total).toBeGreaterThanOrEqual(1);
    });

    test('should filter by workstream', async () => {
      // Create a bug in a specific workstream
      await app.request('/api/bug/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'filter-test',
          summary: 'Filter test bug',
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });

      const res = await app.request('/api/bug/list?workstream=FILTER-TEST');
      expect(res.status).toBe(200);

      const result = await res.json();
      expect(result.bugs.every((b: any) => b.workstream === 'FILTER-TEST')).toBe(true);
    });

    test('should sort by summary ascending', async () => {
      // Create bugs with different summaries
      await app.request('/api/bug/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'sort-test',
          summary: 'Zebra bug',
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });
      await app.request('/api/bug/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'sort-test',
          summary: 'Apple bug',
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });

      const res = await app.request('/api/bug/list?workstream=sort-test&sortBy=summary&sortOrder=asc');
      expect(res.status).toBe(200);

      const result = await res.json();
      expect(result.bugs[0].summary).toBe('Apple bug');
    });

    test('should search in summary', async () => {
      await app.request('/api/bug/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'search-test',
          summary: 'Critical authentication bug',
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });

      const res = await app.request('/api/bug/list?workstream=search-test&search=authentication');
      expect(res.status).toBe(200);

      const result = await res.json();
      expect(result.bugs.length).toBe(1);
      expect(result.bugs[0].summary).toContain('authentication');
    });

    test('should filter by tags', async () => {
      await app.request('/api/bug/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'tags-route-test',
          summary: 'Tagged bug',
          reporterType: 'agent',
          reporterName: 'test',
          tags: ['frontend', 'urgent'],
        }),
      });

      const res = await app.request('/api/bug/list?workstream=tags-route-test&tags=frontend');
      expect(res.status).toBe(200);

      const result = await res.json();
      expect(result.bugs.length).toBe(1);
      expect(result.bugs[0].tags).toContain('frontend');
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

  describe('GET /api/bug/get/:bugId', () => {
    test('should get specific bug', async () => {
      // Create a bug first
      const createRes = await app.request('/api/bug/create', {
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

      const res = await app.request(`/api/bug/get/${created.bugId}`);
      expect(res.status).toBe(200);

      const bug = await res.json();
      expect(bug.bugId).toBe(created.bugId);
    });

    test('should return 404 for non-existent bug', async () => {
      const res = await app.request('/api/bug/get/FAKE-99999');
      expect(res.status).toBe(404);
    });
  });

  describe('POST /api/bug/update/:bugId', () => {
    test('should update bug', async () => {
      // Create a bug first
      const createRes = await app.request('/api/bug/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          workstream: 'update-test',
          summary: 'Original summary',
          reporterType: 'agent',
          reporterName: 'test',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/bug/update/${created.bugId}`, {
        method: 'POST',
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

  describe('POST /api/bug/update-status/:bugId', () => {
    test('should update status', async () => {
      // Create a bug first
      const createRes = await app.request('/api/bug/create', {
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

      const res = await app.request(`/api/bug/update-status/${created.bugId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'Fixed' }),
      });

      expect(res.status).toBe(200);
      const updated = await res.json();
      expect(updated.status).toBe('Fixed');
    });

    test('should return 400 for invalid status', async () => {
      const createRes = await app.request('/api/bug/create', {
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

      const res = await app.request(`/api/bug/update-status/${created.bugId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'InvalidStatus' }),
      });

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/bug/assign/:bugId', () => {
    test('should assign bug', async () => {
      // Create a bug first
      const createRes = await app.request('/api/bug/create', {
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

      const res = await app.request(`/api/bug/assign/${created.bugId}`, {
        method: 'POST',
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

  describe('POST /api/bug/delete/:bugId', () => {
    test('should delete bug', async () => {
      // Create a bug first
      const createRes = await app.request('/api/bug/create', {
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

      const res = await app.request(`/api/bug/delete/${created.bugId}`, {
        method: 'POST',
      });

      expect(res.status).toBe(200);

      // Verify it's gone
      const getRes = await app.request(`/api/bug/get/${created.bugId}`);
      expect(getRes.status).toBe(404);
    });
  });
});
