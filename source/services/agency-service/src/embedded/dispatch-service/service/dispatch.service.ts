/**
 * Dispatch Service
 *
 * Business logic layer for the dispatch queue system.
 * Handles work item lifecycle and instance management.
 */

import type {
  DispatchItem,
  DispatchInstance,
  EnqueueItemInput,
  ClaimItemInput,
  ListDispatchQuery,
  DispatchListResponse,
  DispatchStats,
  RegisterInstanceInput,
} from '../types';
import type { DispatchRepository } from '../repository/dispatch.repository';
import type { QueueAdapter } from '../../../core/adapters/queue';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('dispatch-service');

export class DispatchService {
  private sweepInterval: ReturnType<typeof setInterval> | null = null;

  constructor(
    private repository: DispatchRepository,
    private queue?: QueueAdapter
  ) {}

  /**
   * Start background sweep for expired claims
   */
  startSweep(intervalMs: number = 60000): void {
    if (this.sweepInterval) return;

    this.sweepInterval = setInterval(async () => {
      try {
        await this.repository.sweepExpiredClaims();
      } catch (error) {
        logger.warn({ error }, 'Claim sweep failed');
      }
    }, intervalMs);

    logger.info({ intervalMs }, 'Claim sweep started');
  }

  /**
   * Stop background sweep
   */
  stopSweep(): void {
    if (this.sweepInterval) {
      clearInterval(this.sweepInterval);
      this.sweepInterval = null;
    }
  }

  // ==================== Work Items ====================

  /**
   * Enqueue a work item
   */
  async enqueue(data: EnqueueItemInput): Promise<DispatchItem> {
    // Validate: agent queue requires agentName
    if (data.queueType === 'agent' && !data.agentName) {
      throw new Error('Agent queue items require agentName');
    }

    const item = await this.repository.enqueue(data);

    this.emitEvent('dispatch.enqueued', {
      itemId: item.id,
      queue: data.queueType,
      agent: data.agentName,
    });

    return item;
  }

  /**
   * Claim next available item
   */
  async claim(data: ClaimItemInput): Promise<DispatchItem | null> {
    // Sweep expired claims first
    await this.repository.sweepExpiredClaims();

    return this.repository.claim(data);
  }

  /**
   * Release a claimed item
   */
  async release(id: string): Promise<boolean> {
    return this.repository.release(id);
  }

  /**
   * Mark item as active
   */
  async activate(id: string): Promise<boolean> {
    return this.repository.activate(id);
  }

  /**
   * Complete an item
   */
  async complete(id: string, result?: string): Promise<boolean> {
    const completed = await this.repository.complete(id, result);

    if (completed) {
      this.emitEvent('dispatch.completed', { itemId: id });
    }

    return completed;
  }

  /**
   * Fail an item
   */
  async fail(id: string, error: string): Promise<boolean> {
    const failed = await this.repository.fail(id, error);

    if (failed) {
      this.emitEvent('dispatch.failed', { itemId: id, error });
    }

    return failed;
  }

  /**
   * Cancel a pending item
   */
  async cancel(id: string): Promise<boolean> {
    return this.repository.cancel(id);
  }

  /**
   * Peek at next available item without claiming
   */
  async peekNext(agentName: string): Promise<DispatchItem | null> {
    return this.repository.peekNext(agentName);
  }

  /**
   * Get an item by ID
   */
  async getItem(id: string): Promise<DispatchItem | null> {
    return this.repository.findById(id);
  }

  /**
   * List items with filtering
   */
  async listItems(query: ListDispatchQuery): Promise<DispatchListResponse> {
    const { items, total } = await this.repository.list(query);
    return {
      items,
      total,
      limit: query.limit,
      offset: query.offset,
    };
  }

  /**
   * Get queue statistics
   */
  async getStats(): Promise<DispatchStats> {
    return this.repository.getStats();
  }

  // ==================== Instance Registry ====================

  /**
   * Register an instance
   */
  async registerInstance(data: RegisterInstanceInput): Promise<DispatchInstance> {
    return this.repository.registerInstance(data);
  }

  /**
   * Heartbeat
   */
  async heartbeat(id: string): Promise<boolean> {
    return this.repository.heartbeat(id);
  }

  /**
   * Deregister an instance
   */
  async deregisterInstance(id: string): Promise<boolean> {
    return this.repository.deregisterInstance(id);
  }

  /**
   * Release all claims by an instance
   */
  async releaseAllByInstance(id: string): Promise<number> {
    return this.repository.releaseAllByInstance(id);
  }

  /**
   * List instances
   */
  async listInstances(): Promise<DispatchInstance[]> {
    return this.repository.listInstances();
  }

  /**
   * Emit a queue event (fire and forget)
   */
  private emitEvent(event: string, data: Record<string, unknown>): void {
    if (!this.queue) return;

    try {
      this.queue.enqueue('dispatch.events', { data: { event, ...data } });
    } catch (error) {
      logger.warn({ error, event }, 'Failed to emit dispatch event');
    }
  }
}
