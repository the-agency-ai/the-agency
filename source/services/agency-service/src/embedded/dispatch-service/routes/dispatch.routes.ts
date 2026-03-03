/**
 * Dispatch Routes
 *
 * HTTP API endpoints for the dispatch queue system.
 * Uses explicit operation names (not HTTP verb semantics).
 */

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import type { DispatchService } from '../service/dispatch.service';
import {
  enqueueItemSchema,
  claimItemSchema,
  completeItemSchema,
  failItemSchema,
  registerInstanceSchema,
  listDispatchQuerySchema,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('dispatch-routes');

/**
 * Create dispatch routes with explicit operation names
 */
export function createDispatchRoutes(dispatchService: DispatchService): Hono {
  const app = new Hono();

  // Global error handler
  app.onError((err, c) => {
    logger.error({ error: err.message, stack: err.stack }, 'Dispatch route error');
    return c.json(
      { error: 'Internal Server Error', message: 'An unexpected error occurred' },
      500
    );
  });

  // ==================== Work Items ====================

  /**
   * POST /dispatch/enqueue — Add work to queue
   */
  app.post('/enqueue', zValidator('json', enqueueItemSchema), async (c) => {
    const data = c.req.valid('json');

    try {
      const item = await dispatchService.enqueue(data);
      return c.json(item, 201);
    } catch (error) {
      if (error instanceof Error) {
        return c.json({ error: 'Bad Request', message: error.message }, 400);
      }
      throw error;
    }
  });

  /**
   * POST /dispatch/claim — Claim next item (agent-first, then shared)
   */
  app.post('/claim', zValidator('json', claimItemSchema), async (c) => {
    const data = c.req.valid('json');
    const item = await dispatchService.claim(data);

    if (!item) {
      return c.json({ item: null, message: 'No work available' });
    }

    return c.json({ item });
  });

  /**
   * POST /dispatch/release/:id — Release claimed item back to pending
   */
  app.post('/release/:id', async (c) => {
    const id = c.req.param('id');
    const released = await dispatchService.release(id);

    if (!released) {
      return c.json({ error: 'Not Found', message: `Item ${id} not found or not claimed` }, 404);
    }

    return c.json({ success: true, itemId: id });
  });

  /**
   * POST /dispatch/complete/:id — Mark completed
   */
  app.post('/complete/:id', zValidator('json', completeItemSchema), async (c) => {
    const id = c.req.param('id');
    const data = c.req.valid('json');
    const completed = await dispatchService.complete(id, data.result);

    if (!completed) {
      return c.json({ error: 'Not Found', message: `Item ${id} not found or not in claimable state` }, 404);
    }

    return c.json({ success: true, itemId: id });
  });

  /**
   * POST /dispatch/fail/:id — Mark failed
   */
  app.post('/fail/:id', zValidator('json', failItemSchema), async (c) => {
    const id = c.req.param('id');
    const data = c.req.valid('json');
    const failed = await dispatchService.fail(id, data.error);

    if (!failed) {
      return c.json({ error: 'Not Found', message: `Item ${id} not found or not in claimable state` }, 404);
    }

    return c.json({ success: true, itemId: id });
  });

  /**
   * POST /dispatch/cancel/:id — Cancel pending item
   */
  app.post('/cancel/:id', async (c) => {
    const id = c.req.param('id');
    const cancelled = await dispatchService.cancel(id);

    if (!cancelled) {
      return c.json({ error: 'Not Found', message: `Item ${id} not found or not pending` }, 404);
    }

    return c.json({ success: true, itemId: id });
  });

  /**
   * GET /dispatch/next/:agentName — Peek without claiming
   */
  app.get('/next/:agentName', async (c) => {
    const agentName = c.req.param('agentName');
    const item = await dispatchService.peekNext(agentName);

    return c.json({ item });
  });

  /**
   * GET /dispatch/list — List items with filters
   */
  app.get('/list', zValidator('query', listDispatchQuerySchema), async (c) => {
    const query = c.req.valid('query');
    const result = await dispatchService.listItems(query);
    return c.json(result);
  });

  /**
   * GET /dispatch/get/:id — Get specific item
   */
  app.get('/get/:id', async (c) => {
    const id = c.req.param('id');
    const item = await dispatchService.getItem(id);

    if (!item) {
      return c.json({ error: 'Not Found', message: `Item ${id} not found` }, 404);
    }

    return c.json(item);
  });

  /**
   * GET /dispatch/stats — Queue statistics
   */
  app.get('/stats', async (c) => {
    const stats = await dispatchService.getStats();
    return c.json(stats);
  });

  // ==================== Instance Registry ====================

  /**
   * POST /dispatch/instance/register — Register instance
   */
  app.post('/instance/register', zValidator('json', registerInstanceSchema), async (c) => {
    const data = c.req.valid('json');

    try {
      const instance = await dispatchService.registerInstance(data);
      return c.json(instance, 201);
    } catch (error) {
      if (error instanceof Error) {
        return c.json({ error: 'Bad Request', message: error.message }, 400);
      }
      throw error;
    }
  });

  /**
   * POST /dispatch/instance/heartbeat/:id — Heartbeat
   */
  app.post('/instance/heartbeat/:id', async (c) => {
    const id = c.req.param('id');
    const success = await dispatchService.heartbeat(id);

    return c.json({ success, instanceId: id });
  });

  /**
   * POST /dispatch/instance/deregister/:id — Remove instance
   */
  app.post('/instance/deregister/:id', async (c) => {
    const id = c.req.param('id');
    const deregistered = await dispatchService.deregisterInstance(id);

    if (!deregistered) {
      return c.json({ error: 'Not Found', message: `Instance ${id} not found` }, 404);
    }

    return c.json({ success: true, instanceId: id });
  });

  /**
   * POST /dispatch/instance/release-all/:id — Release all claims by instance
   */
  app.post('/instance/release-all/:id', async (c) => {
    const id = c.req.param('id');
    const count = await dispatchService.releaseAllByInstance(id);

    return c.json({ success: true, instanceId: id, releasedCount: count });
  });

  /**
   * GET /dispatch/instance/list — List instances
   */
  app.get('/instance/list', async (c) => {
    const instances = await dispatchService.listInstances();
    return c.json({ instances });
  });

  return app;
}
