/**
 * Log Service
 *
 * Embedded service for log aggregation and querying.
 * Can be extracted to standalone service later.
 *
 * Features:
 * - Log ingestion and querying
 * - Tool run tracking
 * - Configurable retention with automatic cleanup
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
  retentionDays?: number; // Log retention in days (default: 30)
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
  const retentionDays = options.retentionDays ?? 30;

  return {
    routes,
    service,
    async initialize() {
      await repository.initialize();

      // Run automatic cleanup based on retention policy
      try {
        const { deleted } = await service.cleanup(retentionDays);
        if (deleted > 0) {
          logger.info({ deleted, retentionDays }, 'Log cleanup completed on startup');
        }
      } catch (err) {
        // Don't fail startup if cleanup fails
        logger.warn({ error: err }, 'Log cleanup failed on startup');
      }

      logger.info({ retentionDays }, 'Log Service initialized');
    },
  };
}

// Re-export types
export * from './types';
export { LogRepository } from './repository/log.repository';
export { LogService } from './service/log.service';
