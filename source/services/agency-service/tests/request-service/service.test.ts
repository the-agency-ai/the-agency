/**
 * Request Service Tests
 *
 * Tests for request business logic layer.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { RequestRepository } from '../../src/embedded/request-service/repository/request.repository';
import { RequestService } from '../../src/embedded/request-service/service/request.service';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Request Service', () => {
  let db: DatabaseAdapter;
  let repo: RequestRepository;
  let service: RequestService;
  const testDbPath = '/tmp/agency-test-request-service';
  const testDbFile = `${testDbPath}/requests.db`;

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'requests.db',
    });
    await db.initialize();
    repo = new RequestRepository(db);
    await repo.initialize();
    service = new RequestService(repo);
  });

  afterEach(async () => {
    await db.close();
    try {
      if (existsSync(testDbFile)) await unlink(testDbFile);
      if (existsSync(`${testDbFile}-wal`)) await unlink(`${testDbFile}-wal`);
      if (existsSync(`${testDbFile}-shm`)) await unlink(`${testDbFile}-shm`);
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  describe('createRequest', () => {
    test('should create request and return it', async () => {
      const request = await service.createRequest({
        title: 'New feature request',
        summary: 'Please add this feature',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      expect(request.requestId).toMatch(/^REQUEST-jordan-\d{4}$/);
      expect(request.title).toBe('New feature request');
      expect(request.status).toBe('Open');
    });

    test('should generate unique IDs', async () => {
      const r1 = await service.createRequest({
        title: 'First',
        summary: 'First request',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      const r2 = await service.createRequest({
        title: 'Second',
        summary: 'Second request',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      expect(r1.requestId).not.toBe(r2.requestId);
    });
  });

  describe('getRequest', () => {
    test('should return request by ID', async () => {
      const created = await service.createRequest({
        title: 'Find me',
        summary: 'Can be found',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      const found = await service.getRequest(created.requestId);
      expect(found).not.toBeNull();
      expect(found!.title).toBe('Find me');
    });

    test('should return null for non-existent', async () => {
      const found = await service.getRequest('REQUEST-fake-9999');
      expect(found).toBeNull();
    });
  });

  describe('listRequests', () => {
    beforeEach(async () => {
      await service.createRequest({
        title: 'Open request',
        summary: 'Still open',
        principalName: 'alice',
        reporterType: 'principal',
        reporterName: 'alice',
      });

      const complete = await service.createRequest({
        title: 'Complete request',
        summary: 'Done',
        principalName: 'bob',
        reporterType: 'principal',
        reporterName: 'bob',
      });
      await service.updateStatus(complete.requestId, 'Complete');
    });

    test('should list all requests', async () => {
      const result = await service.listRequests({
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });

      expect(result.total).toBe(2);
      expect(result.requests.length).toBe(2);
    });

    test('should filter by status', async () => {
      const result = await service.listRequests({
        status: 'Complete',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });

      expect(result.total).toBe(1);
      expect(result.requests[0].title).toBe('Complete request');
    });

    test('should filter by principal', async () => {
      const result = await service.listRequests({
        principal: 'alice',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });

      expect(result.total).toBe(1);
      expect(result.requests[0].principalName).toBe('alice');
    });
  });

  describe('updateRequest', () => {
    test('should update multiple fields', async () => {
      const created = await service.createRequest({
        title: 'Original',
        summary: 'Will be updated',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      const updated = await service.updateRequest(created.requestId, {
        title: 'Updated title',
        priority: 'High',
        tags: ['urgent'],
      });

      expect(updated!.title).toBe('Updated title');
      expect(updated!.priority).toBe('High');
      expect(updated!.tags).toEqual(['urgent']);
    });
  });

  describe('updateStatus', () => {
    test('should change status', async () => {
      const created = await service.createRequest({
        title: 'Status test',
        summary: 'Status will change',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      expect(created.status).toBe('Open');

      const updated = await service.updateStatus(created.requestId, 'In Progress');
      expect(updated!.status).toBe('In Progress');
    });

    test('should return null for non-existent request', async () => {
      const result = await service.updateStatus('REQUEST-fake-9999', 'Complete');
      expect(result).toBeNull();
    });

    test('should transition through all valid status values', async () => {
      const allStatuses = [
        'Open',
        'In Progress',
        'Review',
        'Testing',
        'Complete',
        'On Hold',
        'Cancelled',
      ] as const;

      for (const status of allStatuses) {
        const created = await service.createRequest({
          title: `Status ${status}`,
          summary: 'Testing all statuses',
          principalName: 'jordan',
          reporterType: 'principal',
          reporterName: 'jordan',
        });

        const updated = await service.updateStatus(created.requestId, status);
        expect(updated!.status).toBe(status);
      }
    });
  });

  describe('assignRequest', () => {
    test('should assign to agent', async () => {
      const created = await service.createRequest({
        title: 'Unassigned',
        summary: 'Needs assignment',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      const assigned = await service.assignRequest(created.requestId, 'agent', 'housekeeping');
      expect(assigned!.assigneeType).toBe('agent');
      expect(assigned!.assigneeName).toBe('housekeeping');
    });
  });

  describe('deleteRequest', () => {
    test('should delete existing request', async () => {
      const created = await service.createRequest({
        title: 'Delete me',
        summary: 'Will be removed',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      const deleted = await service.deleteRequest(created.requestId);
      expect(deleted).toBe(true);

      const found = await service.getRequest(created.requestId);
      expect(found).toBeNull();
    });
  });

  describe('getStats', () => {
    test('should return correct stats', async () => {
      // Create requests with various statuses
      await service.createRequest({
        title: 'Open 1',
        summary: 'Open',
        principalName: 'jordan',
        priority: 'Low',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      const inProgress = await service.createRequest({
        title: 'In Progress',
        summary: 'Working',
        principalName: 'jordan',
        priority: 'High',
        reporterType: 'principal',
        reporterName: 'jordan',
      });
      await service.updateStatus(inProgress.requestId, 'In Progress');

      const stats = await service.getStats();
      expect(stats.total).toBe(2);
      expect(stats.open).toBe(1);
      expect(stats.inProgress).toBe(1);
      expect(stats.byPriority.low).toBe(1);
      expect(stats.byPriority.high).toBe(1);
    });
  });
});
