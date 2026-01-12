/**
 * Message Service
 *
 * Business logic layer for messaging.
 * Handles validation, orchestration, and notifications.
 */

import type {
  Message,
  MessageWithRecipients,
  CreateMessageRequest,
  ListMessagesQuery,
  MessageListResponse,
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
   * Send a new message
   */
  async sendMessage(data: CreateMessageRequest): Promise<MessageWithRecipients> {
    // Validate broadcast messages
    if (data.toType === 'broadcast' && !data.recipients?.length) {
      throw new Error('Broadcast messages require at least one recipient');
    }

    // Validate direct messages
    if (data.toType !== 'broadcast' && !data.toName && !data.recipients?.length) {
      throw new Error('Direct messages require a recipient');
    }

    // Create the message
    const message = await this.repository.create(data);

    logger.info({
      messageId: message.id,
      from: `${data.fromType}:${data.fromName}`,
      to: data.toType === 'broadcast' ? 'broadcast' : `${data.toType}:${data.toName}`,
      recipients: message.recipients.length,
    }, 'Message sent');

    return message;
  }

  /**
   * Get a message by ID
   */
  async getMessage(id: number): Promise<MessageWithRecipients | null> {
    return this.repository.findById(id);
  }

  /**
   * Get inbox for an entity
   */
  async getInbox(
    recipientType: 'agent' | 'principal',
    recipientName: string,
    unreadOnly: boolean = false
  ): Promise<MessageWithRecipients[]> {
    return this.repository.getInbox(recipientType, recipientName, unreadOnly);
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
   * Mark a message as read
   */
  async markAsRead(
    messageId: number,
    recipientType: 'agent' | 'principal',
    recipientName: string
  ): Promise<boolean> {
    const result = await this.repository.markAsRead(messageId, recipientType, recipientName);

    if (result) {
      logger.debug({
        messageId,
        reader: `${recipientType}:${recipientName}`,
      }, 'Message marked as read');
    }

    return result;
  }

  /**
   * Mark all messages as read for an entity
   */
  async markAllAsRead(
    recipientType: 'agent' | 'principal',
    recipientName: string
  ): Promise<number> {
    const inbox = await this.getInbox(recipientType, recipientName, true);
    let count = 0;

    for (const message of inbox) {
      const marked = await this.repository.markAsRead(message.id, recipientType, recipientName);
      if (marked) {
        count++;
      }
    }

    logger.info({
      reader: `${recipientType}:${recipientName}`,
      count,
    }, 'Marked all messages as read');

    return count;
  }

  /**
   * Delete a message
   */
  async deleteMessage(id: number): Promise<boolean> {
    const deleted = await this.repository.delete(id);
    if (deleted) {
      logger.info({ messageId: id }, 'Message deleted');
    }
    return deleted;
  }

  /**
   * Get stats for an entity
   */
  async getStats(
    recipientType: 'agent' | 'principal',
    recipientName: string
  ): Promise<MessageStats> {
    return this.repository.getStats(recipientType, recipientName);
  }
}
