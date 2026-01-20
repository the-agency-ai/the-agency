/**
 * Test Service Tests
 *
 * Tests for test execution business logic.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { TestService } from '../../src/embedded/test-service/service/test.service';
import { unlink } from 'fs/promises';
import { existsSync, mkdirSync, writeFileSync, rmSync } from 'fs';

describe('Test Service', () => {
  let db: DatabaseAdapter;
  let service: TestService;
  const testDbPath = '/tmp/agency-test-service-tests';
  const testDbFile = `${testDbPath}/tests.db`;
  const testProjectRoot = '/tmp/agency-test-project';

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'tests.db',
    });
    await db.initialize();

    // Create a mock project with tests directory
    mkdirSync(`${testProjectRoot}/tests/unit`, { recursive: true });
    mkdirSync(`${testProjectRoot}/tests/integration`, { recursive: true });

    service = new TestService(db, testProjectRoot);
    await service.initialize();
  });

  afterEach(async () => {
    await db.close();
    try {
      if (existsSync(testDbFile)) await unlink(testDbFile);
      if (existsSync(`${testDbFile}-wal`)) await unlink(`${testDbFile}-wal`);
      if (existsSync(`${testDbFile}-shm`)) await unlink(`${testDbFile}-shm`);
      rmSync(testProjectRoot, { recursive: true, force: true });
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  describe('startRun', () => {
    test('should create a pending run', async () => {
      const run = await service.startRun({
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      expect(run.id).toBeDefined();
      expect(run.suite).toBe('unit');
      expect(run.status).toBe('pending');
    });
  });

  describe('getRun', () => {
    test('should get existing run', async () => {
      const created = await service.startRun({
        suite: 'all',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      const found = await service.getRun(created.id);
      expect(found).not.toBeNull();
      expect(found!.id).toBe(created.id);
    });

    test('should return null for non-existent run', async () => {
      const found = await service.getRun('nonexistent');
      expect(found).toBeNull();
    });
  });

  describe('listRuns', () => {
    test('should list test runs', async () => {
      await service.startRun({
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      await service.startRun({
        suite: 'integration',
        triggeredByType: 'agent',
        triggeredByName: 'tester',
      });

      const { runs, total } = await service.listRuns({
        limit: 50,
        offset: 0,
      });

      expect(total).toBe(2);
      expect(runs.length).toBe(2);
    });

    test('should filter by suite', async () => {
      await service.startRun({
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      await service.startRun({
        suite: 'integration',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      const { runs } = await service.listRuns({
        suite: 'unit',
        limit: 50,
        offset: 0,
      });

      expect(runs.length).toBe(1);
      expect(runs[0].suite).toBe('unit');
    });
  });

  describe('getStats', () => {
    test('should return empty stats for new service', async () => {
      const stats = await service.getStats();
      expect(stats.totalRuns).toBe(0);
    });

    test('should track runs', async () => {
      await service.startRun({
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      const stats = await service.getStats();
      expect(stats.totalRuns).toBe(1);
    });
  });

  describe('getLatestRun', () => {
    test('should return null when no runs exist', async () => {
      const latest = await service.getLatestRun();
      expect(latest).toBeNull();
    });

    test('should return most recent run', async () => {
      await service.startRun({
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      const second = await service.startRun({
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      const latest = await service.getLatestRun();
      expect(latest!.id).toBe(second.id);
    });
  });

  describe('getSuites', () => {
    test('should return configured suites (or default if no config)', async () => {
      const suites = await service.getSuites();

      // Default config has one suite: 'All Tests'
      expect(suites.length).toBeGreaterThanOrEqual(1);
      expect(suites.some(s => s.name === 'All Tests')).toBe(true);
    });
  });

  describe('cancelRun', () => {
    test('should return false for non-existent run', async () => {
      const cancelled = await service.cancelRun('nonexistent');
      expect(cancelled).toBe(false);
    });

    test('should return false for pending run', async () => {
      const run = await service.startRun({
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      // Pending runs can't be cancelled (not running)
      const cancelled = await service.cancelRun(run.id);
      expect(cancelled).toBe(false);
    });
  });

  describe('cleanup', () => {
    test('should clean up old runs', async () => {
      await service.startRun({
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      // Cleanup runs older than 0 days (should delete everything)
      const deleted = await service.cleanup(0);
      expect(deleted).toBe(1);

      const { total } = await service.listRuns({ limit: 50, offset: 0 });
      expect(total).toBe(0);
    });
  });

  describe('getFlakyTests', () => {
    test('should return empty array when no flaky tests', async () => {
      const flaky = await service.getFlakyTests();
      expect(flaky).toHaveLength(0);
    });
  });
});
