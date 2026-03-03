/**
 * Dispatch Service Types
 *
 * Domain models for the dispatch queue system.
 * Manages work item queuing, claiming, and instance registration.
 */

import { z } from 'zod';

/**
 * Queue type values
 */
export const QueueType = {
  AGENT: 'agent',
  SHARED: 'shared',
} as const;

export type QueueTypeValue = (typeof QueueType)[keyof typeof QueueType];

/**
 * Work type values
 */
export const WorkType = {
  REQUEST: 'request',
  COLLABORATION: 'collaboration',
  REVIEW: 'review',
  CUSTOM: 'custom',
} as const;

export type WorkTypeValue = (typeof WorkType)[keyof typeof WorkType];

/**
 * Dispatch item status values
 */
export const DispatchStatus = {
  PENDING: 'pending',
  CLAIMED: 'claimed',
  ACTIVE: 'active',
  COMPLETED: 'completed',
  FAILED: 'failed',
  CANCELLED: 'cancelled',
} as const;

export type DispatchStatusValue = (typeof DispatchStatus)[keyof typeof DispatchStatus];

/**
 * Instance status values
 */
export const InstanceStatus = {
  ACTIVE: 'active',
  IDLE: 'idle',
  STOPPING: 'stopping',
  DEAD: 'dead',
} as const;

export type InstanceStatusValue = (typeof InstanceStatus)[keyof typeof InstanceStatus];

/**
 * Dispatch item entity
 */
export interface DispatchItem {
  id: string;
  queueType: QueueTypeValue;
  agentName: string | null;  // null for shared queue
  workType: WorkTypeValue;
  workId: string | null;     // e.g., REQUEST-jordan-0065
  title: string;
  description: string | null;
  prompt: string | null;
  priority: number;          // 0=normal, 10=high, 20=critical
  status: DispatchStatusValue;
  claimedBy: string | null;
  claimedAt: string | null;
  claimExpiresAt: string | null;
  createdAt: string;
  startedAt: string | null;
  completedAt: string | null;
  error: string | null;
  result: string | null;
  source: string | null;
  metadata: Record<string, unknown>;
}

/**
 * Dispatch instance entity
 */
export interface DispatchInstance {
  id: string;              // session ID
  agentName: string;
  workstream: string | null;
  pid: number | null;
  status: InstanceStatusValue;
  currentItemId: string | null;
  lastHeartbeat: string;
  registeredAt: string;
  metadata: Record<string, unknown>;
}

/**
 * Enqueue item schema
 */
export const enqueueItemSchema = z.object({
  queueType: z.enum(['agent', 'shared']).default('agent'),
  agentName: z.string().optional(),
  workType: z.enum(['request', 'collaboration', 'review', 'custom']).default('custom'),
  workId: z.string().optional(),
  title: z.string().min(1, 'Title is required'),
  description: z.string().optional(),
  prompt: z.string().optional(),
  priority: z.number().min(0).max(20).default(0),
  source: z.string().optional(),
  metadata: z.record(z.unknown()).default({}),
});

export type EnqueueItemInput = z.infer<typeof enqueueItemSchema>;

/**
 * Claim item schema
 */
export const claimItemSchema = z.object({
  agentName: z.string().min(1, 'Agent name is required'),
  instanceId: z.string().optional(),
  ttlMinutes: z.number().min(1).max(60).default(5),
});

export type ClaimItemInput = z.infer<typeof claimItemSchema>;

/**
 * Complete item schema
 */
export const completeItemSchema = z.object({
  result: z.string().optional(),
});

export type CompleteItemInput = z.infer<typeof completeItemSchema>;

/**
 * Fail item schema
 */
export const failItemSchema = z.object({
  error: z.string().min(1, 'Error message is required'),
});

export type FailItemInput = z.infer<typeof failItemSchema>;

/**
 * Register instance schema
 */
export const registerInstanceSchema = z.object({
  id: z.string().min(1, 'Instance ID is required'),
  agentName: z.string().min(1, 'Agent name is required'),
  workstream: z.string().optional(),
  pid: z.number().optional(),
  metadata: z.record(z.unknown()).default({}),
});

export type RegisterInstanceInput = z.infer<typeof registerInstanceSchema>;

/**
 * List dispatch items query
 */
export const listDispatchQuerySchema = z.object({
  agentName: z.string().optional(),
  status: z.string().optional(),
  queueType: z.enum(['agent', 'shared']).optional(),
  workType: z.string().optional(),
  limit: z.coerce.number().min(1).max(100).default(50),
  offset: z.coerce.number().min(0).default(0),
});

export type ListDispatchQuery = z.infer<typeof listDispatchQuerySchema>;

/**
 * Dispatch item list response
 */
export interface DispatchListResponse {
  items: DispatchItem[];
  total: number;
  limit: number;
  offset: number;
}

/**
 * Dispatch stats
 */
export interface DispatchStats {
  total: number;
  pending: number;
  claimed: number;
  active: number;
  completed: number;
  failed: number;
  cancelled: number;
  activeInstances: number;
}
