/**
 * Dispatch Service
 *
 * Embedded service for work dispatch and instance registry.
 * Manages agent queues, shared queue, and claim lifecycle.
 */

import { Hono } from 'hono';
import type { DatabaseAdapter } from '../../core/adapters/database';
import type { QueueAdapter } from '../../core/adapters/queue';
import { DispatchRepository } from './repository/dispatch.repository';
import { DispatchService } from './service/dispatch.service';
import { createDispatchRoutes } from './routes/dispatch.routes';
import { createServiceLogger } from '../../core/lib/logger';

const logger = createServiceLogger('dispatch-service');

export interface DispatchServiceOptions {
  db: DatabaseAdapter;
  queue?: QueueAdapter;
}

export interface DispatchServiceInstance {
  routes: Hono;
  service: DispatchService;
  initialize(): Promise<void>;
}

/**
 * Create the dispatch-service embedded service
 */
export function createDispatchService(options: DispatchServiceOptions): DispatchServiceInstance {
  const repository = new DispatchRepository(options.db);
  const service = new DispatchService(repository, options.queue);
  const routes = createDispatchRoutes(service);

  return {
    routes,
    service,
    async initialize() {
      await repository.initialize();
      service.startSweep(); // Background claim expiry sweep
      logger.info('Dispatch Service initialized');
    },
  };
}

// Re-export types
export * from './types';
export { DispatchRepository } from './repository/dispatch.repository';
export { DispatchService } from './service/dispatch.service';
