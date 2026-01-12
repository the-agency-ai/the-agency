/**
 * Bug Service Tests
 *
 * Tests for bug business logic layer.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { BugRepository } from '../../src/embedded/bug-service/repository/bug.repository';
import { BugService } from '../../src/embedded/bug-service/service/bug.service';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Bug Service', () => {
  let db: DatabaseAdapter;
  let repo: BugRepository;
  let service: BugService;
  const testDbPath = '/tmp/agency-test-bug-service';
  const testDbFile = `${testDbPath}/bugs.db`;

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'bugs.db',
    });
    await db.initialize();
    repo = new BugRepository(db);
    await repo.initialize();
    service = new BugService(repo); // No queue for tests
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

  describe('createBug', () => {
    test('should create bug with auto-generated ID', async () => {
      const bug = await service.createBug({
        workstream: 'service',
        summary: 'New bug via service',
        reporterType: 'agent',
        reporterName: 'test-agent',
      });

      expect(bug.bugId).toBe('SERVICE-00001');
      expect(bug.status).toBe('Open');
    });

    test('should create multiple bugs with sequential IDs', async () => {
      const bug1 = await service.createBug({
        workstream: 'seq',
        summary: 'First bug',
        reporterType: 'agent',
        reporterName: 'test',
      });

      const bug2 = await service.createBug({
        workstream: 'seq',
        summary: 'Second bug',
        reporterType: 'agent',
        reporterName: 'test',
      });

      expect(bug1.bugId).toBe('SEQ-00001');
      expect(bug2.bugId).toBe('SEQ-00002');
    });

    test('should create bug with assignee', async () => {
      const bug = await service.createBug({
        workstream: 'assign',
        summary: 'Assigned bug',
        reporterType: 'principal',
        reporterName: 'jordan',
        assigneeType: 'agent',
        assigneeName: 'housekeeping',
      });

      expect(bug.assigneeName).toBe('housekeeping');
      expect(bug.assigneeType).toBe('agent');
    });
  });

  describe('getBug', () => {
    test('should get existing bug', async () => {
      const created = await service.createBug({
        workstream: 'get',
        summary: 'Bug to get',
        reporterType: 'agent',
        reporterName: 'test',
      });

      const found = await service.getBug(created.bugId);
      expect(found).not.toBeNull();
      expect(found!.bugId).toBe(created.bugId);
    });

    test('should return null for non-existent bug', async () => {
      const found = await service.getBug('FAKE-99999');
      expect(found).toBeNull();
    });
  });

  describe('listBugs', () => {
    beforeEach(async () => {
      await service.createBug({
        workstream: 'list',
        summary: 'Bug 1',
        reporterType: 'agent',
        reporterName: 'agent1',
      });
      await service.createBug({
        workstream: 'list',
        summary: 'Bug 2',
        reporterType: 'agent',
        reporterName: 'agent2',
      });
    });

    test('should list all bugs', async () => {
      const result = await service.listBugs({ limit: 50, offset: 0 });
      expect(result.bugs.length).toBe(2);
      expect(result.total).toBe(2);
    });

    test('should respect limit and offset', async () => {
      const result = await service.listBugs({ limit: 1, offset: 0 });
      expect(result.bugs.length).toBe(1);
      expect(result.limit).toBe(1);
      expect(result.offset).toBe(0);
    });
  });

  describe('updateBug', () => {
    test('should update bug status', async () => {
      const created = await service.createBug({
        workstream: 'update',
        summary: 'Bug to update',
        reporterType: 'agent',
        reporterName: 'test',
      });

      const updated = await service.updateBug(created.bugId, {
        status: 'In Progress',
      });

      expect(updated!.status).toBe('In Progress');
    });

    test('should update multiple fields', async () => {
      const created = await service.createBug({
        workstream: 'update',
        summary: 'Original summary',
        reporterType: 'agent',
        reporterName: 'test',
      });

      const updated = await service.updateBug(created.bugId, {
        summary: 'New summary',
        description: 'Added description',
        status: 'Fixed',
      });

      expect(updated!.summary).toBe('New summary');
      expect(updated!.description).toBe('Added description');
      expect(updated!.status).toBe('Fixed');
    });
  });

  describe('updateStatus', () => {
    test('should update status via convenience method', async () => {
      const created = await service.createBug({
        workstream: 'status',
        summary: 'Status test',
        reporterType: 'agent',
        reporterName: 'test',
      });

      const updated = await service.updateStatus(created.bugId, 'Fixed');
      expect(updated!.status).toBe('Fixed');
    });
  });

  describe('assignBug', () => {
    test('should assign bug to new assignee', async () => {
      const created = await service.createBug({
        workstream: 'assign',
        summary: 'To assign',
        reporterType: 'agent',
        reporterName: 'test',
      });

      const updated = await service.assignBug(created.bugId, 'agent', 'housekeeping');

      expect(updated!.assigneeName).toBe('housekeeping');
      expect(updated!.assigneeType).toBe('agent');
    });

    test('should reassign bug', async () => {
      const created = await service.createBug({
        workstream: 'reassign',
        summary: 'To reassign',
        reporterType: 'agent',
        reporterName: 'test',
        assigneeType: 'agent',
        assigneeName: 'agent1',
      });

      const updated = await service.assignBug(created.bugId, 'agent', 'agent2');
      expect(updated!.assigneeName).toBe('agent2');
    });
  });

  describe('deleteBug', () => {
    test('should delete existing bug', async () => {
      const created = await service.createBug({
        workstream: 'delete',
        summary: 'To delete',
        reporterType: 'agent',
        reporterName: 'test',
      });

      const deleted = await service.deleteBug(created.bugId);
      expect(deleted).toBe(true);

      const found = await service.getBug(created.bugId);
      expect(found).toBeNull();
    });

    test('should return false for non-existent bug', async () => {
      const deleted = await service.deleteBug('FAKE-99999');
      expect(deleted).toBe(false);
    });
  });

  describe('getStats', () => {
    test('should return correct statistics', async () => {
      await service.createBug({
        workstream: 'stats',
        summary: 'Open 1',
        reporterType: 'agent',
        reporterName: 'test',
      });

      await service.createBug({
        workstream: 'stats',
        summary: 'Open 2',
        reporterType: 'agent',
        reporterName: 'test',
      });

      const bug3 = await service.createBug({
        workstream: 'stats',
        summary: 'Will be fixed',
        reporterType: 'agent',
        reporterName: 'test',
      });
      await service.updateStatus(bug3.bugId, 'Fixed');

      const stats = await service.getStats();
      expect(stats.total).toBe(3);
      expect(stats.open).toBe(2);
      expect(stats.fixed).toBe(1);
    });
  });
});
