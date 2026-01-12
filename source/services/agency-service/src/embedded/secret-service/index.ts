/**
 * Secret Service
 *
 * Embedded service for managing secrets with encryption at rest.
 * Provides secure storage for passwords, API keys, tokens, and certificates.
 */

import type { Hono } from 'hono';
import type { DatabaseAdapter } from '../../core/adapters/database';
import { SecretRepository } from './repository/secret.repository';
import { SecretService } from './service/secret.service';
import { createSecretRoutes } from './routes/secret.routes';
import { createServiceLogger } from '../../core/lib/logger';

const logger = createServiceLogger('secret-service');

export interface SecretServiceConfig {
  db: DatabaseAdapter;
}

export interface SecretServiceInstance {
  routes: Hono;
  service: SecretService;
  repository: SecretRepository;
  initialize(): Promise<void>;
}

/**
 * Create a secret service instance
 */
export function createSecretService(config: SecretServiceConfig): SecretServiceInstance {
  const repository = new SecretRepository(config.db);
  const service = new SecretService(repository);
  const routes = createSecretRoutes(service);

  return {
    routes,
    service,
    repository,

    async initialize(): Promise<void> {
      await repository.initialize();
      logger.info('Secret Service initialized');
    },
  };
}

// Re-export types
export * from './types';
export { SecretRepository } from './repository/secret.repository';
export { SecretService } from './service/secret.service';
export { createSecretRoutes } from './routes/secret.routes';
