/**
 * SQLite Database Adapter
 *
 * Local-first database adapter using Bun's built-in SQLite.
 * Fast, synchronous operations perfect for CLI auto-launch.
 */

import { Database } from 'bun:sqlite';
import type { DatabaseAdapter, TransactionContext, DatabaseConfig } from './types';
import { createServiceLogger } from '../../lib/logger';
import fs from 'fs';
import path from 'path';

const logger = createServiceLogger('sqlite-adapter');

export class SQLiteAdapter implements DatabaseAdapter {
  private db: Database | null = null;
  private config: DatabaseConfig;

  constructor(config: DatabaseConfig) {
    this.config = config;
  }

  async initialize(): Promise<void> {
    const dbPath = this.getDbPath();

    // Ensure directory exists
    const dir = path.dirname(dbPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
      logger.info({ dir }, 'Created database directory');
    }

    this.db = new Database(dbPath, { create: true });

    // Enable WAL mode for better concurrent access
    this.db.exec('PRAGMA journal_mode = WAL');
    // Enable foreign keys
    this.db.exec('PRAGMA foreign_keys = ON');

    logger.info({ path: dbPath }, 'SQLite database initialized');
  }

  async close(): Promise<void> {
    if (this.db) {
      this.db.close();
      this.db = null;
      logger.info('SQLite database closed');
    }
  }

  async execute(sql: string, params: unknown[] = []): Promise<void> {
    this.ensureConnected();
    this.db!.run(sql, ...params);
  }

  async query<T>(sql: string, params: unknown[] = []): Promise<T[]> {
    this.ensureConnected();
    const stmt = this.db!.prepare(sql);
    return stmt.all(...params) as T[];
  }

  async get<T>(sql: string, params: unknown[] = []): Promise<T | null> {
    this.ensureConnected();
    const stmt = this.db!.prepare(sql);
    const result = stmt.get(...params);
    return (result as T) ?? null;
  }

  async insert(sql: string, params: unknown[] = []): Promise<number> {
    this.ensureConnected();
    const stmt = this.db!.prepare(sql);
    const result = stmt.run(...params);
    return Number(result.lastInsertRowid);
  }

  async update(sql: string, params: unknown[] = []): Promise<number> {
    this.ensureConnected();
    const stmt = this.db!.prepare(sql);
    const result = stmt.run(...params);
    return result.changes;
  }

  async delete(sql: string, params: unknown[] = []): Promise<number> {
    this.ensureConnected();
    const stmt = this.db!.prepare(sql);
    const result = stmt.run(...params);
    return result.changes;
  }

  async transaction<T>(fn: (tx: TransactionContext) => Promise<T>): Promise<T> {
    this.ensureConnected();

    const tx: TransactionContext = {
      execute: async (sql, params = []) => {
        this.db!.run(sql, ...params);
      },
      query: async <T>(sql: string, params: unknown[] = []) => {
        const stmt = this.db!.prepare(sql);
        return stmt.all(...params) as T[];
      },
      get: async <T>(sql: string, params: unknown[] = []) => {
        const stmt = this.db!.prepare(sql);
        const result = stmt.get(...params);
        return (result as T) ?? null;
      },
      insert: async (sql, params = []) => {
        const stmt = this.db!.prepare(sql);
        const result = stmt.run(...params);
        return Number(result.lastInsertRowid);
      },
      update: async (sql, params = []) => {
        const stmt = this.db!.prepare(sql);
        const result = stmt.run(...params);
        return result.changes;
      },
      delete: async (sql, params = []) => {
        const stmt = this.db!.prepare(sql);
        const result = stmt.run(...params);
        return result.changes;
      },
    };

    // Use Bun's transaction helper
    const runTx = this.db!.transaction(() => fn(tx));
    return runTx() as T;
  }

  async healthCheck(): Promise<boolean> {
    try {
      this.ensureConnected();
      this.db!.prepare('SELECT 1').get();
      return true;
    } catch (error) {
      logger.error({ error }, 'Health check failed');
      return false;
    }
  }

  /**
   * Get the database instance for direct access (use sparingly)
   */
  getDatabase(): Database {
    this.ensureConnected();
    return this.db!;
  }

  private getDbPath(): string {
    if (this.config.path && this.config.filename) {
      return path.join(this.config.path, this.config.filename);
    }
    if (this.config.path) {
      return path.join(this.config.path, 'agency.db');
    }
    return ':memory:';
  }

  private ensureConnected(): void {
    if (!this.db) {
      throw new Error('Database not initialized. Call initialize() first.');
    }
  }
}

/**
 * Factory function to create SQLite adapter
 */
export function createSQLiteAdapter(config: DatabaseConfig): DatabaseAdapter {
  return new SQLiteAdapter(config);
}
