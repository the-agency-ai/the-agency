/**
 * Database Adapter Factory
 *
 * Creates the appropriate database adapter based on configuration.
 * Swap adapters by changing AGENCY_DB_ADAPTER environment variable.
 */

import type { DatabaseAdapter, DatabaseConfig } from './types';
import { createSQLiteAdapter } from './sqlite.adapter';
import { getConfig } from '../../config';

export * from './types';
export { createSQLiteAdapter } from './sqlite.adapter';

/**
 * Create a database adapter based on current configuration
 */
export function createDatabaseAdapter(overrides?: Partial<DatabaseConfig>): DatabaseAdapter {
  const config = getConfig();

  const dbConfig: DatabaseConfig = {
    adapter: (overrides?.adapter || config.dbAdapter) as 'sqlite' | 'postgres',
    path: overrides?.path || config.dbPath,
    url: overrides?.url || config.dbUrl,
    debug: config.nodeEnv === 'development',
    ...overrides,
  };

  switch (dbConfig.adapter) {
    case 'sqlite':
      return createSQLiteAdapter(dbConfig);

    case 'postgres':
      // TODO: Implement PostgreSQL adapter when needed
      throw new Error('PostgreSQL adapter not yet implemented. Use sqlite for now.');

    default:
      throw new Error(`Unknown database adapter: ${dbConfig.adapter}`);
  }
}

// Singleton database instance
let _db: DatabaseAdapter | null = null;

/**
 * Get the singleton database adapter instance
 */
export async function getDatabase(): Promise<DatabaseAdapter> {
  if (!_db) {
    _db = createDatabaseAdapter();
    await _db.initialize();
  }
  return _db;
}

/**
 * Close the database connection (for cleanup)
 */
export async function closeDatabase(): Promise<void> {
  if (_db) {
    await _db.close();
    _db = null;
  }
}
