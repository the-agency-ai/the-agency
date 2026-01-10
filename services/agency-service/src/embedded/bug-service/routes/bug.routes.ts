/**
 * Bug Routes
 *
 * HTTP API endpoints for bug management.
 */

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import type { BugService } from '../service/bug.service';
import { createBugSchema, updateBugSchema, listBugsQuerySchema } from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('bug-routes');

/**
 * Create bug routes
 */
export function createBugRoutes(bugService: BugService): Hono {
  const app = new Hono();

  /**
   * GET /bugs - List bugs
   */
  app.get('/', zValidator('query', listBugsQuerySchema), async (c) => {
    const query = c.req.valid('query');
    const result = await bugService.listBugs(query);
    return c.json(result);
  });

  /**
   * GET /bugs/stats - Get bug statistics
   */
  app.get('/stats', async (c) => {
    const stats = await bugService.getStats();
    return c.json(stats);
  });

  /**
   * GET /bugs/:bugId - Get a specific bug
   */
  app.get('/:bugId', async (c) => {
    const bugId = c.req.param('bugId');
    const bug = await bugService.getBug(bugId);

    if (!bug) {
      return c.json({ error: 'Not Found', message: `Bug ${bugId} not found` }, 404);
    }

    return c.json(bug);
  });

  /**
   * POST /bugs - Create a new bug
   */
  app.post('/', zValidator('json', createBugSchema), async (c) => {
    const data = c.req.valid('json');
    const user = c.get('user');

    // Use authenticated user as reporter if not specified
    const reporterName = data.reporterName || user?.name || 'unknown';
    const reporterType = data.reporterType || user?.type || 'system';

    const bug = await bugService.createBug({
      ...data,
      reporterName,
      reporterType,
    });

    logger.info({ bugId: bug.bugId, reporter: reporterName }, 'Bug created via API');
    return c.json(bug, 201);
  });

  /**
   * PATCH /bugs/:bugId - Update a bug
   */
  app.patch('/:bugId', zValidator('json', updateBugSchema), async (c) => {
    const bugId = c.req.param('bugId');
    const data = c.req.valid('json');

    const bug = await bugService.updateBug(bugId, data);

    if (!bug) {
      return c.json({ error: 'Not Found', message: `Bug ${bugId} not found` }, 404);
    }

    logger.info({ bugId, updates: Object.keys(data) }, 'Bug updated via API');
    return c.json(bug);
  });

  /**
   * PATCH /bugs/:bugId/status - Update bug status
   */
  app.patch('/:bugId/status', async (c) => {
    const bugId = c.req.param('bugId');
    const body = await c.req.json();
    const status = body.status;

    if (!status) {
      return c.json({ error: 'Bad Request', message: 'status is required' }, 400);
    }

    const validStatuses = ['Open', 'In Progress', 'Fixed', "Won't Fix"];
    if (!validStatuses.includes(status)) {
      return c.json({
        error: 'Bad Request',
        message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
      }, 400);
    }

    const bug = await bugService.updateStatus(bugId, status);

    if (!bug) {
      return c.json({ error: 'Not Found', message: `Bug ${bugId} not found` }, 404);
    }

    logger.info({ bugId, status }, 'Bug status updated via API');
    return c.json(bug);
  });

  /**
   * PATCH /bugs/:bugId/assign - Assign a bug
   */
  app.patch('/:bugId/assign', async (c) => {
    const bugId = c.req.param('bugId');
    const body = await c.req.json();
    const { assigneeType, assigneeName } = body;

    if (!assigneeName) {
      return c.json({ error: 'Bad Request', message: 'assigneeName is required' }, 400);
    }

    const validTypes = ['agent', 'principal'];
    const type = assigneeType || 'agent';
    if (!validTypes.includes(type)) {
      return c.json({
        error: 'Bad Request',
        message: `Invalid assigneeType. Must be one of: ${validTypes.join(', ')}`,
      }, 400);
    }

    const bug = await bugService.assignBug(bugId, type, assigneeName);

    if (!bug) {
      return c.json({ error: 'Not Found', message: `Bug ${bugId} not found` }, 404);
    }

    logger.info({ bugId, assignee: assigneeName }, 'Bug assigned via API');
    return c.json(bug);
  });

  /**
   * DELETE /bugs/:bugId - Delete a bug
   */
  app.delete('/:bugId', async (c) => {
    const bugId = c.req.param('bugId');
    const deleted = await bugService.deleteBug(bugId);

    if (!deleted) {
      return c.json({ error: 'Not Found', message: `Bug ${bugId} not found` }, 404);
    }

    logger.info({ bugId }, 'Bug deleted via API');
    return c.json({ success: true, bugId });
  });

  return app;
}
