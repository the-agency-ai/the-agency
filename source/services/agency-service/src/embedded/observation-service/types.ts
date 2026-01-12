/**
 * Observation Service Types
 *
 * Observations are simpler work items for capturing notes, findings, and insights.
 * Unlike requests/bugs, they have a simpler workflow.
 */

import { z } from 'zod';

/**
 * Observation status - simpler than request/bug workflows
 */
export type ObservationStatus = 'Open' | 'Acknowledged' | 'Noted' | 'Archived';

/**
 * Observation category
 */
export type ObservationCategory =
  | 'insight'     // General insight or observation
  | 'pattern'     // Pattern noticed in codebase
  | 'concern'     // Potential concern or smell
  | 'improvement' // Possible improvement idea
  | 'note'        // General note
  | 'finding';    // Specific finding from review/analysis

/**
 * Entity types for attribution
 */
export type EntityType = 'agent' | 'principal' | 'system';

/**
 * Observation entity
 */
export interface Observation {
  id: number;
  observationId: string;  // e.g., OBS-0001
  title: string;
  summary: string;
  status: ObservationStatus;
  category: ObservationCategory;

  // Attribution
  reporterType: EntityType;
  reporterName: string;

  // Context linking
  contextPath?: string | null;   // File or directory path
  contextLine?: number | null;   // Line number in file
  contextRef?: string | null;    // Reference (e.g., function name, class)
  workstream?: string | null;

  // Organization
  tags: string[];

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Input for creating an observation
 */
export interface CreateObservationInput {
  title: string;
  summary: string;
  category?: ObservationCategory;
  reporterType: EntityType;
  reporterName: string;
  contextPath?: string;
  contextLine?: number;
  contextRef?: string;
  workstream?: string;
  tags?: string[];
}

/**
 * Input for updating an observation
 */
export interface UpdateObservationInput {
  title?: string;
  summary?: string;
  status?: ObservationStatus;
  category?: ObservationCategory;
  contextPath?: string;
  contextLine?: number;
  contextRef?: string;
  workstream?: string;
  tags?: string[];
}

/**
 * Query parameters for listing observations
 */
export interface ListObservationsQuery {
  status?: ObservationStatus;
  category?: ObservationCategory;
  reporter?: string;
  workstream?: string;
  contextPath?: string;  // Filter by context path
  tags?: string;         // Comma-separated tags
  search?: string;
  sortBy: 'createdAt' | 'updatedAt' | 'title' | 'status' | 'category';
  sortOrder: 'asc' | 'desc';
  limit: number;
  offset: number;
}

/**
 * List response with pagination metadata
 */
export interface ObservationListResponse {
  observations: Observation[];
  total: number;
  limit: number;
  offset: number;
}

/**
 * Stats for observations
 */
export interface ObservationStats {
  total: number;
  open: number;
  acknowledged: number;
  noted: number;
  archived: number;
  byCategory: {
    insight: number;
    pattern: number;
    concern: number;
    improvement: number;
    note: number;
    finding: number;
  };
}

// Zod schemas for validation

export const createObservationSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  summary: z.string().min(1, 'Summary is required'),
  category: z.enum(['insight', 'pattern', 'concern', 'improvement', 'note', 'finding']).default('note'),
  reporterType: z.enum(['agent', 'principal', 'system']),
  reporterName: z.string().min(1, 'Reporter name is required'),
  contextPath: z.string().optional(),
  contextLine: z.number().int().positive().optional(),
  contextRef: z.string().optional(),
  workstream: z.string().optional(),
  tags: z.array(z.string()).default([]),
});

export const updateObservationSchema = z.object({
  title: z.string().min(1).optional(),
  summary: z.string().min(1).optional(),
  status: z.enum(['Open', 'Acknowledged', 'Noted', 'Archived']).optional(),
  category: z.enum(['insight', 'pattern', 'concern', 'improvement', 'note', 'finding']).optional(),
  contextPath: z.string().optional(),
  contextLine: z.number().int().positive().optional(),
  contextRef: z.string().optional(),
  workstream: z.string().optional(),
  tags: z.array(z.string()).optional(),
});

export const listObservationsQuerySchema = z.object({
  status: z.enum(['Open', 'Acknowledged', 'Noted', 'Archived']).optional(),
  category: z.enum(['insight', 'pattern', 'concern', 'improvement', 'note', 'finding']).optional(),
  reporter: z.string().optional(),
  workstream: z.string().optional(),
  contextPath: z.string().optional(),
  tags: z.string().optional(),
  search: z.string().optional(),
  sortBy: z.enum(['createdAt', 'updatedAt', 'title', 'status', 'category']).default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});

export type CreateObservationSchema = z.infer<typeof createObservationSchema>;
export type UpdateObservationSchema = z.infer<typeof updateObservationSchema>;
export type ListObservationsQuerySchema = z.infer<typeof listObservationsQuerySchema>;
