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

    // Emit event if queue is available
    if (this.queue) {
      await this.queue.emit('observation.created', {
        observationId,
        title: observation.title,
        category: observation.category,
        contextPath: observation.contextPath,
      });
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

    // Emit status change event if status changed
    if (this.queue && data.status && data.status !== existing.status) {
      await this.queue.emit('observation.status_changed', {
        observationId,
        previousStatus: existing.status,
        newStatus: data.status,
      });
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
      await this.queue.emit('observation.status_changed', {
        observationId,
        previousStatus: existing.status,
        newStatus: status,
      });
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
      await this.queue.emit('observation.deleted', { observationId });
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
