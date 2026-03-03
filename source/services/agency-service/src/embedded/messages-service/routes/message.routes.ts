/**
 * Unified Message Routes
 *
 * HTTP API endpoints for the unified messaging system.
 * Uses explicit operation names (not HTTP verb semantics).
 */

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import type { MessageService } from '../service/message.service';
import {
  sendMessageSchema,
  broadcastMessageSchema,
  markReadSchema,
  listMessagesQuerySchema,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('message-routes');

/**
 * Create message routes with explicit operation names
 */
export function createMessageRoutes(messageService: MessageService): Hono {
  const app = new Hono();

  // Global error handler
  app.onError((err, c) => {
    logger.error({ error: err.message, stack: err.stack }, 'Message route error');
    return c.json(
      { error: 'Internal Server Error', message: 'An unexpected error occurred' },
      500
    );
  });

  /**
   * POST /message/send — Send direct message
   */
  app.post('/send', zValidator('json', sendMessageSchema), async (c) => {
    const data = c.req.valid('json');

    try {
      const message = await messageService.sendMessage(data);
      return c.json(message, 201);
    } catch (error) {
      if (error instanceof Error) {
        return c.json({ error: 'Bad Request', message: error.message }, 400);
      }
      throw error;
    }
  });

  /**
   * POST /message/broadcast — Send broadcast message
   */
  app.post('/broadcast', zValidator('json', broadcastMessageSchema), async (c) => {
    const data = c.req.valid('json');

    try {
      const message = await messageService.broadcastMessage(data);
      return c.json(message, 201);
    } catch (error) {
      if (error instanceof Error) {
        return c.json({ error: 'Bad Request', message: error.message }, 400);
      }
      throw error;
    }
  });

  /**
   * POST /message/read/:id — Mark message as read by agent
   */
  app.post('/read/:id', zValidator('json', markReadSchema), async (c) => {
    const id = c.req.param('id');
    const data = c.req.valid('json');

    const result = await messageService.markAsRead(id, data.agentName);
    return c.json({ success: result, messageId: id });
  });

  /**
   * GET /message/list — List messages with filters
   */
  app.get('/list', zValidator('query', listMessagesQuerySchema), async (c) => {
    const query = c.req.valid('query');
    const result = await messageService.listMessages(query);
    return c.json(result);
  });

  /**
   * GET /message/get/:id — Get specific message
   */
  app.get('/get/:id', async (c) => {
    const id = c.req.param('id');
    const message = await messageService.getMessage(id);

    if (!message) {
      return c.json({ error: 'Not Found', message: `Message ${id} not found` }, 404);
    }

    return c.json(message);
  });

  /**
   * GET /message/unread/:agentName — Get unread count + messages
   */
  app.get('/unread/:agentName', async (c) => {
    const agentName = c.req.param('agentName');
    const result = await messageService.getUnread(agentName);
    return c.json(result);
  });

  /**
   * GET /message/thread/:id — Get message + all references to it
   */
  app.get('/thread/:id', async (c) => {
    const id = c.req.param('id');

    try {
      const thread = await messageService.getThread(id);
      return c.json(thread);
    } catch (error) {
      if (error instanceof Error && error.message.includes('not found')) {
        return c.json({ error: 'Not Found', message: error.message }, 404);
      }
      throw error;
    }
  });

  /**
   * POST /message/delete/:id — Delete message
   */
  app.post('/delete/:id', async (c) => {
    const id = c.req.param('id');
    const deleted = await messageService.deleteMessage(id);

    if (!deleted) {
      return c.json({ error: 'Not Found', message: `Message ${id} not found` }, 404);
    }

    return c.json({ success: true, messageId: id });
  });

  /**
   * GET /message/stats — Message statistics
   */
  app.get('/stats', async (c) => {
    const stats = await messageService.getStats();
    return c.json(stats);
  });

  return app;
}
