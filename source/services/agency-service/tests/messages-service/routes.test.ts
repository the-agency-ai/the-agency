/**
 * Message Routes Tests
 *
 * Tests for message HTTP API endpoints.
 * Uses explicit operation names.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { Hono } from 'hono';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { createMessagesService } from '../../src/embedded/messages-service';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Message Routes', () => {
  let db: DatabaseAdapter;
  let app: Hono;
  const testDbPath = '/tmp/agency-test-messages-routes';
  const testDbFile = `${testDbPath}/messages.db`;

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'messages.db',
    });
    await db.initialize();

    const messagesService = createMessagesService({ db });
    await messagesService.initialize();

    app = new Hono();
    app.route('/api/message', messagesService.routes);
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

  describe('POST /api/message/send', () => {
    test('should create message', async () => {
      const res = await app.request('/api/message/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fromType: 'agent',
          fromName: 'housekeeping',
          toType: 'principal',
          toName: 'jordan',
          subject: 'Test',
          content: 'Hello, world!',
        }),
      });

      expect(res.status).toBe(201);
      const data = await res.json();
      expect(data.id).toBeGreaterThan(0);
      expect(data.fromName).toBe('housekeeping');
      expect(data.toName).toBe('jordan');
    });

    test('should validate required fields', async () => {
      const res = await app.request('/api/message/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fromType: 'agent',
          toType: 'agent',
        }),
      });

      expect(res.status).toBe(400);
    });

    test('should reject broadcast without recipients', async () => {
      const res = await app.request('/api/message/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fromType: 'system',
          fromName: 'notifications',
          toType: 'broadcast',
          content: 'No recipients',
        }),
      });

      expect(res.status).toBe(400);
      const data = await res.json();
      expect(data.message).toContain('Broadcast');
    });
  });

  describe('GET /api/message/list', () => {
    beforeEach(async () => {
      // Create test messages
      for (let i = 0; i < 3; i++) {
        await app.request('/api/message/send', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            fromType: 'agent',
            fromName: 'sender',
            toType: 'agent',
            toName: 'receiver',
            content: `Message ${i}`,
          }),
        });
      }
    });

    test('should list messages', async () => {
      const res = await app.request('/api/message/list');
      expect(res.status).toBe(200);

      const data = await res.json();
      expect(data.messages).toHaveLength(3);
      expect(data.total).toBe(3);
    });

    test('should paginate', async () => {
      const res = await app.request('/api/message/list?limit=2&offset=0');
      expect(res.status).toBe(200);

      const data = await res.json();
      expect(data.messages).toHaveLength(2);
      expect(data.limit).toBe(2);
    });
  });

  describe('GET /api/message/get/:id', () => {
    test('should get message by ID', async () => {
      const createRes = await app.request('/api/message/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fromType: 'agent',
          fromName: 'sender',
          toType: 'agent',
          toName: 'receiver',
          content: 'Find me',
        }),
      });

      const created = await createRes.json();
      const res = await app.request(`/api/message/get/${created.id}`);

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.content).toBe('Find me');
    });

    test('should return 404 for non-existent', async () => {
      const res = await app.request('/api/message/get/99999');
      expect(res.status).toBe(404);
    });

    test('should return 400 for invalid ID', async () => {
      const res = await app.request('/api/message/get/invalid');
      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/message/inbox/:recipientType/:recipientName', () => {
    test('should get inbox', async () => {
      await app.request('/api/message/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fromType: 'agent',
          fromName: 'sender',
          toType: 'agent',
          toName: 'test-inbox',
          content: 'Inbox message',
        }),
      });

      const res = await app.request('/api/message/inbox/agent/test-inbox');
      expect(res.status).toBe(200);

      const data = await res.json();
      expect(data.messages).toHaveLength(1);
      expect(data.count).toBe(1);
    });

    test('should filter unread only', async () => {
      const createRes = await app.request('/api/message/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fromType: 'agent',
          fromName: 'sender',
          toType: 'agent',
          toName: 'unread-test',
          content: 'Message 1',
        }),
      });

      const msg = await createRes.json();

      await app.request('/api/message/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fromType: 'agent',
          fromName: 'sender',
          toType: 'agent',
          toName: 'unread-test',
          content: 'Message 2',
        }),
      });

      // Mark one as read
      await app.request(`/api/message/mark-read/${msg.id}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          recipientType: 'agent',
          recipientName: 'unread-test',
        }),
      });

      const res = await app.request('/api/message/inbox/agent/unread-test?unreadOnly=true');
      const data = await res.json();
      expect(data.messages).toHaveLength(1);
    });

    test('should validate recipient type', async () => {
      const res = await app.request('/api/message/inbox/invalid/name');
      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/message/stats/:recipientType/:recipientName', () => {
    test('should get stats', async () => {
      const msg1 = await app.request('/api/message/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fromType: 'agent',
          fromName: 'sender',
          toType: 'agent',
          toName: 'stats-test',
          content: 'Message 1',
        }),
      });
      const created = await msg1.json();

      await app.request('/api/message/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fromType: 'agent',
          fromName: 'sender',
          toType: 'agent',
          toName: 'stats-test',
          content: 'Message 2',
        }),
      });

      await app.request(`/api/message/mark-read/${created.id}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          recipientType: 'agent',
          recipientName: 'stats-test',
        }),
      });

      const res = await app.request('/api/message/stats/agent/stats-test');
      expect(res.status).toBe(200);

      const data = await res.json();
      expect(data.total).toBe(2);
      expect(data.unread).toBe(1);
    });
  });

  describe('POST /api/message/mark-read/:id', () => {
    test('should mark message as read', async () => {
      const createRes = await app.request('/api/message/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fromType: 'agent',
          fromName: 'sender',
          toType: 'agent',
          toName: 'reader',
          content: 'To read',
        }),
      });
      const msg = await createRes.json();

      const res = await app.request(`/api/message/mark-read/${msg.id}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          recipientType: 'agent',
          recipientName: 'reader',
        }),
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.success).toBe(true);
    });
  });

  describe('POST /api/message/mark-all-read', () => {
    test('should mark all as read', async () => {
      for (let i = 0; i < 3; i++) {
        await app.request('/api/message/send', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            fromType: 'agent',
            fromName: 'sender',
            toType: 'agent',
            toName: 'bulk-reader',
            content: `Message ${i}`,
          }),
        });
      }

      const res = await app.request('/api/message/mark-all-read', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          recipientType: 'agent',
          recipientName: 'bulk-reader',
        }),
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.success).toBe(true);
      expect(data.count).toBe(3);
    });
  });

  describe('POST /api/message/delete/:id', () => {
    test('should delete message', async () => {
      const createRes = await app.request('/api/message/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fromType: 'agent',
          fromName: 'sender',
          toType: 'agent',
          toName: 'receiver',
          content: 'To delete',
        }),
      });
      const msg = await createRes.json();

      const res = await app.request(`/api/message/delete/${msg.id}`, {
        method: 'POST',
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.success).toBe(true);

      const getRes = await app.request(`/api/message/get/${msg.id}`);
      expect(getRes.status).toBe(404);
    });

    test('should return 404 for non-existent', async () => {
      const res = await app.request('/api/message/delete/99999', {
        method: 'POST',
      });
      expect(res.status).toBe(404);
    });
  });
});
