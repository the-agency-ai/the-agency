/**
 * Log Routes
 *
 * HTTP API endpoints for log management.
 * Supports focused queries for tool run debugging.
 */

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import type { LogService } from '../service/log.service';
import {
  createLogEntrySchema,
  batchCreateLogEntriesSchema,
  queryLogsSchema,
  createToolRunSchema,
  endToolRunSchema,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('log-routes');

/**
 * Create log routes
 */
export function createLogRoutes(logService: LogService): Hono {
  const app = new Hono();

  // ─────────────────────────────────────────────────────────────
  // Log Ingestion
  // ─────────────────────────────────────────────────────────────

  /**
   * POST /log - Ingest a single log entry
   */
  app.post('/', zValidator('json', createLogEntrySchema), async (c) => {
    const data = c.req.valid('json');
    const entry = await logService.ingest(data);
    return c.json(entry, 201);
  });

  /**
   * POST /log/batch - Ingest multiple log entries
   */
  app.post('/batch', zValidator('json', batchCreateLogEntriesSchema), async (c) => {
    const data = c.req.valid('json');
    const result = await logService.ingestBatch(data);
    logger.debug({ count: result.count }, 'Batch ingested');
    return c.json(result, 201);
  });

  // ─────────────────────────────────────────────────────────────
  // Log Queries
  // ─────────────────────────────────────────────────────────────

  /**
   * GET /log - Query logs with filters
   *
   * Query params:
   *   service   - Filter by service name
   *   level     - Filter by level (trace, debug, info, warn, error, fatal)
   *   runId     - Filter by tool run ID
   *   requestId - Filter by HTTP request ID
   *   userId    - Filter by user
   *   search    - Full-text search in message
   *   since     - Time range start (1h, 24h, 7d, or ISO timestamp)
   *   until     - Time range end (ISO timestamp)
   *   limit     - Max results (default 100)
   *   offset    - Pagination offset
   */
  app.get('/', zValidator('query', queryLogsSchema), async (c) => {
    const query = c.req.valid('query');
    const result = await logService.query(query);
    return c.json(result);
  });

  /**
   * GET /log/stats - Get log statistics
   */
  app.get('/stats', async (c) => {
    const stats = await logService.getStats();
    return c.json(stats);
  });

  /**
   * GET /log/services - List services with logs
   */
  app.get('/services', async (c) => {
    const services = await logService.getServices();
    return c.json({ services });
  });

  /**
   * GET /log/search - Full-text search in logs
   */
  app.get('/search', async (c) => {
    const query = c.req.query('q');
    const since = c.req.query('since') || '24h';
    const limit = parseInt(c.req.query('limit') || '100', 10);

    if (!query) {
      return c.json({ error: 'Bad Request', message: 'q parameter required' }, 400);
    }

    const result = await logService.query({
      search: query,
      since,
      limit,
      offset: 0,
    });

    return c.json(result);
  });

  // ─────────────────────────────────────────────────────────────
  // Tool Run APIs (focused queries)
  // ─────────────────────────────────────────────────────────────

  /**
   * POST /log/run - Start a new tool run
   * Returns run-id for logging correlation
   */
  app.post('/run', zValidator('json', createToolRunSchema), async (c) => {
    const data = c.req.valid('json');
    const run = await logService.startToolRun(data);
    logger.info({ runId: run.runId, tool: data.tool }, 'Tool run started via API');
    return c.json(run, 201);
  });

  /**
   * POST /log/run/:runId/end - End a tool run
   */
  app.post('/run/:runId/end', zValidator('json', endToolRunSchema), async (c) => {
    const runId = c.req.param('runId');
    const data = c.req.valid('json');
    const run = await logService.endToolRun(runId, data);

    if (!run) {
      return c.json({ error: 'Not Found', message: `Run ${runId} not found` }, 404);
    }

    logger.info({ runId, status: data.status }, 'Tool run ended via API');
    return c.json(run);
  });

  /**
   * GET /log/run/:runId - Get run details with logs
   * Returns run info and log summary
   */
  app.get('/run/:runId', async (c) => {
    const runId = c.req.param('runId');
    const details = await logService.getRunDetails(runId);

    if (!details.run && details.logs.length === 0) {
      return c.json({ error: 'Not Found', message: `Run ${runId} not found` }, 404);
    }

    return c.json(details);
  });

  /**
   * GET /log/run/:runId/all - Get ALL log lines for a run
   * Focused query: returns just the logs, no metadata
   */
  app.get('/run/:runId/all', async (c) => {
    const runId = c.req.param('runId');
    const logs = await logService.getRunLogs(runId, { errorsOnly: false });
    return c.json({ runId, count: logs.length, logs });
  });

  /**
   * GET /log/run/:runId/errors - Get only ERROR lines for a run
   * Focused query: returns just error/fatal logs
   */
  app.get('/run/:runId/errors', async (c) => {
    const runId = c.req.param('runId');
    const logs = await logService.getRunLogs(runId, { errorsOnly: true });
    return c.json({ runId, count: logs.length, logs });
  });

  // ─────────────────────────────────────────────────────────────
  // Maintenance
  // ─────────────────────────────────────────────────────────────

  /**
   * POST /log/cleanup - Clean up old logs
   */
  app.post('/cleanup', async (c) => {
    const body = await c.req.json().catch(() => ({}));
    const daysToKeep = body.daysToKeep || 30;
    const result = await logService.cleanup(daysToKeep);
    logger.info({ deleted: result.deleted, daysToKeep }, 'Log cleanup via API');
    return c.json(result);
  });

  return app;
}
