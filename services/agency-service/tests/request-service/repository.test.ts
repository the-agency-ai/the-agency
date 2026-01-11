/**
 * Request Repository Tests
 *
 * Tests for request data access layer.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { RequestRepository } from '../../src/embedded/request-service/repository/request.repository';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Request Repository', () => {
  let db: DatabaseAdapter;
  let repo: RequestRepository;
  const testDbPath = '/tmp/agency-test-requests';
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

  describe('getNextRequestId', () => {
    test('should generate sequential IDs for principal', async () => {
      const id1 = await repo.getNextRequestId('jordan');
      const id2 = await repo.getNextRequestId('jordan');
      const id3 = await repo.getNextRequestId('jordan');

      expect(id1).toBe('REQUEST-jordan-0001');
      expect(id2).toBe('REQUEST-jordan-0002');
      expect(id3).toBe('REQUEST-jordan-0003');
    });

    test('should lowercase principal', async () => {
      const id = await repo.getNextRequestId('Jordan');
      expect(id).toBe('REQUEST-jordan-0001');
    });

    test('should maintain separate sequences per principal', async () => {
      const idA1 = await repo.getNextRequestId('alice');
      const idB1 = await repo.getNextRequestId('bob');
      const idA2 = await repo.getNextRequestId('alice');

      expect(idA1).toBe('REQUEST-alice-0001');
      expect(idB1).toBe('REQUEST-bob-0001');
      expect(idA2).toBe('REQUEST-alice-0002');
    });
  });

  describe('create', () => {
    test('should create request with required fields', async () => {
      const requestId = await repo.getNextRequestId('jordan');
      const request = await repo.create(requestId, {
        title: 'Test request',
        summary: 'This is a test request',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      expect(request.requestId).toBe('REQUEST-jordan-0001');
      expect(request.title).toBe('Test request');
      expect(request.status).toBe('Open');
      expect(request.priority).toBe('Medium');
      expect(request.principalName).toBe('jordan');
      expect(request.assigneeName).toBeNull();
    });

    test('should create request with optional fields', async () => {
      const requestId = await repo.getNextRequestId('jordan');
      const request = await repo.create(requestId, {
        title: 'Full request',
        summary: 'Request with all fields',
        principalName: 'jordan',
        priority: 'High',
        reporterType: 'agent',
        reporterName: 'housekeeping',
        assigneeType: 'agent',
        assigneeName: 'web-agent',
        workstream: 'housekeeping',
        tags: ['urgent', 'feature'],
      });

      expect(request.priority).toBe('High');
      expect(request.assigneeName).toBe('web-agent');
      expect(request.workstream).toBe('housekeeping');
      expect(request.tags).toEqual(['urgent', 'feature']);
    });
  });

  describe('findByRequestId', () => {
    test('should find existing request', async () => {
      const requestId = await repo.getNextRequestId('jordan');
      await repo.create(requestId, {
        title: 'Findable request',
        summary: 'Can be found',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      const found = await repo.findByRequestId(requestId);
      expect(found).not.toBeNull();
      expect(found!.title).toBe('Findable request');
    });

    test('should return null for non-existent request', async () => {
      const found = await repo.findByRequestId('REQUEST-fake-9999');
      expect(found).toBeNull();
    });
  });

  describe('list', () => {
    beforeEach(async () => {
      // Create test requests
      for (const principal of ['alice', 'bob']) {
        for (const status of ['Open', 'Complete']) {
          const requestId = await repo.getNextRequestId(principal);
          await repo.create(requestId, {
            title: `${principal} ${status} request`,
            summary: `A ${status.toLowerCase()} request from ${principal}`,
            principalName: principal,
            reporterType: 'principal',
            reporterName: principal,
          });
          if (status === 'Complete') {
            await repo.update(requestId, { status: 'Complete' });
          }
        }
      }
    });

    test('should list all requests', async () => {
      const { requests, total } = await repo.list({ limit: 50, offset: 0, sortBy: 'createdAt', sortOrder: 'desc' });
      expect(total).toBe(4);
      expect(requests.length).toBe(4);
    });

    test('should filter by principal', async () => {
      const { requests, total } = await repo.list({ principal: 'alice', limit: 50, offset: 0, sortBy: 'createdAt', sortOrder: 'desc' });
      expect(total).toBe(2);
      expect(requests.every(r => r.principalName === 'alice')).toBe(true);
    });

    test('should filter by status', async () => {
      const { requests, total } = await repo.list({ status: 'Complete', limit: 50, offset: 0, sortBy: 'createdAt', sortOrder: 'desc' });
      expect(total).toBe(2);
      expect(requests.every(r => r.status === 'Complete')).toBe(true);
    });

    test('should paginate results', async () => {
      const page1 = await repo.list({ limit: 2, offset: 0, sortBy: 'createdAt', sortOrder: 'desc' });
      const page2 = await repo.list({ limit: 2, offset: 2, sortBy: 'createdAt', sortOrder: 'desc' });

      expect(page1.requests.length).toBe(2);
      expect(page2.requests.length).toBe(2);
      expect(page1.requests[0].requestId).not.toBe(page2.requests[0].requestId);
    });

    test('should sort by title ascending', async () => {
      const { requests } = await repo.list({ limit: 50, offset: 0, sortBy: 'title', sortOrder: 'asc' });
      for (let i = 1; i < requests.length; i++) {
        expect(requests[i].title >= requests[i - 1].title).toBe(true);
      }
    });

    test('should sort by title descending', async () => {
      const { requests } = await repo.list({ limit: 50, offset: 0, sortBy: 'title', sortOrder: 'desc' });
      for (let i = 1; i < requests.length; i++) {
        expect(requests[i].title <= requests[i - 1].title).toBe(true);
      }
    });

    test('should search in title and summary', async () => {
      const requestId = await repo.getNextRequestId('charlie');
      await repo.create(requestId, {
        title: 'Unique searchable title',
        summary: 'This has special keywords',
        principalName: 'charlie',
        reporterType: 'principal',
        reporterName: 'charlie',
      });

      const byTitle = await repo.list({ search: 'searchable', limit: 50, offset: 0, sortBy: 'createdAt', sortOrder: 'desc' });
      expect(byTitle.total).toBe(1);
      expect(byTitle.requests[0].title).toContain('searchable');

      const bySummary = await repo.list({ search: 'special keywords', limit: 50, offset: 0, sortBy: 'createdAt', sortOrder: 'desc' });
      expect(bySummary.total).toBe(1);
    });

    test('should escape LIKE special characters in search', async () => {
      const requestId = await repo.getNextRequestId('escape');
      await repo.create(requestId, {
        title: 'Request with 100% complete status',
        summary: 'Has special_underscore in text',
        principalName: 'escape',
        reporterType: 'principal',
        reporterName: 'escape',
      });

      // % and _ are SQL LIKE wildcards - should be escaped
      const byPercent = await repo.list({ search: '100%', limit: 50, offset: 0, sortBy: 'createdAt', sortOrder: 'desc' });
      expect(byPercent.total).toBe(1);

      const byUnderscore = await repo.list({ search: 'special_underscore', limit: 50, offset: 0, sortBy: 'createdAt', sortOrder: 'desc' });
      expect(byUnderscore.total).toBe(1);

      // A single % should not match everything
      const wildcardAttempt = await repo.list({ search: '%', limit: 50, offset: 0, sortBy: 'createdAt', sortOrder: 'desc' });
      expect(wildcardAttempt.total).toBe(1); // Only matches if literal % in text
    });

    test('should escape LIKE special characters in tag search', async () => {
      const requestId = await repo.getNextRequestId('tagsafe');
      await repo.create(requestId, {
        title: 'Tagged request',
        summary: 'Has special tags',
        principalName: 'tagsafe',
        reporterType: 'principal',
        reporterName: 'tagsafe',
        tags: ['100%', 'special_tag'],
      });

      const byPercent = await repo.list({ tags: '100%', limit: 50, offset: 0, sortBy: 'createdAt', sortOrder: 'desc' });
      expect(byPercent.total).toBe(1);

      const byUnderscore = await repo.list({ tags: 'special_tag', limit: 50, offset: 0, sortBy: 'createdAt', sortOrder: 'desc' });
      expect(byUnderscore.total).toBe(1);
    });

    test('should normalize invalid sort direction to ASC', async () => {
      const requestId = await repo.getNextRequestId('sortdir');
      await repo.create(requestId, {
        title: 'Sort test',
        summary: 'Testing sort direction',
        principalName: 'sortdir',
        reporterType: 'principal',
        reporterName: 'sortdir',
      });

      // Invalid sort direction should default to ASC without error
      // Filter by principal to isolate this test from beforeEach data
      const result = await repo.list({
        principal: 'sortdir',
        limit: 50,
        offset: 0,
        sortBy: 'title',
        sortOrder: 'INVALID; DROP TABLE requests;--' as any
      });
      expect(result.total).toBe(1);
    });

    test('should return empty results when offset exceeds total', async () => {
      const result = await repo.list({
        limit: 50,
        offset: 1000,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      // Total should reflect actual count, but requests should be empty
      expect(result.requests).toHaveLength(0);
    });

    test('should handle limit of 0', async () => {
      const requestId = await repo.getNextRequestId('limittest');
      await repo.create(requestId, {
        title: 'Limit test',
        summary: 'Testing limit zero',
        principalName: 'limittest',
        reporterType: 'principal',
        reporterName: 'limittest',
      });

      const result = await repo.list({
        principal: 'limittest',
        limit: 0,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      expect(result.total).toBe(1);
      expect(result.requests).toHaveLength(0);
    });

    test('should filter by multiple criteria (principal AND status)', async () => {
      // Create test data
      const r1 = await repo.getNextRequestId('combo');
      await repo.create(r1, {
        title: 'Combo Open',
        summary: 'Open request',
        principalName: 'combo',
        reporterType: 'principal',
        reporterName: 'combo',
      });

      const r2 = await repo.getNextRequestId('combo');
      await repo.create(r2, {
        title: 'Combo Complete',
        summary: 'Complete request',
        principalName: 'combo',
        reporterType: 'principal',
        reporterName: 'combo',
      });
      await repo.update(r2, { status: 'Complete' });

      // Filter by principal AND status
      const result = await repo.list({
        principal: 'combo',
        status: 'Open',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });

      expect(result.total).toBe(1);
      expect(result.requests[0].status).toBe('Open');
    });

    test('should filter by assignee and reporter', async () => {
      const requestId = await repo.getNextRequestId('filters');
      await repo.create(requestId, {
        title: 'Assigned request',
        summary: 'Has assignee',
        principalName: 'filters',
        reporterType: 'agent',
        reporterName: 'housekeeping',
        assigneeType: 'agent',
        assigneeName: 'web-agent',
      });

      const byAssignee = await repo.list({
        assignee: 'web-agent',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      expect(byAssignee.total).toBe(1);
      expect(byAssignee.requests[0].assigneeName).toBe('web-agent');

      const byReporter = await repo.list({
        reporter: 'housekeeping',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      expect(byReporter.total).toBe(1);
      expect(byReporter.requests[0].reporterName).toBe('housekeeping');
    });
  });

  describe('update', () => {
    test('should update request status', async () => {
      const requestId = await repo.getNextRequestId('jordan');
      await repo.create(requestId, {
        title: 'To be updated',
        summary: 'Status will change',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      const updated = await repo.update(requestId, { status: 'In Progress' });
      expect(updated!.status).toBe('In Progress');
    });

    test('should update request priority', async () => {
      const requestId = await repo.getNextRequestId('jordan');
      await repo.create(requestId, {
        title: 'Priority change',
        summary: 'Will become critical',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      const updated = await repo.update(requestId, { priority: 'Critical' });
      expect(updated!.priority).toBe('Critical');
    });

    test('should update assignee', async () => {
      const requestId = await repo.getNextRequestId('jordan');
      await repo.create(requestId, {
        title: 'Unassigned request',
        summary: 'Needs assignment',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      const updated = await repo.update(requestId, {
        assigneeType: 'agent',
        assigneeName: 'housekeeping',
      });

      expect(updated!.assigneeName).toBe('housekeeping');
      expect(updated!.assigneeType).toBe('agent');
    });

    test('should update tags', async () => {
      const requestId = await repo.getNextRequestId('jordan');
      await repo.create(requestId, {
        title: 'Tagged request',
        summary: 'Has tags',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
        tags: ['initial'],
      });

      const updated = await repo.update(requestId, { tags: ['updated', 'modified'] });
      expect(updated!.tags).toEqual(['updated', 'modified']);
    });

    test('should return null for non-existent request', async () => {
      const updated = await repo.update('REQUEST-fake-9999', { status: 'Complete' });
      expect(updated).toBeNull();
    });
  });

  describe('delete', () => {
    test('should delete existing request', async () => {
      const requestId = await repo.getNextRequestId('jordan');
      await repo.create(requestId, {
        title: 'To be deleted',
        summary: 'Will be removed',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
      });

      const deleted = await repo.delete(requestId);
      expect(deleted).toBe(true);

      const found = await repo.findByRequestId(requestId);
      expect(found).toBeNull();
    });

    test('should return false for non-existent request', async () => {
      const deleted = await repo.delete('REQUEST-fake-9999');
      expect(deleted).toBe(false);
    });
  });

  describe('getStats', () => {
    test('should return correct statistics', async () => {
      // Create requests with different statuses and priorities
      const statuses = ['Open', 'In Progress', 'Review', 'Complete'];
      const priorities = ['Low', 'Medium', 'High', 'Critical'];

      for (let i = 0; i < statuses.length; i++) {
        const requestId = await repo.getNextRequestId('stats');
        await repo.create(requestId, {
          title: `Request ${i}`,
          summary: `Status: ${statuses[i]}, Priority: ${priorities[i]}`,
          principalName: 'stats',
          priority: priorities[i] as 'Low' | 'Medium' | 'High' | 'Critical',
          reporterType: 'principal',
          reporterName: 'stats',
        });
        if (statuses[i] !== 'Open') {
          await repo.update(requestId, { status: statuses[i] as any });
        }
      }

      const stats = await repo.getStats();
      expect(stats.total).toBe(4);
      expect(stats.open).toBe(1);
      expect(stats.inProgress).toBe(1);
      expect(stats.review).toBe(1);
      expect(stats.complete).toBe(1);
      expect(stats.byPriority.low).toBe(1);
      expect(stats.byPriority.medium).toBe(1);
      expect(stats.byPriority.high).toBe(1);
      expect(stats.byPriority.critical).toBe(1);
    });
  });
});
