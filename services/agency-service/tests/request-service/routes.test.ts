/**
 * Request Routes Tests
 *
 * Tests for request HTTP API endpoints.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { Hono } from 'hono';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { createRequestService } from '../../src/embedded/request-service';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Request Routes', () => {
  let db: DatabaseAdapter;
  let app: Hono;
  const testDbPath = '/tmp/agency-test-request-routes';
  const testDbFile = `${testDbPath}/requests.db`;

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'requests.db',
    });
    await db.initialize();

    const requestService = createRequestService({ db });
    await requestService.initialize();

    app = new Hono();
    app.route('/request', requestService.routes);
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

  describe('POST /request/create', () => {
    test('should create a new request', async () => {
      const res = await app.request('/request/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'New feature',
          summary: 'Add this feature please',
          principalName: 'jordan',
          reporterType: 'principal',
          reporterName: 'jordan',
        }),
      });

      expect(res.status).toBe(201);
      const data = await res.json();
      expect(data.requestId).toMatch(/^REQUEST-jordan-\d{4}$/);
      expect(data.title).toBe('New feature');
      expect(data.status).toBe('Open');
    });

    test('should return 400 for missing required fields', async () => {
      const res = await app.request('/request/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Missing summary',
          // summary missing
          principalName: 'jordan',
          reporterType: 'principal',
          reporterName: 'jordan',
        }),
      });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /request/list', () => {
    beforeEach(async () => {
      // Create test requests
      await app.request('/request/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Request 1',
          summary: 'First request',
          principalName: 'alice',
          reporterType: 'principal',
          reporterName: 'alice',
        }),
      });

      await app.request('/request/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Request 2',
          summary: 'Second request',
          principalName: 'bob',
          reporterType: 'principal',
          reporterName: 'bob',
        }),
      });
    });

    test('should list all requests', async () => {
      const res = await app.request('/request/list');
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.total).toBe(2);
      expect(data.requests.length).toBe(2);
    });

    test('should filter by principal', async () => {
      const res = await app.request('/request/list?principal=alice');
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.total).toBe(1);
      expect(data.requests[0].principalName).toBe('alice');
    });

    test('should sort by title', async () => {
      const res = await app.request('/request/list?sortBy=title&sortOrder=asc');
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.requests[0].title).toBe('Request 1');
    });

    test('should search in title', async () => {
      const res = await app.request('/request/list?search=First');
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.total).toBe(1);
      expect(data.requests[0].summary).toContain('First');
    });
  });

  describe('GET /request/get/:requestId', () => {
    test('should get request by ID', async () => {
      // Create a request first
      const createRes = await app.request('/request/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Findable',
          summary: 'Can be found',
          principalName: 'jordan',
          reporterType: 'principal',
          reporterName: 'jordan',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/request/get/${created.requestId}`);
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.title).toBe('Findable');
    });

    test('should return 404 for non-existent', async () => {
      const res = await app.request('/request/get/REQUEST-fake-9999');
      expect(res.status).toBe(404);
    });
  });

  describe('POST /request/update/:requestId', () => {
    test('should update request', async () => {
      // Create first
      const createRes = await app.request('/request/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Original',
          summary: 'Will be updated',
          principalName: 'jordan',
          reporterType: 'principal',
          reporterName: 'jordan',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/request/update/${created.requestId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Updated',
          priority: 'High',
        }),
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.title).toBe('Updated');
      expect(data.priority).toBe('High');
    });

    test('should return 404 for non-existent request', async () => {
      const res = await app.request('/request/update/REQUEST-fake-9999', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: 'Updated' }),
      });
      expect(res.status).toBe(404);
    });
  });

  describe('POST /request/update-status/:requestId', () => {
    test('should update status', async () => {
      const createRes = await app.request('/request/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Status test',
          summary: 'Status will change',
          principalName: 'jordan',
          reporterType: 'principal',
          reporterName: 'jordan',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/request/update-status/${created.requestId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'In Progress' }),
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.status).toBe('In Progress');
    });

    test('should return 404 for non-existent request', async () => {
      const res = await app.request('/request/update-status/REQUEST-fake-9999', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'Complete' }),
      });
      expect(res.status).toBe(404);
    });
  });

  describe('POST /request/assign/:requestId', () => {
    test('should assign request', async () => {
      const createRes = await app.request('/request/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Unassigned',
          summary: 'Needs assignment',
          principalName: 'jordan',
          reporterType: 'principal',
          reporterName: 'jordan',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/request/assign/${created.requestId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          assigneeType: 'agent',
          assigneeName: 'housekeeping',
        }),
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.assigneeName).toBe('housekeeping');
    });

    test('should return 404 for non-existent request', async () => {
      const res = await app.request('/request/assign/REQUEST-fake-9999', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          assigneeType: 'agent',
          assigneeName: 'housekeeping',
        }),
      });
      expect(res.status).toBe(404);
    });
  });

  describe('POST /request/delete/:requestId', () => {
    test('should delete request', async () => {
      const createRes = await app.request('/request/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Delete me',
          summary: 'Will be removed',
          principalName: 'jordan',
          reporterType: 'principal',
          reporterName: 'jordan',
        }),
      });
      const created = await createRes.json();

      const res = await app.request(`/request/delete/${created.requestId}`, {
        method: 'POST',
      });

      expect(res.status).toBe(200);

      const getRes = await app.request(`/request/get/${created.requestId}`);
      expect(getRes.status).toBe(404);
    });

    test('should return 404 for non-existent request', async () => {
      const res = await app.request('/request/delete/REQUEST-fake-9999', {
        method: 'POST',
      });
      expect(res.status).toBe(404);
    });
  });

  describe('GET /request/stats', () => {
    test('should return statistics', async () => {
      // Create some requests
      await app.request('/request/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: 'Request 1',
          summary: 'Test',
          principalName: 'jordan',
          priority: 'High',
          reporterType: 'principal',
          reporterName: 'jordan',
        }),
      });

      const res = await app.request('/request/stats');
      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.total).toBe(1);
      expect(data.open).toBe(1);
      expect(data.byPriority.high).toBe(1);
    });
  });
});
