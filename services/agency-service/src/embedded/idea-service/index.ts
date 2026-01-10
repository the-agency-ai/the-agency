/**
 * Idea Service
 *
 * Embedded service for quick idea capture and management.
 * Ideas can be promoted to REQUESTs when they're ready for implementation.
 */

import { Hono } from 'hono';
import type { DatabaseAdapter } from '../../core/adapters/database';
import { IdeaRepository } from './repository/idea.repository';
import { IdeaService } from './service/idea.service';
import { createIdeaRoutes } from './routes/idea.routes';
import { createServiceLogger } from '../../core/lib/logger';

const logger = createServiceLogger('idea-service');

export interface IdeaServiceOptions {
  db: DatabaseAdapter;
}

export interface IdeaServiceInstance {
  routes: Hono;
  service: IdeaService;
  initialize(): Promise<void>;
}

/**
 * Create the idea-service embedded service
 */
export function createIdeaService(options: IdeaServiceOptions): IdeaServiceInstance {
  const repository = new IdeaRepository(options.db);
  const service = new IdeaService(repository);
  const routes = createIdeaRoutes(service);

  return {
    routes,
    service,
    async initialize() {
      await repository.initialize();
      logger.info('Idea Service initialized');
    },
  };
}

// Re-export types
export * from './types';
export { IdeaRepository } from './repository/idea.repository';
export { IdeaService } from './service/idea.service';
