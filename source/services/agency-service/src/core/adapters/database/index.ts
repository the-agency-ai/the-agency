/**
 * Database Adapter Factory
 *
 * Creates the appropriate database adapter based on configuration.
 * Swap adapters by changing AGENCY_DB_ADAPTER environment variable.
 *
 * Per-service isolation: each embedded service gets its own database file
 * via createDatabaseAdapter({ serviceName: 'messages' }) → messages.db
 */

import type { DatabaseAdapter, DatabaseConfig } from './types';
import { createSQLiteAdapter } from './sqlite.adapter';
import { getConfig } from '../../config';

export * from './types';
export { createSQLiteAdapter } from './sqlite.adapter';

/**
 * Create a database adapter based on current configuration.
 *
 * When `serviceName` is provided, resolves to a per-service database file:
 *   - Checks env var AGENCY_DB_PATH_{SERVICE} (e.g., AGENCY_DB_PATH_MESSAGES)
 *   - Falls back to {dataDir}/{serviceName}.db
 */
export function createDatabaseAdapter(overrides?: Partial<DatabaseConfig> & { serviceName?: string }): DatabaseAdapter {
  const config = getConfig();

  // Resolve per-service filename
  let filename: string | undefined = overrides?.filename;
  let dbPath: string | undefined = overrides?.path || config.dbPath;

  if (overrides?.serviceName) {
    const envKey = `AGENCY_DB_PATH_${overrides.serviceName.toUpperCase()}`;
    const envOverride = process.env[envKey];
    if (envOverride) {
      // Full path override from env
      const path = require('path');
      dbPath = path.dirname(envOverride);
      filename = path.basename(envOverride);
    } else {
      filename = `${overrides.serviceName}.db`;
    }
  }

  const dbConfig: DatabaseConfig = {
    adapter: (overrides?.adapter || config.dbAdapter) as 'sqlite' | 'postgres',
    path: dbPath,
    filename,
    url: overrides?.url || config.dbUrl,
    debug: config.nodeEnv === 'development',
    ...overrides,
  };

  // Ensure serviceName-derived filename/path aren't clobbered by spread
  if (filename) dbConfig.filename = filename;
  if (dbPath) dbConfig.path = dbPath;

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

/**
 * Registry of per-service database adapters.
 * Provides lifecycle management for all service databases.
 */
export interface DatabaseRegistry {
  adapters: Map<string, DatabaseAdapter>;
  initializeAll(): Promise<void>;
  closeAll(): Promise<void>;
  healthCheckAll(): Promise<Record<string, boolean>>;
}

/**
 * Create a registry of per-service database adapters.
 * Each service gets its own isolated database file.
 */
export function createDatabaseRegistry(serviceNames: string[]): DatabaseRegistry {
  const adapters = new Map<string, DatabaseAdapter>();
  for (const name of serviceNames) {
    adapters.set(name, createDatabaseAdapter({ serviceName: name }));
  }

  return {
    adapters,

    async initializeAll() {
      await Promise.all(
        Array.from(adapters.values()).map(adapter => adapter.initialize())
      );
    },

    async closeAll() {
      await Promise.all(
        Array.from(adapters.values()).map(adapter => adapter.close())
      );
    },

    async healthCheckAll() {
      const results: Record<string, boolean> = {};
      await Promise.all(
        Array.from(adapters.entries()).map(async ([name, adapter]) => {
          results[name] = await adapter.healthCheck();
        })
      );
      return results;
    },
  };
}
