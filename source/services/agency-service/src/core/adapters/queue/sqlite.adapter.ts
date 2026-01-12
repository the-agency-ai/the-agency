/**
 * SQLite Queue Adapter
 *
 * Local queue implementation using Bun's built-in SQLite.
 * Uses polling (not elegant, but pragmatic for local development).
 *
 * Design: Interface allows swap to push-based system later without changing consumers.
 */

import { Database } from 'bun:sqlite';
import type {
  QueueAdapter,
  QueueJob,
  QueueHandler,
  QueueSubscription,
  QueueConfig,
} from './types';
import { createServiceLogger } from '../../lib/logger';
import { randomUUID } from 'crypto';
import fs from 'fs';
import path from 'path';

const logger = createServiceLogger('sqlite-queue');

interface QueueRow {
  id: string;
  queue_name: string;
  data: string;
  priority: number;
  attempts: number;
  max_attempts: number;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  error: string | null;
  delay_until: string | null;
  created_at: string;
  processed_at: string | null;
  completed_at: string | null;
}

export class SQLiteQueueAdapter implements QueueAdapter {
  private db: Database | null = null;
  private config: QueueConfig;
  private subscriptions: Map<string, NodeJS.Timeout> = new Map();

  constructor(config: QueueConfig) {
    this.config = {
      pollInterval: 1000, // Default 1 second
      ...config,
    };
  }

  async initialize(): Promise<void> {
    const dbPath = this.getDbPath();

    // Ensure directory exists
    const dir = path.dirname(dbPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    this.db = new Database(dbPath, { create: true });
    this.db.exec('PRAGMA journal_mode = WAL');

    // Create queue table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS queue_jobs (
        id TEXT PRIMARY KEY,
        queue_name TEXT NOT NULL,
        data TEXT NOT NULL,
        priority INTEGER DEFAULT 0,
        attempts INTEGER DEFAULT 0,
        max_attempts INTEGER DEFAULT 3,
        status TEXT DEFAULT 'pending',
        error TEXT,
        delay_until TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        processed_at TEXT,
        completed_at TEXT
      );

      CREATE INDEX IF NOT EXISTS idx_queue_jobs_queue_status
        ON queue_jobs(queue_name, status, priority DESC, created_at ASC);

      CREATE INDEX IF NOT EXISTS idx_queue_jobs_status
        ON queue_jobs(status);
    `);

    logger.info({ path: dbPath }, 'SQLite queue initialized');
  }

  async close(): Promise<void> {
    // Stop all subscriptions
    for (const [queueName, timer] of this.subscriptions) {
      clearInterval(timer);
      this.subscriptions.delete(queueName);
    }

    if (this.db) {
      this.db.close();
      this.db = null;
      logger.info('SQLite queue closed');
    }
  }

  async enqueue<T extends Record<string, unknown>>(
    queueName: string,
    job: QueueJob<T>
  ): Promise<string> {
    this.ensureConnected();

    const id = job.id || randomUUID();
    const delayUntil = job.delay
      ? new Date(Date.now() + job.delay).toISOString()
      : null;

    const stmt = this.db!.prepare(`
      INSERT INTO queue_jobs (id, queue_name, data, priority, max_attempts, delay_until)
      VALUES (?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      id,
      queueName,
      JSON.stringify(job.data),
      job.priority ?? 0,
      job.maxAttempts ?? 3,
      delayUntil
    );

    logger.debug({ jobId: id, queueName }, 'Job enqueued');
    return id;
  }

  async dequeue<T extends Record<string, unknown>>(
    queueName: string
  ): Promise<QueueJob<T> | null> {
    this.ensureConnected();

    const now = new Date().toISOString();

    // Find next available job (not delayed, pending, ordered by priority then created_at)
    const stmt = this.db!.prepare(`
      SELECT * FROM queue_jobs
      WHERE queue_name = ?
        AND status = 'pending'
        AND (delay_until IS NULL OR delay_until <= ?)
      ORDER BY priority DESC, created_at ASC
      LIMIT 1
    `);

    const row = stmt.get(queueName, now) as QueueRow | null;

    if (!row) {
      return null;
    }

    // Mark as processing
    const updateStmt = this.db!.prepare(`
      UPDATE queue_jobs
      SET status = 'processing', processed_at = datetime('now'), attempts = attempts + 1
      WHERE id = ?
    `);
    updateStmt.run(row.id);

    logger.debug({ jobId: row.id, queueName }, 'Job dequeued');

    return {
      id: row.id,
      data: JSON.parse(row.data) as T,
      priority: row.priority,
      attempts: row.attempts + 1,
      maxAttempts: row.max_attempts,
      createdAt: new Date(row.created_at),
      processedAt: new Date(),
    };
  }

  async complete(jobId: string): Promise<void> {
    this.ensureConnected();

    const stmt = this.db!.prepare(`
      UPDATE queue_jobs
      SET status = 'completed', completed_at = datetime('now')
      WHERE id = ?
    `);
    stmt.run(jobId);

    logger.debug({ jobId }, 'Job completed');
  }

  async fail(jobId: string, error: string): Promise<void> {
    this.ensureConnected();

    // Check if we should retry
    const selectStmt = this.db!.prepare(`SELECT * FROM queue_jobs WHERE id = ?`);
    const row = selectStmt.get(jobId) as QueueRow | null;

    if (!row) {
      logger.warn({ jobId }, 'Job not found for failure');
      return;
    }

    if (row.attempts < row.max_attempts) {
      // Retry with exponential backoff
      const backoffMs = Math.pow(2, row.attempts) * 1000;
      const delayUntil = new Date(Date.now() + backoffMs).toISOString();

      const updateStmt = this.db!.prepare(`
        UPDATE queue_jobs
        SET status = 'pending', error = ?, delay_until = ?
        WHERE id = ?
      `);
      updateStmt.run(error, delayUntil, jobId);

      logger.debug({ jobId, attempts: row.attempts, backoffMs }, 'Job will retry');
    } else {
      // Mark as permanently failed
      const updateStmt = this.db!.prepare(`
        UPDATE queue_jobs
        SET status = 'failed', error = ?
        WHERE id = ?
      `);
      updateStmt.run(error, jobId);

      logger.warn({ jobId, error }, 'Job permanently failed');
    }
  }

  async getPendingCount(queueName: string): Promise<number> {
    this.ensureConnected();

    const stmt = this.db!.prepare(`
      SELECT COUNT(*) as count FROM queue_jobs
      WHERE queue_name = ? AND status = 'pending'
    `);
    const row = stmt.get(queueName) as { count: number } | null;

    return row?.count ?? 0;
  }

  async subscribe<T extends Record<string, unknown>>(
    queueName: string,
    handler: QueueHandler<T>
  ): Promise<QueueSubscription> {
    // Start polling loop
    const poll = async () => {
      try {
        const job = await this.dequeue<T>(queueName);
        if (job && job.id) {
          try {
            await handler(job);
            await this.complete(job.id);
          } catch (error) {
            const errorMsg = error instanceof Error ? error.message : String(error);
            await this.fail(job.id, errorMsg);
          }
        }
      } catch (error) {
        logger.error({ error, queueName }, 'Poll error');
      }
    };

    // Start polling
    const timer = setInterval(poll, this.config.pollInterval);
    this.subscriptions.set(queueName, timer);

    // Run immediately
    poll();

    logger.info({ queueName, pollInterval: this.config.pollInterval }, 'Subscribed to queue');

    return {
      unsubscribe: async () => {
        const t = this.subscriptions.get(queueName);
        if (t) {
          clearInterval(t);
          this.subscriptions.delete(queueName);
          logger.info({ queueName }, 'Unsubscribed from queue');
        }
      },
    };
  }

  async healthCheck(): Promise<boolean> {
    try {
      this.ensureConnected();
      this.db!.prepare('SELECT 1').get();
      return true;
    } catch (error) {
      logger.error({ error }, 'Queue health check failed');
      return false;
    }
  }

  private getDbPath(): string {
    if (this.config.dbPath) {
      return path.join(this.config.dbPath, 'queue.db');
    }
    return ':memory:';
  }

  private ensureConnected(): void {
    if (!this.db) {
      throw new Error('Queue not initialized. Call initialize() first.');
    }
  }
}

/**
 * Factory function to create SQLite queue adapter
 */
export function createSQLiteQueueAdapter(config: QueueConfig): QueueAdapter {
  return new SQLiteQueueAdapter(config);
}
