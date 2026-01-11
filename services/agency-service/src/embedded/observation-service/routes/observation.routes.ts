/**
 * Observation Routes
 *
 * HTTP API endpoints for observation management.
 * Uses explicit operation names (not HTTP verb semantics).
 */

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import type { ObservationService } from '../service/observation.service';
import { createObservationSchema, updateObservationSchema, listObservationsQuerySchema } from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('observation-routes');

// Schemas for status update endpoint
const updateStatusSchema = z.object({
  status: z.enum(['Open', 'Acknowledged', 'Noted', 'Archived']),
});

/**
 * Create observation routes with explicit operation names
 */
export function createObservationRoutes(observationService: ObservationService): Hono {
  const app = new Hono();

  // Global error handler
  app.onError((err, c) => {
    logger.error({ error: err.message, stack: err.stack }, 'Observation route error');
    return c.json(
      { error: 'Internal Server Error', message: 'An unexpected error occurred' },
      500
    );
  });

  /**
   * POST /observation/create - Create a new observation
   */
  app.post('/create', zValidator('json', createObservationSchema), async (c) => {
    const data = c.req.valid('json');
    const user = c.get('user');

    // Use authenticated user as reporter if not specified
    const reporterName = data.reporterName || user?.name || 'unknown';
    const reporterType = data.reporterType || user?.type || 'system';

    const observation = await observationService.createObservation({
      ...data,
      reporterName,
      reporterType,
    });

    logger.info({ observationId: observation.observationId }, 'Observation created via API');
    return c.json(observation, 201);
  });

  /**
   * GET /observation/list - List observations with filters, sorting, search
   */
  app.get('/list', zValidator('query', listObservationsQuerySchema), async (c) => {
    const query = c.req.valid('query');
    const result = await observationService.listObservations(query);
    return c.json(result);
  });

  /**
   * GET /observation/get/:observationId - Get a specific observation
   */
  app.get('/get/:observationId', async (c) => {
    const observationId = c.req.param('observationId');
    const observation = await observationService.getObservation(observationId);

    if (!observation) {
      return c.json({ error: 'Not Found', message: `Observation ${observationId} not found` }, 404);
    }

    return c.json(observation);
  });

  /**
   * POST /observation/update/:observationId - Update an observation
   */
  app.post('/update/:observationId', zValidator('json', updateObservationSchema), async (c) => {
    const observationId = c.req.param('observationId');
    const data = c.req.valid('json');

    const observation = await observationService.updateObservation(observationId, data);

    if (!observation) {
      return c.json({ error: 'Not Found', message: `Observation ${observationId} not found` }, 404);
    }

    logger.info({ observationId, updates: Object.keys(data) }, 'Observation updated via API');
    return c.json(observation);
  });

  /**
   * POST /observation/update-status/:observationId - Update observation status
   */
  app.post('/update-status/:observationId', zValidator('json', updateStatusSchema), async (c) => {
    const observationId = c.req.param('observationId');
    const { status } = c.req.valid('json');

    const observation = await observationService.updateStatus(observationId, status);

    if (!observation) {
      return c.json({ error: 'Not Found', message: `Observation ${observationId} not found` }, 404);
    }

    logger.info({ observationId, status }, 'Observation status updated via API');
    return c.json(observation);
  });

  /**
   * POST /observation/acknowledge/:observationId - Quick acknowledge
   */
  app.post('/acknowledge/:observationId', async (c) => {
    const observationId = c.req.param('observationId');
    const observation = await observationService.acknowledgeObservation(observationId);

    if (!observation) {
      return c.json({ error: 'Not Found', message: `Observation ${observationId} not found` }, 404);
    }

    logger.info({ observationId }, 'Observation acknowledged via API');
    return c.json(observation);
  });

  /**
   * POST /observation/archive/:observationId - Quick archive
   */
  app.post('/archive/:observationId', async (c) => {
    const observationId = c.req.param('observationId');
    const observation = await observationService.archiveObservation(observationId);

    if (!observation) {
      return c.json({ error: 'Not Found', message: `Observation ${observationId} not found` }, 404);
    }

    logger.info({ observationId }, 'Observation archived via API');
    return c.json(observation);
  });

  /**
   * POST /observation/delete/:observationId - Delete an observation
   */
  app.post('/delete/:observationId', async (c) => {
    const observationId = c.req.param('observationId');
    const deleted = await observationService.deleteObservation(observationId);

    if (!deleted) {
      return c.json({ error: 'Not Found', message: `Observation ${observationId} not found` }, 404);
    }

    logger.info({ observationId }, 'Observation deleted via API');
    return c.json({ success: true, message: `Observation ${observationId} deleted` });
  });

  /**
   * GET /observation/stats - Get observation statistics
   */
  app.get('/stats', async (c) => {
    const stats = await observationService.getStats();
    return c.json(stats);
  });

  return app;
}
