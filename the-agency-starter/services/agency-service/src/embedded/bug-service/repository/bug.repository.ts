/**
 * Bug Repository
 *
 * Data access layer for bugs. Uses the database adapter interface.
 * Business logic stays in the service layer.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import type { Bug, BugAttachment, CreateBugRequest, UpdateBugRequest, ListBugsQuery } from '../types';
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
  created_at: string;
  updated_at: string;
}

interface SequenceRow {
  workstream: string;
  next_id: number;
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

    logger.info('Bug schema initialized');
  }

  /**
   * Get the next bug ID for a workstream
   */
  async getNextBugId(workstream: string): Promise<string> {
    const upperWorkstream = workstream.toUpperCase();

    // Get or create sequence
    let row = await this.db.get<SequenceRow>(
      'SELECT * FROM bug_sequences WHERE workstream = ?',
      [upperWorkstream]
    );

    let nextId: number;
    if (!row) {
      nextId = 1;
      await this.db.execute(
        'INSERT INTO bug_sequences (workstream, next_id) VALUES (?, 2)',
        [upperWorkstream]
      );
    } else {
      nextId = row.next_id;
      await this.db.execute(
        'UPDATE bug_sequences SET next_id = next_id + 1 WHERE workstream = ?',
        [upperWorkstream]
      );
    }

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
        xref_type, xref_id
      ) VALUES (?, ?, ?, ?, 'Open', ?, ?, ?, ?, ?, ?)`,
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
   * List bugs with optional filtering
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

    const whereClause = conditions.length > 0
      ? `WHERE ${conditions.join(' AND ')}`
      : '';

    // Get total count
    const countRow = await this.db.get<{ count: number }>(
      `SELECT COUNT(*) as count FROM bugs ${whereClause}`,
      params
    );
    const total = countRow?.count ?? 0;

    // Get paginated results
    const rows = await this.db.query<BugRow>(
      `SELECT * FROM bugs ${whereClause}
       ORDER BY created_at DESC
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
  async getStats(): Promise<{
    total: number;
    open: number;
    inProgress: number;
    fixed: number;
  }> {
    const rows = await this.db.query<{ status: string; count: number }>(
      `SELECT status, COUNT(*) as count FROM bugs GROUP BY status`
    );

    const stats = {
      total: 0,
      open: 0,
      inProgress: 0,
      fixed: 0,
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
      }
    }

    return stats;
  }
}
