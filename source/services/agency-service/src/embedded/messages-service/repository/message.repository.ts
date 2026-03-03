/**
 * Unified Message Repository
 *
 * Data access layer for the unified messaging system.
 * Replaces the old two-table (messages + recipients) model with
 * a single messages table using JSON arrays for read tracking.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import type {
  Message,
  SendMessageInput,
  BroadcastMessageInput,
  ListMessagesQuery,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('message-repository');

/**
 * Database row type (snake_case as stored in SQLite)
 */
interface MessageRow {
  id: string;
  type: string;
  from_agent: string;
  to_agent: string | null;
  subject: string;
  body: string;
  reference_id: string | null;
  tags: string;       // JSON array
  read_by: string;    // JSON array
  created_at: string;
  metadata: string;   // JSON object
}

/**
 * Convert database row to Message entity
 */
function rowToMessage(row: MessageRow): Message {
  return {
    id: row.id,
    type: row.type as Message['type'],
    fromAgent: row.from_agent,
    toAgent: row.to_agent,
    subject: row.subject,
    body: row.body,
    referenceId: row.reference_id,
    tags: JSON.parse(row.tags || '[]'),
    readBy: JSON.parse(row.read_by || '[]'),
    createdAt: row.created_at,
    metadata: JSON.parse(row.metadata || '{}'),
  };
}

export class MessageRepository {
  constructor(private db: DatabaseAdapter) {}

  /**
   * Initialize the unified messages schema
   */
  async initialize(): Promise<void> {
    // Check if old schema exists and needs migration
    const hasOldTable = await this.db.get<{ name: string }>(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='messages'"
    );

    if (hasOldTable) {
      // Check if it's the old schema (has from_type column) or new schema (has type column)
      const hasOldColumn = await this.db.get<{ name: string }>(
        "SELECT name FROM pragma_table_info('messages') WHERE name='from_type'"
      );

      if (hasOldColumn) {
        // Old schema exists — rename it to preserve data
        logger.info('Migrating old messages schema...');
        await this.db.execute('ALTER TABLE messages RENAME TO messages_legacy');
        // Also rename recipients if it exists
        const hasRecipients = await this.db.get<{ name: string }>(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='recipients'"
        );
        if (hasRecipients) {
          await this.db.execute('ALTER TABLE recipients RENAME TO recipients_legacy');
        }
        logger.info('Old messages tables renamed to *_legacy');
      }
    }

    // Create new unified schema
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        from_agent TEXT NOT NULL,
        to_agent TEXT,
        subject TEXT NOT NULL,
        body TEXT NOT NULL,
        reference_id TEXT,
        tags TEXT DEFAULT '[]',
        read_by TEXT DEFAULT '[]',
        created_at TEXT DEFAULT (datetime('now')),
        metadata TEXT DEFAULT '{}'
      )
    `);

    await this.db.execute(`
      CREATE INDEX IF NOT EXISTS idx_messages_direct
        ON messages(to_agent, created_at DESC)
        WHERE type = 'direct'
    `);

    await this.db.execute(`
      CREATE INDEX IF NOT EXISTS idx_messages_broadcast
        ON messages(created_at DESC)
        WHERE type = 'broadcast'
    `);

    await this.db.execute(`
      CREATE INDEX IF NOT EXISTS idx_messages_reference
        ON messages(reference_id)
        WHERE reference_id IS NOT NULL
    `);

    await this.db.execute(`
      CREATE INDEX IF NOT EXISTS idx_messages_from
        ON messages(from_agent, created_at DESC)
    `);

    logger.info('Unified message schema initialized');
  }

  /**
   * Generate a UUID
   */
  private generateId(): string {
    return crypto.randomUUID();
  }

  /**
   * Create a direct message
   */
  async createDirect(data: SendMessageInput): Promise<Message> {
    const id = this.generateId();

    await this.db.execute(
      `INSERT INTO messages (id, type, from_agent, to_agent, subject, body, reference_id, tags, metadata)
       VALUES (?, 'direct', ?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        data.fromAgent,
        data.toAgent,
        data.subject,
        data.body,
        data.referenceId || null,
        JSON.stringify(data.tags || []),
        JSON.stringify(data.metadata || {}),
      ]
    );

    const message = await this.findById(id);
    if (!message) {
      throw new Error('Failed to create message');
    }

    logger.info({ messageId: id, to: data.toAgent }, 'Direct message created');
    return message;
  }

  /**
   * Create a broadcast message
   */
  async createBroadcast(data: BroadcastMessageInput): Promise<Message> {
    const id = this.generateId();

    await this.db.execute(
      `INSERT INTO messages (id, type, from_agent, to_agent, subject, body, reference_id, tags, metadata)
       VALUES (?, 'broadcast', ?, NULL, ?, ?, ?, ?, ?)`,
      [
        id,
        data.fromAgent,
        data.subject,
        data.body,
        data.referenceId || null,
        JSON.stringify(data.tags || []),
        JSON.stringify(data.metadata || {}),
      ]
    );

    const message = await this.findById(id);
    if (!message) {
      throw new Error('Failed to create broadcast');
    }

    logger.info({ messageId: id }, 'Broadcast message created');
    return message;
  }

  /**
   * Find a message by ID
   */
  async findById(id: string): Promise<Message | null> {
    const row = await this.db.get<MessageRow>(
      'SELECT * FROM messages WHERE id = ?',
      [id]
    );

    return row ? rowToMessage(row) : null;
  }

  /**
   * Mark a message as read by an agent
   */
  async markAsRead(id: string, agentName: string): Promise<boolean> {
    // Atomic update: add agentName to read_by JSON array if not already present
    const changes = await this.db.update(
      `UPDATE messages
       SET read_by = json_insert(read_by, '$[#]', ?)
       WHERE id = ?
         AND NOT EXISTS (
           SELECT 1 FROM json_each(messages.read_by) WHERE value = ?
         )`,
      [agentName, id, agentName]
    );

    if (changes > 0) {
      logger.debug({ messageId: id, agent: agentName }, 'Message marked as read');
    }

    return changes > 0;
  }

  /**
   * List messages with filtering
   */
  async list(query: ListMessagesQuery): Promise<{ messages: Message[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];

    // Filter by type
    if (query.type) {
      conditions.push('type = ?');
      params.push(query.type);
    }

    // Filter by agent (matches toAgent OR fromAgent)
    if (query.agent) {
      conditions.push('(to_agent = ? OR from_agent = ?)');
      params.push(query.agent, query.agent);
    }

    // Filter by fromAgent
    if (query.fromAgent) {
      conditions.push('from_agent = ?');
      params.push(query.fromAgent);
    }

    // Filter by toAgent
    if (query.toAgent) {
      conditions.push('to_agent = ?');
      params.push(query.toAgent);
    }

    // Filter unread for a specific agent
    if (query.unread) {
      conditions.push(
        `NOT EXISTS (SELECT 1 FROM json_each(read_by) WHERE value = ?)`
      );
      params.push(query.unread);
      // For unread, show direct messages to this agent + all broadcasts
      conditions.push(`(to_agent = ? OR type = 'broadcast')`);
      params.push(query.unread);
    }

    // Filter by tags
    if (query.tags) {
      const tagList = query.tags.split(',').map(t => t.trim());
      for (const tag of tagList) {
        conditions.push(
          `EXISTS (SELECT 1 FROM json_each(tags) WHERE value = ?)`
        );
        params.push(tag);
      }
    }

    // Time filter
    if (query.since) {
      const since = this.parseSince(query.since);
      if (since) {
        conditions.push('created_at >= ?');
        params.push(since);
      }
    }

    const whereClause = conditions.length > 0
      ? `WHERE ${conditions.join(' AND ')}`
      : '';

    // Get total count
    const countSql = 'SELECT COUNT(*) as count FROM messages ' + whereClause;
    const countRow = await this.db.get<{ count: number }>(countSql, params);
    const total = countRow?.count ?? 0;

    // Get paginated results
    const listSql = 'SELECT * FROM messages ' + whereClause +
      ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    const rows = await this.db.query<MessageRow>(
      listSql,
      [...params, query.limit, query.offset]
    );

    return {
      messages: rows.map(rowToMessage),
      total,
    };
  }

  /**
   * Get unread messages for an agent
   */
  async getUnread(agentName: string): Promise<{ count: number; messages: Message[] }> {
    const rows = await this.db.query<MessageRow>(
      `SELECT * FROM messages
       WHERE (to_agent = ? OR type = 'broadcast')
         AND NOT EXISTS (SELECT 1 FROM json_each(read_by) WHERE value = ?)
       ORDER BY created_at DESC`,
      [agentName, agentName]
    );

    return {
      count: rows.length,
      messages: rows.map(rowToMessage),
    };
  }

  /**
   * Get message thread (root + all replies referencing it)
   */
  async getThread(id: string): Promise<{ root: Message | null; replies: Message[] }> {
    const root = await this.findById(id);

    const replyRows = await this.db.query<MessageRow>(
      `SELECT * FROM messages WHERE reference_id = ? ORDER BY created_at ASC`,
      [id]
    );

    return {
      root,
      replies: replyRows.map(rowToMessage),
    };
  }

  /**
   * Delete a message
   */
  async delete(id: string): Promise<boolean> {
    const changes = await this.db.delete(
      'DELETE FROM messages WHERE id = ?',
      [id]
    );

    if (changes > 0) {
      logger.info({ messageId: id }, 'Message deleted');
    }

    return changes > 0;
  }

  /**
   * Get message statistics
   */
  async getStats(): Promise<{
    total: number;
    direct: number;
    broadcast: number;
    today: number;
  }> {
    const row = await this.db.get<{
      total: number;
      direct: number;
      broadcast: number;
      today: number;
    }>(
      `SELECT
         COUNT(*) as total,
         SUM(CASE WHEN type = 'direct' THEN 1 ELSE 0 END) as direct,
         SUM(CASE WHEN type = 'broadcast' THEN 1 ELSE 0 END) as broadcast,
         SUM(CASE WHEN created_at >= date('now') THEN 1 ELSE 0 END) as today
       FROM messages`
    );

    return {
      total: row?.total ?? 0,
      direct: row?.direct ?? 0,
      broadcast: row?.broadcast ?? 0,
      today: row?.today ?? 0,
    };
  }

  /**
   * Parse relative time strings like "1h", "24h", "7d"
   */
  private parseSince(since: string): string | null {
    // Check if it's already an ISO timestamp
    if (since.includes('T') || since.includes('-')) {
      const date = new Date(since);
      return isNaN(date.getTime()) ? null : date.toISOString();
    }

    // Parse relative time
    const match = since.match(/^(\d+)([mhdw])$/);
    if (!match) {
      return null;
    }

    const [, amount, unit] = match;
    const now = new Date();
    const ms: Record<string, number> = {
      m: 60 * 1000,
      h: 60 * 60 * 1000,
      d: 24 * 60 * 60 * 1000,
      w: 7 * 24 * 60 * 60 * 1000,
    };

    const multiplier = ms[unit];
    if (!multiplier) {
      return null;
    }

    return new Date(now.getTime() - parseInt(amount, 10) * multiplier).toISOString();
  }
}
