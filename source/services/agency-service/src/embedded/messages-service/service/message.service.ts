/**
 * Unified Message Service
 *
 * Business logic layer for the unified messaging system.
 * Handles direct messages and broadcasts.
 */

import type {
  Message,
  SendMessageInput,
  BroadcastMessageInput,
  ListMessagesQuery,
  MessageListResponse,
  UnreadResponse,
  ThreadResponse,
  MessageStats,
} from '../types';
import type { MessageRepository } from '../repository/message.repository';
import type { QueueAdapter } from '../../../core/adapters/queue';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('message-service');

export class MessageService {
  constructor(
    private repository: MessageRepository,
    private queue?: QueueAdapter
  ) {}

  /**
   * Send a direct message
   */
  async sendMessage(data: SendMessageInput): Promise<Message> {
    const message = await this.repository.createDirect(data);

    logger.info({
      messageId: message.id,
      from: data.fromAgent,
      to: data.toAgent,
    }, 'Direct message sent');

    // Emit queue event (non-blocking)
    this.emitEvent('message.sent', {
      messageId: message.id,
      type: 'direct',
      from: data.fromAgent,
      to: data.toAgent,
    });

    return message;
  }

  /**
   * Send a broadcast message
   */
  async broadcastMessage(data: BroadcastMessageInput): Promise<Message> {
    const message = await this.repository.createBroadcast(data);

    logger.info({
      messageId: message.id,
      from: data.fromAgent,
    }, 'Broadcast message sent');

    this.emitEvent('message.broadcast', {
      messageId: message.id,
      from: data.fromAgent,
    });

    return message;
  }

  /**
   * Get a message by ID
   */
  async getMessage(id: string): Promise<Message | null> {
    return this.repository.findById(id);
  }

  /**
   * Mark a message as read by an agent
   */
  async markAsRead(id: string, agentName: string): Promise<boolean> {
    return this.repository.markAsRead(id, agentName);
  }

  /**
   * List messages with filtering
   */
  async listMessages(query: ListMessagesQuery): Promise<MessageListResponse> {
    const { messages, total } = await this.repository.list(query);

    return {
      messages,
      total,
      limit: query.limit,
      offset: query.offset,
    };
  }

  /**
   * Get unread messages for an agent
   */
  async getUnread(agentName: string): Promise<UnreadResponse> {
    const { count, messages } = await this.repository.getUnread(agentName);

    return {
      agentName,
      unreadCount: count,
      messages,
    };
  }

  /**
   * Get a message thread
   */
  async getThread(id: string): Promise<ThreadResponse> {
    const { root, replies } = await this.repository.getThread(id);

    if (!root) {
      throw new Error(`Message ${id} not found`);
    }

    return { root, replies };
  }

  /**
   * Delete a message
   */
  async deleteMessage(id: string): Promise<boolean> {
    const deleted = await this.repository.delete(id);
    if (deleted) {
      logger.info({ messageId: id }, 'Message deleted');
    }
    return deleted;
  }

  /**
   * Get message statistics
   */
  async getStats(): Promise<MessageStats> {
    return this.repository.getStats();
  }

  /**
   * Emit a queue event (fire and forget)
   */
  private emitEvent(event: string, data: Record<string, unknown>): void {
    if (!this.queue) return;

    try {
      this.queue.enqueue('message.events', { data: { event, ...data } });
    } catch (error) {
      logger.warn({ error, event }, 'Failed to emit message event');
    }
  }
}
