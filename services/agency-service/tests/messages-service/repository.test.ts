/**
 * Message Repository Tests
 *
 * Tests for message data access layer.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { MessageRepository } from '../../src/embedded/messages-service/repository/message.repository';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Message Repository', () => {
  let db: DatabaseAdapter;
  let repo: MessageRepository;
  const testDbPath = '/tmp/agency-test-messages';
  const testDbFile = `${testDbPath}/messages.db`;

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'messages.db',
    });
    await db.initialize();
    repo = new MessageRepository(db);
    await repo.initialize();
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

  describe('create', () => {
    test('should create message with single recipient', async () => {
      const message = await repo.create({
        fromType: 'agent',
        fromName: 'housekeeping',
        toType: 'principal',
        toName: 'jordan',
        subject: 'Test Subject',
        content: 'Test message content',
      });

      expect(message.id).toBeGreaterThan(0);
      expect(message.fromType).toBe('agent');
      expect(message.fromName).toBe('housekeeping');
      expect(message.toType).toBe('principal');
      expect(message.toName).toBe('jordan');
      expect(message.subject).toBe('Test Subject');
      expect(message.content).toBe('Test message content');
      expect(message.recipients).toHaveLength(1);
      expect(message.recipients[0].recipientName).toBe('jordan');
    });

    test('should create message with multiple recipients', async () => {
      const message = await repo.create({
        fromType: 'system',
        fromName: 'notifications',
        toType: 'broadcast',
        content: 'Broadcast message',
        recipients: [
          { recipientType: 'agent', recipientName: 'housekeeping' },
          { recipientType: 'agent', recipientName: 'web' },
          { recipientType: 'principal', recipientName: 'jordan' },
        ],
      });

      expect(message.toType).toBe('broadcast');
      expect(message.recipients).toHaveLength(3);
    });

    test('should create message without subject', async () => {
      const message = await repo.create({
        fromType: 'agent',
        fromName: 'test',
        toType: 'agent',
        toName: 'other',
        content: 'No subject message',
      });

      expect(message.subject).toBeNull();
    });
  });

  describe('findById', () => {
    test('should find existing message', async () => {
      const created = await repo.create({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'receiver',
        subject: 'Find me',
        content: 'Content',
      });

      const found = await repo.findById(created.id);
      expect(found).not.toBeNull();
      expect(found!.subject).toBe('Find me');
      expect(found!.recipients).toHaveLength(1);
    });

    test('should return null for non-existent message', async () => {
      const found = await repo.findById(99999);
      expect(found).toBeNull();
    });
  });

  describe('list', () => {
    beforeEach(async () => {
      // Create test messages
      await repo.create({
        fromType: 'agent',
        fromName: 'sender1',
        toType: 'agent',
        toName: 'receiver1',
        content: 'Message 1',
      });
      await repo.create({
        fromType: 'agent',
        fromName: 'sender2',
        toType: 'principal',
        toName: 'jordan',
        content: 'Message 2',
      });
      await repo.create({
        fromType: 'principal',
        fromName: 'jordan',
        toType: 'agent',
        toName: 'receiver1',
        content: 'Message 3',
      });
    });

    test('should list all messages', async () => {
      const { messages, total } = await repo.list({ limit: 50, offset: 0 });
      expect(total).toBe(3);
      expect(messages.length).toBe(3);
    });

    test('should filter by sender', async () => {
      const { messages, total } = await repo.list({
        fromType: 'principal',
        fromName: 'jordan',
        limit: 50,
        offset: 0,
      });
      expect(total).toBe(1);
      expect(messages[0].fromName).toBe('jordan');
    });

    test('should filter by recipient (inbox)', async () => {
      const { messages, total } = await repo.list({
        recipientType: 'agent',
        recipientName: 'receiver1',
        limit: 50,
        offset: 0,
      });
      expect(total).toBe(2);
      expect(messages.every(m =>
        m.recipients.some(r => r.recipientName === 'receiver1')
      )).toBe(true);
    });

    test('should paginate results', async () => {
      const page1 = await repo.list({ limit: 2, offset: 0 });
      const page2 = await repo.list({ limit: 2, offset: 2 });

      expect(page1.messages.length).toBe(2);
      expect(page2.messages.length).toBe(1);
    });
  });

  describe('getInbox', () => {
    test('should get inbox for entity', async () => {
      await repo.create({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'receiver',
        content: 'Inbox message 1',
      });
      await repo.create({
        fromType: 'principal',
        fromName: 'jordan',
        toType: 'agent',
        toName: 'receiver',
        content: 'Inbox message 2',
      });
      await repo.create({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'principal',
        toName: 'jordan',
        content: 'Not in receiver inbox',
      });

      const inbox = await repo.getInbox('agent', 'receiver');
      expect(inbox).toHaveLength(2);
    });

    test('should filter unread only', async () => {
      const msg1 = await repo.create({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'receiver',
        content: 'Message 1',
      });
      await repo.create({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'receiver',
        content: 'Message 2',
      });

      // Mark one as read
      await repo.markAsRead(msg1.id, 'agent', 'receiver');

      const unread = await repo.getInbox('agent', 'receiver', true);
      expect(unread).toHaveLength(1);
    });
  });

  describe('markAsRead', () => {
    test('should mark message as read', async () => {
      const message = await repo.create({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'receiver',
        content: 'To be read',
      });

      const marked = await repo.markAsRead(message.id, 'agent', 'receiver');
      expect(marked).toBe(true);

      const found = await repo.findById(message.id);
      expect(found!.recipients[0].readAt).not.toBeNull();
    });

    test('should return false if already read', async () => {
      const message = await repo.create({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'receiver',
        content: 'Already read',
      });

      await repo.markAsRead(message.id, 'agent', 'receiver');
      const secondMark = await repo.markAsRead(message.id, 'agent', 'receiver');
      expect(secondMark).toBe(false);
    });

    test('should only mark for correct recipient', async () => {
      const message = await repo.create({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'broadcast',
        content: 'Broadcast',
        recipients: [
          { recipientType: 'agent', recipientName: 'agent1' },
          { recipientType: 'agent', recipientName: 'agent2' },
        ],
      });

      await repo.markAsRead(message.id, 'agent', 'agent1');

      const found = await repo.findById(message.id);
      const agent1 = found!.recipients.find(r => r.recipientName === 'agent1');
      const agent2 = found!.recipients.find(r => r.recipientName === 'agent2');

      expect(agent1!.readAt).not.toBeNull();
      expect(agent2!.readAt).toBeNull();
    });
  });

  describe('delete', () => {
    test('should delete message and recipients', async () => {
      const message = await repo.create({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'receiver',
        content: 'To be deleted',
      });

      const deleted = await repo.delete(message.id);
      expect(deleted).toBe(true);

      const found = await repo.findById(message.id);
      expect(found).toBeNull();
    });

    test('should return false for non-existent message', async () => {
      const deleted = await repo.delete(99999);
      expect(deleted).toBe(false);
    });
  });

  describe('getStats', () => {
    test('should return correct statistics', async () => {
      // Create messages for 'agent:test'
      const msg1 = await repo.create({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'test',
        content: 'Message 1',
      });
      await repo.create({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'test',
        content: 'Message 2',
      });
      await repo.create({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'test',
        content: 'Message 3',
      });

      // Mark one as read
      await repo.markAsRead(msg1.id, 'agent', 'test');

      const stats = await repo.getStats('agent', 'test');
      expect(stats.total).toBe(3);
      expect(stats.unread).toBe(2);
      expect(stats.today).toBe(3);
    });
  });
});
