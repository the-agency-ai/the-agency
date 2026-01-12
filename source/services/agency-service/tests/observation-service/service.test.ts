/**
 * Observation Service Tests
 *
 * Tests for observation business logic layer.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { ObservationRepository } from '../../src/embedded/observation-service/repository/observation.repository';
import { ObservationService } from '../../src/embedded/observation-service/service/observation.service';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Observation Service', () => {
  let db: DatabaseAdapter;
  let repo: ObservationRepository;
  let service: ObservationService;
  const testDbPath = '/tmp/agency-test-observation-service';
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
    service = new ObservationService(repo);
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

  describe('createObservation', () => {
    test('should create observation and return it', async () => {
      const observation = await service.createObservation({
        title: 'New observation',
        summary: 'Something noticed',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      expect(observation.observationId).toMatch(/^OBS-\d{4}$/);
      expect(observation.title).toBe('New observation');
      expect(observation.status).toBe('Open');
    });

    test('should generate unique IDs', async () => {
      const o1 = await service.createObservation({
        title: 'First',
        summary: 'First observation',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const o2 = await service.createObservation({
        title: 'Second',
        summary: 'Second observation',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      expect(o1.observationId).not.toBe(o2.observationId);
    });
  });

  describe('getObservation', () => {
    test('should return observation by ID', async () => {
      const created = await service.createObservation({
        title: 'Find me',
        summary: 'Can be found',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const found = await service.getObservation(created.observationId);
      expect(found).not.toBeNull();
      expect(found!.title).toBe('Find me');
    });

    test('should return null for non-existent', async () => {
      const found = await service.getObservation('OBS-9999');
      expect(found).toBeNull();
    });
  });

  describe('listObservations', () => {
    beforeEach(async () => {
      await service.createObservation({
        title: 'Open observation',
        summary: 'Still open',
        reporterType: 'agent',
        reporterName: 'agent1',
      });

      const archived = await service.createObservation({
        title: 'Archived observation',
        summary: 'Done',
        reporterType: 'agent',
        reporterName: 'agent2',
      });
      await service.archiveObservation(archived.observationId);
    });

    test('should list all observations', async () => {
      const result = await service.listObservations({
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });

      expect(result.total).toBe(2);
      expect(result.observations.length).toBe(2);
    });

    test('should filter by status', async () => {
      const result = await service.listObservations({
        status: 'Archived',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });

      expect(result.total).toBe(1);
      expect(result.observations[0].title).toBe('Archived observation');
    });

    test('should filter by reporter', async () => {
      const result = await service.listObservations({
        reporter: 'agent1',
        limit: 50,
        offset: 0,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      });

      expect(result.total).toBe(1);
      expect(result.observations[0].reporterName).toBe('agent1');
    });
  });

  describe('updateObservation', () => {
    test('should update multiple fields', async () => {
      const created = await service.createObservation({
        title: 'Original',
        summary: 'Will be updated',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const updated = await service.updateObservation(created.observationId, {
        title: 'Updated title',
        category: 'concern',
        tags: ['important'],
      });

      expect(updated!.title).toBe('Updated title');
      expect(updated!.category).toBe('concern');
      expect(updated!.tags).toEqual(['important']);
    });

    test('should return null for non-existent', async () => {
      const result = await service.updateObservation('OBS-9999', { title: 'New' });
      expect(result).toBeNull();
    });
  });

  describe('updateStatus', () => {
    test('should change status', async () => {
      const created = await service.createObservation({
        title: 'Status test',
        summary: 'Status will change',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      expect(created.status).toBe('Open');

      const updated = await service.updateStatus(created.observationId, 'Acknowledged');
      expect(updated!.status).toBe('Acknowledged');
    });

    test('should return null for non-existent', async () => {
      const result = await service.updateStatus('OBS-9999', 'Archived');
      expect(result).toBeNull();
    });

    test('should transition through all valid status values', async () => {
      const allStatuses = ['Open', 'Acknowledged', 'Noted', 'Archived'] as const;

      for (const status of allStatuses) {
        const created = await service.createObservation({
          title: `Status ${status}`,
          summary: 'Testing all statuses',
          reporterType: 'agent',
          reporterName: 'housekeeping',
        });

        const updated = await service.updateStatus(created.observationId, status);
        expect(updated!.status).toBe(status);
      }
    });
  });

  describe('acknowledgeObservation', () => {
    test('should set status to Acknowledged', async () => {
      const created = await service.createObservation({
        title: 'To acknowledge',
        summary: 'Will be acknowledged',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const acknowledged = await service.acknowledgeObservation(created.observationId);
      expect(acknowledged!.status).toBe('Acknowledged');
    });
  });

  describe('archiveObservation', () => {
    test('should set status to Archived', async () => {
      const created = await service.createObservation({
        title: 'To archive',
        summary: 'Will be archived',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const archived = await service.archiveObservation(created.observationId);
      expect(archived!.status).toBe('Archived');
    });
  });

  describe('deleteObservation', () => {
    test('should delete existing observation', async () => {
      const created = await service.createObservation({
        title: 'Delete me',
        summary: 'Will be removed',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const deleted = await service.deleteObservation(created.observationId);
      expect(deleted).toBe(true);

      const found = await service.getObservation(created.observationId);
      expect(found).toBeNull();
    });

    test('should return false for non-existent', async () => {
      const deleted = await service.deleteObservation('OBS-9999');
      expect(deleted).toBe(false);
    });
  });

  describe('getStats', () => {
    test('should return correct stats', async () => {
      await service.createObservation({
        title: 'Open 1',
        summary: 'Open',
        category: 'insight',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });

      const concern = await service.createObservation({
        title: 'Concern',
        summary: 'A concern',
        category: 'concern',
        reporterType: 'agent',
        reporterName: 'housekeeping',
      });
      await service.acknowledgeObservation(concern.observationId);

      const stats = await service.getStats();
      expect(stats.total).toBe(2);
      expect(stats.open).toBe(1);
      expect(stats.acknowledged).toBe(1);
      expect(stats.byCategory.insight).toBe(1);
      expect(stats.byCategory.concern).toBe(1);
    });
  });
});
