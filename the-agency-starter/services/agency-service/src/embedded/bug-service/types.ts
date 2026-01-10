/**
 * Bug Bench Service Types
 *
 * Domain models for bug tracking.
 */

import { z } from 'zod';

/**
 * Bug status values
 */
export const BugStatus = {
  OPEN: 'Open',
  IN_PROGRESS: 'In Progress',
  FIXED: 'Fixed',
  WONT_FIX: "Won't Fix",
} as const;

export type BugStatusType = (typeof BugStatus)[keyof typeof BugStatus];

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
 * Bug entity
 */
export interface Bug {
  id: number;
  bugId: string; // e.g., "BENCH-00001"
  workstream: string;
  summary: string;
  description: string | null;
  status: BugStatusType;
  reporterType: EntityTypeValue;
  reporterName: string;
  assigneeType: EntityTypeValue | null;
  assigneeName: string | null;
  xrefType: string | null;
  xrefId: string | null;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Bug attachment
 */
export interface BugAttachment {
  id: number;
  bugId: string;
  filename: string;
  filepath: string;
  mimeType: string | null;
  createdAt: Date;
}

/**
 * Create bug request schema
 */
export const createBugSchema = z.object({
  workstream: z.string().min(1, 'Workstream is required'),
  summary: z.string().min(1, 'Summary is required'),
  description: z.string().optional(),
  reporterType: z.enum(['agent', 'principal', 'system']).default('agent'),
  reporterName: z.string().min(1, 'Reporter name is required'),
  assigneeType: z.enum(['agent', 'principal']).optional(),
  assigneeName: z.string().optional(),
  xrefType: z.string().optional(),
  xrefId: z.string().optional(),
});

export type CreateBugRequest = z.infer<typeof createBugSchema>;

/**
 * Update bug request schema
 */
export const updateBugSchema = z.object({
  summary: z.string().min(1).optional(),
  description: z.string().optional(),
  status: z.enum(['Open', 'In Progress', 'Fixed', "Won't Fix"]).optional(),
  assigneeType: z.enum(['agent', 'principal']).nullable().optional(),
  assigneeName: z.string().nullable().optional(),
});

export type UpdateBugRequest = z.infer<typeof updateBugSchema>;

/**
 * List bugs query parameters
 */
export const listBugsQuerySchema = z.object({
  workstream: z.string().optional(),
  status: z.string().optional(),
  assignee: z.string().optional(),
  reporter: z.string().optional(),
  limit: z.coerce.number().min(1).max(100).default(50),
  offset: z.coerce.number().min(0).default(0),
});

export type ListBugsQuery = z.infer<typeof listBugsQuerySchema>;

/**
 * Bug list response
 */
export interface BugListResponse {
  bugs: Bug[];
  total: number;
  limit: number;
  offset: number;
}
