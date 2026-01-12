/**
 * Queue Adapter Factory
 *
 * Creates the appropriate queue adapter based on configuration.
 * Swap adapters by changing AGENCY_QUEUE_ADAPTER environment variable.
 */

import type { QueueAdapter, QueueConfig } from './types';
import { createSQLiteQueueAdapter } from './sqlite.adapter';
import { getConfig } from '../../config';

export * from './types';
export { createSQLiteQueueAdapter } from './sqlite.adapter';

/**
 * Create a queue adapter based on current configuration
 */
export function createQueueAdapter(overrides?: Partial<QueueConfig>): QueueAdapter {
  const config = getConfig();

  const queueConfig: QueueConfig = {
    adapter: (overrides?.adapter || config.queueAdapter) as 'sqlite' | 'redis',
    dbPath: overrides?.dbPath || config.dbPath,
    redisUrl: overrides?.redisUrl || config.redisUrl,
    ...overrides,
  };

  switch (queueConfig.adapter) {
    case 'sqlite':
      return createSQLiteQueueAdapter(queueConfig);

    case 'redis':
      // TODO: Implement Redis/BullMQ adapter when needed
      throw new Error('Redis queue adapter not yet implemented. Use sqlite for now.');

    default:
      throw new Error(`Unknown queue adapter: ${queueConfig.adapter}`);
  }
}

// Singleton queue instance
let _queue: QueueAdapter | null = null;

/**
 * Get the singleton queue adapter instance
 */
export async function getQueue(): Promise<QueueAdapter> {
  if (!_queue) {
    _queue = createQueueAdapter();
    await _queue.initialize();
  }
  return _queue;
}

/**
 * Close the queue connection (for cleanup)
 */
export async function closeQueue(): Promise<void> {
  if (_queue) {
    await _queue.close();
    _queue = null;
  }
}
