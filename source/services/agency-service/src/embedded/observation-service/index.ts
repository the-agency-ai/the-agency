/**
 * Observation Service
 *
 * Factory function for creating and initializing the observation service.
 */

import type { Hono } from 'hono';
import type { DatabaseAdapter } from '../../core/adapters/database';
import type { QueueAdapter } from '../../core/adapters/queue';
import { ObservationRepository } from './repository/observation.repository';
import { ObservationService } from './service/observation.service';
import { createObservationRoutes } from './routes/observation.routes';

interface ObservationServiceConfig {
  db: DatabaseAdapter;
  queue?: QueueAdapter;
}

interface ObservationServiceInstance {
  routes: Hono;
  service: ObservationService;
  initialize: () => Promise<void>;
}

/**
 * Create and configure the observation service
 */
export function createObservationService(config: ObservationServiceConfig): ObservationServiceInstance {
  const repository = new ObservationRepository(config.db);
  const service = new ObservationService(repository, config.queue);
  const routes = createObservationRoutes(service);

  return {
    routes,
    service,
    initialize: async () => {
      await repository.initialize();
    },
  };
}

// Re-export types
export * from './types';
export { ObservationRepository } from './repository/observation.repository';
export { ObservationService } from './service/observation.service';
export { createObservationRoutes } from './routes/observation.routes';
