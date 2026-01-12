/**
 * Messages Service Types
 *
 * Domain models for inter-entity messaging.
 */

import { z } from 'zod';

/**
 * Entity types (sender, recipient)
 */
export const EntityType = {
  AGENT: 'agent',
  PRINCIPAL: 'principal',
  SYSTEM: 'system',
  BROADCAST: 'broadcast',
} as const;

export type EntityTypeValue = (typeof EntityType)[keyof typeof EntityType];

/**
 * Message entity
 */
export interface Message {
  id: number;
  timestamp: Date;
  fromType: EntityTypeValue;
  fromName: string;
  toType: EntityTypeValue;
  toName: string | null; // null for broadcasts
  subject: string | null;
  content: string;
}

/**
 * Recipient tracking (for delivery/read status)
 */
export interface Recipient {
  id: number;
  messageId: number;
  recipientType: EntityTypeValue;
  recipientName: string;
  readAt: Date | null;
}

/**
 * Message with recipients
 */
export interface MessageWithRecipients extends Message {
  recipients: Recipient[];
}

/**
 * Create message request schema
 */
export const createMessageSchema = z.object({
  fromType: z.enum(['agent', 'principal', 'system']).default('agent'),
  fromName: z.string().min(1, 'Sender name is required'),
  toType: z.enum(['agent', 'principal', 'system', 'broadcast']),
  toName: z.string().optional(), // Optional for broadcasts
  subject: z.string().optional(),
  content: z.string().min(1, 'Content is required'),
  recipients: z.array(z.object({
    recipientType: z.enum(['agent', 'principal']),
    recipientName: z.string().min(1),
  })).optional(), // For multi-recipient messages
});

export type CreateMessageRequest = z.infer<typeof createMessageSchema>;

/**
 * Mark message as read request
 */
export const markReadSchema = z.object({
  recipientType: z.enum(['agent', 'principal']),
  recipientName: z.string().min(1),
});

export type MarkReadRequest = z.infer<typeof markReadSchema>;

/**
 * List messages query parameters
 */
export const listMessagesQuerySchema = z.object({
  // Inbox filters
  recipientType: z.enum(['agent', 'principal']).optional(),
  recipientName: z.string().optional(),
  unreadOnly: z.coerce.boolean().default(false),

  // Outbox filters
  fromType: z.enum(['agent', 'principal', 'system']).optional(),
  fromName: z.string().optional(),

  // General filters
  since: z.string().optional(), // ISO timestamp or relative like "1h", "24h"

  // Pagination
  limit: z.coerce.number().min(1).max(100).default(50),
  offset: z.coerce.number().min(0).default(0),
});

export type ListMessagesQuery = z.infer<typeof listMessagesQuerySchema>;

/**
 * Message list response
 */
export interface MessageListResponse {
  messages: MessageWithRecipients[];
  total: number;
  limit: number;
  offset: number;
}

/**
 * Message stats
 */
export interface MessageStats {
  total: number;
  unread: number;
  today: number;
}
