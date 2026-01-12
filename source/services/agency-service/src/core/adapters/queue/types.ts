/**
 * Queue Adapter Interface
 *
 * Vendor-neutral interface for message queue operations.
 * Implementations: SQLite-backed (local), Redis/BullMQ (cloud)
 *
 * Design note: SQLite as queue isn't elegant (polling), but pragmatic for local.
 * Interface designed to swap to push-based system without changing consumers.
 */

export interface QueueAdapter {
  /**
   * Initialize the queue (create tables, connect, etc.)
   */
  initialize(): Promise<void>;

  /**
   * Close the queue connection
   */
  close(): Promise<void>;

  /**
   * Add a job to a queue
   */
  enqueue<T extends Record<string, unknown>>(
    queueName: string,
    job: QueueJob<T>
  ): Promise<string>; // Returns job ID

  /**
   * Get the next job from a queue (marks it as processing)
   */
  dequeue<T extends Record<string, unknown>>(
    queueName: string
  ): Promise<QueueJob<T> | null>;

  /**
   * Mark a job as completed
   */
  complete(jobId: string): Promise<void>;

  /**
   * Mark a job as failed (will be retried based on config)
   */
  fail(jobId: string, error: string): Promise<void>;

  /**
   * Get pending jobs count for a queue
   */
  getPendingCount(queueName: string): Promise<number>;

  /**
   * Subscribe to jobs on a queue (for push-based adapters)
   * For polling adapters, this starts a polling loop
   */
  subscribe<T extends Record<string, unknown>>(
    queueName: string,
    handler: QueueHandler<T>
  ): Promise<QueueSubscription>;

  /**
   * Health check
   */
  healthCheck(): Promise<boolean>;
}

/**
 * A job in the queue
 */
export interface QueueJob<T extends Record<string, unknown> = Record<string, unknown>> {
  id?: string;
  data: T;
  priority?: number; // Higher = more urgent
  attempts?: number;
  maxAttempts?: number;
  delay?: number; // Delay in ms before processing
  createdAt?: Date;
  processedAt?: Date;
}

/**
 * Job handler function
 */
export type QueueHandler<T extends Record<string, unknown>> = (
  job: QueueJob<T>
) => Promise<void>;

/**
 * Subscription handle for unsubscribing
 */
export interface QueueSubscription {
  unsubscribe(): Promise<void>;
}

/**
 * Queue configuration
 */
export interface QueueConfig {
  adapter: 'sqlite' | 'redis';
  // SQLite
  dbPath?: string;
  pollInterval?: number; // ms between polls (default 1000)
  // Redis
  redisUrl?: string;
}

/**
 * Queue adapter factory function type
 */
export type QueueAdapterFactory = (config: QueueConfig) => QueueAdapter;
