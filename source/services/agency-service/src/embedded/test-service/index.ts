/**
 * Test Service
 *
 * Embedded service for test execution and history tracking.
 * Provides API and data storage for test runs and results.
 */

import { Hono } from 'hono';
import type { DatabaseAdapter } from '../../core/adapters/database';
import { TestRunRepository } from './repository/test-run.repository';
import { TestService } from './service/test.service';
import { createTestRoutes } from './routes/test.routes';
import { createServiceLogger } from '../../core/lib/logger';

const logger = createServiceLogger('test-service-init');

export interface TestServiceOptions {
  db: DatabaseAdapter;
  projectRoot: string;
}

export interface TestServiceInstance {
  routes: Hono;
  service: TestService;
  initialize(): Promise<void>;
}

/**
 * Create the test-service embedded service
 */
export function createTestService(options: TestServiceOptions): TestServiceInstance {
  const service = new TestService(options.db, options.projectRoot);
  const routes = createTestRoutes(service);

  return {
    routes,
    service,
    async initialize() {
      await service.initialize();
      logger.info('Test Service initialized');
    },
  };
}

// Re-export types
export * from './types';
export { TestRunRepository } from './repository/test-run.repository';
export { TestService } from './service/test.service';
