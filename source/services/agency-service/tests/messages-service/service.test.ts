/**
 * Message Service Tests
 *
 * Tests for message business logic layer.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { MessageRepository } from '../../src/embedded/messages-service/repository/message.repository';
import { MessageService } from '../../src/embedded/messages-service/service/message.service';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Message Service', () => {
  let db: DatabaseAdapter;
  let repo: MessageRepository;
  let service: MessageService;
  const testDbPath = '/tmp/agency-test-messages-svc';
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
    service = new MessageService(repo);
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

  describe('sendMessage', () => {
    test('should send a direct message', async () => {
      const message = await service.sendMessage({
        fromType: 'agent',
        fromName: 'housekeeping',
        toType: 'principal',
        toName: 'jordan',
        subject: 'Hello',
        content: 'Test content',
      });

      expect(message.id).toBeGreaterThan(0);
      expect(message.fromName).toBe('housekeeping');
      expect(message.toName).toBe('jordan');
    });

    test('should reject broadcast without recipients', async () => {
      await expect(
        service.sendMessage({
          fromType: 'system',
          fromName: 'notifications',
          toType: 'broadcast',
          content: 'Invalid broadcast',
        })
      ).rejects.toThrow('Broadcast messages require at least one recipient');
    });

    test('should reject direct message without recipient', async () => {
      await expect(
        service.sendMessage({
          fromType: 'agent',
          fromName: 'test',
          toType: 'agent',
          content: 'No recipient',
        })
      ).rejects.toThrow('Direct messages require a recipient');
    });

    test('should send broadcast to multiple recipients', async () => {
      const message = await service.sendMessage({
        fromType: 'system',
        fromName: 'notifications',
        toType: 'broadcast',
        subject: 'Announcement',
        content: 'Important update',
        recipients: [
          { recipientType: 'agent', recipientName: 'agent1' },
          { recipientType: 'agent', recipientName: 'agent2' },
        ],
      });

      expect(message.recipients).toHaveLength(2);
    });
  });

  describe('getMessage', () => {
    test('should get existing message', async () => {
      const sent = await service.sendMessage({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'receiver',
        content: 'Find me',
      });

      const found = await service.getMessage(sent.id);
      expect(found).not.toBeNull();
      expect(found!.content).toBe('Find me');
    });

    test('should return null for non-existent', async () => {
      const found = await service.getMessage(99999);
      expect(found).toBeNull();
    });
  });

  describe('getInbox', () => {
    test('should return messages for entity', async () => {
      await service.sendMessage({
        fromType: 'agent',
        fromName: 'a',
        toType: 'agent',
        toName: 'inbox-test',
        content: 'Msg 1',
      });
      await service.sendMessage({
        fromType: 'agent',
        fromName: 'b',
        toType: 'agent',
        toName: 'inbox-test',
        content: 'Msg 2',
      });

      const inbox = await service.getInbox('agent', 'inbox-test');
      expect(inbox).toHaveLength(2);
    });
  });

  describe('listMessages', () => {
    test('should list with pagination', async () => {
      for (let i = 0; i < 5; i++) {
        await service.sendMessage({
          fromType: 'agent',
          fromName: 'sender',
          toType: 'agent',
          toName: 'receiver',
          content: `Message ${i}`,
        });
      }

      const result = await service.listMessages({ limit: 2, offset: 0 });
      expect(result.messages).toHaveLength(2);
      expect(result.total).toBe(5);
      expect(result.limit).toBe(2);
      expect(result.offset).toBe(0);
    });
  });

  describe('markAsRead', () => {
    test('should mark single message as read', async () => {
      const msg = await service.sendMessage({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'reader',
        content: 'To read',
      });

      const result = await service.markAsRead(msg.id, 'agent', 'reader');
      expect(result).toBe(true);

      const found = await service.getMessage(msg.id);
      expect(found!.recipients[0].readAt).not.toBeNull();
    });
  });

  describe('markAllAsRead', () => {
    test('should mark all messages as read', async () => {
      for (let i = 0; i < 3; i++) {
        await service.sendMessage({
          fromType: 'agent',
          fromName: 'sender',
          toType: 'agent',
          toName: 'bulk-reader',
          content: `Message ${i}`,
        });
      }

      const count = await service.markAllAsRead('agent', 'bulk-reader');
      expect(count).toBe(3);

      const inbox = await service.getInbox('agent', 'bulk-reader', true);
      expect(inbox).toHaveLength(0);
    });
  });

  describe('deleteMessage', () => {
    test('should delete message', async () => {
      const msg = await service.sendMessage({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'receiver',
        content: 'To delete',
      });

      const deleted = await service.deleteMessage(msg.id);
      expect(deleted).toBe(true);

      const found = await service.getMessage(msg.id);
      expect(found).toBeNull();
    });
  });

  describe('getStats', () => {
    test('should return correct stats', async () => {
      const msg1 = await service.sendMessage({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'stats-test',
        content: 'Read',
      });
      await service.sendMessage({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'stats-test',
        content: 'Unread 1',
      });
      await service.sendMessage({
        fromType: 'agent',
        fromName: 'sender',
        toType: 'agent',
        toName: 'stats-test',
        content: 'Unread 2',
      });

      await service.markAsRead(msg1.id, 'agent', 'stats-test');

      const stats = await service.getStats('agent', 'stats-test');
      expect(stats.total).toBe(3);
      expect(stats.unread).toBe(2);
      expect(stats.today).toBe(3);
    });
  });
});
