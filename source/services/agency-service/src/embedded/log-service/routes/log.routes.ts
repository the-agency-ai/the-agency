/**
 * Log Routes
 *
 * HTTP API endpoints for log management.
 * Uses explicit operation names (not HTTP verb semantics).
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
 * Create log routes with explicit operation names
 */
export function createLogRoutes(logService: LogService): Hono {
  const app = new Hono();

  // Global error handler
  app.onError((err, c) => {
    logger.error({ error: err.message, stack: err.stack }, 'Log route error');
    return c.json(
      { error: 'Internal Server Error', message: 'An unexpected error occurred' },
      500
    );
  });

  // ─────────────────────────────────────────────────────────────
  // Log Ingestion
  // ─────────────────────────────────────────────────────────────

  /**
   * POST /log/ingest - Ingest a single log entry
   */
  app.post('/ingest', zValidator('json', createLogEntrySchema), async (c) => {
    const data = c.req.valid('json');
    const entry = await logService.ingest(data);
    return c.json(entry, 201);
  });

  /**
   * POST /log/ingest-batch - Ingest multiple log entries
   */
  app.post('/ingest-batch', zValidator('json', batchCreateLogEntriesSchema), async (c) => {
    const data = c.req.valid('json');
    const result = await logService.ingestBatch(data);
    logger.debug({ count: result.count }, 'Batch ingested');
    return c.json(result, 201);
  });

  // ─────────────────────────────────────────────────────────────
  // Log Queries
  // ─────────────────────────────────────────────────────────────

  /**
   * GET /log/query - Query logs with filters
   */
  app.get('/query', zValidator('query', queryLogsSchema), async (c) => {
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
   * POST /log/run/start - Start a new tool run
   */
  app.post('/run/start', zValidator('json', createToolRunSchema), async (c) => {
    const data = c.req.valid('json');
    const run = await logService.startToolRun(data);
    logger.info({ runId: run.runId, tool: data.tool }, 'Tool run started via API');
    return c.json(run, 201);
  });

  /**
   * POST /log/run/end/:runId - End a tool run
   */
  app.post('/run/end/:runId', zValidator('json', endToolRunSchema), async (c) => {
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
   * GET /log/run/get/:runId - Get run details with logs
   */
  app.get('/run/get/:runId', async (c) => {
    const runId = c.req.param('runId');
    const details = await logService.getRunDetails(runId);

    if (!details.run && details.logs.length === 0) {
      return c.json({ error: 'Not Found', message: `Run ${runId} not found` }, 404);
    }

    return c.json(details);
  });

  /**
   * GET /log/run/logs/:runId - Get ALL log lines for a run
   */
  app.get('/run/logs/:runId', async (c) => {
    const runId = c.req.param('runId');
    const logs = await logService.getRunLogs(runId, { errorsOnly: false });
    return c.json({ runId, count: logs.length, logs });
  });

  /**
   * GET /log/run/errors/:runId - Get only ERROR lines for a run
   */
  app.get('/run/errors/:runId', async (c) => {
    const runId = c.req.param('runId');
    const logs = await logService.getRunLogs(runId, { errorsOnly: true });
    return c.json({ runId, count: logs.length, logs });
  });

  // ─────────────────────────────────────────────────────────────
  // Tool Telemetry
  // ─────────────────────────────────────────────────────────────

  /**
   * GET /log/stats/tools - Get tool usage statistics
   */
  app.get('/stats/tools', async (c) => {
    const since = c.req.query('since') || '7d';
    const tool = c.req.query('tool');
    const toolType = c.req.query('toolType');
    const stats = await logService.getToolStats({
      since,
      tool: tool || undefined,
      toolType: toolType || undefined,
    });
    return c.json(stats);
  });

  /**
   * GET /log/stats/tools/:name - Get stats for a specific tool
   */
  app.get('/stats/tools/:name', async (c) => {
    const toolName = c.req.param('name');
    const since = c.req.query('since') || '7d';
    const stats = await logService.getToolStats({ since, tool: toolName });
    return c.json(stats);
  });

  /**
   * GET /log/failures - Get recent tool failures
   */
  app.get('/failures', async (c) => {
    const limit = parseInt(c.req.query('limit') || '20', 10);
    const failures = await logService.getRecentFailures(limit);
    return c.json({ count: failures.length, failures });
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
