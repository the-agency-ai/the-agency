/**
 * Observation Repository
 *
 * Data access layer for observations. Uses the database adapter interface.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import type {
  Observation,
  CreateObservationInput,
  UpdateObservationInput,
  ListObservationsQuery,
  ObservationStats,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('observation-repository');

/**
 * Database row types (snake_case as stored in SQLite)
 */
interface ObservationRow {
  id: number;
  observation_id: string;
  title: string;
  summary: string;
  status: string;
  category: string;
  reporter_type: string;
  reporter_name: string;
  context_path: string | null;
  context_line: number | null;
  context_ref: string | null;
  workstream: string | null;
  tags: string; // JSON array
  created_at: string;
  updated_at: string;
}

interface SequenceRow {
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
 * Convert database row to Observation entity
 */
function rowToObservation(row: ObservationRow): Observation {
  return {
    id: row.id,
    observationId: row.observation_id,
    title: row.title,
    summary: row.summary,
    status: row.status as Observation['status'],
    category: row.category as Observation['category'],
    reporterType: row.reporter_type as Observation['reporterType'],
    reporterName: row.reporter_name,
    contextPath: row.context_path,
    contextLine: row.context_line,
    contextRef: row.context_ref,
    workstream: row.workstream,
    tags: safeParseJsonArray(row.tags),
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
    category: 'category',
  };
  return mapping[sortBy] || 'created_at';
}

export class ObservationRepository {
  constructor(private db: DatabaseAdapter) {}

  /**
   * Initialize the observations schema
   */
  async initialize(): Promise<void> {
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS observations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        observation_id TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        status TEXT DEFAULT 'Open',
        category TEXT DEFAULT 'note',
        reporter_type TEXT NOT NULL,
        reporter_name TEXT NOT NULL,
        context_path TEXT,
        context_line INTEGER,
        context_ref TEXT,
        workstream TEXT,
        tags TEXT DEFAULT '[]',
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
      )
    `);

    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS observation_sequence (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        next_id INTEGER DEFAULT 1
      )
    `);

    // Initialize sequence if not exists
    await this.db.execute(`
      INSERT OR IGNORE INTO observation_sequence (id, next_id) VALUES (1, 1)
    `);

    // Create indexes
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_observations_status ON observations(status)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_observations_category ON observations(category)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_observations_reporter ON observations(reporter_name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_observations_workstream ON observations(workstream)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_observations_context ON observations(context_path)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_observations_created ON observations(created_at)`);

    logger.info('Observation schema initialized');
  }

  /**
   * Get the next observation ID
   * Uses atomic increment-then-read pattern to prevent race conditions
   */
  async getNextObservationId(): Promise<string> {
    // Atomically increment first, then read the value
    // This prevents race conditions in concurrent scenarios
    await this.db.execute(
      'UPDATE observation_sequence SET next_id = next_id + 1 WHERE id = 1'
    );

    // Read the incremented value and subtract 1 to get the ID we just reserved
    const row = await this.db.get<SequenceRow>(
      'SELECT next_id - 1 as next_id FROM observation_sequence WHERE id = 1'
    );

    const nextId = row?.next_id ?? 1;

    // Format: OBS-0001
    return `OBS-${String(nextId).padStart(4, '0')}`;
  }

  /**
   * Create a new observation
   */
  async create(observationId: string, data: CreateObservationInput): Promise<Observation> {
    await this.db.execute(
      `INSERT INTO observations (
        observation_id, title, summary, status, category,
        reporter_type, reporter_name,
        context_path, context_line, context_ref, workstream, tags
      ) VALUES (?, ?, ?, 'Open', ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        observationId,
        data.title,
        data.summary,
        data.category || 'note',
        data.reporterType,
        data.reporterName,
        data.contextPath || null,
        data.contextLine || null,
        data.contextRef || null,
        data.workstream || null,
        JSON.stringify(data.tags || []),
      ]
    );

    const observation = await this.findByObservationId(observationId);
    if (!observation) {
      throw new Error(`Failed to create observation ${observationId}`);
    }

    logger.info({ observationId }, 'Observation created');
    return observation;
  }

  /**
   * Find an observation by its observation_id
   */
  async findByObservationId(observationId: string): Promise<Observation | null> {
    const row = await this.db.get<ObservationRow>(
      'SELECT * FROM observations WHERE observation_id = ?',
      [observationId]
    );
    return row ? rowToObservation(row) : null;
  }

  /**
   * Find an observation by its internal id
   */
  async findById(id: number): Promise<Observation | null> {
    const row = await this.db.get<ObservationRow>(
      'SELECT * FROM observations WHERE id = ?',
      [id]
    );
    return row ? rowToObservation(row) : null;
  }

  /**
   * List observations with filtering, sorting, search, and pagination
   */
  async list(query: ListObservationsQuery): Promise<{ observations: Observation[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];

    // Filters
    if (query.status) {
      conditions.push('status = ?');
      params.push(query.status);
    }

    if (query.category) {
      conditions.push('category = ?');
      params.push(query.category);
    }

    if (query.reporter) {
      conditions.push('reporter_name = ?');
      params.push(query.reporter);
    }

    if (query.workstream) {
      conditions.push('workstream = ?');
      params.push(query.workstream);
    }

    if (query.contextPath) {
      conditions.push("context_path LIKE ? ESCAPE '\\'");
      const escaped = escapeLikePattern(query.contextPath);
      params.push(`${escaped}%`);
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

    // Search (in title and summary)
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
      `SELECT COUNT(*) as count FROM observations ${whereClause}`,
      params
    );
    const total = countRow?.count ?? 0;

    // Sorting - validate direction to prevent SQL injection
    const sortColumn = getSortColumn(query.sortBy);
    const sortDirection = normalizeSortDirection(query.sortOrder);

    // Get paginated results
    const rows = await this.db.query<ObservationRow>(
      `SELECT * FROM observations ${whereClause}
       ORDER BY ${sortColumn} ${sortDirection}
       LIMIT ? OFFSET ?`,
      [...params, query.limit, query.offset]
    );

    return {
      observations: rows.map(rowToObservation),
      total,
    };
  }

  /**
   * Update an observation
   */
  async update(observationId: string, data: UpdateObservationInput): Promise<Observation | null> {
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

    if (data.category !== undefined) {
      sets.push('category = ?');
      params.push(data.category);
    }

    if (data.contextPath !== undefined) {
      sets.push('context_path = ?');
      params.push(data.contextPath);
    }

    if (data.contextLine !== undefined) {
      sets.push('context_line = ?');
      params.push(data.contextLine);
    }

    if (data.contextRef !== undefined) {
      sets.push('context_ref = ?');
      params.push(data.contextRef);
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
      return this.findByObservationId(observationId);
    }

    sets.push("updated_at = datetime('now')");
    params.push(observationId);

    await this.db.execute(
      `UPDATE observations SET ${sets.join(', ')} WHERE observation_id = ?`,
      params
    );

    logger.info({ observationId, updates: Object.keys(data) }, 'Observation updated');
    return this.findByObservationId(observationId);
  }

  /**
   * Delete an observation
   */
  async delete(observationId: string): Promise<boolean> {
    const changes = await this.db.delete(
      'DELETE FROM observations WHERE observation_id = ?',
      [observationId]
    );

    if (changes > 0) {
      logger.info({ observationId }, 'Observation deleted');
    }

    return changes > 0;
  }

  /**
   * Get stats for dashboard
   */
  async getStats(): Promise<ObservationStats> {
    // Status counts
    const statusRows = await this.db.query<{ status: string; count: number }>(
      `SELECT status, COUNT(*) as count FROM observations GROUP BY status`
    );

    // Category counts
    const categoryRows = await this.db.query<{ category: string; count: number }>(
      `SELECT category, COUNT(*) as count FROM observations GROUP BY category`
    );

    const stats: ObservationStats = {
      total: 0,
      open: 0,
      acknowledged: 0,
      noted: 0,
      archived: 0,
      byCategory: {
        insight: 0,
        pattern: 0,
        concern: 0,
        improvement: 0,
        note: 0,
        finding: 0,
      },
    };

    for (const row of statusRows) {
      stats.total += row.count;
      switch (row.status) {
        case 'Open':
          stats.open = row.count;
          break;
        case 'Acknowledged':
          stats.acknowledged = row.count;
          break;
        case 'Noted':
          stats.noted = row.count;
          break;
        case 'Archived':
          stats.archived = row.count;
          break;
      }
    }

    for (const row of categoryRows) {
      switch (row.category) {
        case 'insight':
          stats.byCategory.insight = row.count;
          break;
        case 'pattern':
          stats.byCategory.pattern = row.count;
          break;
        case 'concern':
          stats.byCategory.concern = row.count;
          break;
        case 'improvement':
          stats.byCategory.improvement = row.count;
          break;
        case 'note':
          stats.byCategory.note = row.count;
          break;
        case 'finding':
          stats.byCategory.finding = row.count;
          break;
      }
    }

    return stats;
  }
}
