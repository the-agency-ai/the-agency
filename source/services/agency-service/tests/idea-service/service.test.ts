/**
 * Idea Service Tests
 *
 * Tests for idea business logic layer.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { IdeaRepository } from '../../src/embedded/idea-service/repository/idea.repository';
import { IdeaService } from '../../src/embedded/idea-service/service/idea.service';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Idea Service', () => {
  let db: DatabaseAdapter;
  let repo: IdeaRepository;
  let service: IdeaService;
  const testDbPath = '/tmp/agency-test-idea-service';
  const testDbFile = `${testDbPath}/ideas.db`;

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'ideas.db',
    });
    await db.initialize();
    repo = new IdeaRepository(db);
    await repo.initialize();
    service = new IdeaService(repo);
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

  describe('createIdea', () => {
    test('should create idea with auto-generated ID', async () => {
      const idea = await service.createIdea({
        title: 'New idea via service',
        sourceType: 'agent',
        sourceName: 'test-agent',
        tags: [],
      });

      expect(idea.ideaId).toBe('IDEA-00001');
      expect(idea.status).toBe('captured');
    });

    test('should create multiple ideas with sequential IDs', async () => {
      const idea1 = await service.createIdea({
        title: 'First idea',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const idea2 = await service.createIdea({
        title: 'Second idea',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      expect(idea1.ideaId).toBe('IDEA-00001');
      expect(idea2.ideaId).toBe('IDEA-00002');
    });

    test('should create idea with tags', async () => {
      const idea = await service.createIdea({
        title: 'Tagged idea',
        sourceType: 'principal',
        sourceName: 'jordan',
        tags: ['ui', 'tooling'],
      });

      expect(idea.tags).toEqual(['ui', 'tooling']);
    });
  });

  describe('getIdea', () => {
    test('should get existing idea', async () => {
      const created = await service.createIdea({
        title: 'Idea to get',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const found = await service.getIdea(created.ideaId);
      expect(found).not.toBeNull();
      expect(found!.ideaId).toBe(created.ideaId);
    });

    test('should return null for non-existent idea', async () => {
      const found = await service.getIdea('IDEA-99999');
      expect(found).toBeNull();
    });
  });

  describe('listIdeas', () => {
    beforeEach(async () => {
      await service.createIdea({
        title: 'Idea 1',
        sourceType: 'agent',
        sourceName: 'agent1',
        tags: ['test'],
      });
      await service.createIdea({
        title: 'Idea 2',
        sourceType: 'agent',
        sourceName: 'agent2',
        tags: ['test'],
      });
    });

    test('should list all ideas', async () => {
      const result = await service.listIdeas({ limit: 50, offset: 0 });
      expect(result.ideas.length).toBe(2);
      expect(result.total).toBe(2);
    });

    test('should respect limit and offset', async () => {
      const result = await service.listIdeas({ limit: 1, offset: 0 });
      expect(result.ideas.length).toBe(1);
      expect(result.limit).toBe(1);
      expect(result.offset).toBe(0);
    });
  });

  describe('updateIdea', () => {
    test('should update idea title', async () => {
      const created = await service.createIdea({
        title: 'Original title',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const updated = await service.updateIdea(created.ideaId, {
        title: 'Updated title',
      });

      expect(updated!.title).toBe('Updated title');
    });

    test('should update multiple fields', async () => {
      const created = await service.createIdea({
        title: 'Original title',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const updated = await service.updateIdea(created.ideaId, {
        title: 'New title',
        description: 'Added description',
        status: 'exploring',
      });

      expect(updated!.title).toBe('New title');
      expect(updated!.description).toBe('Added description');
      expect(updated!.status).toBe('exploring');
    });

    test('should block update on promoted idea', async () => {
      const created = await service.createIdea({
        title: 'Will be promoted',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      await service.promoteIdea(created.ideaId, 'REQUEST-jordan-0001');

      // Trying to update title should be blocked
      const result = await service.updateIdea(created.ideaId, {
        title: 'Should not update',
      });

      expect(result!.title).toBe('Will be promoted'); // Original title
    });

    test('should allow park/discard on promoted idea', async () => {
      const created = await service.createIdea({
        title: 'Will be promoted then parked',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      await service.promoteIdea(created.ideaId, 'REQUEST-jordan-0001');

      // Parking should work
      const parked = await service.updateIdea(created.ideaId, {
        status: 'parked',
      });

      expect(parked!.status).toBe('parked');
    });
  });

  describe('promoteIdea', () => {
    test('should promote captured idea', async () => {
      const created = await service.createIdea({
        title: 'Promotable idea',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const promoted = await service.promoteIdea(created.ideaId, 'REQUEST-jordan-0025');

      expect(promoted!.status).toBe('promoted');
      expect(promoted!.promotedTo).toBe('REQUEST-jordan-0025');
    });

    test('should block re-promotion of already promoted idea', async () => {
      const created = await service.createIdea({
        title: 'Already promoted',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      await service.promoteIdea(created.ideaId, 'REQUEST-jordan-0025');

      // Try to promote again
      const result = await service.promoteIdea(created.ideaId, 'REQUEST-jordan-0026');

      // Should return unchanged (still linked to original request)
      expect(result!.promotedTo).toBe('REQUEST-jordan-0025');
    });

    test('should block promotion of discarded idea', async () => {
      const created = await service.createIdea({
        title: 'Discarded idea',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      await service.discardIdea(created.ideaId);

      const result = await service.promoteIdea(created.ideaId, 'REQUEST-jordan-0025');

      // Should return null for discarded ideas
      expect(result).toBeNull();

      // Verify the idea is still discarded
      const idea = await service.getIdea(created.ideaId);
      expect(idea!.status).toBe('discarded');
      expect(idea!.promotedTo).toBeNull();
    });
  });

  describe('status transitions', () => {
    test('should explore captured idea', async () => {
      const created = await service.createIdea({
        title: 'To explore',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const explored = await service.exploreIdea(created.ideaId);
      expect(explored!.status).toBe('exploring');
    });

    test('should park idea', async () => {
      const created = await service.createIdea({
        title: 'To park',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const parked = await service.parkIdea(created.ideaId);
      expect(parked!.status).toBe('parked');
    });

    test('should discard idea', async () => {
      const created = await service.createIdea({
        title: 'To discard',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const discarded = await service.discardIdea(created.ideaId);
      expect(discarded!.status).toBe('discarded');
    });
  });

  describe('addTags', () => {
    test('should add tags to idea', async () => {
      const created = await service.createIdea({
        title: 'Tagged idea',
        sourceType: 'agent',
        sourceName: 'test',
        tags: ['original'],
      });

      const updated = await service.addTags(created.ideaId, ['new-tag', 'another']);

      expect(updated!.tags).toContain('original');
      expect(updated!.tags).toContain('new-tag');
      expect(updated!.tags).toContain('another');
    });

    test('should deduplicate tags', async () => {
      const created = await service.createIdea({
        title: 'Tagged idea',
        sourceType: 'agent',
        sourceName: 'test',
        tags: ['existing'],
      });

      const updated = await service.addTags(created.ideaId, ['existing', 'new']);

      // Should have both without duplicates
      expect(updated!.tags.filter(t => t === 'existing').length).toBe(1);
      expect(updated!.tags).toContain('new');
    });
  });

  describe('removeTags', () => {
    test('should remove tags from idea', async () => {
      const created = await service.createIdea({
        title: 'Tagged idea',
        sourceType: 'agent',
        sourceName: 'test',
        tags: ['keep', 'remove', 'also-remove'],
      });

      const updated = await service.removeTags(created.ideaId, ['remove', 'also-remove']);

      expect(updated!.tags).toEqual(['keep']);
    });

    test('should handle removing non-existent tags gracefully', async () => {
      const created = await service.createIdea({
        title: 'Tagged idea',
        sourceType: 'agent',
        sourceName: 'test',
        tags: ['existing'],
      });

      const updated = await service.removeTags(created.ideaId, ['non-existent']);

      expect(updated!.tags).toEqual(['existing']);
    });
  });

  describe('deleteIdea', () => {
    test('should delete existing idea', async () => {
      const created = await service.createIdea({
        title: 'To delete',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const deleted = await service.deleteIdea(created.ideaId);
      expect(deleted).toBe(true);

      const found = await service.getIdea(created.ideaId);
      expect(found).toBeNull();
    });

    test('should return false for non-existent idea', async () => {
      const deleted = await service.deleteIdea('IDEA-99999');
      expect(deleted).toBe(false);
    });
  });

  describe('getStats', () => {
    test('should return correct statistics', async () => {
      await service.createIdea({
        title: 'Captured 1',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      await service.createIdea({
        title: 'Captured 2',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const idea3 = await service.createIdea({
        title: 'Will explore',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });
      await service.exploreIdea(idea3.ideaId);

      const stats = await service.getStats();
      expect(stats.total).toBe(3);
      expect(stats.captured).toBe(2);
      expect(stats.exploring).toBe(1);
    });
  });
});
