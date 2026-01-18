/**
 * Message Repository
 *
 * Data access layer for messages. Uses the database adapter interface.
 * Business logic stays in the service layer.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import type {
  Message,
  Recipient,
  MessageWithRecipients,
  CreateMessageRequest,
  ListMessagesQuery,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('message-repository');

/**
 * Database row types (snake_case as stored in SQLite)
 */
interface MessageRow {
  id: number;
  timestamp: string;
  from_type: string;
  from_name: string;
  to_type: string;
  to_name: string | null;
  subject: string | null;
  content: string;
}

interface RecipientRow {
  id: number;
  message_id: number;
  recipient_type: string;
  recipient_name: string;
  read_at: string | null;
}

/**
 * Convert database row to Message entity
 */
function rowToMessage(row: MessageRow): Message {
  return {
    id: row.id,
    timestamp: new Date(row.timestamp),
    fromType: row.from_type as Message['fromType'],
    fromName: row.from_name,
    toType: row.to_type as Message['toType'],
    toName: row.to_name,
    subject: row.subject,
    content: row.content,
  };
}

/**
 * Convert database row to Recipient entity
 */
function rowToRecipient(row: RecipientRow): Recipient {
  return {
    id: row.id,
    messageId: row.message_id,
    recipientType: row.recipient_type as Recipient['recipientType'],
    recipientName: row.recipient_name,
    readAt: row.read_at ? new Date(row.read_at) : null,
  };
}

export class MessageRepository {
  constructor(private db: DatabaseAdapter) {}

  /**
   * Initialize the messages schema
   */
  async initialize(): Promise<void> {
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT DEFAULT (datetime('now')),
        from_type TEXT NOT NULL,
        from_name TEXT NOT NULL,
        to_type TEXT NOT NULL,
        to_name TEXT,
        subject TEXT,
        content TEXT NOT NULL
      )
    `);

    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS recipients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message_id INTEGER NOT NULL,
        recipient_type TEXT NOT NULL,
        recipient_name TEXT NOT NULL,
        read_at TEXT,
        FOREIGN KEY (message_id) REFERENCES messages(id)
      )
    `);

    // Create indexes
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_messages_from ON messages(from_type, from_name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_messages_to ON messages(to_type, to_name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp DESC)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_recipients_message ON recipients(message_id)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_recipients_recipient ON recipients(recipient_type, recipient_name)`);

    logger.info('Message schema initialized');
  }

  /**
   * Create a new message
   */
  async create(data: CreateMessageRequest): Promise<MessageWithRecipients> {
    // Insert message
    await this.db.execute(
      `INSERT INTO messages (from_type, from_name, to_type, to_name, subject, content)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        data.fromType,
        data.fromName,
        data.toType,
        data.toName || null,
        data.subject || null,
        data.content,
      ]
    );

    // Get the inserted message ID
    const lastRow = await this.db.get<{ id: number }>(
      'SELECT last_insert_rowid() as id'
    );
    const messageId = lastRow!.id;

    // Insert recipients
    const recipients: Recipient[] = [];

    // If explicit recipients provided
    if (data.recipients && data.recipients.length > 0) {
      for (const r of data.recipients) {
        await this.db.execute(
          `INSERT INTO recipients (message_id, recipient_type, recipient_name)
           VALUES (?, ?, ?)`,
          [messageId, r.recipientType, r.recipientName]
        );
        const recipientRow = await this.db.get<RecipientRow>(
          'SELECT * FROM recipients WHERE id = last_insert_rowid()'
        );
        if (recipientRow) {
          recipients.push(rowToRecipient(recipientRow));
        }
      }
    } else if (data.toType !== 'broadcast' && data.toName) {
      // Single recipient from to fields
      await this.db.execute(
        `INSERT INTO recipients (message_id, recipient_type, recipient_name)
         VALUES (?, ?, ?)`,
        [messageId, data.toType, data.toName]
      );
      const recipientRow = await this.db.get<RecipientRow>(
        'SELECT * FROM recipients WHERE id = last_insert_rowid()'
      );
      if (recipientRow) {
        recipients.push(rowToRecipient(recipientRow));
      }
    }

    const message = await this.findById(messageId);
    if (!message) {
      throw new Error(`Failed to create message`);
    }

    logger.info({ messageId, recipients: recipients.length }, 'Message created');
    return { ...message, recipients };
  }

  /**
   * Find a message by its ID
   */
  async findById(id: number): Promise<MessageWithRecipients | null> {
    const row = await this.db.get<MessageRow>(
      'SELECT * FROM messages WHERE id = ?',
      [id]
    );

    if (!row) {
      return null;
    }

    const recipientRows = await this.db.query<RecipientRow>(
      'SELECT * FROM recipients WHERE message_id = ?',
      [id]
    );

    return {
      ...rowToMessage(row),
      recipients: recipientRows.map(rowToRecipient),
    };
  }

  /**
   * List messages (inbox or outbox based on query)
   */
  async list(query: ListMessagesQuery): Promise<{ messages: MessageWithRecipients[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];
    let fromRecipients = false;

    // Inbox query: filter by recipient
    if (query.recipientType && query.recipientName) {
      fromRecipients = true;
      conditions.push('r.recipient_type = ?');
      params.push(query.recipientType);
      conditions.push('r.recipient_name = ?');
      params.push(query.recipientName);

      if (query.unreadOnly) {
        conditions.push('r.read_at IS NULL');
      }
    }

    // Outbox query: filter by sender
    if (query.fromType) {
      conditions.push('m.from_type = ?');
      params.push(query.fromType);
    }

    if (query.fromName) {
      conditions.push('m.from_name = ?');
      params.push(query.fromName);
    }

    // Time filter
    if (query.since) {
      const since = this.parseSince(query.since);
      if (since) {
        conditions.push('m.timestamp >= ?');
        params.push(since.toISOString());
      }
    }

    const whereClause = conditions.length > 0
      ? `WHERE ${conditions.join(' AND ')}`
      : '';

    // Build query with optional recipient join
    const baseQuery = fromRecipients
      ? `FROM messages m JOIN recipients r ON m.id = r.message_id ${whereClause}`
      : `FROM messages m ${whereClause}`;

    // Get total count
    const countRow = await this.db.get<{ count: number }>(
      `SELECT COUNT(DISTINCT m.id) as count ${baseQuery}`,
      params
    );
    const total = countRow?.count ?? 0;

    // Get paginated results
    const rows = await this.db.query<MessageRow>(
      `SELECT DISTINCT m.* ${baseQuery}
       ORDER BY m.timestamp DESC
       LIMIT ? OFFSET ?`,
      [...params, query.limit, query.offset]
    );

    // Batch fetch all recipients for the messages to avoid N+1 queries
    const messageIds = rows.map(r => r.id);
    const recipientRows = messageIds.length > 0
      ? await this.db.query<RecipientRow>(
          `SELECT * FROM recipients WHERE message_id IN (${messageIds.map(() => '?').join(',')})`,
          messageIds
        )
      : [];

    // Group recipients by message_id
    const recipientsByMessageId = new Map<number, RecipientRow[]>();
    for (const row of recipientRows) {
      const existing = recipientsByMessageId.get(row.message_id) || [];
      existing.push(row);
      recipientsByMessageId.set(row.message_id, existing);
    }

    // Build message objects with their recipients
    const messages: MessageWithRecipients[] = rows.map(row => ({
      ...rowToMessage(row),
      recipients: (recipientsByMessageId.get(row.id) || []).map(rowToRecipient),
    }));

    return { messages, total };
  }

  /**
   * Get inbox messages for an entity
   */
  async getInbox(
    recipientType: string,
    recipientName: string,
    unreadOnly: boolean = false
  ): Promise<MessageWithRecipients[]> {
    const { messages } = await this.list({
      recipientType: recipientType as 'agent' | 'principal',
      recipientName,
      unreadOnly,
      limit: 100,
      offset: 0,
    });
    return messages;
  }

  /**
   * Mark a message as read for a recipient
   */
  async markAsRead(
    messageId: number,
    recipientType: string,
    recipientName: string
  ): Promise<boolean> {
    const changes = await this.db.update(
      `UPDATE recipients
       SET read_at = datetime('now')
       WHERE message_id = ? AND recipient_type = ? AND recipient_name = ? AND read_at IS NULL`,
      [messageId, recipientType, recipientName]
    );

    if (changes > 0) {
      logger.debug({ messageId, recipient: `${recipientType}:${recipientName}` }, 'Message marked as read');
    }

    return changes > 0;
  }

  /**
   * Delete a message
   */
  async delete(id: number): Promise<boolean> {
    // Delete recipients first
    await this.db.execute('DELETE FROM recipients WHERE message_id = ?', [id]);

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
   * Get stats for an entity
   */
  async getStats(recipientType: string, recipientName: string): Promise<{
    total: number;
    unread: number;
    today: number;
  }> {
    const statsRow = await this.db.get<{ total: number; unread: number; today: number }>(
      `SELECT
         COUNT(*) as total,
         SUM(CASE WHEN r.read_at IS NULL THEN 1 ELSE 0 END) as unread,
         SUM(CASE WHEN m.timestamp >= date('now') THEN 1 ELSE 0 END) as today
       FROM recipients r
       JOIN messages m ON r.message_id = m.id
       WHERE r.recipient_type = ? AND r.recipient_name = ?`,
      [recipientType, recipientName]
    );

    return {
      total: statsRow?.total ?? 0,
      unread: statsRow?.unread ?? 0,
      today: statsRow?.today ?? 0,
    };
  }

  /**
   * Parse relative time strings like "1h", "24h", "7d"
   */
  private parseSince(since: string): Date | null {
    // Check if it's already an ISO timestamp
    if (since.includes('T') || since.includes('-')) {
      const date = new Date(since);
      return isNaN(date.getTime()) ? null : date;
    }

    // Parse relative time
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
