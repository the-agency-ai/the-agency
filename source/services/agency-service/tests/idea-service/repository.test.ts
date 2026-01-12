/**
 * Idea Repository Tests
 *
 * Tests for idea data access layer.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { IdeaRepository } from '../../src/embedded/idea-service/repository/idea.repository';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Idea Repository', () => {
  let db: DatabaseAdapter;
  let repo: IdeaRepository;
  const testDbPath = '/tmp/agency-test-ideas';
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

  describe('getNextIdeaId', () => {
    test('should generate sequential IDs', async () => {
      const id1 = await repo.getNextIdeaId();
      const id2 = await repo.getNextIdeaId();
      const id3 = await repo.getNextIdeaId();

      expect(id1).toBe('IDEA-00001');
      expect(id2).toBe('IDEA-00002');
      expect(id3).toBe('IDEA-00003');
    });

    test('should format ID with proper padding', async () => {
      const id = await repo.getNextIdeaId();
      expect(id).toMatch(/^IDEA-\d{5}$/);
    });
  });

  describe('create', () => {
    test('should create idea with required fields', async () => {
      const ideaId = await repo.getNextIdeaId();
      const idea = await repo.create(ideaId, {
        title: 'Test idea',
        sourceType: 'agent',
        sourceName: 'test-agent',
        tags: [],
      });

      expect(idea.ideaId).toBe('IDEA-00001');
      expect(idea.title).toBe('Test idea');
      expect(idea.status).toBe('captured');
      expect(idea.sourceName).toBe('test-agent');
      expect(idea.description).toBeNull();
      expect(idea.tags).toEqual([]);
    });

    test('should create idea with optional fields', async () => {
      const ideaId = await repo.getNextIdeaId();
      const idea = await repo.create(ideaId, {
        title: 'Idea with details',
        description: 'Detailed description',
        sourceType: 'principal',
        sourceName: 'jordan',
        tags: ['ui', 'tooling'],
      });

      expect(idea.description).toBe('Detailed description');
      expect(idea.tags).toEqual(['ui', 'tooling']);
    });
  });

  describe('findByIdeaId', () => {
    test('should find existing idea', async () => {
      const ideaId = await repo.getNextIdeaId();
      await repo.create(ideaId, {
        title: 'Findable idea',
        sourceType: 'system',
        sourceName: 'test',
        tags: [],
      });

      const found = await repo.findByIdeaId(ideaId);
      expect(found).not.toBeNull();
      expect(found!.title).toBe('Findable idea');
    });

    test('should return null for non-existent idea', async () => {
      const found = await repo.findByIdeaId('IDEA-99999');
      expect(found).toBeNull();
    });
  });

  describe('list', () => {
    beforeEach(async () => {
      // Create test ideas with different statuses
      for (const status of ['captured', 'exploring']) {
        const ideaId = await repo.getNextIdeaId();
        await repo.create(ideaId, {
          title: `${status} idea`,
          sourceType: 'agent',
          sourceName: 'test',
          tags: ['test-tag'],
        });
        if (status === 'exploring') {
          await repo.update(ideaId, { status: 'exploring' });
        }
      }
    });

    test('should list all ideas', async () => {
      const { ideas, total } = await repo.list({ limit: 50, offset: 0 });
      expect(total).toBe(2);
      expect(ideas.length).toBe(2);
    });

    test('should filter by status', async () => {
      const { ideas, total } = await repo.list({ status: 'captured', limit: 50, offset: 0 });
      expect(total).toBe(1);
      expect(ideas.every(i => i.status === 'captured')).toBe(true);
    });

    test('should filter by source', async () => {
      const { ideas, total } = await repo.list({ source: 'test', limit: 50, offset: 0 });
      expect(total).toBe(2);
      expect(ideas.every(i => i.sourceName === 'test')).toBe(true);
    });

    test('should filter by tag', async () => {
      const { ideas, total } = await repo.list({ tags: 'test-tag', limit: 50, offset: 0 });
      expect(total).toBe(2);
      expect(ideas.every(i => i.tags.includes('test-tag'))).toBe(true);
    });

    test('should search in title and description', async () => {
      const ideaId = await repo.getNextIdeaId();
      await repo.create(ideaId, {
        title: 'Searchable feature request',
        description: 'This has searchable content',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const { ideas, total } = await repo.list({ search: 'searchable', limit: 50, offset: 0 });
      expect(total).toBe(1);
      expect(ideas[0].title).toBe('Searchable feature request');
    });

    test('should paginate results', async () => {
      // Create more ideas
      for (let i = 0; i < 3; i++) {
        const ideaId = await repo.getNextIdeaId();
        await repo.create(ideaId, {
          title: `Extra idea ${i}`,
          sourceType: 'agent',
          sourceName: 'test',
          tags: [],
        });
      }

      const page1 = await repo.list({ limit: 2, offset: 0 });
      const page2 = await repo.list({ limit: 2, offset: 2 });

      expect(page1.ideas.length).toBe(2);
      expect(page2.ideas.length).toBe(2);
      expect(page1.ideas[0].ideaId).not.toBe(page2.ideas[0].ideaId);
    });

    test('should escape LIKE special characters in tag search', async () => {
      const ideaId = await repo.getNextIdeaId();
      await repo.create(ideaId, {
        title: 'Idea with special tag',
        sourceType: 'agent',
        sourceName: 'test',
        tags: ['tag%special'],
      });

      // Search for exact tag should find it
      const { ideas: found } = await repo.list({ tags: 'tag%special', limit: 50, offset: 0 });
      expect(found.some(i => i.tags.includes('tag%special'))).toBe(true);

      // Search for partial should not match due to escaping
      const { ideas: notFound } = await repo.list({ tags: 'tag', limit: 50, offset: 0 });
      expect(notFound.some(i => i.tags.includes('tag%special'))).toBe(false);
    });
  });

  describe('update', () => {
    test('should update idea title', async () => {
      const ideaId = await repo.getNextIdeaId();
      await repo.create(ideaId, {
        title: 'Original title',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const updated = await repo.update(ideaId, { title: 'Updated title' });
      expect(updated!.title).toBe('Updated title');
    });

    test('should update idea status', async () => {
      const ideaId = await repo.getNextIdeaId();
      await repo.create(ideaId, {
        title: 'To be updated',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const updated = await repo.update(ideaId, { status: 'exploring' });
      expect(updated!.status).toBe('exploring');
    });

    test('should update idea tags', async () => {
      const ideaId = await repo.getNextIdeaId();
      await repo.create(ideaId, {
        title: 'Tagged idea',
        sourceType: 'agent',
        sourceName: 'test',
        tags: ['original'],
      });

      const updated = await repo.update(ideaId, { tags: ['new-tag', 'another'] });
      expect(updated!.tags).toEqual(['new-tag', 'another']);
    });

    test('should return null for non-existent idea', async () => {
      const updated = await repo.update('IDEA-99999', { status: 'exploring' });
      expect(updated).toBeNull();
    });
  });

  describe('promote', () => {
    test('should mark idea as promoted', async () => {
      const ideaId = await repo.getNextIdeaId();
      await repo.create(ideaId, {
        title: 'Promotable idea',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const promoted = await repo.promote(ideaId, 'REQUEST-jordan-0025');
      expect(promoted!.status).toBe('promoted');
      expect(promoted!.promotedTo).toBe('REQUEST-jordan-0025');
    });
  });

  describe('delete', () => {
    test('should delete existing idea', async () => {
      const ideaId = await repo.getNextIdeaId();
      await repo.create(ideaId, {
        title: 'To be deleted',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });

      const deleted = await repo.delete(ideaId);
      expect(deleted).toBe(true);

      const found = await repo.findByIdeaId(ideaId);
      expect(found).toBeNull();
    });

    test('should return false for non-existent idea', async () => {
      const deleted = await repo.delete('IDEA-99999');
      expect(deleted).toBe(false);
    });
  });

  describe('getStats', () => {
    test('should return correct statistics', async () => {
      // Create ideas with different statuses
      for (let i = 0; i < 3; i++) {
        const ideaId = await repo.getNextIdeaId();
        await repo.create(ideaId, {
          title: `Captured idea ${i}`,
          sourceType: 'agent',
          sourceName: 'test',
          tags: [],
        });
      }

      const exploringId = await repo.getNextIdeaId();
      await repo.create(exploringId, {
        title: 'Exploring idea',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });
      await repo.update(exploringId, { status: 'exploring' });

      const parkedId = await repo.getNextIdeaId();
      await repo.create(parkedId, {
        title: 'Parked idea',
        sourceType: 'agent',
        sourceName: 'test',
        tags: [],
      });
      await repo.update(parkedId, { status: 'parked' });

      const stats = await repo.getStats();
      expect(stats.total).toBe(5);
      expect(stats.captured).toBe(3);
      expect(stats.exploring).toBe(1);
      expect(stats.parked).toBe(1);
      expect(stats.promoted).toBe(0);
      expect(stats.discarded).toBe(0);
    });
  });
});
