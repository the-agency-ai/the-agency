/**
 * Bug Repository
 *
 * Data access layer for bugs. Uses the database adapter interface.
 * Business logic stays in the service layer.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import type { Bug, BugAttachment, CreateBugRequest, UpdateBugRequest, ListBugsQuery, BugStats } from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('bug-repository');

/**
 * Database row types (snake_case as stored in SQLite)
 */
interface BugRow {
  id: number;
  bug_id: string;
  workstream: string;
  summary: string;
  description: string | null;
  status: string;
  reporter_type: string;
  reporter_name: string;
  assignee_type: string | null;
  assignee_name: string | null;
  xref_type: string | null;
  xref_id: string | null;
  tags: string; // JSON array
  created_at: string;
  updated_at: string;
}

interface SequenceRow {
  workstream: string;
  next_id: number;
}

/**
 * Safely parse JSON with fallback to empty array
 */
function safeParseJsonArray(json: string | null | undefined): string[] {
  if (!json) return [];
  try {
    const parsed = JSON.parse(json);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    logger.warn({ json }, 'Failed to parse tags JSON, returning empty array');
    return [];
  }
}

/**
 * Escape special characters for SQL LIKE patterns
 */
function escapeLikePattern(pattern: string): string {
  return pattern
    .replace(/\\/g, '\\\\')
    .replace(/%/g, '\\%')
    .replace(/_/g, '\\_');
}

/**
 * Validate and normalize sort direction
 */
function normalizeSortDirection(direction: string): 'ASC' | 'DESC' {
  const upper = direction.toUpperCase();
  return upper === 'DESC' ? 'DESC' : 'ASC';
}

/**
 * Map sortBy field to database column
 */
function getSortColumn(sortBy: string): string {
  const mapping: Record<string, string> = {
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    summary: 'summary',
    status: 'status',
    workstream: 'workstream',
  };
  return mapping[sortBy] || 'created_at';
}

/**
 * Convert database row to Bug entity
 */
function rowToBug(row: BugRow): Bug {
  return {
    id: row.id,
    bugId: row.bug_id,
    workstream: row.workstream,
    summary: row.summary,
    description: row.description,
    status: row.status as Bug['status'],
    reporterType: row.reporter_type as Bug['reporterType'],
    reporterName: row.reporter_name,
    assigneeType: row.assignee_type as Bug['assigneeType'],
    assigneeName: row.assignee_name,
    xrefType: row.xref_type,
    xrefId: row.xref_id,
    tags: safeParseJsonArray(row.tags),
    createdAt: new Date(row.created_at),
    updatedAt: new Date(row.updated_at),
  };
}

export class BugRepository {
  constructor(private db: DatabaseAdapter) {}

  /**
   * Initialize the bugs schema
   */
  async initialize(): Promise<void> {
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS bugs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bug_id TEXT UNIQUE NOT NULL,
        workstream TEXT NOT NULL,
        summary TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'Open',
        reporter_type TEXT NOT NULL,
        reporter_name TEXT NOT NULL,
        assignee_type TEXT,
        assignee_name TEXT,
        xref_type TEXT,
        xref_id TEXT,
        tags TEXT DEFAULT '[]',
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
      )
    `);

    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS bug_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bug_id TEXT NOT NULL,
        filename TEXT NOT NULL,
        filepath TEXT NOT NULL,
        mime_type TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (bug_id) REFERENCES bugs(bug_id)
      )
    `);

    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS bug_sequences (
        workstream TEXT PRIMARY KEY,
        next_id INTEGER DEFAULT 1
      )
    `);

    // Create indexes
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_bugs_workstream ON bugs(workstream)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_bugs_status ON bugs(status)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_bugs_assignee ON bugs(assignee_name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_bugs_reporter ON bugs(reporter_name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_bugs_created ON bugs(created_at)`);

    logger.info('Bug schema initialized');
  }

  /**
   * Get the next bug ID for a workstream
   * Uses atomic UPSERT with RETURNING to prevent race conditions
   */
  async getNextBugId(workstream: string): Promise<string> {
    const upperWorkstream = workstream.toUpperCase();

    // Use UPSERT with RETURNING to atomically create/increment and get the reserved ID
    // The INSERT sets next_id to 2 (reserving 1), UPDATE increments and we read pre-increment value
    const row = await this.db.get<{ reserved_id: number }>(
      `INSERT INTO bug_sequences (workstream, next_id) VALUES (?, 2)
       ON CONFLICT(workstream) DO UPDATE SET next_id = next_id + 1
       RETURNING next_id - 1 as reserved_id`,
      [upperWorkstream]
    );

    const nextId = row?.reserved_id ?? 1;

    // Format: BENCH-00001
    return `${upperWorkstream}-${String(nextId).padStart(5, '0')}`;
  }

  /**
   * Create a new bug
   */
  async create(bugId: string, data: CreateBugRequest): Promise<Bug> {
    const upperWorkstream = data.workstream.toUpperCase();

    await this.db.execute(
      `INSERT INTO bugs (
        bug_id, workstream, summary, description, status,
        reporter_type, reporter_name, assignee_type, assignee_name,
        xref_type, xref_id, tags
      ) VALUES (?, ?, ?, ?, 'Open', ?, ?, ?, ?, ?, ?, ?)`,
      [
        bugId,
        upperWorkstream,
        data.summary,
        data.description || null,
        data.reporterType,
        data.reporterName,
        data.assigneeType || null,
        data.assigneeName || null,
        data.xrefType || null,
        data.xrefId || null,
        JSON.stringify(data.tags || []),
      ]
    );

    const bug = await this.findByBugId(bugId);
    if (!bug) {
      throw new Error(`Failed to create bug ${bugId}`);
    }

    logger.info({ bugId }, 'Bug created');
    return bug;
  }

  /**
   * Find a bug by its bug_id (e.g., "BENCH-00001")
   */
  async findByBugId(bugId: string): Promise<Bug | null> {
    const row = await this.db.get<BugRow>(
      'SELECT * FROM bugs WHERE bug_id = ?',
      [bugId]
    );
    return row ? rowToBug(row) : null;
  }

  /**
   * Find a bug by its internal id
   */
  async findById(id: number): Promise<Bug | null> {
    const row = await this.db.get<BugRow>(
      'SELECT * FROM bugs WHERE id = ?',
      [id]
    );
    return row ? rowToBug(row) : null;
  }

  /**
   * List bugs with filtering, sorting, search, and pagination
   */
  async list(query: ListBugsQuery): Promise<{ bugs: Bug[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];

    if (query.workstream) {
      conditions.push('workstream = ?');
      params.push(query.workstream.toUpperCase());
    }

    if (query.status) {
      conditions.push('status = ?');
      params.push(query.status);
    }

    if (query.assignee) {
      conditions.push('assignee_name = ?');
      params.push(query.assignee);
    }

    if (query.reporter) {
      conditions.push('reporter_name = ?');
      params.push(query.reporter);
    }

    if (query.tags) {
      const tagList = query.tags.split(',').map(t => t.trim());
      const tagConditions = tagList.map(() => "tags LIKE ? ESCAPE '\\'");
      conditions.push(`(${tagConditions.join(' OR ')})`);
      tagList.forEach(tag => {
        const escaped = escapeLikePattern(tag);
        params.push(`%"${escaped}"%`);
      });
    }

    // Search (in summary and description)
    if (query.search) {
      conditions.push("(summary LIKE ? ESCAPE '\\' OR description LIKE ? ESCAPE '\\')");
      const escaped = escapeLikePattern(query.search);
      const searchPattern = `%${escaped}%`;
      params.push(searchPattern, searchPattern);
    }

    const whereClause = conditions.length > 0
      ? `WHERE ${conditions.join(' AND ')}`
      : '';

    // Get total count
    const countRow = await this.db.get<{ count: number }>(
      `SELECT COUNT(*) as count FROM bugs ${whereClause}`,
      params
    );
    const total = countRow?.count ?? 0;

    // Sorting - validate direction to prevent SQL injection
    const sortColumn = getSortColumn(query.sortBy || 'createdAt');
    const sortDirection = normalizeSortDirection(query.sortOrder || 'desc');

    // Get paginated results
    const rows = await this.db.query<BugRow>(
      `SELECT * FROM bugs ${whereClause}
       ORDER BY ${sortColumn} ${sortDirection}
       LIMIT ? OFFSET ?`,
      [...params, query.limit, query.offset]
    );

    return {
      bugs: rows.map(rowToBug),
      total,
    };
  }

  /**
   * Update a bug
   */
  async update(bugId: string, data: UpdateBugRequest): Promise<Bug | null> {
    const sets: string[] = [];
    const params: unknown[] = [];

    if (data.summary !== undefined) {
      sets.push('summary = ?');
      params.push(data.summary);
    }

    if (data.description !== undefined) {
      sets.push('description = ?');
      params.push(data.description);
    }

    if (data.status !== undefined) {
      sets.push('status = ?');
      params.push(data.status);
    }

    if (data.assigneeType !== undefined) {
      sets.push('assignee_type = ?');
      params.push(data.assigneeType);
    }

    if (data.assigneeName !== undefined) {
      sets.push('assignee_name = ?');
      params.push(data.assigneeName);
    }

    if (data.tags !== undefined) {
      sets.push('tags = ?');
      params.push(JSON.stringify(data.tags));
    }

    if (sets.length === 0) {
      return this.findByBugId(bugId);
    }

    sets.push("updated_at = datetime('now')");
    params.push(bugId);

    await this.db.execute(
      `UPDATE bugs SET ${sets.join(', ')} WHERE bug_id = ?`,
      params
    );

    logger.info({ bugId, updates: Object.keys(data) }, 'Bug updated');
    return this.findByBugId(bugId);
  }

  /**
   * Delete a bug
   */
  async delete(bugId: string): Promise<boolean> {
    // Delete attachments first
    await this.db.execute('DELETE FROM bug_attachments WHERE bug_id = ?', [bugId]);

    const changes = await this.db.delete(
      'DELETE FROM bugs WHERE bug_id = ?',
      [bugId]
    );

    if (changes > 0) {
      logger.info({ bugId }, 'Bug deleted');
    }

    return changes > 0;
  }

  /**
   * Get stats for dashboard
   */
  async getStats(): Promise<BugStats> {
    const rows = await this.db.query<{ status: string; count: number }>(
      `SELECT status, COUNT(*) as count FROM bugs GROUP BY status`
    );

    const stats: BugStats = {
      total: 0,
      open: 0,
      inProgress: 0,
      fixed: 0,
      wontFix: 0,
    };

    for (const row of rows) {
      stats.total += row.count;
      switch (row.status) {
        case 'Open':
          stats.open = row.count;
          break;
        case 'In Progress':
          stats.inProgress = row.count;
          break;
        case 'Fixed':
          stats.fixed = row.count;
          break;
        case "Won't Fix":
          stats.wontFix = row.count;
          break;
      }
    }

    return stats;
  }
}
