/**
 * Idea Routes Tests
 *
 * Integration tests for idea API endpoints.
 * Uses explicit operation names.
 */

import { describe, test, expect, beforeAll, afterAll } from 'bun:test';
import { Hono } from 'hono';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { createIdeaService } from '../../src/embedded/idea-service';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Idea Routes', () => {
  let app: Hono;
  let db: DatabaseAdapter;
  const testDbPath = '/tmp/agency-test-idea-routes';
  const testDbFile = `${testDbPath}/ideas.db`;

  beforeAll(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'ideas.db',
    });
    await db.initialize();

    const ideaService = createIdeaService({ db });
    await ideaService.initialize();

    app = new Hono();
    // Use local auth (pass-through)
    app.use('*', async (c, next) => {
      c.set('user', { id: 'test', type: 'agent', name: 'test-agent' });
      await next();
    });
    app.route('/api/idea', ideaService.routes);
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

  describe('POST /api/idea/create', () => {
    test('should create idea', async () => {
      const res = await app.request('/api/idea/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Idea from API test',
          sourceType: 'agent',
          sourceName: 'test-agent',
          tags: ['test'],
        }),
      });

      expect(res.status).toBe(201);
      const idea = await res.json();
      expect(idea.ideaId).toBe('IDEA-00001');
      expect(idea.title).toBe('Idea from API test');
      expect(idea.status).toBe('captured');
    });

    test('should return 400 for missing required fields', async () => {
      const res = await app.request('/api/idea/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          // missing title
          sourceType: 'agent',
          sourceName: 'test',
        }),
      });

      expect(res.status).toBe(400);
    });

    test('should return 400 for invalid tag format', async () => {
      const res = await app.request('/api/idea/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Invalid tags',
          sourceType: 'agent',
          sourceName: 'test',
          tags: ['valid', 'invalid tag with spaces'],
        }),
      });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/idea/list', () => {
    test('should list ideas', async () => {
      const res = await app.request('/api/idea/list');

      expect(res.status).toBe(200);
      const result = await res.json();
      expect(result.ideas).toBeDefined();
      expect(Array.isArray(result.ideas)).toBe(true);
      expect(result.total).toBeGreaterThanOrEqual(1);
    });

    test('should filter by status', async () => {
      const res = await app.request('/api/idea/list?status=captured');
      expect(res.status).toBe(200);

      const result = await res.json();
      expect(result.ideas.every((i: any) => i.status === 'captured')).toBe(true);
    });

    test('should return 400 for invalid status', async () => {
      const res = await app.request('/api/idea/list?status=invalid');
      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/idea/stats', () => {
    test('should return statistics', async () => {
      const res = await app.request('/api/idea/stats');

      expect(res.status).toBe(200);
      const stats = await res.json();
      expect(typeof stats.total).toBe('number');
      expect(typeof stats.captured).toBe('number');
      expect(typeof stats.exploring).toBe('number');
      expect(typeof stats.promoted).toBe('number');
      expect(typeof stats.parked).toBe('number');
      expect(typeof stats.discarded).toBe('number');
    });
  });

  describe('GET /api/idea/get/:ideaId', () => {
    test('should get specific idea', async () => {
      // Create an idea first
      const createRes = await app.request('/api/idea/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Get test idea',
          sourceType: 'agent',
          sourceName: 'test',
          tags: [],
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/idea/get/${created.ideaId}`);
      expect(res.status).toBe(200);

      const idea = await res.json();
      expect(idea.ideaId).toBe(created.ideaId);
    });

    test('should return 404 for non-existent idea', async () => {
      const res = await app.request('/api/idea/get/IDEA-99999');
      expect(res.status).toBe(404);
    });

    test('should return 400 for invalid idea ID format', async () => {
      const res = await app.request('/api/idea/get/INVALID-FORMAT');
      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/idea/update/:ideaId', () => {
    test('should update idea', async () => {
      // Create an idea first
      const createRes = await app.request('/api/idea/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Original title',
          sourceType: 'agent',
          sourceName: 'test',
          tags: [],
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/idea/update/${created.ideaId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Updated title',
          description: 'Added description',
        }),
      });

      expect(res.status).toBe(200);
      const updated = await res.json();
      expect(updated.title).toBe('Updated title');
      expect(updated.description).toBe('Added description');
    });

    test('should return 400 for invalid idea ID format', async () => {
      const res = await app.request('/api/idea/update/INVALID-ID', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: 'Test' }),
      });
      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/idea/promote/:ideaId', () => {
    test('should promote idea', async () => {
      // Create an idea first
      const createRes = await app.request('/api/idea/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Promotable idea',
          sourceType: 'agent',
          sourceName: 'test',
          tags: [],
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/idea/promote/${created.ideaId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ requestId: 'REQUEST-jordan-0030' }),
      });

      expect(res.status).toBe(200);
      const promoted = await res.json();
      expect(promoted.status).toBe('promoted');
      expect(promoted.promotedTo).toBe('REQUEST-jordan-0030');
    });

    test('should return 400 for invalid idea ID format', async () => {
      const res = await app.request('/api/idea/promote/BAD-ID', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ requestId: 'REQUEST-001' }),
      });
      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/idea/explore/:ideaId', () => {
    test('should explore idea', async () => {
      // Create an idea first
      const createRes = await app.request('/api/idea/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Explorable idea',
          sourceType: 'agent',
          sourceName: 'test',
          tags: [],
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/idea/explore/${created.ideaId}`, {
        method: 'POST',
      });

      expect(res.status).toBe(200);
      const explored = await res.json();
      expect(explored.status).toBe('exploring');
    });
  });

  describe('POST /api/idea/park/:ideaId', () => {
    test('should park idea', async () => {
      const createRes = await app.request('/api/idea/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Parkable idea',
          sourceType: 'agent',
          sourceName: 'test',
          tags: [],
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/idea/park/${created.ideaId}`, {
        method: 'POST',
      });

      expect(res.status).toBe(200);
      const parked = await res.json();
      expect(parked.status).toBe('parked');
    });
  });

  describe('POST /api/idea/discard/:ideaId', () => {
    test('should discard idea', async () => {
      const createRes = await app.request('/api/idea/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Discardable idea',
          sourceType: 'agent',
          sourceName: 'test',
          tags: [],
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/idea/discard/${created.ideaId}`, {
        method: 'POST',
      });

      expect(res.status).toBe(200);
      const discarded = await res.json();
      expect(discarded.status).toBe('discarded');
    });
  });

  describe('POST /api/idea/add-tags/:ideaId', () => {
    test('should add tags to idea', async () => {
      const createRes = await app.request('/api/idea/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Tagged idea',
          sourceType: 'agent',
          sourceName: 'test',
          tags: ['original'],
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/idea/add-tags/${created.ideaId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tags: ['new-tag'] }),
      });

      expect(res.status).toBe(200);
      const updated = await res.json();
      expect(updated.tags).toContain('original');
      expect(updated.tags).toContain('new-tag');
    });
  });

  describe('POST /api/idea/remove-tags/:ideaId', () => {
    test('should remove tags from idea', async () => {
      const createRes = await app.request('/api/idea/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Tagged idea',
          sourceType: 'agent',
          sourceName: 'test',
          tags: ['keep', 'remove'],
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/idea/remove-tags/${created.ideaId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tags: ['remove'] }),
      });

      expect(res.status).toBe(200);
      const updated = await res.json();
      expect(updated.tags).toEqual(['keep']);
    });
  });

  describe('POST /api/idea/delete/:ideaId', () => {
    test('should delete idea', async () => {
      // Create an idea first
      const createRes = await app.request('/api/idea/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Delete test idea',
          sourceType: 'agent',
          sourceName: 'test',
          tags: [],
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/api/idea/delete/${created.ideaId}`, {
        method: 'POST',
      });

      expect(res.status).toBe(200);

      // Verify it's gone
      const getRes = await app.request(`/api/idea/get/${created.ideaId}`);
      expect(getRes.status).toBe(404);
    });

    test('should return 400 for invalid idea ID format', async () => {
      const res = await app.request('/api/idea/delete/WRONG-FORMAT', {
        method: 'POST',
      });
      expect(res.status).toBe(400);
    });

    test('should return 404 for non-existent idea', async () => {
      const res = await app.request('/api/idea/delete/IDEA-99999', {
        method: 'POST',
      });
      expect(res.status).toBe(404);
    });
  });
});
