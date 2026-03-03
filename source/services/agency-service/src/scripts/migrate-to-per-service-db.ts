#!/usr/bin/env bun
/**
 * Migration Script: Shared agency.db → Per-Service Databases
 *
 * Copies data from the monolithic agency.db into per-service database files.
 * Each service's tables are moved to {serviceName}.db.
 *
 * - Opens agency.db read-only
 * - Creates per-service adapters (which run schema initialization via initialize())
 * - Copies rows with INSERT OR IGNORE (idempotent — safe to re-run)
 * - Preserves agency.db as backup
 *
 * Usage:
 *   bun source/services/agency-service/src/scripts/migrate-to-per-service-db.ts
 */

import { Database } from 'bun:sqlite';
import { createDatabaseRegistry } from '../core/adapters/database';
import { getConfig } from '../core/config';
import path from 'path';
import fs from 'fs';

const SERVICE_TABLES: Record<string, string[]> = {
  messages: ['messages'],
  dispatch: ['dispatch_items', 'dispatch_instances'],
  request: ['requests', 'request_sequences'],
  log: ['log_entries', 'tool_runs'], // FTS rebuilt via triggers on insert
  bug: ['bugs', 'bug_sequences', 'bug_attachments'],
  secret: ['secrets', 'secret_tags', 'secret_grants', 'secret_access_log', 'vault_config', 'vault_recovery'],
  test: ['test_runs', 'test_results'],
  idea: ['ideas', 'idea_sequence'],
  observation: ['observations', 'observation_sequence'],
  product: ['products', 'product_contributors', 'product_sequences'],
};

async function migrate() {
  const config = getConfig();
  const dataDir = config.dbPath!;
  const agencyDbPath = path.join(dataDir, 'agency.db');

  if (!fs.existsSync(agencyDbPath)) {
    console.log('No agency.db found — nothing to migrate.');
    console.log(`Looked at: ${agencyDbPath}`);
    process.exit(0);
  }

  console.log(`Opening source database: ${agencyDbPath}`);
  const sourceDb = new Database(agencyDbPath, { readonly: true });

  // Get list of tables that actually exist in source
  const existingTables = new Set(
    (sourceDb.query("SELECT name FROM sqlite_master WHERE type='table'").all() as { name: string }[])
      .map(r => r.name)
  );
  console.log(`Source tables: ${Array.from(existingTables).join(', ')}`);

  // Create per-service databases via registry (runs schema initialization)
  const serviceNames = Object.keys(SERVICE_TABLES);
  const registry = createDatabaseRegistry(serviceNames);
  await registry.initializeAll();

  let totalRows = 0;

  for (const [service, tables] of Object.entries(SERVICE_TABLES)) {
    const adapter = registry.adapters.get(service)!;
    console.log(`\n--- Migrating: ${service} ---`);

    for (const table of tables) {
      if (!existingTables.has(table)) {
        console.log(`  ${table}: not in source, skipping`);
        continue;
      }

      // Get column names from source table
      // Note: table names come from hardcoded SERVICE_TABLES constant, not user input
      const pragmaSql = ['PRAGMA table_info(', table, ')'].join('');
      const columns = (sourceDb.query(pragmaSql).all() as { name: string }[])
        .map(c => c.name);

      // Count source rows
      const countSql = ['SELECT COUNT(*) as cnt FROM ', table].join('');
      const countResult = sourceDb.query(countSql).get() as { cnt: number };
      const sourceCount = countResult.cnt;

      if (sourceCount === 0) {
        console.log(`  ${table}: empty, skipping`);
        continue;
      }

      // Read all rows from source
      const selectSql = ['SELECT * FROM ', table].join('');
      const rows = sourceDb.query(selectSql).all() as Record<string, unknown>[];

      // Insert into target with INSERT OR IGNORE
      const placeholders = columns.map(() => '?').join(', ');
      const colList = columns.join(', ');
      const insertSql = ['INSERT OR IGNORE INTO ', table, ' (', colList, ') VALUES (', placeholders, ')'].join('');

      let inserted = 0;
      for (const row of rows) {
        const values = columns.map(col => row[col]);
        try {
          await adapter.execute(insertSql, values);
          inserted++;
        } catch (err) {
          console.error(`  ${table}: error inserting row:`, err);
        }
      }

      console.log(`  ${table}: ${inserted}/${sourceCount} rows migrated`);
      totalRows += inserted;
    }
  }

  // Close everything
  sourceDb.close();
  await registry.closeAll();

  console.log(`\n=== Migration complete ===`);
  console.log(`Total rows migrated: ${totalRows}`);
  console.log(`Original agency.db preserved at: ${agencyDbPath}`);
  console.log(`\nPer-service databases created in: ${dataDir}/`);
  for (const service of serviceNames) {
    const dbFile = path.join(dataDir, `${service}.db`);
    if (fs.existsSync(dbFile)) {
      const stats = fs.statSync(dbFile);
      console.log(`  ${service}.db (${(stats.size / 1024).toFixed(1)} KB)`);
    }
  }
}

migrate().catch((error) => {
  console.error('Migration failed:', error);
  process.exit(1);
});
