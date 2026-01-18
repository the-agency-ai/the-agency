/**
 * Request Repository
 *
 * Data access layer for requests. Uses the database adapter interface.
 * Business logic stays in the service layer.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import type {
  Request,
  CreateRequestInput,
  UpdateRequestInput,
  ListRequestsQuery,
  RequestStats,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('request-repository');

/**
 * Database row types (snake_case as stored in SQLite)
 */
interface RequestRow {
  id: number;
  request_id: string;
  title: string;
  summary: string;
  status: string;
  priority: string;
  principal_name: string;
  reporter_type: string;
  reporter_name: string;
  assignee_type: string | null;
  assignee_name: string | null;
  workstream: string | null;
  tags: string; // JSON array
  xref_type: string | null;
  xref_id: string | null;
  file_path: string | null;
  created_at: string;
  updated_at: string;
}

interface SequenceRow {
  principal: string;
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
 * Prevents SQL injection via LIKE wildcards
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
 * Convert database row to Request entity
 */
function rowToRequest(row: RequestRow): Request {
  return {
    id: row.id,
    requestId: row.request_id,
    title: row.title,
    summary: row.summary,
    status: row.status as Request['status'],
    priority: row.priority as Request['priority'],
    principalName: row.principal_name,
    reporterType: row.reporter_type as Request['reporterType'],
    reporterName: row.reporter_name,
    assigneeType: row.assignee_type as Request['assigneeType'],
    assigneeName: row.assignee_name,
    workstream: row.workstream,
    tags: safeParseJsonArray(row.tags),
    xrefType: row.xref_type,
    xrefId: row.xref_id,
    filePath: row.file_path,
    createdAt: new Date(row.created_at),
    updatedAt: new Date(row.updated_at),
  };
}

/**
 * Map sortBy field to database column
 */
function getSortColumn(sortBy: string): string {
  const mapping: Record<string, string> = {
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    title: 'title',
    status: 'status',
    priority: 'priority',
  };
  return mapping[sortBy] || 'created_at';
}

export class RequestRepository {
  constructor(private db: DatabaseAdapter) {}

  /**
   * Initialize the requests schema
   */
  async initialize(): Promise<void> {
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        status TEXT DEFAULT 'Open',
        priority TEXT DEFAULT 'Medium',
        principal_name TEXT NOT NULL,
        reporter_type TEXT NOT NULL,
        reporter_name TEXT NOT NULL,
        assignee_type TEXT,
        assignee_name TEXT,
        workstream TEXT,
        tags TEXT DEFAULT '[]',
        xref_type TEXT,
        xref_id TEXT,
        file_path TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
      )
    `);

    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS request_sequences (
        principal TEXT PRIMARY KEY,
        next_id INTEGER DEFAULT 1
      )
    `);

    // Create indexes
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_requests_principal ON requests(principal_name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_requests_status ON requests(status)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_requests_priority ON requests(priority)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_requests_assignee ON requests(assignee_name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_requests_workstream ON requests(workstream)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_requests_created ON requests(created_at)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_requests_updated ON requests(updated_at)`);

    logger.info('Request schema initialized');
  }

  /**
   * Get the next request ID for a principal
   * Uses atomic UPSERT with RETURNING to prevent race conditions
   */
  async getNextRequestId(principal: string): Promise<string> {
    const lowerPrincipal = principal.toLowerCase();

    // Use UPSERT with RETURNING to atomically create/increment and get the reserved ID
    // INSERT starts at 2 (reserving 1), UPDATE increments and RETURNING gets pre-increment value
    const row = await this.db.get<{ reserved_id: number }>(
      `INSERT INTO request_sequences (principal, next_id) VALUES (?, 2)
       ON CONFLICT(principal) DO UPDATE SET next_id = next_id + 1
       RETURNING next_id - 1 as reserved_id`,
      [lowerPrincipal]
    );

    const nextId = row?.reserved_id ?? 1;

    // Format: REQUEST-jordan-0035
    return `REQUEST-${lowerPrincipal}-${String(nextId).padStart(4, '0')}`;
  }

  /**
   * Create a new request
   */
  async create(requestId: string, data: CreateRequestInput): Promise<Request> {
    await this.db.execute(
      `INSERT INTO requests (
        request_id, title, summary, status, priority,
        principal_name, reporter_type, reporter_name,
        assignee_type, assignee_name, workstream, tags,
        xref_type, xref_id
      ) VALUES (?, ?, ?, 'Open', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        requestId,
        data.title,
        data.summary,
        data.priority || 'Medium',
        data.principalName.toLowerCase(),
        data.reporterType,
        data.reporterName,
        data.assigneeType || null,
        data.assigneeName || null,
        data.workstream || null,
        JSON.stringify(data.tags || []),
        data.xrefType || null,
        data.xrefId || null,
      ]
    );

    const request = await this.findByRequestId(requestId);
    if (!request) {
      throw new Error(`Failed to create request ${requestId}`);
    }

    logger.info({ requestId }, 'Request created');
    return request;
  }

  /**
   * Find a request by its request_id (e.g., "REQUEST-jordan-0035")
   */
  async findByRequestId(requestId: string): Promise<Request | null> {
    const row = await this.db.get<RequestRow>(
      'SELECT * FROM requests WHERE request_id = ?',
      [requestId]
    );
    return row ? rowToRequest(row) : null;
  }

  /**
   * Find a request by its internal id
   */
  async findById(id: number): Promise<Request | null> {
    const row = await this.db.get<RequestRow>(
      'SELECT * FROM requests WHERE id = ?',
      [id]
    );
    return row ? rowToRequest(row) : null;
  }

  /**
   * List requests with filtering, sorting, search, and pagination
   */
  async list(query: ListRequestsQuery): Promise<{ requests: Request[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];

    // Filters
    if (query.status) {
      conditions.push('status = ?');
      params.push(query.status);
    }

    if (query.priority) {
      conditions.push('priority = ?');
      params.push(query.priority);
    }

    if (query.principal) {
      conditions.push('principal_name = ?');
      params.push(query.principal.toLowerCase());
    }

    if (query.assignee) {
      conditions.push('assignee_name = ?');
      params.push(query.assignee);
    }

    if (query.reporter) {
      conditions.push('reporter_name = ?');
      params.push(query.reporter);
    }

    if (query.workstream) {
      conditions.push('workstream = ?');
      params.push(query.workstream);
    }

    if (query.tags) {
      // Search for any of the comma-separated tags
      // Escape LIKE special characters to prevent injection
      const tagList = query.tags.split(',').map(t => t.trim());
      const tagConditions = tagList.map(() => "tags LIKE ? ESCAPE '\\'");
      conditions.push(`(${tagConditions.join(' OR ')})`);
      tagList.forEach(tag => {
        const escaped = escapeLikePattern(tag);
        params.push(`%"${escaped}"%`);
      });
    }

    // Search (in title and summary)
    // Escape LIKE special characters to prevent injection
    if (query.search) {
      conditions.push("(title LIKE ? ESCAPE '\\' OR summary LIKE ? ESCAPE '\\')");
      const escaped = escapeLikePattern(query.search);
      const searchPattern = `%${escaped}%`;
      params.push(searchPattern, searchPattern);
    }

    const whereClause = conditions.length > 0
      ? `WHERE ${conditions.join(' AND ')}`
      : '';

    // Get total count
    const countRow = await this.db.get<{ count: number }>(
      `SELECT COUNT(*) as count FROM requests ${whereClause}`,
      params
    );
    const total = countRow?.count ?? 0;

    // Sorting - validate direction to prevent SQL injection
    const sortColumn = getSortColumn(query.sortBy);
    const sortDirection = normalizeSortDirection(query.sortOrder);

    // Get paginated results
    const rows = await this.db.query<RequestRow>(
      `SELECT * FROM requests ${whereClause}
       ORDER BY ${sortColumn} ${sortDirection}
       LIMIT ? OFFSET ?`,
      [...params, query.limit, query.offset]
    );

    return {
      requests: rows.map(rowToRequest),
      total,
    };
  }

  /**
   * Update a request
   */
  async update(requestId: string, data: UpdateRequestInput): Promise<Request | null> {
    const sets: string[] = [];
    const params: unknown[] = [];

    if (data.title !== undefined) {
      sets.push('title = ?');
      params.push(data.title);
    }

    if (data.summary !== undefined) {
      sets.push('summary = ?');
      params.push(data.summary);
    }

    if (data.status !== undefined) {
      sets.push('status = ?');
      params.push(data.status);
    }

    if (data.priority !== undefined) {
      sets.push('priority = ?');
      params.push(data.priority);
    }

    if (data.assigneeType !== undefined) {
      sets.push('assignee_type = ?');
      params.push(data.assigneeType);
    }

    if (data.assigneeName !== undefined) {
      sets.push('assignee_name = ?');
      params.push(data.assigneeName);
    }

    if (data.workstream !== undefined) {
      sets.push('workstream = ?');
      params.push(data.workstream);
    }

    if (data.tags !== undefined) {
      sets.push('tags = ?');
      params.push(JSON.stringify(data.tags));
    }

    if (sets.length === 0) {
      return this.findByRequestId(requestId);
    }

    sets.push("updated_at = datetime('now')");
    params.push(requestId);

    await this.db.execute(
      `UPDATE requests SET ${sets.join(', ')} WHERE request_id = ?`,
      params
    );

    logger.info({ requestId, updates: Object.keys(data) }, 'Request updated');
    return this.findByRequestId(requestId);
  }

  /**
   * Delete a request
   */
  async delete(requestId: string): Promise<boolean> {
    const changes = await this.db.delete(
      'DELETE FROM requests WHERE request_id = ?',
      [requestId]
    );

    if (changes > 0) {
      logger.info({ requestId }, 'Request deleted');
    }

    return changes > 0;
  }

  /**
   * Get stats for dashboard
   */
  async getStats(): Promise<RequestStats> {
    // Status counts
    const statusRows = await this.db.query<{ status: string; count: number }>(
      `SELECT status, COUNT(*) as count FROM requests GROUP BY status`
    );

    // Priority counts
    const priorityRows = await this.db.query<{ priority: string; count: number }>(
      `SELECT priority, COUNT(*) as count FROM requests GROUP BY priority`
    );

    const stats: RequestStats = {
      total: 0,
      open: 0,
      inProgress: 0,
      review: 0,
      testing: 0,
      complete: 0,
      onHold: 0,
      cancelled: 0,
      byPriority: {
        low: 0,
        medium: 0,
        high: 0,
        critical: 0,
      },
    };

    for (const row of statusRows) {
      stats.total += row.count;
      switch (row.status) {
        case 'Open':
          stats.open = row.count;
          break;
        case 'In Progress':
          stats.inProgress = row.count;
          break;
        case 'Review':
          stats.review = row.count;
          break;
        case 'Testing':
          stats.testing = row.count;
          break;
        case 'Complete':
          stats.complete = row.count;
          break;
        case 'On Hold':
          stats.onHold = row.count;
          break;
        case 'Cancelled':
          stats.cancelled = row.count;
          break;
      }
    }

    for (const row of priorityRows) {
      switch (row.priority) {
        case 'Low':
          stats.byPriority.low = row.count;
          break;
        case 'Medium':
          stats.byPriority.medium = row.count;
          break;
        case 'High':
          stats.byPriority.high = row.count;
          break;
        case 'Critical':
          stats.byPriority.critical = row.count;
          break;
      }
    }

    return stats;
  }
}
