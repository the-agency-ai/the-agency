/**
 * Unified Message Service Types
 *
 * Domain models for the unified messaging system.
 * Replaces collaboration files, NEWS.md, and old messages.db.
 *
 * Two message types:
 * - direct: agent-to-agent communication
 * - broadcast: agent-to-all announcements
 */

import { z } from 'zod';

/**
 * Message type values
 */
export const MessageType = {
  DIRECT: 'direct',
  BROADCAST: 'broadcast',
} as const;

export type MessageTypeValue = (typeof MessageType)[keyof typeof MessageType];

/**
 * Message entity
 */
export interface Message {
  id: string;           // UUID
  type: MessageTypeValue;
  fromAgent: string;
  toAgent: string | null; // null for broadcast
  subject: string;
  body: string;
  referenceId: string | null;
  tags: string[];       // JSON array
  readBy: string[];     // JSON array of agent names
  createdAt: string;    // ISO timestamp
  metadata: Record<string, unknown>;
}

/**
 * Send direct message schema
 */
export const sendMessageSchema = z.object({
  fromAgent: z.string().min(1, 'Sender agent name is required'),
  toAgent: z.string().min(1, 'Recipient agent name is required'),
  subject: z.string().min(1, 'Subject is required'),
  body: z.string().min(1, 'Body is required'),
  referenceId: z.string().nullable().optional(),
  tags: z.array(z.string()).default([]),
  metadata: z.record(z.unknown()).default({}),
});

export type SendMessageInput = z.infer<typeof sendMessageSchema>;

/**
 * Broadcast message schema
 */
export const broadcastMessageSchema = z.object({
  fromAgent: z.string().min(1, 'Sender agent name is required'),
  subject: z.string().min(1, 'Subject is required'),
  body: z.string().min(1, 'Body is required'),
  referenceId: z.string().nullable().optional(),
  tags: z.array(z.string()).default([]),
  metadata: z.record(z.unknown()).default({}),
});

export type BroadcastMessageInput = z.infer<typeof broadcastMessageSchema>;

/**
 * Mark as read schema
 */
export const markReadSchema = z.object({
  agentName: z.string().min(1, 'Agent name is required'),
});

export type MarkReadInput = z.infer<typeof markReadSchema>;

/**
 * List messages query parameters
 */
export const listMessagesQuerySchema = z.object({
  type: z.enum(['direct', 'broadcast']).optional(),
  agent: z.string().optional(),       // Filter by toAgent or fromAgent
  fromAgent: z.string().optional(),
  toAgent: z.string().optional(),
  unread: z.string().optional(),      // Agent name — show messages not read by this agent
  tags: z.string().optional(),        // Comma-separated
  since: z.string().optional(),       // ISO timestamp or relative like "1h", "24h"
  limit: z.coerce.number().min(1).max(100).default(50),
  offset: z.coerce.number().min(0).default(0),
});

export type ListMessagesQuery = z.infer<typeof listMessagesQuerySchema>;

/**
 * Message list response
 */
export interface MessageListResponse {
  messages: Message[];
  total: number;
  limit: number;
  offset: number;
}

/**
 * Unread response
 */
export interface UnreadResponse {
  agentName: string;
  unreadCount: number;
  messages: Message[];
}

/**
 * Thread response
 */
export interface ThreadResponse {
  root: Message;
  replies: Message[];
}

/**
 * Message stats
 */
export interface MessageStats {
  total: number;
  direct: number;
  broadcast: number;
  today: number;
}
