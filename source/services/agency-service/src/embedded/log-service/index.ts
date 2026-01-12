/**
 * Log Service
 *
 * Embedded service for log aggregation and querying.
 * Can be extracted to standalone service later.
 */

import { Hono } from 'hono';
import type { DatabaseAdapter } from '../../core/adapters/database';
import { LogRepository } from './repository/log.repository';
import { LogService } from './service/log.service';
import { createLogRoutes } from './routes/log.routes';
import { createServiceLogger } from '../../core/lib/logger';

const logger = createServiceLogger('log-service-init');

export interface LogServiceOptions {
  db: DatabaseAdapter;
}

export interface LogServiceInstance {
  routes: Hono;
  service: LogService;
  initialize(): Promise<void>;
}

/**
 * Create the log-service embedded service
 */
export function createLogService(options: LogServiceOptions): LogServiceInstance {
  const repository = new LogRepository(options.db);
  const service = new LogService(repository);
  const routes = createLogRoutes(service);

  return {
    routes,
    service,
    async initialize() {
      await repository.initialize();
      logger.info('Log Service initialized');
    },
  };
}

// Re-export types
export * from './types';
export { LogRepository } from './repository/log.repository';
export { LogService } from './service/log.service';
