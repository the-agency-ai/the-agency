/**
 * Test Routes
 *
 * HTTP API endpoints for test execution and history.
 * Uses explicit operation names (not HTTP verb semantics).
 */

import { Hono } from 'hono';
import { z, ZodError } from 'zod';
import { zValidator } from '@hono/zod-validator';
import { TestService } from '../service/test.service';
import { createTestRunSchema, queryTestRunsSchema } from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

// Cleanup request schema
const cleanupSchema = z.object({
  days: z.coerce.number().int().min(1).max(365).default(30),
});

const logger = createServiceLogger('test-routes');

export function createTestRoutes(testService: TestService) {
  const app = new Hono();

  // Global error handler
  app.onError((err, c) => {
    logger.error({ error: err.message, stack: err.stack }, 'Test route error');
    return c.json(
      { error: 'Internal Server Error', message: 'An unexpected error occurred' },
      500
    );
  });

  // ─────────────────────────────────────────────────────────────
  // Test Run Operations
  // ─────────────────────────────────────────────────────────────

  /**
   * POST /test/run/execute - Start and execute a test run
   */
  app.post('/run/execute', async (c) => {
    try {
      const body = await c.req.json();
      const request = createTestRunSchema.parse(body);

      const result = await testService.runTests(request);

      logger.info({ runId: result.id, status: result.status }, 'Test run completed via API');

      return c.json(result, 201);
    } catch (error) {
      logger.error({ error }, 'Failed to run tests');
      if (error instanceof ZodError) {
        return c.json({ error: 'Invalid request', details: error }, 400);
      }
      throw error;
    }
  });

  /**
   * POST /test/run/start - Start a test run (without executing)
   */
  app.post('/run/start', async (c) => {
    try {
      const body = await c.req.json();
      const request = createTestRunSchema.parse(body);

      const run = await testService.startRun(request);

      return c.json(run, 201);
    } catch (error) {
      logger.error({ error }, 'Failed to start test run');
      if (error instanceof ZodError) {
        return c.json({ error: 'Invalid request', details: error }, 400);
      }
      throw error;
    }
  });

  /**
   * POST /test/run/execute/:id - Execute a pending test run
   */
  app.post('/run/execute/:id', async (c) => {
    try {
      const id = c.req.param('id');
      const result = await testService.executeRun(id);

      return c.json(result);
    } catch (error) {
      logger.error({ error }, 'Failed to execute test run');
      throw error;
    }
  });

  /**
   * POST /test/run/cancel/:id - Cancel a running test
   */
  app.post('/run/cancel/:id', async (c) => {
    try {
      const id = c.req.param('id');
      const cancelled = await testService.cancelRun(id);

      if (!cancelled) {
        return c.json({ error: 'Run not found or not running' }, 404);
      }

      return c.json({ cancelled: true });
    } catch (error) {
      logger.error({ error }, 'Failed to cancel test run');
      throw error;
    }
  });

  // ─────────────────────────────────────────────────────────────
  // Test Run Queries
  // ─────────────────────────────────────────────────────────────

  /**
   * GET /test/run/list - List test runs
   */
  app.get('/run/list', async (c) => {
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
      throw error;
    }
  });

  /**
   * GET /test/run/latest - Get the most recent test run
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
      throw error;
    }
  });

  /**
   * GET /test/run/get/:id - Get a specific test run
   */
  app.get('/run/get/:id', async (c) => {
    try {
      const id = c.req.param('id');
      const run = await testService.getRunWithResults(id);

      if (!run) {
        return c.json({ error: 'Test run not found' }, 404);
      }

      return c.json(run);
    } catch (error) {
      logger.error({ error }, 'Failed to get test run');
      throw error;
    }
  });

  /**
   * GET /test/run/results/:id - Get all results for a run
   */
  app.get('/run/results/:id', async (c) => {
    try {
      const id = c.req.param('id');
      const run = await testService.getRunWithResults(id);

      if (!run) {
        return c.json({ error: 'Test run not found' }, 404);
      }

      return c.json(run);
    } catch (error) {
      logger.error({ error }, 'Failed to get test results');
      throw error;
    }
  });

  /**
   * GET /test/run/failures/:id - Get only failed results for a run
   */
  app.get('/run/failures/:id', async (c) => {
    try {
      const id = c.req.param('id');
      const run = await testService.getFailedResults(id);

      if (!run) {
        return c.json({ error: 'Test run not found' }, 404);
      }

      return c.json(run);
    } catch (error) {
      logger.error({ error }, 'Failed to get failed results');
      throw error;
    }
  });

  // ─────────────────────────────────────────────────────────────
  // Statistics & Discovery
  // ─────────────────────────────────────────────────────────────

  /**
   * GET /test/stats - Get test statistics
   */
  app.get('/stats', async (c) => {
    try {
      const suite = c.req.query('suite');
      const stats = await testService.getStats(suite);

      return c.json(stats);
    } catch (error) {
      logger.error({ error }, 'Failed to get test stats');
      throw error;
    }
  });

  /**
   * GET /test/flaky - Get flaky tests
   */
  app.get('/flaky', async (c) => {
    try {
      const limit = parseInt(c.req.query('limit') || '10', 10);
      const flaky = await testService.getFlakyTests(limit);

      return c.json({ tests: flaky });
    } catch (error) {
      logger.error({ error }, 'Failed to get flaky tests');
      throw error;
    }
  });

  /**
   * GET /test/suites - Get available test suites
   */
  app.get('/suites', async (c) => {
    try {
      const suites = await testService.getSuites();

      return c.json({ suites });
    } catch (error) {
      logger.error({ error }, 'Failed to get suites');
      throw error;
    }
  });

  // ─────────────────────────────────────────────────────────────
  // Maintenance
  // ─────────────────────────────────────────────────────────────

  /**
   * POST /test/cleanup - Clean up old test runs
   */
  app.post('/cleanup', zValidator('json', cleanupSchema), async (c) => {
    try {
      const { days } = c.req.valid('json');
      const deleted = await testService.cleanup(days);

      return c.json({ deleted, message: `Deleted ${deleted} old test runs` });
    } catch (error) {
      logger.error({ error }, 'Failed to cleanup');
      throw error;
    }
  });

  return app;
}
