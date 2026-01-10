/**
 * Database Adapter Interface
 *
 * Vendor-neutral interface for database operations.
 * Implementations: SQLite (local), PostgreSQL (cloud)
 *
 * Design principle: "If you can't swap it by changing config + adding an adapter, it's too coupled."
 */

export interface DatabaseAdapter {
  /**
   * Initialize the database connection and run any pending migrations
   */
  initialize(): Promise<void>;

  /**
   * Close the database connection
   */
  close(): Promise<void>;

  /**
   * Execute a raw SQL query (use sparingly - prefer typed methods)
   */
  execute(sql: string, params?: unknown[]): Promise<void>;

  /**
   * Query rows with automatic type inference
   */
  query<T>(sql: string, params?: unknown[]): Promise<T[]>;

  /**
   * Get a single row
   */
  get<T>(sql: string, params?: unknown[]): Promise<T | null>;

  /**
   * Insert a row and return the inserted ID (for auto-increment)
   */
  insert(sql: string, params?: unknown[]): Promise<number>;

  /**
   * Update rows and return count of affected rows
   */
  update(sql: string, params?: unknown[]): Promise<number>;

  /**
   * Delete rows and return count of affected rows
   */
  delete(sql: string, params?: unknown[]): Promise<number>;

  /**
   * Run operations in a transaction
   */
  transaction<T>(fn: (tx: TransactionContext) => Promise<T>): Promise<T>;

  /**
   * Check if the database is connected and healthy
   */
  healthCheck(): Promise<boolean>;
}

/**
 * Transaction context - passed to transaction callbacks
 */
export interface TransactionContext {
  execute(sql: string, params?: unknown[]): Promise<void>;
  query<T>(sql: string, params?: unknown[]): Promise<T[]>;
  get<T>(sql: string, params?: unknown[]): Promise<T | null>;
  insert(sql: string, params?: unknown[]): Promise<number>;
  update(sql: string, params?: unknown[]): Promise<number>;
  delete(sql: string, params?: unknown[]): Promise<number>;
}

/**
 * Database adapter factory function type
 */
export type DatabaseAdapterFactory = (config: DatabaseConfig) => DatabaseAdapter;

/**
 * Database configuration
 */
export interface DatabaseConfig {
  adapter: 'sqlite' | 'postgres';
  // SQLite
  path?: string;
  filename?: string;
  // PostgreSQL
  url?: string;
  // Common
  debug?: boolean;
}
