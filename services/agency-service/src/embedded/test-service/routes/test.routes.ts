/**
 * Test Routes
 *
 * HTTP API endpoints for test execution and history.
 * Follows the SOA pattern with singular naming (/api/test).
 */

import { Hono } from 'hono';
import { TestService } from '../service/test.service';
import { createTestRunSchema, queryTestRunsSchema } from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('test-routes');

export function createTestRoutes(testService: TestService) {
  const app = new Hono();

  /**
   * POST /api/test/run - Start and execute a test run
   */
  app.post('/run', async (c) => {
    try {
      const body = await c.req.json();
      const request = createTestRunSchema.parse(body);

      const result = await testService.runTests(request);

      logger.info({ runId: result.id, status: result.status }, 'Test run completed via API');

      return c.json(result, 201);
    } catch (error) {
      logger.error({ error }, 'Failed to run tests');
      if (error instanceof Error && error.name === 'ZodError') {
        return c.json({ error: 'Invalid request', details: error }, 400);
      }
      return c.json({ error: 'Failed to run tests' }, 500);
    }
  });

  /**
   * POST /api/test/run/start - Start a test run (without executing)
   */
  app.post('/run/start', async (c) => {
    try {
      const body = await c.req.json();
      const request = createTestRunSchema.parse(body);

      const run = await testService.startRun(request);

      return c.json(run, 201);
    } catch (error) {
      logger.error({ error }, 'Failed to start test run');
      if (error instanceof Error && error.name === 'ZodError') {
        return c.json({ error: 'Invalid request', details: error }, 400);
      }
      return c.json({ error: 'Failed to start test run' }, 500);
    }
  });

  /**
   * POST /api/test/run/:id/execute - Execute a pending test run
   */
  app.post('/run/:id/execute', async (c) => {
    try {
      const id = c.req.param('id');
      const result = await testService.executeRun(id);

      return c.json(result);
    } catch (error) {
      logger.error({ error }, 'Failed to execute test run');
      const message = error instanceof Error ? error.message : 'Failed to execute';
      return c.json({ error: message }, 500);
    }
  });

  /**
   * POST /api/test/run/:id/cancel - Cancel a running test
   */
  app.post('/run/:id/cancel', async (c) => {
    try {
      const id = c.req.param('id');
      const cancelled = await testService.cancelRun(id);

      if (!cancelled) {
        return c.json({ error: 'Run not found or not running' }, 404);
      }

      return c.json({ cancelled: true });
    } catch (error) {
      logger.error({ error }, 'Failed to cancel test run');
      return c.json({ error: 'Failed to cancel' }, 500);
    }
  });

  /**
   * GET /api/test/run - List test runs
   */
  app.get('/run', async (c) => {
    try {
      const query = queryTestRunsSchema.parse({
        suite: c.req.query('suite'),
        status: c.req.query('status'),
        since: c.req.query('since'),
        limit: c.req.query('limit'),
        offset: c.req.query('offset'),
      });

      const result = await testService.listRuns(query);

      return c.json(result);
    } catch (error) {
      logger.error({ error }, 'Failed to list test runs');
      return c.json({ error: 'Failed to list runs' }, 500);
    }
  });

  /**
   * GET /api/test/run/latest - Get the most recent test run
   */
  app.get('/run/latest', async (c) => {
    try {
      const suite = c.req.query('suite');
      const run = await testService.getLatestRun(suite);

      if (!run) {
        return c.json({ error: 'No test runs found' }, 404);
      }

      return c.json(run);
    } catch (error) {
      logger.error({ error }, 'Failed to get latest run');
      return c.json({ error: 'Failed to get latest run' }, 500);
    }
  });

  /**
   * GET /api/test/run/:id - Get a specific test run
   */
  app.get('/run/:id', async (c) => {
    try {
      const id = c.req.param('id');
      const run = await testService.getRunWithResults(id);

      if (!run) {
        return c.json({ error: 'Test run not found' }, 404);
      }

      return c.json(run);
    } catch (error) {
      logger.error({ error }, 'Failed to get test run');
      return c.json({ error: 'Failed to get run' }, 500);
    }
  });

  /**
   * GET /api/test/run/:id/all - Get all results for a run
   */
  app.get('/run/:id/all', async (c) => {
    try {
      const id = c.req.param('id');
      const run = await testService.getRunWithResults(id);

      if (!run) {
        return c.json({ error: 'Test run not found' }, 404);
      }

      return c.json(run);
    } catch (error) {
      logger.error({ error }, 'Failed to get test results');
      return c.json({ error: 'Failed to get results' }, 500);
    }
  });

  /**
   * GET /api/test/run/:id/failures - Get only failed results for a run
   */
  app.get('/run/:id/failures', async (c) => {
    try {
      const id = c.req.param('id');
      const run = await testService.getFailedResults(id);

      if (!run) {
        return c.json({ error: 'Test run not found' }, 404);
      }

      return c.json(run);
    } catch (error) {
      logger.error({ error }, 'Failed to get failed results');
      return c.json({ error: 'Failed to get failures' }, 500);
    }
  });

  /**
   * GET /api/test/stats - Get test statistics
   */
  app.get('/stats', async (c) => {
    try {
      const suite = c.req.query('suite');
      const stats = await testService.getStats(suite);

      return c.json(stats);
    } catch (error) {
      logger.error({ error }, 'Failed to get test stats');
      return c.json({ error: 'Failed to get stats' }, 500);
    }
  });

  /**
   * GET /api/test/flaky - Get flaky tests
   */
  app.get('/flaky', async (c) => {
    try {
      const limit = parseInt(c.req.query('limit') || '10', 10);
      const flaky = await testService.getFlakyTests(limit);

      return c.json({ tests: flaky });
    } catch (error) {
      logger.error({ error }, 'Failed to get flaky tests');
      return c.json({ error: 'Failed to get flaky tests' }, 500);
    }
  });

  /**
   * GET /api/test/suites - Get available test suites
   */
  app.get('/suites', async (c) => {
    try {
      const suites = await testService.getSuites();

      return c.json({ suites });
    } catch (error) {
      logger.error({ error }, 'Failed to get suites');
      return c.json({ error: 'Failed to get suites' }, 500);
    }
  });

  /**
   * DELETE /api/test/cleanup - Clean up old test runs
   */
  app.delete('/cleanup', async (c) => {
    try {
      const days = parseInt(c.req.query('days') || '30', 10);
      const deleted = await testService.cleanup(days);

      return c.json({ deleted, message: `Deleted ${deleted} old test runs` });
    } catch (error) {
      logger.error({ error }, 'Failed to cleanup');
      return c.json({ error: 'Failed to cleanup' }, 500);
    }
  });

  return app;
}
