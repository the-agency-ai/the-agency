/**
 * Test Run Repository Tests
 *
 * Tests for test run data access layer.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { TestRunRepository } from '../../src/embedded/test-service/repository/test-run.repository';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('TestRun Repository', () => {
  let db: DatabaseAdapter;
  let repo: TestRunRepository;
  const testDbPath = '/tmp/agency-test-testruns';
  const testDbFile = `${testDbPath}/testruns.db`;

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'testruns.db',
    });
    await db.initialize();
    repo = new TestRunRepository(db);
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

  describe('createRun', () => {
    test('should create a new test run', async () => {
      const run = await repo.createRun({
        id: 'test-run-001',
        suite: 'all',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      expect(run.id).toBe('test-run-001');
      expect(run.suite).toBe('all');
      expect(run.status).toBe('pending');
      expect(run.triggeredByType).toBe('system');
      expect(run.triggeredByName).toBe('cli');
      expect(run.total).toBe(0);
    });

    test('should create run with git context', async () => {
      const run = await repo.createRun({
        id: 'test-run-002',
        suite: 'unit',
        triggeredByType: 'agent',
        triggeredByName: 'housekeeping',
        gitBranch: 'feature/tests',
        gitCommit: 'abc123',
      });

      expect(run.gitBranch).toBe('feature/tests');
      expect(run.gitCommit).toBe('abc123');
    });
  });

  describe('findRunById', () => {
    test('should find existing run', async () => {
      await repo.createRun({
        id: 'find-me-001',
        suite: 'integration',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      const found = await repo.findRunById('find-me-001');
      expect(found).not.toBeNull();
      expect(found!.suite).toBe('integration');
    });

    test('should return null for non-existent run', async () => {
      const found = await repo.findRunById('nonexistent');
      expect(found).toBeNull();
    });
  });

  describe('markRunning', () => {
    test('should update status to running', async () => {
      await repo.createRun({
        id: 'running-001',
        suite: 'all',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      await repo.markRunning('running-001');

      const run = await repo.findRunById('running-001');
      expect(run!.status).toBe('running');
    });
  });

  describe('completeRun', () => {
    test('should complete run with passed status', async () => {
      await repo.createRun({
        id: 'complete-001',
        suite: 'all',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      await repo.completeRun('complete-001', 'passed', {
        total: 10,
        passed: 10,
        failed: 0,
        skipped: 0,
        duration: 1500,
      });

      const run = await repo.findRunById('complete-001');
      expect(run!.status).toBe('passed');
      expect(run!.total).toBe(10);
      expect(run!.passed).toBe(10);
      expect(run!.failed).toBe(0);
      expect(run!.duration).toBe(1500);
      expect(run!.completedAt).not.toBeNull();
    });

    test('should complete run with failed status', async () => {
      await repo.createRun({
        id: 'complete-002',
        suite: 'unit',
        triggeredByType: 'agent',
        triggeredByName: 'tester',
      });

      await repo.completeRun('complete-002', 'failed', {
        total: 10,
        passed: 8,
        failed: 2,
        skipped: 0,
        duration: 2000,
      });

      const run = await repo.findRunById('complete-002');
      expect(run!.status).toBe('failed');
      expect(run!.failed).toBe(2);
    });
  });

  describe('addResult', () => {
    test('should add passing test result', async () => {
      await repo.createRun({
        id: 'results-001',
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      const result = await repo.addResult({
        runId: 'results-001',
        testName: 'should pass',
        suite: 'unit',
        file: 'test.ts',
        status: 'passed',
        duration: 50,
      });

      expect(result.id).toBeGreaterThan(0);
      expect(result.testName).toBe('should pass');
      expect(result.status).toBe('passed');
    });

    test('should add failing test result with error', async () => {
      await repo.createRun({
        id: 'results-002',
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      const result = await repo.addResult({
        runId: 'results-002',
        testName: 'should fail',
        suite: 'unit',
        status: 'failed',
        duration: 100,
        errorMessage: 'Expected true, got false',
        errorStack: 'at test.ts:10:5',
      });

      expect(result.status).toBe('failed');
      expect(result.errorMessage).toBe('Expected true, got false');
    });
  });

  describe('getResultsForRun', () => {
    test('should get all results for a run', async () => {
      await repo.createRun({
        id: 'get-results-001',
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      await repo.addResult({
        runId: 'get-results-001',
        testName: 'test 1',
        suite: 'unit',
        status: 'passed',
        duration: 10,
      });
      await repo.addResult({
        runId: 'get-results-001',
        testName: 'test 2',
        suite: 'unit',
        status: 'failed',
        duration: 20,
      });
      await repo.addResult({
        runId: 'get-results-001',
        testName: 'test 3',
        suite: 'unit',
        status: 'skipped',
        duration: 0,
      });

      const results = await repo.getResultsForRun('get-results-001');
      expect(results).toHaveLength(3);
    });
  });

  describe('getFailedResultsForRun', () => {
    test('should get only failed results', async () => {
      await repo.createRun({
        id: 'failed-only-001',
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      await repo.addResult({
        runId: 'failed-only-001',
        testName: 'passes',
        suite: 'unit',
        status: 'passed',
        duration: 10,
      });
      await repo.addResult({
        runId: 'failed-only-001',
        testName: 'fails 1',
        suite: 'unit',
        status: 'failed',
        duration: 20,
      });
      await repo.addResult({
        runId: 'failed-only-001',
        testName: 'fails 2',
        suite: 'unit',
        status: 'failed',
        duration: 30,
      });

      const failures = await repo.getFailedResultsForRun('failed-only-001');
      expect(failures).toHaveLength(2);
      expect(failures.every(f => f.status === 'failed')).toBe(true);
    });
  });

  describe('listRuns', () => {
    beforeEach(async () => {
      await repo.createRun({
        id: 'list-001',
        suite: 'all',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      await repo.completeRun('list-001', 'passed', {
        total: 5, passed: 5, failed: 0, skipped: 0, duration: 100,
      });

      await repo.createRun({
        id: 'list-002',
        suite: 'unit',
        triggeredByType: 'agent',
        triggeredByName: 'tester',
      });
      await repo.completeRun('list-002', 'failed', {
        total: 10, passed: 8, failed: 2, skipped: 0, duration: 200,
      });

      await repo.createRun({
        id: 'list-003',
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
    });

    test('should list all runs', async () => {
      const { runs, total } = await repo.listRuns({ limit: 50, offset: 0 });
      expect(total).toBe(3);
      expect(runs.length).toBe(3);
    });

    test('should filter by suite', async () => {
      const { runs, total } = await repo.listRuns({
        suite: 'unit',
        limit: 50,
        offset: 0,
      });
      expect(total).toBe(2);
    });

    test('should filter by status', async () => {
      const { runs, total } = await repo.listRuns({
        status: 'passed',
        limit: 50,
        offset: 0,
      });
      expect(total).toBe(1);
      expect(runs[0].status).toBe('passed');
    });

    test('should paginate results', async () => {
      const page1 = await repo.listRuns({ limit: 2, offset: 0 });
      const page2 = await repo.listRuns({ limit: 2, offset: 2 });

      expect(page1.runs.length).toBe(2);
      expect(page2.runs.length).toBe(1);
    });
  });

  describe('getStats', () => {
    test('should return correct statistics', async () => {
      await repo.createRun({
        id: 'stats-001',
        suite: 'all',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      await repo.completeRun('stats-001', 'passed', {
        total: 10, passed: 10, failed: 0, skipped: 0, duration: 100,
      });

      await repo.createRun({
        id: 'stats-002',
        suite: 'all',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      await repo.completeRun('stats-002', 'passed', {
        total: 10, passed: 10, failed: 0, skipped: 0, duration: 200,
      });

      await repo.createRun({
        id: 'stats-003',
        suite: 'all',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      await repo.completeRun('stats-003', 'failed', {
        total: 10, passed: 8, failed: 2, skipped: 0, duration: 300,
      });

      const stats = await repo.getStats();
      expect(stats.totalRuns).toBe(3);
      expect(stats.passedRuns).toBe(2);
      expect(stats.failedRuns).toBe(1);
      expect(stats.passRate).toBeCloseTo(66.67, 1);
      expect(stats.avgDuration).toBe(200);
    });

    test('should filter stats by suite', async () => {
      await repo.createRun({
        id: 'suite-stats-001',
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      await repo.completeRun('suite-stats-001', 'passed', {
        total: 5, passed: 5, failed: 0, skipped: 0, duration: 100,
      });

      await repo.createRun({
        id: 'suite-stats-002',
        suite: 'integration',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      await repo.completeRun('suite-stats-002', 'failed', {
        total: 5, passed: 4, failed: 1, skipped: 0, duration: 200,
      });

      const unitStats = await repo.getStats('unit');
      expect(unitStats.totalRuns).toBe(1);
      expect(unitStats.passedRuns).toBe(1);
    });
  });

  describe('getFlakyTests', () => {
    test('should find tests that sometimes pass and sometimes fail', async () => {
      // Run 1: test passes
      await repo.createRun({
        id: 'flaky-run-001',
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      await repo.addResult({
        runId: 'flaky-run-001',
        testName: 'flaky test',
        suite: 'unit',
        status: 'passed',
        duration: 10,
      });

      // Run 2: test fails
      await repo.createRun({
        id: 'flaky-run-002',
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      await repo.addResult({
        runId: 'flaky-run-002',
        testName: 'flaky test',
        suite: 'unit',
        status: 'failed',
        duration: 10,
      });

      // Consistent test
      await repo.addResult({
        runId: 'flaky-run-001',
        testName: 'stable test',
        suite: 'unit',
        status: 'passed',
        duration: 5,
      });
      await repo.addResult({
        runId: 'flaky-run-002',
        testName: 'stable test',
        suite: 'unit',
        status: 'passed',
        duration: 5,
      });

      const flaky = await repo.getFlakyTests();
      expect(flaky).toHaveLength(1);
      expect(flaky[0].testName).toBe('flaky test');
      expect(flaky[0].passes).toBe(1);
      expect(flaky[0].failures).toBe(1);
      expect(flaky[0].flakinessScore).toBe(0.5);
    });
  });

  describe('getLatestRun', () => {
    test('should get most recent run', async () => {
      await repo.createRun({
        id: 'latest-001',
        suite: 'all',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      await repo.createRun({
        id: 'latest-002',
        suite: 'all',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      const latest = await repo.getLatestRun();
      expect(latest).not.toBeNull();
      expect(latest!.id).toBe('latest-002');
    });

    test('should filter by suite', async () => {
      await repo.createRun({
        id: 'suite-latest-001',
        suite: 'unit',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });
      await repo.createRun({
        id: 'suite-latest-002',
        suite: 'integration',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      const latest = await repo.getLatestRun('unit');
      expect(latest!.id).toBe('suite-latest-001');
    });
  });

  describe('deleteOldRuns', () => {
    test('should delete runs older than cutoff date', async () => {
      // Create a run
      await repo.createRun({
        id: 'old-run-001',
        suite: 'all',
        triggeredByType: 'system',
        triggeredByName: 'cli',
      });

      // Delete runs older than tomorrow (should delete everything)
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      const deleted = await repo.deleteOldRuns(tomorrow);

      expect(deleted).toBe(1);

      const found = await repo.findRunById('old-run-001');
      expect(found).toBeNull();
    });
  });
});
