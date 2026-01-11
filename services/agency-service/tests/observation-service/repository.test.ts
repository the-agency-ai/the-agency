/**
 * Observation Repository Tests
 *
 * Tests for observation data access layer.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { ObservationRepository } from '../../src/embedded/observation-service/repository/observation.repository';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Observation Repository', () => {
  let db: DatabaseAdapter;
  let repo: ObservationRepository;
  const testDbPath = '/tmp/agency-test-observations';
  const testDbFile = `${testDbPath}/observations.db`;

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'observations.db',
    });
    await db.initialize();
    repo = new ObservationRepository(db);
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

  describe('getNextObservationId', () => {
    test('should generate sequential IDs', async () => {
      const id1 = await repo.getNextObservationId();
      const id2 = await repo.getNextObservationId();
      const id3 = await repo.getNextObservationId();

      expect(id1).toBe('OBS-0001');
      expect(id2).toBe('OBS-0002');
      expect(id3).toBe('OBS-0003');
    });
  });

  describe('create', () => {
    test('should create observation with required fields', async () => {
      const observationId = await repo.getNextObservationId();
      const observation = await repo.create(observationId, {
        title: 'Test observation',
        summary: 'This is a test observation',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      expect(observation.observationId).toBe('OBS-0001');
      expect(observation.title).toBe('Test observation');
      expect(observation.status).toBe('Open');
      expect(observation.category).toBe('note');
    });

    test('should create observation with context', async () => {
      const observationId = await repo.getNextObservationId();
      const observation = await repo.create(observationId, {
        title: 'Code smell',
        summary: 'Found potential issue',
        reporterType: 'agent',
        reporterName: 'housekeeping',
        category: 'concern',
        contextPath: 'src/services/auth.ts',
        contextLine: 42,
        contextRef: 'validateToken',
      });

      expect(observation.category).toBe('concern');
      expect(observation.contextPath).toBe('src/services/auth.ts');
      expect(observation.contextLine).toBe(42);
      expect(observation.contextRef).toBe('validateToken');
    });
  });

  describe('findByObservationId', () => {
    test('should find existing observation', async () => {
      const observationId = await repo.getNextObservationId();
      await repo.create(observationId, {
        title: 'Findable',
        summary: 'Can be found',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const found = await repo.findByObservationId(observationId);
      expect(found).not.toBeNull();
      expect(found!.title).toBe('Findable');
    });

    test('should return null for non-existent', async () => {
      const found = await repo.findByObservationId('OBS-9999');
      expect(found).toBeNull();
    });
  });

  describe('list', () => {
    beforeEach(async () => {
      // Create test observations
      for (const category of ['note', 'concern', 'insight']) {
        const observationId = await repo.getNextObservationId();
        await repo.create(observationId, {
          title: `${category} observation`,
          summary: `A ${category}`,
          reporterType: 'agent',
          reporterName: 'housekeeping',
          category: category as any,
        });
      }
    });

    test('should list all observations', async () => {
      const { observations, total } = await repo.list({
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      expect(total).toBe(3);
      expect(observations.length).toBe(3);
    });

    test('should filter by category', async () => {
      const { observations, total } = await repo.list({
        category: 'concern',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      expect(total).toBe(1);
      expect(observations[0].category).toBe('concern');
    });

    test('should sort by title', async () => {
      const { observations } = await repo.list({
        limit: 50,
        offset: 0,
        sortBy: 'title',
        sortOrder: 'asc',
      });
      for (let i = 1; i < observations.length; i++) {
        expect(observations[i].title >= observations[i - 1].title).toBe(true);
      }
    });

    test('should search in title and summary', async () => {
      const { total } = await repo.list({
        search: 'concern',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      expect(total).toBe(1);
    });

    test('should filter by context path prefix', async () => {
      const obs1 = await repo.getNextObservationId();
      await repo.create(obs1, {
        title: 'In services',
        summary: 'Found in services',
        reporterType: 'agent',
        reporterName: 'housekeeping',
        contextPath: 'src/services/auth.ts',
      });

      const obs2 = await repo.getNextObservationId();
      await repo.create(obs2, {
        title: 'In components',
        summary: 'Found in components',
        reporterType: 'agent',
        reporterName: 'housekeeping',
        contextPath: 'src/components/Button.tsx',
      });

      const { total } = await repo.list({
        contextPath: 'src/services',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      expect(total).toBe(1);
    });
  });

  describe('update', () => {
    test('should update observation status', async () => {
      const observationId = await repo.getNextObservationId();
      await repo.create(observationId, {
        title: 'To be updated',
        summary: 'Status will change',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const updated = await repo.update(observationId, { status: 'Acknowledged' });
      expect(updated!.status).toBe('Acknowledged');
    });

    test('should update category', async () => {
      const observationId = await repo.getNextObservationId();
      await repo.create(observationId, {
        title: 'Category change',
        summary: 'Will become concern',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const updated = await repo.update(observationId, { category: 'concern' });
      expect(updated!.category).toBe('concern');
    });

    test('should return null for non-existent', async () => {
      const updated = await repo.update('OBS-9999', { status: 'Archived' });
      expect(updated).toBeNull();
    });
  });

  describe('delete', () => {
    test('should delete existing observation', async () => {
      const observationId = await repo.getNextObservationId();
      await repo.create(observationId, {
        title: 'To be deleted',
        summary: 'Will be removed',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const deleted = await repo.delete(observationId);
      expect(deleted).toBe(true);

      const found = await repo.findByObservationId(observationId);
      expect(found).toBeNull();
    });

    test('should return false for non-existent', async () => {
      const deleted = await repo.delete('OBS-9999');
      expect(deleted).toBe(false);
    });
  });

  describe('findById', () => {
    test('should find by internal ID', async () => {
      const observationId = await repo.getNextObservationId();
      const created = await repo.create(observationId, {
        title: 'Find by internal ID',
        summary: 'Test internal ID lookup',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const found = await repo.findById(created.id);
      expect(found).not.toBeNull();
      expect(found!.observationId).toBe(observationId);
    });

    test('should return null for non-existent internal ID', async () => {
      const found = await repo.findById(99999);
      expect(found).toBeNull();
    });
  });

  describe('security - LIKE pattern escaping', () => {
    test('should escape % in search', async () => {
      const observationId = await repo.getNextObservationId();
      await repo.create(observationId, {
        title: 'Contains 100% match',
        summary: 'This has a percent sign',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      // Search for literal %
      const { total } = await repo.list({
        search: '100%',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      expect(total).toBe(1);
    });

    test('should escape _ in search', async () => {
      const observationId = await repo.getNextObservationId();
      await repo.create(observationId, {
        title: 'Has under_score',
        summary: 'Underscore in title',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      // Search for literal _
      const { total } = await repo.list({
        search: 'under_score',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      expect(total).toBe(1);
    });

    test('should escape % in contextPath', async () => {
      const observationId = await repo.getNextObservationId();
      await repo.create(observationId, {
        title: 'In weird path',
        summary: 'Has percent in path',
        reporterType: 'agent',
        reporterName: 'housekeeping',
        contextPath: 'src/100%_complete/file.ts',
      });

      // Filter by exact path prefix with special char
      const { total } = await repo.list({
        contextPath: 'src/100%',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      expect(total).toBe(1);
    });

    test('should escape special chars in tags', async () => {
      const observationId = await repo.getNextObservationId();
      await repo.create(observationId, {
        title: 'Tagged observation',
        summary: 'Has special tag',
        reporterType: 'agent',
        reporterName: 'housekeeping',
        tags: ['100%', 'under_score'],
      });

      // Filter by tag with special char
      const { total } = await repo.list({
        tags: '100%',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });
      expect(total).toBe(1);
    });
  });

  describe('security - sortBy/sortOrder validation', () => {
    test('should default invalid sortBy to createdAt', async () => {
      const observationId = await repo.getNextObservationId();
      await repo.create(observationId, {
        title: 'Test observation',
        summary: 'For sorting test',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      // Attempt SQL injection via sortBy - should default to created_at safely
      const { total } = await repo.list({
        limit: 50,
        offset: 0,
        sortBy: 'title; DROP TABLE observations--' as any,
        sortOrder: 'desc',
      });
      // If we get here without error, the injection was prevented
      expect(total).toBe(1);
    });

    test('should normalize malicious sortOrder', async () => {
      const observationId = await repo.getNextObservationId();
      await repo.create(observationId, {
        title: 'Test observation',
        summary: 'For sorting test',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      // Attempt SQL injection via sortOrder - should normalize to ASC/DESC
      const { total } = await repo.list({
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'DESC; DROP TABLE observations--' as any,
      });
      // If we get here without error, the injection was prevented
      expect(total).toBe(1);
    });
  });

  describe('edge cases', () => {
    test('should return empty stats for empty database', async () => {
      const stats = await repo.getStats();
      expect(stats.total).toBe(0);
      expect(stats.open).toBe(0);
      expect(stats.acknowledged).toBe(0);
    });

    test('should handle empty update gracefully', async () => {
      const observationId = await repo.getNextObservationId();
      const created = await repo.create(observationId, {
        title: 'No changes',
        summary: 'Will not be modified',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const updated = await repo.update(observationId, {});
      expect(updated).not.toBeNull();
      expect(updated!.title).toBe(created.title);
    });
  });

  describe('getStats', () => {
    test('should return correct statistics', async () => {
      const categories = ['insight', 'pattern', 'concern', 'note'] as const;
      const statuses = ['Open', 'Acknowledged', 'Noted', 'Archived'] as const;

      for (let i = 0; i < categories.length; i++) {
        const observationId = await repo.getNextObservationId();
        await repo.create(observationId, {
          title: `Observation ${i}`,
          summary: `Category: ${categories[i]}`,
          category: categories[i],
          reporterType: 'agent',
          reporterName: 'housekeeping',
        });
        if (statuses[i] !== 'Open') {
          await repo.update(observationId, { status: statuses[i] });
        }
      }

      const stats = await repo.getStats();
      expect(stats.total).toBe(4);
      expect(stats.open).toBe(1);
      expect(stats.acknowledged).toBe(1);
      expect(stats.noted).toBe(1);
      expect(stats.archived).toBe(1);
      expect(stats.byCategory.insight).toBe(1);
      expect(stats.byCategory.pattern).toBe(1);
      expect(stats.byCategory.concern).toBe(1);
      expect(stats.byCategory.note).toBe(1);
    });
  });
});
