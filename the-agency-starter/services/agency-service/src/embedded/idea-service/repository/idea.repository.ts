/**
 * Idea Repository
 *
 * Data access layer for ideas. Uses the database adapter interface.
 * Business logic stays in the service layer.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import type { Idea, CreateIdeaRequest, UpdateIdeaRequest, ListIdeasQuery } from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('idea-repository');

/**
 * Database row types (snake_case as stored in SQLite)
 */
interface IdeaRow {
  id: number;
  idea_id: string;
  title: string;
  description: string | null;
  status: string;
  source_type: string;
  source_name: string;
  tags: string; // JSON array
  promoted_to: string | null;
  created_at: string;
  updated_at: string;
}

interface SequenceRow {
  next_id: number;
}

/**
 * Convert database row to Idea entity
 */
function rowToIdea(row: IdeaRow): Idea {
  let tags: string[] = [];
  try {
    tags = JSON.parse(row.tags || '[]');
  } catch {
    tags = [];
  }

  return {
    id: row.id,
    ideaId: row.idea_id,
    title: row.title,
    description: row.description,
    status: row.status as Idea['status'],
    sourceType: row.source_type as Idea['sourceType'],
    sourceName: row.source_name,
    tags,
    promotedTo: row.promoted_to,
    createdAt: new Date(row.created_at),
    updatedAt: new Date(row.updated_at),
  };
}

export class IdeaRepository {
  constructor(private db: DatabaseAdapter) {}

  /**
   * Initialize the ideas schema
   */
  async initialize(): Promise<void> {
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS ideas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idea_id TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'captured',
        source_type TEXT NOT NULL,
        source_name TEXT NOT NULL,
        tags TEXT DEFAULT '[]',
        promoted_to TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
      )
    `);

    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS idea_sequence (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        next_id INTEGER DEFAULT 1
      )
    `);

    // Initialize sequence if not exists
    await this.db.execute(`
      INSERT OR IGNORE INTO idea_sequence (id, next_id) VALUES (1, 1)
    `);

    // Create indexes
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_ideas_status ON ideas(status)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_ideas_source ON ideas(source_name)`);

    logger.info('Idea schema initialized');
  }

  /**
   * Get the next idea ID
   */
  async getNextIdeaId(): Promise<string> {
    const row = await this.db.get<SequenceRow>(
      'SELECT next_id FROM idea_sequence WHERE id = 1'
    );

    const nextId = row?.next_id || 1;

    await this.db.execute(
      'UPDATE idea_sequence SET next_id = next_id + 1 WHERE id = 1'
    );

    // Format: IDEA-00001
    return `IDEA-${String(nextId).padStart(5, '0')}`;
  }

  /**
   * Create a new idea
   */
  async create(ideaId: string, data: CreateIdeaRequest): Promise<Idea> {
    await this.db.execute(
      `INSERT INTO ideas (
        idea_id, title, description, status,
        source_type, source_name, tags
      ) VALUES (?, ?, ?, 'captured', ?, ?, ?)`,
      [
        ideaId,
        data.title,
        data.description || null,
        data.sourceType,
        data.sourceName,
        JSON.stringify(data.tags || []),
      ]
    );

    const idea = await this.findByIdeaId(ideaId);
    if (!idea) {
      throw new Error(`Failed to create idea ${ideaId}`);
    }

    logger.info({ ideaId }, 'Idea created');
    return idea;
  }

  /**
   * Find an idea by its idea_id (e.g., "IDEA-00001")
   */
  async findByIdeaId(ideaId: string): Promise<Idea | null> {
    const row = await this.db.get<IdeaRow>(
      'SELECT * FROM ideas WHERE idea_id = ?',
      [ideaId]
    );
    return row ? rowToIdea(row) : null;
  }

  /**
   * Find an idea by its internal id
   */
  async findById(id: number): Promise<Idea | null> {
    const row = await this.db.get<IdeaRow>(
      'SELECT * FROM ideas WHERE id = ?',
      [id]
    );
    return row ? rowToIdea(row) : null;
  }

  /**
   * List ideas with optional filtering
   */
  async list(query: ListIdeasQuery): Promise<{ ideas: Idea[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];

    if (query.status) {
      conditions.push('status = ?');
      params.push(query.status);
    }

    if (query.source) {
      conditions.push('source_name = ?');
      params.push(query.source);
    }

    if (query.tag) {
      // Search in JSON array - escape LIKE special characters
      const escapedTag = query.tag.replace(/[%_\\]/g, '\\$&');
      conditions.push("tags LIKE ? ESCAPE '\\'");
      params.push(`%"${escapedTag}"%`);
    }

    if (query.search) {
      // Escape LIKE special characters for exact substring matching
      const escapedSearch = query.search.replace(/[%_\\]/g, '\\$&');
      conditions.push("(title LIKE ? ESCAPE '\\' OR description LIKE ? ESCAPE '\\')");
      const searchTerm = `%${escapedSearch}%`;
      params.push(searchTerm, searchTerm);
    }

    const whereClause = conditions.length > 0
      ? `WHERE ${conditions.join(' AND ')}`
      : '';

    // Get total count
    const countRow = await this.db.get<{ count: number }>(
      `SELECT COUNT(*) as count FROM ideas ${whereClause}`,
      params
    );
    const total = countRow?.count ?? 0;

    // Get paginated results
    const rows = await this.db.query<IdeaRow>(
      `SELECT * FROM ideas ${whereClause}
       ORDER BY created_at DESC
       LIMIT ? OFFSET ?`,
      [...params, query.limit, query.offset]
    );

    return {
      ideas: rows.map(rowToIdea),
      total,
    };
  }

  /**
   * Update an idea
   */
  async update(ideaId: string, data: UpdateIdeaRequest): Promise<Idea | null> {
    const sets: string[] = [];
    const params: unknown[] = [];

    if (data.title !== undefined) {
      sets.push('title = ?');
      params.push(data.title);
    }

    if (data.description !== undefined) {
      sets.push('description = ?');
      params.push(data.description);
    }

    if (data.status !== undefined) {
      sets.push('status = ?');
      params.push(data.status);
    }

    if (data.tags !== undefined) {
      sets.push('tags = ?');
      params.push(JSON.stringify(data.tags));
    }

    if (sets.length === 0) {
      return this.findByIdeaId(ideaId);
    }

    sets.push("updated_at = datetime('now')");
    params.push(ideaId);

    await this.db.execute(
      `UPDATE ideas SET ${sets.join(', ')} WHERE idea_id = ?`,
      params
    );

    logger.info({ ideaId, updates: Object.keys(data) }, 'Idea updated');
    return this.findByIdeaId(ideaId);
  }

  /**
   * Mark idea as promoted
   */
  async promote(ideaId: string, requestId: string): Promise<Idea | null> {
    await this.db.execute(
      `UPDATE ideas SET status = 'promoted', promoted_to = ?, updated_at = datetime('now') WHERE idea_id = ?`,
      [requestId, ideaId]
    );

    logger.info({ ideaId, requestId }, 'Idea promoted to request');
    return this.findByIdeaId(ideaId);
  }

  /**
   * Delete an idea
   */
  async delete(ideaId: string): Promise<boolean> {
    const changes = await this.db.delete(
      'DELETE FROM ideas WHERE idea_id = ?',
      [ideaId]
    );

    if (changes > 0) {
      logger.info({ ideaId }, 'Idea deleted');
    }

    return changes > 0;
  }

  /**
   * Get stats for dashboard
   */
  async getStats(): Promise<{
    total: number;
    captured: number;
    exploring: number;
    promoted: number;
    parked: number;
    discarded: number;
  }> {
    const rows = await this.db.query<{ status: string; count: number }>(
      `SELECT status, COUNT(*) as count FROM ideas GROUP BY status`
    );

    const stats = {
      total: 0,
      captured: 0,
      exploring: 0,
      promoted: 0,
      parked: 0,
      discarded: 0,
    };

    for (const row of rows) {
      stats.total += row.count;
      switch (row.status) {
        case 'captured':
          stats.captured = row.count;
          break;
        case 'exploring':
          stats.exploring = row.count;
          break;
        case 'promoted':
          stats.promoted = row.count;
          break;
        case 'parked':
          stats.parked = row.count;
          break;
        case 'discarded':
          stats.discarded = row.count;
          break;
      }
    }

    return stats;
  }
}
