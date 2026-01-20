/**
 * Agency Service Configuration
 *
 * Environment-based configuration with sensible local defaults.
 * Swap adapters by changing environment variables.
 */

import { z } from 'zod';

const configSchema = z.object({
  // Server
  port: z.number().default(3141),
  host: z.string().default('127.0.0.1'),

  // Environment
  nodeEnv: z.enum(['development', 'production', 'test']).default('development'),

  // Auth
  authMode: z.enum(['local', 'jwt']).default('local'),
  jwtSecret: z.string().optional(),

  // Database
  dbAdapter: z.enum(['sqlite', 'postgres']).default('sqlite'),
  dbPath: z.string().optional(), // For SQLite
  dbUrl: z.string().optional(),  // For PostgreSQL

  // Queue
  queueAdapter: z.enum(['sqlite', 'redis']).default('sqlite'),
  redisUrl: z.string().optional(),

  // Logging
  logLevel: z.enum(['trace', 'debug', 'info', 'warn', 'error', 'fatal']).default('info'),
  logDir: z.string().optional(),
  logRetentionDays: z.number().min(1).max(365).default(30), // Log retention in days

  // Paths
  projectRoot: z.string(),
});

export type Config = z.infer<typeof configSchema>;

function findProjectRoot(): string {
  // Walk up from service directory to find project root (has CLAUDE.md)
  let dir = process.cwd();
  const fs = require('fs');
  const path = require('path');

  // If we're in services/agency-service, go up
  if (dir.includes('services/agency-service')) {
    dir = path.resolve(dir, '../../');
  }

  // Look for CLAUDE.md as marker
  while (dir !== '/') {
    if (fs.existsSync(path.join(dir, 'CLAUDE.md'))) {
      return dir;
    }
    dir = path.dirname(dir);
  }

  // Fallback: use env or cwd
  return process.env.AGENCY_PROJECT_ROOT || process.cwd();
}

function loadConfig(): Config {
  const projectRoot = process.env.AGENCY_PROJECT_ROOT || findProjectRoot();
  const path = require('path');

  const raw = {
    port: parseInt(process.env.AGENCY_SERVICE_PORT || '3141', 10),
    host: process.env.AGENCY_SERVICE_HOST || '127.0.0.1',
    nodeEnv: process.env.NODE_ENV || 'development',
    authMode: process.env.AGENCY_AUTH_MODE || 'local',
    jwtSecret: process.env.AGENCY_JWT_SECRET,
    dbAdapter: process.env.AGENCY_DB_ADAPTER || 'sqlite',
    dbPath: process.env.AGENCY_DB_PATH || path.join(projectRoot, 'claude/data'),
    dbUrl: process.env.AGENCY_DB_URL,
    queueAdapter: process.env.AGENCY_QUEUE_ADAPTER || 'sqlite',
    redisUrl: process.env.AGENCY_REDIS_URL,
    logLevel: process.env.AGENCY_LOG_LEVEL || 'info',
    logDir: process.env.AGENCY_LOG_DIR || path.join(projectRoot, 'services/agency-service/logs'),
    logRetentionDays: parseInt(process.env.AGENCY_LOG_RETENTION_DAYS || '30', 10),
    projectRoot,
  };

  return configSchema.parse(raw);
}

// Singleton config
let _config: Config | null = null;

export function getConfig(): Config {
  if (!_config) {
    _config = loadConfig();
  }
  return _config;
}

// For testing
export function resetConfig(): void {
  _config = null;
}

export default getConfig;
