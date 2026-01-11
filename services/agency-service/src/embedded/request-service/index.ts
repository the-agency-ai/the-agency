/**
 * Request Service
 *
 * Embedded service for REQUEST tracking domain.
 * Can be extracted to standalone service later.
 */

import { Hono } from 'hono';
import type { DatabaseAdapter } from '../../core/adapters/database';
import type { QueueAdapter } from '../../core/adapters/queue';
import { RequestRepository } from './repository/request.repository';
import { RequestService } from './service/request.service';
import { createRequestRoutes } from './routes/request.routes';
import { createServiceLogger } from '../../core/lib/logger';

const logger = createServiceLogger('request-service');

export interface RequestServiceOptions {
  db: DatabaseAdapter;
  queue?: QueueAdapter;
}

export interface RequestServiceInstance {
  routes: Hono;
  service: RequestService;
  initialize(): Promise<void>;
}

/**
 * Create the request-service embedded service
 */
export function createRequestService(options: RequestServiceOptions): RequestServiceInstance {
  const repository = new RequestRepository(options.db);
  const service = new RequestService(repository, options.queue);
  const routes = createRequestRoutes(service);

  return {
    routes,
    service,
    async initialize() {
      await repository.initialize();
      logger.info('Request Service initialized');
    },
  };
}

// Re-export types
export * from './types';
export { RequestRepository } from './repository/request.repository';
export { RequestService } from './service/request.service';
