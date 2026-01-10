/**
 * Bug Service
 *
 * Embedded service for bug tracking domain.
 * Can be extracted to standalone service later.
 */

import { Hono } from 'hono';
import type { DatabaseAdapter } from '../../core/adapters/database';
import type { QueueAdapter } from '../../core/adapters/queue';
import { BugRepository } from './repository/bug.repository';
import { BugService } from './service/bug.service';
import { createBugRoutes } from './routes/bug.routes';
import { createServiceLogger } from '../../core/lib/logger';

const logger = createServiceLogger('bug-service');

export interface BugServiceOptions {
  db: DatabaseAdapter;
  queue?: QueueAdapter;
}

export interface BugServiceInstance {
  routes: Hono;
  service: BugService;
  initialize(): Promise<void>;
}

/**
 * Create the bug-service embedded service
 */
export function createBugService(options: BugServiceOptions): BugServiceInstance {
  const repository = new BugRepository(options.db);
  const service = new BugService(repository, options.queue);
  const routes = createBugRoutes(service);

  return {
    routes,
    service,
    async initialize() {
      await repository.initialize();
      logger.info('Bug Service initialized');
    },
  };
}

// Re-export types
export * from './types';
export { BugRepository } from './repository/bug.repository';
export { BugService } from './service/bug.service';
