/**
 * Bug Repository Tests
 *
 * Tests for bug data access layer.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { BugRepository } from '../../src/embedded/bug-service/repository/bug.repository';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Bug Repository', () => {
  let db: DatabaseAdapter;
  let repo: BugRepository;
  const testDbPath = '/tmp/agency-test-bugs';
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

  describe('getNextBugId', () => {
    test('should generate sequential IDs for workstream', async () => {
      const id1 = await repo.getNextBugId('test');
      const id2 = await repo.getNextBugId('test');
      const id3 = await repo.getNextBugId('test');

      expect(id1).toBe('TEST-00001');
      expect(id2).toBe('TEST-00002');
      expect(id3).toBe('TEST-00003');
    });

    test('should uppercase workstream', async () => {
      const id = await repo.getNextBugId('lowercase');
      expect(id).toBe('LOWERCASE-00001');
    });

    test('should maintain separate sequences per workstream', async () => {
      const idA1 = await repo.getNextBugId('alpha');
      const idB1 = await repo.getNextBugId('beta');
      const idA2 = await repo.getNextBugId('alpha');

      expect(idA1).toBe('ALPHA-00001');
      expect(idB1).toBe('BETA-00001');
      expect(idA2).toBe('ALPHA-00002');
    });
  });

  describe('create', () => {
    test('should create bug with required fields', async () => {
      const bugId = await repo.getNextBugId('create');
      const bug = await repo.create(bugId, {
        workstream: 'create',
        summary: 'Test bug',
        reporterType: 'agent',
        reporterName: 'test-agent',
      });

      expect(bug.bugId).toBe('CREATE-00001');
      expect(bug.summary).toBe('Test bug');
      expect(bug.status).toBe('Open');
      expect(bug.reporterName).toBe('test-agent');
      expect(bug.assigneeName).toBeNull();
    });

    test('should create bug with optional fields', async () => {
      const bugId = await repo.getNextBugId('optional');
      const bug = await repo.create(bugId, {
        workstream: 'optional',
        summary: 'Bug with details',
        description: 'Detailed description',
        reporterType: 'principal',
        reporterName: 'jordan',
        assigneeType: 'agent',
        assigneeName: 'housekeeping',
        xrefType: 'request',
        xrefId: 'REQUEST-001',
      });

      expect(bug.description).toBe('Detailed description');
      expect(bug.assigneeName).toBe('housekeeping');
      expect(bug.xrefId).toBe('REQUEST-001');
    });
  });

  describe('findByBugId', () => {
    test('should find existing bug', async () => {
      const bugId = await repo.getNextBugId('find');
      await repo.create(bugId, {
        workstream: 'find',
        summary: 'Findable bug',
        reporterType: 'system',
        reporterName: 'test',
      });

      const found = await repo.findByBugId(bugId);
      expect(found).not.toBeNull();
      expect(found!.summary).toBe('Findable bug');
    });

    test('should return null for non-existent bug', async () => {
      const found = await repo.findByBugId('NONEXISTENT-99999');
      expect(found).toBeNull();
    });
  });

  describe('list', () => {
    beforeEach(async () => {
      // Create test bugs
      for (const ws of ['A', 'B']) {
        for (const status of ['Open', 'Fixed']) {
          const bugId = await repo.getNextBugId(ws);
          await repo.create(bugId, {
            workstream: ws,
            summary: `${ws} ${status} bug`,
            reporterType: 'agent',
            reporterName: 'test',
          });
          if (status === 'Fixed') {
            await repo.update(bugId, { status: 'Fixed' });
          }
        }
      }
    });

    test('should list all bugs', async () => {
      const { bugs, total } = await repo.list({ limit: 50, offset: 0 });
      expect(total).toBe(4);
      expect(bugs.length).toBe(4);
    });

    test('should filter by workstream', async () => {
      const { bugs, total } = await repo.list({ workstream: 'A', limit: 50, offset: 0 });
      expect(total).toBe(2);
      expect(bugs.every(b => b.workstream === 'A')).toBe(true);
    });

    test('should filter by status', async () => {
      const { bugs, total } = await repo.list({ status: 'Fixed', limit: 50, offset: 0 });
      expect(total).toBe(2);
      expect(bugs.every(b => b.status === 'Fixed')).toBe(true);
    });

    test('should paginate results', async () => {
      const page1 = await repo.list({ limit: 2, offset: 0 });
      const page2 = await repo.list({ limit: 2, offset: 2 });

      expect(page1.bugs.length).toBe(2);
      expect(page2.bugs.length).toBe(2);
      expect(page1.bugs[0].bugId).not.toBe(page2.bugs[0].bugId);
    });
  });

  describe('update', () => {
    test('should update bug status', async () => {
      const bugId = await repo.getNextBugId('update');
      await repo.create(bugId, {
        workstream: 'update',
        summary: 'To be updated',
        reporterType: 'agent',
        reporterName: 'test',
      });

      const updated = await repo.update(bugId, { status: 'In Progress' });
      expect(updated!.status).toBe('In Progress');
    });

    test('should update bug summary', async () => {
      const bugId = await repo.getNextBugId('update');
      await repo.create(bugId, {
        workstream: 'update',
        summary: 'Original summary',
        reporterType: 'agent',
        reporterName: 'test',
      });

      const updated = await repo.update(bugId, { summary: 'Updated summary' });
      expect(updated!.summary).toBe('Updated summary');
    });

    test('should update assignee', async () => {
      const bugId = await repo.getNextBugId('update');
      await repo.create(bugId, {
        workstream: 'update',
        summary: 'Unassigned bug',
        reporterType: 'agent',
        reporterName: 'test',
      });

      const updated = await repo.update(bugId, {
        assigneeType: 'agent',
        assigneeName: 'housekeeping',
      });

      expect(updated!.assigneeName).toBe('housekeeping');
      expect(updated!.assigneeType).toBe('agent');
    });

    test('should return null for non-existent bug', async () => {
      const updated = await repo.update('FAKE-99999', { status: 'Fixed' });
      expect(updated).toBeNull();
    });
  });

  describe('delete', () => {
    test('should delete existing bug', async () => {
      const bugId = await repo.getNextBugId('delete');
      await repo.create(bugId, {
        workstream: 'delete',
        summary: 'To be deleted',
        reporterType: 'agent',
        reporterName: 'test',
      });

      const deleted = await repo.delete(bugId);
      expect(deleted).toBe(true);

      const found = await repo.findByBugId(bugId);
      expect(found).toBeNull();
    });

    test('should return false for non-existent bug', async () => {
      const deleted = await repo.delete('FAKE-99999');
      expect(deleted).toBe(false);
    });
  });

  describe('getStats', () => {
    test('should return correct statistics', async () => {
      // Create bugs with different statuses
      for (let i = 0; i < 3; i++) {
        const bugId = await repo.getNextBugId('stats');
        await repo.create(bugId, {
          workstream: 'stats',
          summary: `Open bug ${i}`,
          reporterType: 'agent',
          reporterName: 'test',
        });
      }

      const inProgressId = await repo.getNextBugId('stats');
      await repo.create(inProgressId, {
        workstream: 'stats',
        summary: 'In progress bug',
        reporterType: 'agent',
        reporterName: 'test',
      });
      await repo.update(inProgressId, { status: 'In Progress' });

      const fixedId = await repo.getNextBugId('stats');
      await repo.create(fixedId, {
        workstream: 'stats',
        summary: 'Fixed bug',
        reporterType: 'agent',
        reporterName: 'test',
      });
      await repo.update(fixedId, { status: 'Fixed' });

      const stats = await repo.getStats();
      expect(stats.total).toBe(5);
      expect(stats.open).toBe(3);
      expect(stats.inProgress).toBe(1);
      expect(stats.fixed).toBe(1);
    });
  });
});
