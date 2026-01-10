/**
 * Idea Service Types
 *
 * Domain models for idea capture and management.
 */

import { z } from 'zod';

/**
 * Idea status values
 */
export const IdeaStatus = {
  CAPTURED: 'captured',
  EXPLORING: 'exploring',
  PROMOTED: 'promoted',
  PARKED: 'parked',
  DISCARDED: 'discarded',
} as const;

export type IdeaStatusType = (typeof IdeaStatus)[keyof typeof IdeaStatus];

/**
 * Source types (who captured the idea)
 */
export const SourceType = {
  AGENT: 'agent',
  PRINCIPAL: 'principal',
  SYSTEM: 'system',
} as const;

export type SourceTypeValue = (typeof SourceType)[keyof typeof SourceType];

/**
 * Idea entity
 */
export interface Idea {
  id: number;
  ideaId: string; // e.g., "IDEA-00001"
  title: string;
  description: string | null;
  status: IdeaStatusType;
  sourceType: SourceTypeValue;
  sourceName: string;
  tags: string[];
  promotedTo: string | null; // REQUEST-jordan-0012
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Tag validation - alphanumeric with hyphens and underscores, max 50 chars
 */
const tagSchema = z.string()
  .min(1)
  .max(50)
  .regex(/^[a-zA-Z0-9-_]+$/, 'Tags must be alphanumeric (hyphens and underscores allowed)');

/**
 * Create idea request schema
 */
export const createIdeaSchema = z.object({
  title: z.string().min(1, 'Title is required').max(200, 'Title too long'),
  description: z.string().max(5000).optional(),
  sourceType: z.enum(['agent', 'principal', 'system']).default('agent'),
  sourceName: z.string().min(1, 'Source name is required').max(100),
  tags: z.array(tagSchema).max(20).default([]),
});

export type CreateIdeaRequest = z.infer<typeof createIdeaSchema>;

/**
 * Update idea request schema
 */
export const updateIdeaSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  description: z.string().max(5000).nullable().optional(),
  status: z.enum(['captured', 'exploring', 'promoted', 'parked', 'discarded']).optional(),
  tags: z.array(tagSchema).max(20).optional(),
});

export type UpdateIdeaRequest = z.infer<typeof updateIdeaSchema>;

/**
 * Promote idea request schema
 */
export const promoteIdeaSchema = z.object({
  requestId: z.string().min(1, 'Request ID is required'),
});

export type PromoteIdeaRequest = z.infer<typeof promoteIdeaSchema>;

/**
 * List ideas query parameters
 */
export const listIdeasQuerySchema = z.object({
  status: z.enum(['captured', 'exploring', 'promoted', 'parked', 'discarded']).optional(),
  source: z.string().optional(),
  tag: z.string().optional(),
  search: z.string().max(200).optional(),
  limit: z.coerce.number().min(1).max(100).default(50),
  offset: z.coerce.number().min(0).default(0),
});

export type ListIdeasQuery = z.infer<typeof listIdeasQuerySchema>;

/**
 * Idea list response
 */
export interface IdeaListResponse {
  ideas: Idea[];
  total: number;
  limit: number;
  offset: number;
}
