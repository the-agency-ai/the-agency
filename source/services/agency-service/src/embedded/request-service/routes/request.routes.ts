/**
 * Request Routes
 *
 * HTTP API endpoints for request management.
 * Uses explicit operation names (not HTTP verb semantics).
 */

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import type { RequestService } from '../service/request.service';
import { createRequestSchema, updateRequestSchema, listRequestsQuerySchema } from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('request-routes');

// Schemas for status update and assignment endpoints
const updateStatusSchema = z.object({
  status: z.enum(['Open', 'In Progress', 'Review', 'Testing', 'Complete', 'On Hold', 'Cancelled']),
});

const assignRequestSchema = z.object({
  assigneeType: z.enum(['agent', 'principal']).optional().default('agent'),
  assigneeName: z.string().min(1, 'assigneeName is required'),
});

/**
 * Create request routes with explicit operation names
 */
export function createRequestRoutes(requestService: RequestService): Hono {
  const app = new Hono();

  // Global error handler
  app.onError((err, c) => {
    logger.error({ error: err.message, stack: err.stack }, 'Request route error');
    return c.json(
      { error: 'Internal Server Error', message: 'An unexpected error occurred' },
      500
    );
  });

  /**
   * POST /request/create - Create a new request
   */
  app.post('/create', zValidator('json', createRequestSchema), async (c) => {
    const data = c.req.valid('json');
    const user = c.get('user');

    // Use authenticated user as reporter if not specified
    const reporterName = data.reporterName || user?.name || 'unknown';
    const reporterType = data.reporterType || user?.type || 'system';

    const request = await requestService.createRequest({
      ...data,
      reporterName,
      reporterType,
    });

    logger.info({ requestId: request.requestId, principal: request.principalName }, 'Request created via API');
    return c.json(request, 201);
  });

  /**
   * GET /request/list - List requests with filters, sorting, search
   */
  app.get('/list', zValidator('query', listRequestsQuerySchema), async (c) => {
    const query = c.req.valid('query');
    const result = await requestService.listRequests(query);
    return c.json(result);
  });

  /**
   * GET /request/get/:requestId - Get a specific request
   */
  app.get('/get/:requestId', async (c) => {
    const requestId = c.req.param('requestId');
    const request = await requestService.getRequest(requestId);

    if (!request) {
      return c.json({ error: 'Not Found', message: `Request ${requestId} not found` }, 404);
    }

    return c.json(request);
  });

  /**
   * POST /request/update/:requestId - Update a request
   */
  app.post('/update/:requestId', zValidator('json', updateRequestSchema), async (c) => {
    const requestId = c.req.param('requestId');
    const data = c.req.valid('json');

    const request = await requestService.updateRequest(requestId, data);

    if (!request) {
      return c.json({ error: 'Not Found', message: `Request ${requestId} not found` }, 404);
    }

    logger.info({ requestId, updates: Object.keys(data) }, 'Request updated via API');
    return c.json(request);
  });

  /**
   * POST /request/update-status/:requestId - Update request status
   */
  app.post('/update-status/:requestId', zValidator('json', updateStatusSchema), async (c) => {
    const requestId = c.req.param('requestId');
    const { status } = c.req.valid('json');

    const request = await requestService.updateStatus(requestId, status);

    if (!request) {
      return c.json({ error: 'Not Found', message: `Request ${requestId} not found` }, 404);
    }

    logger.info({ requestId, status }, 'Request status updated via API');
    return c.json(request);
  });

  /**
   * POST /request/assign/:requestId - Assign a request
   */
  app.post('/assign/:requestId', zValidator('json', assignRequestSchema), async (c) => {
    const requestId = c.req.param('requestId');
    const { assigneeType, assigneeName } = c.req.valid('json');

    const request = await requestService.assignRequest(requestId, assigneeType, assigneeName);

    if (!request) {
      return c.json({ error: 'Not Found', message: `Request ${requestId} not found` }, 404);
    }

    logger.info({ requestId, assignee: assigneeName }, 'Request assigned via API');
    return c.json(request);
  });

  /**
   * POST /request/delete/:requestId - Delete a request
   */
  app.post('/delete/:requestId', async (c) => {
    const requestId = c.req.param('requestId');
    const deleted = await requestService.deleteRequest(requestId);

    if (!deleted) {
      return c.json({ error: 'Not Found', message: `Request ${requestId} not found` }, 404);
    }

    logger.info({ requestId }, 'Request deleted via API');
    return c.json({ success: true, message: `Request ${requestId} deleted` });
  });

  /**
   * GET /request/stats - Get request statistics
   */
  app.get('/stats', async (c) => {
    const stats = await requestService.getStats();
    return c.json(stats);
  });

  return app;
}
