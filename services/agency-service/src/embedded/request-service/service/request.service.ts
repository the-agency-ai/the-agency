/**
 * Request Service
 *
 * Business logic for request management.
 * Coordinates between repository and external systems.
 */

import type { QueueAdapter } from '../../../core/adapters/queue';
import type { RequestRepository } from '../repository/request.repository';
import type {
  Request,
  CreateRequestInput,
  UpdateRequestInput,
  ListRequestsQuery,
  RequestListResponse,
  RequestStats,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('request-service');

export class RequestService {
  constructor(
    private repository: RequestRepository,
    private queue?: QueueAdapter
  ) {}

  /**
   * Create a new request
   */
  async createRequest(data: CreateRequestInput): Promise<Request> {
    const requestId = await this.repository.getNextRequestId(data.principalName);
    const request = await this.repository.create(requestId, data);

    // Emit event for integrations
    if (this.queue) {
      await this.queue.emit('request.created', {
        requestId: request.requestId,
        principalName: request.principalName,
        title: request.title,
        priority: request.priority,
        assignee: request.assigneeName,
      });
    }

    logger.info({ requestId: request.requestId, principal: request.principalName }, 'Request created');
    return request;
  }

  /**
   * Get a request by ID
   */
  async getRequest(requestId: string): Promise<Request | null> {
    return this.repository.findByRequestId(requestId);
  }

  /**
   * List requests with filters, sorting, search
   */
  async listRequests(query: ListRequestsQuery): Promise<RequestListResponse> {
    const { requests, total } = await this.repository.list(query);

    return {
      requests,
      total,
      limit: query.limit,
      offset: query.offset,
    };
  }

  /**
   * Update a request
   */
  async updateRequest(requestId: string, data: UpdateRequestInput): Promise<Request | null> {
    const existing = await this.repository.findByRequestId(requestId);
    if (!existing) {
      return null;
    }

    const updated = await this.repository.update(requestId, data);

    // Emit event for status changes
    if (this.queue && data.status && data.status !== existing.status) {
      await this.queue.emit('request.status_changed', {
        requestId,
        previousStatus: existing.status,
        newStatus: data.status,
      });
    }

    // Emit event for assignment changes
    if (this.queue && data.assigneeName && data.assigneeName !== existing.assigneeName) {
      await this.queue.emit('request.assigned', {
        requestId,
        previousAssignee: existing.assigneeName,
        newAssignee: data.assigneeName,
      });
    }

    return updated;
  }

  /**
   * Update request status
   */
  async updateStatus(requestId: string, status: Request['status']): Promise<Request | null> {
    return this.updateRequest(requestId, { status });
  }

  /**
   * Assign a request
   */
  async assignRequest(
    requestId: string,
    assigneeType: 'agent' | 'principal',
    assigneeName: string
  ): Promise<Request | null> {
    return this.updateRequest(requestId, { assigneeType, assigneeName });
  }

  /**
   * Delete a request
   */
  async deleteRequest(requestId: string): Promise<boolean> {
    const deleted = await this.repository.delete(requestId);

    if (deleted && this.queue) {
      await this.queue.emit('request.deleted', { requestId });
    }

    return deleted;
  }

  /**
   * Get request statistics
   */
  async getStats(): Promise<RequestStats> {
    return this.repository.getStats();
  }
}
