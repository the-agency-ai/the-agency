/**
 * Request Service Types
 *
 * Domain models for REQUEST tracking.
 * Following unified work item schema from REQUEST-jordan-0040.
 */

import { z } from 'zod';

/**
 * Request status values
 */
export const RequestStatus = {
  OPEN: 'Open',
  IN_PROGRESS: 'In Progress',
  REVIEW: 'Review',
  TESTING: 'Testing',
  COMPLETE: 'Complete',
  ON_HOLD: 'On Hold',
  CANCELLED: 'Cancelled',
} as const;

export type RequestStatusType = (typeof RequestStatus)[keyof typeof RequestStatus];

/**
 * Request priority values
 */
export const RequestPriority = {
  LOW: 'Low',
  MEDIUM: 'Medium',
  HIGH: 'High',
  CRITICAL: 'Critical',
} as const;

export type RequestPriorityType = (typeof RequestPriority)[keyof typeof RequestPriority];

/**
 * Entity types (reporter, assignee)
 */
export const EntityType = {
  AGENT: 'agent',
  PRINCIPAL: 'principal',
  SYSTEM: 'system',
} as const;

export type EntityTypeValue = (typeof EntityType)[keyof typeof EntityType];

/**
 * Request entity
 */
export interface Request {
  id: number;
  requestId: string; // e.g., "REQUEST-jordan-0035"
  title: string;
  summary: string;
  status: RequestStatusType;
  priority: RequestPriorityType;

  // Attribution
  principalName: string; // The principal who requested this
  reporterType: EntityTypeValue;
  reporterName: string;
  assigneeType: EntityTypeValue | null;
  assigneeName: string | null;

  // Organization
  workstream: string | null;
  tags: string[]; // Stored as JSON

  // Cross-references
  xrefType: string | null;
  xrefId: string | null;

  // File path (if synced from file system)
  filePath: string | null;

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Create request schema
 */
export const createRequestSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  summary: z.string().min(1, 'Summary is required'),
  principalName: z.string().min(1, 'Principal name is required'),
  priority: z.enum(['Low', 'Medium', 'High', 'Critical']).default('Medium'),
  reporterType: z.enum(['agent', 'principal', 'system']).default('principal'),
  reporterName: z.string().min(1, 'Reporter name is required'),
  assigneeType: z.enum(['agent', 'principal']).optional(),
  assigneeName: z.string().optional(),
  workstream: z.string().optional(),
  tags: z.array(z.string()).default([]),
  xrefType: z.string().optional(),
  xrefId: z.string().optional(),
});

export type CreateRequestInput = z.infer<typeof createRequestSchema>;

/**
 * Update request schema
 */
export const updateRequestSchema = z.object({
  title: z.string().min(1).optional(),
  summary: z.string().optional(),
  status: z.enum(['Open', 'In Progress', 'Review', 'Testing', 'Complete', 'On Hold', 'Cancelled']).optional(),
  priority: z.enum(['Low', 'Medium', 'High', 'Critical']).optional(),
  assigneeType: z.enum(['agent', 'principal']).nullable().optional(),
  assigneeName: z.string().nullable().optional(),
  workstream: z.string().nullable().optional(),
  tags: z.array(z.string()).optional(),
});

export type UpdateRequestInput = z.infer<typeof updateRequestSchema>;

/**
 * Sort fields for list query
 */
export const SortField = {
  CREATED_AT: 'createdAt',
  UPDATED_AT: 'updatedAt',
  TITLE: 'title',
  STATUS: 'status',
  PRIORITY: 'priority',
} as const;

export type SortFieldType = (typeof SortField)[keyof typeof SortField];

/**
 * Sort order
 */
export const SortOrder = {
  ASC: 'asc',
  DESC: 'desc',
} as const;

export type SortOrderType = (typeof SortOrder)[keyof typeof SortOrder];

/**
 * List requests query parameters (unified schema)
 */
export const listRequestsQuerySchema = z.object({
  // Filters
  status: z.string().optional(),
  priority: z.string().optional(),
  principal: z.string().optional(),
  assignee: z.string().optional(),
  reporter: z.string().optional(),
  workstream: z.string().optional(),
  tags: z.string().optional(), // Comma-separated

  // Sorting
  sortBy: z.enum(['createdAt', 'updatedAt', 'title', 'status', 'priority']).default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),

  // Search
  search: z.string().optional(),

  // Pagination
  limit: z.coerce.number().min(1).max(100).default(50),
  offset: z.coerce.number().min(0).default(0),
});

export type ListRequestsQuery = z.infer<typeof listRequestsQuerySchema>;

/**
 * Request list response
 */
export interface RequestListResponse {
  requests: Request[];
  total: number;
  limit: number;
  offset: number;
}

/**
 * Request stats
 */
export interface RequestStats {
  total: number;
  open: number;
  inProgress: number;
  review: number;
  testing: number;
  complete: number;
  onHold: number;
  cancelled: number;
  byPriority: {
    low: number;
    medium: number;
    high: number;
    critical: number;
  };
}
