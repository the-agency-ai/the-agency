/**
 * Log Repository
 *
 * Data access layer for logs. Uses SQLite with FTS5 for full-text search.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import type {
  LogEntry,
  ToolRun,
  CreateLogEntryRequest,
  CreateToolRunRequest,
  EndToolRunRequest,
  QueryLogsRequest,
  LogStats,
  LogLevelType,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';
import { randomUUID } from 'crypto';

const logger = createServiceLogger('log-repository');

/**
 * Database row types
 */
interface LogEntryRow {
  id: number;
  timestamp: string;
  service: string;
  level: string;
  message: string;
  run_id: string | null;
  request_id: string | null;
  user_id: string | null;
  user_type: string | null;
  data: string | null;
  error_name: string | null;
  error_message: string | null;
  error_stack: string | null;
}

interface ToolRunRow {
  id: number;
  run_id: string;
  tool: string;
  started_at: string;
  ended_at: string | null;
  status: string;
  summary: string | null;
  user_id: string | null;
  user_type: string | null;
  // REQUEST-0012 additions
  tool_type: string | null;
  args: string | null;        // JSON array
  agent_name: string | null;
  workstream: string | null;
  exit_code: number | null;
  output_size: number | null;
}

/**
 * Convert database row to LogEntry entity
 */
function rowToLogEntry(row: LogEntryRow): LogEntry {
  const entry: LogEntry = {
    id: row.id,
    timestamp: new Date(row.timestamp),
    service: row.service,
    level: row.level as LogLevelType,
    message: row.message,
  };

  if (row.run_id) entry.runId = row.run_id;
  if (row.request_id) entry.requestId = row.request_id;
  if (row.user_id) entry.userId = row.user_id;
  if (row.user_type) entry.userType = row.user_type as LogEntry['userType'];
  if (row.data) {
    try {
      entry.data = JSON.parse(row.data);
    } catch {
      // Ignore parse errors
    }
  }
  if (row.error_name) {
    entry.error = {
      name: row.error_name,
      message: row.error_message || '',
      stack: row.error_stack || undefined,
    };
  }

  return entry;
}

/**
 * Convert database row to ToolRun entity (Enhanced per REQUEST-0012)
 */
function rowToToolRun(row: ToolRunRow): ToolRun {
  const startedAt = new Date(row.started_at);
  const endedAt = row.ended_at ? new Date(row.ended_at) : undefined;

  const run: ToolRun = {
    runId: row.run_id,
    tool: row.tool,
    startedAt,
    endedAt,
    status: row.status as ToolRun['status'],
    summary: row.summary || undefined,
    userId: row.user_id || undefined,
    userType: row.user_type as ToolRun['userType'],
  };

  // REQUEST-0012 additions
  if (row.tool_type) run.toolType = row.tool_type as ToolRun['toolType'];
  if (row.args) {
    try {
      run.args = JSON.parse(row.args);
    } catch {
      // Ignore parse errors
    }
  }
  if (row.agent_name) run.agentName = row.agent_name;
  if (row.workstream) run.workstream = row.workstream;
  if (row.exit_code !== null) run.exitCode = row.exit_code;
  if (row.output_size !== null) run.outputSize = row.output_size;

  // Calculate duration if we have both start and end times
  if (endedAt) {
    run.duration = endedAt.getTime() - startedAt.getTime();
  }

  return run;
}

export class LogRepository {
  constructor(private db: DatabaseAdapter) {}

  /**
   * Initialize the log schema
   */
  async initialize(): Promise<void> {
    // Main log entries table
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS log_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT DEFAULT (datetime('now')),
        service TEXT NOT NULL,
        level TEXT NOT NULL DEFAULT 'info',
        message TEXT NOT NULL,
        run_id TEXT,
        request_id TEXT,
        user_id TEXT,
        user_type TEXT,
        data TEXT,
        error_name TEXT,
        error_message TEXT,
        error_stack TEXT
      )
    `);

    // Full-text search virtual table
    await this.db.execute(`
      CREATE VIRTUAL TABLE IF NOT EXISTS log_entries_fts USING fts5(
        message,
        content='log_entries',
        content_rowid='id'
      )
    `);

    // Triggers to keep FTS in sync
    await this.db.execute(`
      CREATE TRIGGER IF NOT EXISTS log_entries_ai AFTER INSERT ON log_entries BEGIN
        INSERT INTO log_entries_fts(rowid, message) VALUES (new.id, new.message);
      END
    `);

    await this.db.execute(`
      CREATE TRIGGER IF NOT EXISTS log_entries_ad AFTER DELETE ON log_entries BEGIN
        INSERT INTO log_entries_fts(log_entries_fts, rowid, message) VALUES('delete', old.id, old.message);
      END
    `);

    await this.db.execute(`
      CREATE TRIGGER IF NOT EXISTS log_entries_au AFTER UPDATE ON log_entries BEGIN
        INSERT INTO log_entries_fts(log_entries_fts, rowid, message) VALUES('delete', old.id, old.message);
        INSERT INTO log_entries_fts(rowid, message) VALUES (new.id, new.message);
      END
    `);

    // Tool runs table (Enhanced per REQUEST-0012)
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS tool_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        run_id TEXT UNIQUE NOT NULL,
        tool TEXT NOT NULL,
        started_at TEXT DEFAULT (datetime('now')),
        ended_at TEXT,
        status TEXT DEFAULT 'running',
        summary TEXT,
        user_id TEXT,
        user_type TEXT,
        -- REQUEST-0012 additions
        tool_type TEXT,       -- agency-tool, bash, mcp
        args TEXT,            -- JSON array of arguments
        agent_name TEXT,      -- Which agent made the call
        workstream TEXT,      -- Work context
        exit_code INTEGER,    -- Process exit code (0-255)
        output_size INTEGER   -- Output size in bytes
      )
    `);

    // Migration: add new columns if they don't exist (for existing DBs)
    const columns = ['tool_type', 'args', 'agent_name', 'workstream', 'exit_code', 'output_size'];
    for (const col of columns) {
      try {
        await this.db.execute(`ALTER TABLE tool_runs ADD COLUMN ${col} ${col.includes('code') || col.includes('size') ? 'INTEGER' : 'TEXT'}`);
      } catch {
        // Column already exists, ignore
      }
    }

    // Indexes
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_log_timestamp ON log_entries(timestamp DESC)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_log_service ON log_entries(service)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_log_level ON log_entries(level)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_log_run_id ON log_entries(run_id)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_log_request_id ON log_entries(request_id)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_tool_runs_run_id ON tool_runs(run_id)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_tool_runs_tool ON tool_runs(tool)`);

    logger.info('Log schema initialized');
  }

  /**
   * Create a log entry
   */
  async create(data: CreateLogEntryRequest): Promise<LogEntry> {
    const dataJson = data.data ? JSON.stringify(data.data) : null;

    await this.db.execute(
      `INSERT INTO log_entries (
        service, level, message, run_id, request_id, user_id, user_type,
        data, error_name, error_message, error_stack
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        data.service,
        data.level || 'info',
        data.message,
        data.runId || null,
        data.requestId || null,
        data.userId || null,
        data.userType || null,
        dataJson,
        data.error?.name || null,
        data.error?.message || null,
        data.error?.stack || null,
      ]
    );

    const row = await this.db.get<LogEntryRow>(
      'SELECT * FROM log_entries WHERE id = last_insert_rowid()'
    );

    return rowToLogEntry(row!);
  }

  /**
   * Create multiple log entries
   */
  async createBatch(entries: CreateLogEntryRequest[]): Promise<number> {
    let count = 0;
    for (const entry of entries) {
      await this.create(entry);
      count++;
    }
    return count;
  }

  /**
   * Query logs with filters
   */
  async query(params: QueryLogsRequest): Promise<{ logs: LogEntry[]; total: number }> {
    const conditions: string[] = [];
    const queryParams: unknown[] = [];

    if (params.service) {
      conditions.push('service = ?');
      queryParams.push(params.service);
    }

    if (params.level) {
      conditions.push('level = ?');
      queryParams.push(params.level);
    }

    if (params.runId) {
      conditions.push('run_id = ?');
      queryParams.push(params.runId);
    }

    if (params.requestId) {
      conditions.push('request_id = ?');
      queryParams.push(params.requestId);
    }

    if (params.userId) {
      conditions.push('user_id = ?');
      queryParams.push(params.userId);
    }

    if (params.since) {
      const since = this.parseSince(params.since);
      if (since) {
        conditions.push('timestamp >= ?');
        queryParams.push(since.toISOString());
      }
    }

    if (params.until) {
      conditions.push('timestamp <= ?');
      queryParams.push(params.until);
    }

    // Full-text search
    let usesFts = false;
    if (params.search) {
      usesFts = true;
    }

    const whereClause = conditions.length > 0
      ? `WHERE ${conditions.join(' AND ')}`
      : '';

    let baseQuery: string;
    let countQuery: string;

    if (usesFts) {
      baseQuery = `
        FROM log_entries e
        JOIN log_entries_fts fts ON e.id = fts.rowid
        ${whereClause}${whereClause ? ' AND' : 'WHERE'} log_entries_fts MATCH ?
      `;
      countQuery = `SELECT COUNT(*) as count ${baseQuery}`;
      queryParams.push(params.search);
    } else {
      baseQuery = `FROM log_entries e ${whereClause}`;
      countQuery = `SELECT COUNT(*) as count ${baseQuery}`;
    }

    // Get total count
    const countRow = await this.db.get<{ count: number }>(countQuery, queryParams);
    const total = countRow?.count ?? 0;

    // Get paginated results
    const paginatedParams = [...queryParams, params.limit, params.offset];
    const rows = await this.db.query<LogEntryRow>(
      `SELECT e.* ${baseQuery} ORDER BY e.timestamp DESC LIMIT ? OFFSET ?`,
      paginatedParams
    );

    return {
      logs: rows.map(rowToLogEntry),
      total,
    };
  }

  /**
   * Get logs by run ID
   */
  async getByRunId(runId: string): Promise<LogEntry[]> {
    const rows = await this.db.query<LogEntryRow>(
      'SELECT * FROM log_entries WHERE run_id = ? ORDER BY timestamp ASC',
      [runId]
    );
    return rows.map(rowToLogEntry);
  }

  /**
   * Get log statistics
   */
  async getStats(): Promise<LogStats> {
    const totalRow = await this.db.get<{ count: number }>(
      'SELECT COUNT(*) as count FROM log_entries'
    );

    const levelRows = await this.db.query<{ level: string; count: number }>(
      'SELECT level, COUNT(*) as count FROM log_entries GROUP BY level'
    );

    const serviceRows = await this.db.query<{ service: string; count: number }>(
      'SELECT service, COUNT(*) as count FROM log_entries GROUP BY service ORDER BY count DESC LIMIT 10'
    );

    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    const errorsRow = await this.db.get<{ count: number }>(
      `SELECT COUNT(*) as count FROM log_entries WHERE level IN ('error', 'fatal') AND timestamp >= ?`,
      [oneHourAgo]
    );

    const byLevel: Record<string, number> = {
      trace: 0,
      debug: 0,
      info: 0,
      warn: 0,
      error: 0,
      fatal: 0,
    };
    for (const row of levelRows) {
      byLevel[row.level] = row.count;
    }

    const byService: Record<string, number> = {};
    for (const row of serviceRows) {
      byService[row.service] = row.count;
    }

    return {
      total: totalRow?.count ?? 0,
      byLevel: byLevel as Record<LogLevelType, number>,
      byService,
      errorsLastHour: errorsRow?.count ?? 0,
    };
  }

  /**
   * Get services that have logs
   */
  async getServices(): Promise<string[]> {
    const rows = await this.db.query<{ service: string }>(
      'SELECT DISTINCT service FROM log_entries ORDER BY service'
    );
    return rows.map(r => r.service);
  }

  /**
   * Create a tool run (Enhanced per REQUEST-0012)
   */
  async createToolRun(data: CreateToolRunRequest): Promise<ToolRun> {
    const runId = randomUUID();
    const argsJson = data.args ? JSON.stringify(data.args) : null;

    await this.db.execute(
      `INSERT INTO tool_runs (run_id, tool, user_id, user_type, tool_type, args, agent_name, workstream)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        runId,
        data.tool,
        data.userId || null,
        data.userType || null,
        data.toolType || null,
        argsJson,
        data.agentName || null,
        data.workstream || null,
      ]
    );

    const row = await this.db.get<ToolRunRow>(
      'SELECT * FROM tool_runs WHERE run_id = ?',
      [runId]
    );

    logger.debug({ runId, tool: data.tool, toolType: data.toolType }, 'Tool run started');
    return rowToToolRun(row!);
  }

  /**
   * End a tool run (Enhanced per REQUEST-0012)
   */
  async endToolRun(runId: string, data: EndToolRunRequest): Promise<ToolRun | null> {
    const existing = await this.db.get<ToolRunRow>(
      'SELECT * FROM tool_runs WHERE run_id = ?',
      [runId]
    );

    if (!existing) {
      return null;
    }

    await this.db.update(
      `UPDATE tool_runs SET ended_at = datetime('now'), status = ?, summary = ?, exit_code = ?, output_size = ?
       WHERE run_id = ?`,
      [
        data.status,
        data.summary || null,
        data.exitCode ?? null,
        data.outputSize ?? null,
        runId,
      ]
    );

    const row = await this.db.get<ToolRunRow>(
      'SELECT * FROM tool_runs WHERE run_id = ?',
      [runId]
    );

    logger.debug({ runId, status: data.status, exitCode: data.exitCode, outputSize: data.outputSize }, 'Tool run ended');
    return rowToToolRun(row!);
  }

  /**
   * Get a tool run by ID
   */
  async getToolRun(runId: string): Promise<ToolRun | null> {
    const row = await this.db.get<ToolRunRow>(
      'SELECT * FROM tool_runs WHERE run_id = ?',
      [runId]
    );
    return row ? rowToToolRun(row) : null;
  }

  /**
   * Clean up old logs (retention)
   */
  async cleanup(daysToKeep: number = 30): Promise<number> {
    const cutoff = new Date(Date.now() - daysToKeep * 24 * 60 * 60 * 1000).toISOString();

    const count = await this.db.delete(
      'DELETE FROM log_entries WHERE timestamp < ?',
      [cutoff]
    );

    await this.db.delete(
      'DELETE FROM tool_runs WHERE ended_at < ?',
      [cutoff]
    );

    if (count > 0) {
      logger.info({ deleted: count, daysToKeep }, 'Old logs cleaned up');
    }

    return count;
  }

  /**
   * Parse relative time strings
   */
  private parseSince(since: string): Date | null {
    if (since.includes('T') || since.includes('-')) {
      const date = new Date(since);
      return isNaN(date.getTime()) ? null : date;
    }

    const match = since.match(/^(\d+)([mhdw])$/);
    if (!match) {
      return null;
    }

    const [, amount, unit] = match;
    const now = new Date();
    const ms = {
      m: 60 * 1000,
      h: 60 * 60 * 1000,
      d: 24 * 60 * 60 * 1000,
      w: 7 * 24 * 60 * 60 * 1000,
    }[unit];

    if (!ms) {
      return null;
    }

    return new Date(now.getTime() - parseInt(amount, 10) * ms);
  }
}
