/**
 * Messages Service
 *
 * Embedded service for inter-entity messaging.
 * Can be extracted to standalone service later.
 */

import { Hono } from 'hono';
import type { DatabaseAdapter } from '../../core/adapters/database';
import type { QueueAdapter } from '../../core/adapters/queue';
import { MessageRepository } from './repository/message.repository';
import { MessageService } from './service/message.service';
import { createMessageRoutes } from './routes/message.routes';
import { createServiceLogger } from '../../core/lib/logger';

const logger = createServiceLogger('messages-service');

export interface MessagesServiceOptions {
  db: DatabaseAdapter;
  queue?: QueueAdapter;
}

export interface MessagesServiceInstance {
  routes: Hono;
  service: MessageService;
  initialize(): Promise<void>;
}

/**
 * Create the messages-service embedded service
 */
export function createMessagesService(options: MessagesServiceOptions): MessagesServiceInstance {
  const repository = new MessageRepository(options.db);
  const service = new MessageService(repository, options.queue);
  const routes = createMessageRoutes(service);

  return {
    routes,
    service,
    async initialize() {
      await repository.initialize();
      logger.info('Messages Service initialized');
    },
  };
}

// Re-export types
export * from './types';
export { MessageRepository } from './repository/message.repository';
export { MessageService } from './service/message.service';
