/**
 * Log Service Types
 *
 * Domain models for log aggregation and querying.
 */

import { z } from 'zod';

/**
 * Log levels
 */
export const LogLevel = {
  TRACE: 'trace',
  DEBUG: 'debug',
  INFO: 'info',
  WARN: 'warn',
  ERROR: 'error',
  FATAL: 'fatal',
} as const;

export type LogLevelType = (typeof LogLevel)[keyof typeof LogLevel];

/**
 * User types for log context
 */
export const UserType = {
  AGENT: 'agent',
  PRINCIPAL: 'principal',
  SYSTEM: 'system',
} as const;

export type UserTypeValue = (typeof UserType)[keyof typeof UserType];

/**
 * Log entry entity
 */
export interface LogEntry {
  id: number;
  timestamp: Date;
  service: string;
  level: LogLevelType;
  message: string;

  // Context
  runId?: string;      // Tool run ID for correlation
  requestId?: string;  // HTTP request correlation
  userId?: string;
  userType?: UserTypeValue;

  // Structured data
  data?: Record<string, unknown>;

  // Error info
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
}

/**
 * Create log entry request schema
 */
export const createLogEntrySchema = z.object({
  service: z.string().min(1, 'Service name is required'),
  level: z.enum(['trace', 'debug', 'info', 'warn', 'error', 'fatal']).default('info'),
  message: z.string().min(1, 'Message is required'),

  // Context
  runId: z.string().optional(),
  requestId: z.string().optional(),
  userId: z.string().optional(),
  userType: z.enum(['agent', 'principal', 'system']).optional(),

  // Structured data
  data: z.record(z.unknown()).optional(),

  // Error info
  error: z.object({
    name: z.string(),
    message: z.string(),
    stack: z.string().optional(),
  }).optional(),
});

export type CreateLogEntryRequest = z.infer<typeof createLogEntrySchema>;

/**
 * Batch create log entries schema
 */
export const batchCreateLogEntriesSchema = z.object({
  entries: z.array(createLogEntrySchema).min(1).max(1000),
});

export type BatchCreateLogEntriesRequest = z.infer<typeof batchCreateLogEntriesSchema>;

/**
 * Query logs parameters
 */
export const queryLogsSchema = z.object({
  service: z.string().optional(),
  level: z.enum(['trace', 'debug', 'info', 'warn', 'error', 'fatal']).optional(),
  runId: z.string().optional(),
  requestId: z.string().optional(),
  userId: z.string().optional(),
  search: z.string().optional(),         // Full-text search in message
  since: z.string().optional(),           // ISO timestamp or relative (1h, 24h, 7d)
  until: z.string().optional(),           // ISO timestamp
  limit: z.coerce.number().min(1).max(1000).default(100),
  offset: z.coerce.number().min(0).default(0),
});

export type QueryLogsRequest = z.infer<typeof queryLogsSchema>;

/**
 * Log list response
 */
export interface LogListResponse {
  logs: LogEntry[];
  total: number;
  limit: number;
  offset: number;
}

/**
 * Log stats response
 */
export interface LogStats {
  total: number;
  byLevel: Record<LogLevelType, number>;
  byService: Record<string, number>;
  errorsLastHour: number;
}

/**
 * Tool types for categorization (REQUEST-0012)
 */
export const ToolType = {
  AGENCY_TOOL: 'agency-tool',  // ./tools/* commands
  BASH: 'bash',                // Shell commands
  MCP: 'mcp',                  // MCP tool calls
} as const;

export type ToolTypeValue = (typeof ToolType)[keyof typeof ToolType];

/**
 * Tool run tracking (Enhanced per REQUEST-0012)
 *
 * Captures detailed tool invocation data for:
 * - Understanding agent behavior
 * - Identifying high-frequency tool usage patterns
 * - Finding opportunities to reduce context/token usage
 * - Making better, more effective tools
 */
export interface ToolRun {
  runId: string;
  tool: string;
  startedAt: Date;
  endedAt?: Date;
  status: 'running' | 'success' | 'failure';
  summary?: string;
  userId?: string;
  userType?: UserTypeValue;

  // REQUEST-0012 additions
  toolType?: ToolTypeValue;     // agency-tool, bash, mcp
  args?: string[];              // Command arguments
  agentName?: string;           // Which agent made the call
  workstream?: string;          // Work context
  exitCode?: number;            // Process exit code (0-255)
  outputSize?: number;          // Output size in bytes (for context analysis)
  duration?: number;            // Duration in ms (calculated from start/end)
}

/**
 * Create tool run schema (Enhanced per REQUEST-0012)
 */
export const createToolRunSchema = z.object({
  tool: z.string().min(1),
  userId: z.string().optional(),
  userType: z.enum(['agent', 'principal', 'system']).optional(),

  // REQUEST-0012 additions
  toolType: z.enum(['agency-tool', 'bash', 'mcp']).optional(),
  args: z.array(z.string()).optional(),
  agentName: z.string().optional(),
  workstream: z.string().optional(),
});

export type CreateToolRunRequest = z.infer<typeof createToolRunSchema>;

/**
 * End tool run schema (Enhanced per REQUEST-0012)
 */
export const endToolRunSchema = z.object({
  status: z.enum(['success', 'failure']),
  summary: z.string().optional(),

  // REQUEST-0012 additions
  exitCode: z.number().int().min(0).max(255).optional(),
  outputSize: z.number().int().min(0).optional(),
});

export type EndToolRunRequest = z.infer<typeof endToolRunSchema>;
