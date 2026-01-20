/**
 * Log Routes Tests
 *
 * Tests for log service HTTP API endpoints.
 * Created for REQUEST-jordan-0012 test review.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { Hono } from 'hono';
import { createLogRoutes } from '../../src/embedded/log-service/routes/log.routes';
import { LogService } from '../../src/embedded/log-service/service/log.service';
import { LogRepository } from '../../src/embedded/log-service/repository/log.repository';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('Log Routes', () => {
  let db: DatabaseAdapter;
  let repo: LogRepository;
  let service: LogService;
  let app: Hono;
  const testDbPath = '/tmp/agency-test-log-routes';
  const testDbFile = `${testDbPath}/logs.db`;

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'logs.db',
    });
    await db.initialize();
    repo = new LogRepository(db);
    await repo.initialize();
    service = new LogService(repo);

    // Create Hono app with log routes
    app = new Hono();
    app.route('/log', createLogRoutes(service));
  });

  afterEach(async () => {
    await db.close();
    try {
      if (existsSync(testDbFile)) await unlink(testDbFile);
      if (existsSync(`${testDbFile}-wal`)) await unlink(`${testDbFile}-wal`);
      if (existsSync(`${testDbFile}-shm`)) await unlink(`${testDbFile}-shm`);
    } catch {
      // Ignore cleanup errors
    }
  });

  describe('POST /log/cleanup', () => {
    test('should accept valid daysToKeep', async () => {
      const res = await app.request('/log/cleanup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ daysToKeep: 30 }),
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.deleted).toBeDefined();
    });

    test('should accept minimum daysToKeep (1)', async () => {
      const res = await app.request('/log/cleanup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ daysToKeep: 1 }),
      });

      expect(res.status).toBe(200);
    });

    test('should accept maximum daysToKeep (365)', async () => {
      const res = await app.request('/log/cleanup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ daysToKeep: 365 }),
      });

      expect(res.status).toBe(200);
    });

    test('should reject daysToKeep less than 1', async () => {
      const res = await app.request('/log/cleanup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ daysToKeep: 0 }),
      });

      expect(res.status).toBe(400);
    });

    test('should reject daysToKeep greater than 365', async () => {
      const res = await app.request('/log/cleanup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ daysToKeep: 366 }),
      });

      expect(res.status).toBe(400);
    });

    test('should reject negative daysToKeep', async () => {
      const res = await app.request('/log/cleanup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ daysToKeep: -1 }),
      });

      expect(res.status).toBe(400);
    });

    test('should reject non-integer daysToKeep', async () => {
      const res = await app.request('/log/cleanup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ daysToKeep: 30.5 }),
      });

      expect(res.status).toBe(400);
    });

    test('should use default when daysToKeep not provided', async () => {
      const res = await app.request('/log/cleanup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });

      expect(res.status).toBe(200);
    });
  });

  describe('GET /log/search', () => {
    test('should require q parameter', async () => {
      const res = await app.request('/log/search');

      expect(res.status).toBe(400);
      const data = await res.json();
      expect(data.error).toBe('Bad Request');
      expect(data.message).toContain('q parameter required');
    });

    test('should accept valid search query', async () => {
      // First create a log entry
      await service.ingest({
        service: 'test-service',
        level: 'info',
        message: 'Test searchable message',
      });

      const res = await app.request('/log/search?q=searchable');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.logs).toBeDefined();
    });

    test('should accept since parameter', async () => {
      const res = await app.request('/log/search?q=test&since=1h');

      expect(res.status).toBe(200);
    });

    test('should accept limit parameter', async () => {
      const res = await app.request('/log/search?q=test&limit=50');

      expect(res.status).toBe(200);
    });

    test('should use default limit for invalid limit', async () => {
      // Invalid limit should fall back to default (100)
      const res = await app.request('/log/search?q=test&limit=invalid');

      expect(res.status).toBe(200);
    });

    test('should use default limit for limit exceeding max', async () => {
      // Limit > 1000 should use default
      const res = await app.request('/log/search?q=test&limit=9999');

      expect(res.status).toBe(200);
    });
  });

  describe('POST /log/ingest', () => {
    test('should ingest valid log entry', async () => {
      const res = await app.request('/log/ingest', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          service: 'test-service',
          level: 'info',
          message: 'Test message',
        }),
      });

      expect(res.status).toBe(201);
      const data = await res.json();
      expect(data.id).toBeDefined();
      expect(data.service).toBe('test-service');
    });

    test('should reject missing service', async () => {
      const res = await app.request('/log/ingest', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          level: 'info',
          message: 'Test message',
        }),
      });

      expect(res.status).toBe(400);
    });

    test('should reject missing message', async () => {
      const res = await app.request('/log/ingest', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          service: 'test-service',
          level: 'info',
        }),
      });

      expect(res.status).toBe(400);
    });

    test('should reject invalid level', async () => {
      const res = await app.request('/log/ingest', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          service: 'test-service',
          level: 'invalid',
          message: 'Test message',
        }),
      });

      expect(res.status).toBe(400);
    });
  });

  describe('POST /log/ingest-batch', () => {
    test('should ingest multiple entries', async () => {
      const res = await app.request('/log/ingest-batch', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          entries: [
            { service: 'svc1', message: 'msg1' },
            { service: 'svc2', message: 'msg2' },
          ],
        }),
      });

      expect(res.status).toBe(201);
      const data = await res.json();
      expect(data.count).toBe(2);
    });

    test('should reject empty entries array', async () => {
      const res = await app.request('/log/ingest-batch', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ entries: [] }),
      });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /log/query', () => {
    beforeEach(async () => {
      await service.ingest({ service: 'api', level: 'info', message: 'API log' });
      await service.ingest({ service: 'db', level: 'error', message: 'DB error' });
    });

    test('should query all logs', async () => {
      const res = await app.request('/log/query');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.logs.length).toBe(2);
    });

    test('should filter by service', async () => {
      const res = await app.request('/log/query?service=api');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.logs.length).toBe(1);
      expect(data.logs[0].service).toBe('api');
    });

    test('should filter by level', async () => {
      const res = await app.request('/log/query?level=error');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.logs.length).toBe(1);
      expect(data.logs[0].level).toBe('error');
    });

    test('should paginate with limit and offset', async () => {
      const res = await app.request('/log/query?limit=1&offset=0');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.logs.length).toBe(1);
      expect(data.total).toBe(2);
      expect(data.limit).toBe(1);
      expect(data.offset).toBe(0);
    });
  });

  describe('GET /log/stats', () => {
    test('should return statistics', async () => {
      await service.ingest({ service: 'api', level: 'info', message: 'Info' });
      await service.ingest({ service: 'api', level: 'error', message: 'Error' });

      const res = await app.request('/log/stats');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.total).toBe(2);
      expect(data.byLevel).toBeDefined();
      expect(data.byService).toBeDefined();
    });
  });

  describe('GET /log/services', () => {
    test('should return list of services', async () => {
      await service.ingest({ service: 'api', level: 'info', message: 'Test' });
      await service.ingest({ service: 'db', level: 'info', message: 'Test' });

      const res = await app.request('/log/services');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.services).toContain('api');
      expect(data.services).toContain('db');
    });
  });

  describe('Tool Run Endpoints', () => {
    test('POST /log/run/start should create tool run', async () => {
      const res = await app.request('/log/run/start', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          tool: 'test-tool',
          toolType: 'agency-tool',
        }),
      });

      expect(res.status).toBe(201);
      const data = await res.json();
      expect(data.runId).toBeDefined();
      expect(data.tool).toBe('test-tool');
      expect(data.status).toBe('running');
    });

    test('POST /log/run/end/:runId should end tool run', async () => {
      // Start a run first
      const startRes = await app.request('/log/run/start', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tool: 'test-tool' }),
      });
      const { runId } = await startRes.json();

      // End the run
      const endRes = await app.request(`/log/run/end/${runId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'success', summary: 'Done' }),
      });

      expect(endRes.status).toBe(200);
      const data = await endRes.json();
      expect(data.status).toBe('success');
      expect(data.summary).toBe('Done');
    });

    test('POST /log/run/end/:runId should return 404 for non-existent run', async () => {
      const res = await app.request('/log/run/end/non-existent', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'success' }),
      });

      expect(res.status).toBe(404);
    });

    test('GET /log/run/get/:runId should return run details', async () => {
      // Start and end a run
      const startRes = await app.request('/log/run/start', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tool: 'test-tool' }),
      });
      const { runId } = await startRes.json();

      const res = await app.request(`/log/run/get/${runId}`);

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.run.runId).toBe(runId);
    });

    test('GET /log/run/get/:runId should return 404 for non-existent run', async () => {
      const res = await app.request('/log/run/get/non-existent');

      expect(res.status).toBe(404);
    });

    test('GET /log/run/logs/:runId should return logs for run', async () => {
      // Start a run
      const startRes = await app.request('/log/run/start', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tool: 'test-tool' }),
      });
      const { runId } = await startRes.json();

      // Ingest a log for this run
      await service.ingest({
        service: 'test',
        message: 'Log for run',
        runId,
      });

      const res = await app.request(`/log/run/logs/${runId}`);

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.runId).toBe(runId);
      // At least 1 log (could be more from startToolRun logging)
      expect(data.logs.length).toBeGreaterThanOrEqual(1);
    });

    test('GET /log/run/errors/:runId should return only errors', async () => {
      // Start a run
      const startRes = await app.request('/log/run/start', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tool: 'test-tool' }),
      });
      const { runId } = await startRes.json();

      // Ingest logs
      await service.ingest({ service: 'test', level: 'info', message: 'Info', runId });
      await service.ingest({ service: 'test', level: 'error', message: 'Error', runId });

      const res = await app.request(`/log/run/errors/${runId}`);

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.logs.length).toBe(1);
      expect(data.logs[0].level).toBe('error');
    });
  });

  describe('Tool Stats Endpoints', () => {
    beforeEach(async () => {
      // Create some tool runs
      const run = await service.startToolRun({ tool: 'commit', toolType: 'agency-tool' });
      await service.endToolRun(run.runId, { status: 'success', exitCode: 0 });
    });

    test('GET /log/stats/tools should return tool statistics', async () => {
      const res = await app.request('/log/stats/tools');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.summary).toBeDefined();
      expect(data.tools).toBeDefined();
    });

    test('GET /log/stats/tools/:name should return stats for specific tool', async () => {
      const res = await app.request('/log/stats/tools/commit');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.summary.totalRuns).toBeGreaterThanOrEqual(1);
    });

    test('GET /log/failures should return recent failures', async () => {
      // Create a failing run
      const run = await service.startToolRun({ tool: 'failing-tool' });
      await service.endToolRun(run.runId, { status: 'failure', exitCode: 1 });

      const res = await app.request('/log/failures');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.failures.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe('Opportunity Endpoints', () => {
    test('GET /log/opportunities should return summary', async () => {
      const res = await app.request('/log/opportunities');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.highOutputTools).toBeDefined();
      expect(data.recommendations).toBeDefined();
    });

    test('GET /log/opportunities/high-output should return high output tools', async () => {
      const res = await app.request('/log/opportunities/high-output');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.tools).toBeDefined();
      expect(data.count).toBeDefined();
    });

    test('GET /log/opportunities/patterns should return patterns', async () => {
      const res = await app.request('/log/opportunities/patterns');

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.patterns).toBeDefined();
    });
  });

  describe('safeParseInt edge cases', () => {
    test('should handle empty limit in search', async () => {
      const res = await app.request('/log/search?q=test&limit=');

      expect(res.status).toBe(200);
    });

    test('should handle negative limit in search', async () => {
      const res = await app.request('/log/search?q=test&limit=-5');

      expect(res.status).toBe(200);
    });

    test('should handle zero limit in search', async () => {
      const res = await app.request('/log/search?q=test&limit=0');

      expect(res.status).toBe(200);
    });
  });

  describe('Error handling', () => {
    test('should handle malformed JSON', async () => {
      const res = await app.request('/log/ingest', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: 'not valid json',
      });

      // Malformed JSON is caught by error handler and returns 500
      expect(res.status).toBe(500);
      const data = await res.json();
      expect(data.error).toBe('Internal Server Error');
    });
  });
});
