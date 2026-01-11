/**
 * Observation Routes Tests
 *
 * Tests for observation HTTP API endpoints.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { Hono } from 'hono';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { createObservationService } from '../../src/embedded/observation-service';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Observation Routes', () => {
  let db: DatabaseAdapter;
  let app: Hono;
  const testDbPath = '/tmp/agency-test-observation-routes';
  const testDbFile = `${testDbPath}/observations.db`;

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'observations.db',
    });
    await db.initialize();

    const observationService = createObservationService({ db });
    await observationService.initialize();

    app = new Hono();
    app.route('/observation', observationService.routes);
  });

  afterEach(async () => {
    await db.close();
    try {
      if (existsSync(testDbFile)) await unlink(testDbFile);
      if (existsSync(`${testDbFile}-wal`)) await unlink(`${testDbFile}-wal`);
      if (existsSync(`${testDbFile}-shm`)) await unlink(`${testDbFile}-shm`);
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  describe('POST /observation/create', () => {
    test('should create a new observation', async () => {
      const res = await app.request('/observation/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'New observation',
          summary: 'Found something interesting',
          reporterType: 'agent',
          reporterName: 'housekeeping',
        }),
      });

      expect(res.status).toBe(201);
      const data = await res.json();
      expect(data.observationId).toMatch(/^OBS-\d{4}$/);
      expect(data.title).toBe('New observation');
      expect(data.status).toBe('Open');
    });

    test('should return 400 for missing required fields', async () => {
      const res = await app.request('/observation/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Missing summary',
          // summary missing
          reporterType: 'agent',
          reporterName: 'housekeeping',
        }),
      });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /observation/list', () => {
    beforeEach(async () => {
      await app.request('/observation/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Observation 1',
          summary: 'First observation',
          category: 'insight',
          reporterType: 'agent',
          reporterName: 'agent1',
        }),
      });

      await app.request('/observation/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Observation 2',
          summary: 'Second observation',
          category: 'concern',
          reporterType: 'agent',
          reporterName: 'agent2',
        }),
      });
    });

    test('should list all observations', async () => {
      const res = await app.request('/observation/list');
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.total).toBe(2);
      expect(data.observations.length).toBe(2);
    });

    test('should filter by category', async () => {
      const res = await app.request('/observation/list?category=concern');
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.total).toBe(1);
      expect(data.observations[0].category).toBe('concern');
    });

    test('should sort by title', async () => {
      const res = await app.request('/observation/list?sortBy=title&sortOrder=asc');
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.observations[0].title).toBe('Observation 1');
    });

    test('should search in title', async () => {
      const res = await app.request('/observation/list?search=First');
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.total).toBe(1);
      expect(data.observations[0].summary).toContain('First');
    });
  });

  describe('GET /observation/get/:observationId', () => {
    test('should get observation by ID', async () => {
      const createRes = await app.request('/observation/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Findable',
          summary: 'Can be found',
          reporterType: 'agent',
          reporterName: 'housekeeping',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/observation/get/${created.observationId}`);
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.title).toBe('Findable');
    });

    test('should return 404 for non-existent', async () => {
      const res = await app.request('/observation/get/OBS-9999');
      expect(res.status).toBe(404);
    });
  });

  describe('POST /observation/update/:observationId', () => {
    test('should update observation', async () => {
      const createRes = await app.request('/observation/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Original',
          summary: 'Will be updated',
          reporterType: 'agent',
          reporterName: 'housekeeping',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/observation/update/${created.observationId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Updated',
          category: 'concern',
        }),
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.title).toBe('Updated');
      expect(data.category).toBe('concern');
    });

    test('should return 404 for non-existent', async () => {
      const res = await app.request('/observation/update/OBS-9999', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: 'Updated' }),
      });
      expect(res.status).toBe(404);
    });
  });

  describe('POST /observation/update-status/:observationId', () => {
    test('should update status', async () => {
      const createRes = await app.request('/observation/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Status test',
          summary: 'Status will change',
          reporterType: 'agent',
          reporterName: 'housekeeping',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/observation/update-status/${created.observationId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'Acknowledged' }),
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.status).toBe('Acknowledged');
    });

    test('should return 404 for non-existent', async () => {
      const res = await app.request('/observation/update-status/OBS-9999', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'Archived' }),
      });
      expect(res.status).toBe(404);
    });
  });

  describe('POST /observation/acknowledge/:observationId', () => {
    test('should acknowledge observation', async () => {
      const createRes = await app.request('/observation/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'To acknowledge',
          summary: 'Needs acknowledgment',
          reporterType: 'agent',
          reporterName: 'housekeeping',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/observation/acknowledge/${created.observationId}`, {
        method: 'POST',
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.status).toBe('Acknowledged');
    });

    test('should return 404 for non-existent', async () => {
      const res = await app.request('/observation/acknowledge/OBS-9999', {
        method: 'POST',
      });
      expect(res.status).toBe(404);
    });
  });

  describe('POST /observation/archive/:observationId', () => {
    test('should archive observation', async () => {
      const createRes = await app.request('/observation/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'To archive',
          summary: 'Needs archiving',
          reporterType: 'agent',
          reporterName: 'housekeeping',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/observation/archive/${created.observationId}`, {
        method: 'POST',
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.status).toBe('Archived');
    });

    test('should return 404 for non-existent', async () => {
      const res = await app.request('/observation/archive/OBS-9999', {
        method: 'POST',
      });
      expect(res.status).toBe(404);
    });
  });

  describe('POST /observation/delete/:observationId', () => {
    test('should delete observation', async () => {
      const createRes = await app.request('/observation/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Delete me',
          summary: 'Will be removed',
          reporterType: 'agent',
          reporterName: 'housekeeping',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/observation/delete/${created.observationId}`, {
        method: 'POST',
      });

      expect(res.status).toBe(200);

      const getRes = await app.request(`/observation/get/${created.observationId}`);
      expect(getRes.status).toBe(404);
    });

    test('should return 404 for non-existent', async () => {
      const res = await app.request('/observation/delete/OBS-9999', {
        method: 'POST',
      });
      expect(res.status).toBe(404);
    });
  });

  describe('GET /observation/stats', () => {
    test('should return statistics', async () => {
      await app.request('/observation/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Observation 1',
          summary: 'Test',
          category: 'concern',
          reporterType: 'agent',
          reporterName: 'housekeeping',
        }),
      });

      const res = await app.request('/observation/stats');
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.total).toBe(1);
      expect(data.open).toBe(1);
      expect(data.byCategory.concern).toBe(1);
    });
  });
});
