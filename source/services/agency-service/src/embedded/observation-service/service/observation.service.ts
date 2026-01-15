/**
 * Observation Service
 *
 * Business logic layer for observations.
 */

import type { ObservationRepository } from '../repository/observation.repository';
import type { QueueAdapter } from '../../../core/adapters/queue';
import type {
  Observation,
  CreateObservationInput,
  UpdateObservationInput,
  ListObservationsQuery,
  ObservationStatus,
  ObservationStats,
  ObservationListResponse,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('observation-service');

export class ObservationService {
  constructor(
    private repo: ObservationRepository,
    private queue?: QueueAdapter
  ) {}

  /**
   * Create a new observation
   */
  async createObservation(data: CreateObservationInput): Promise<Observation> {
    const observationId = await this.repo.getNextObservationId();
    const observation = await this.repo.create(observationId, data);

    logger.info({ observationId, reporter: data.reporterName }, 'Observation created');

    // Queue event if queue is available
    if (this.queue) {
      try {
        await this.queue.enqueue('observation.events', {
          data: {
            event: 'observation.created',
            observationId,
            title: observation.title,
            category: observation.category,
            contextPath: observation.contextPath,
          },
        });
      } catch (error) {
        // Queue failures should not block observation creation
        logger.warn({ error, observationId }, 'Failed to enqueue observation.created event');
      }
    }

    return observation;
  }

  /**
   * Get an observation by ID
   */
  async getObservation(observationId: string): Promise<Observation | null> {
    return this.repo.findByObservationId(observationId);
  }

  /**
   * List observations with filters
   */
  async listObservations(query: ListObservationsQuery): Promise<ObservationListResponse> {
    const { observations, total } = await this.repo.list(query);
    return {
      observations,
      total,
      limit: query.limit,
      offset: query.offset,
    };
  }

  /**
   * Update an observation
   */
  async updateObservation(observationId: string, data: UpdateObservationInput): Promise<Observation | null> {
    const existing = await this.repo.findByObservationId(observationId);
    if (!existing) {
      return null;
    }

    const updated = await this.repo.update(observationId, data);

    // Queue status change event if status changed
    if (this.queue && data.status && data.status !== existing.status) {
      try {
        await this.queue.enqueue('observation.events', {
          data: {
            event: 'observation.status_changed',
            observationId,
            previousStatus: existing.status,
            newStatus: data.status,
          },
        });
      } catch (error) {
        logger.warn({ error, observationId }, 'Failed to enqueue observation.status_changed event');
      }
    }

    return updated;
  }

  /**
   * Update just the status
   */
  async updateStatus(observationId: string, status: ObservationStatus): Promise<Observation | null> {
    const existing = await this.repo.findByObservationId(observationId);
    if (!existing) {
      return null;
    }

    const updated = await this.repo.update(observationId, { status });

    if (this.queue && status !== existing.status) {
      try {
        await this.queue.enqueue('observation.events', {
          data: {
            event: 'observation.status_changed',
            observationId,
            previousStatus: existing.status,
            newStatus: status,
          },
        });
      } catch (error) {
        logger.warn({ error, observationId }, 'Failed to enqueue observation.status_changed event');
      }
    }

    return updated;
  }

  /**
   * Acknowledge an observation (shortcut for status change)
   */
  async acknowledgeObservation(observationId: string): Promise<Observation | null> {
    return this.updateStatus(observationId, 'Acknowledged');
  }

  /**
   * Archive an observation
   */
  async archiveObservation(observationId: string): Promise<Observation | null> {
    return this.updateStatus(observationId, 'Archived');
  }

  /**
   * Delete an observation
   */
  async deleteObservation(observationId: string): Promise<boolean> {
    const deleted = await this.repo.delete(observationId);

    if (deleted && this.queue) {
      try {
        await this.queue.enqueue('observation.events', {
          data: {
            event: 'observation.deleted',
            observationId,
          },
        });
      } catch (error) {
        logger.warn({ error, observationId }, 'Failed to enqueue observation.deleted event');
      }
    }

    return deleted;
  }

  /**
   * Get observation statistics
   */
  async getStats(): Promise<ObservationStats> {
    return this.repo.getStats();
  }
}
