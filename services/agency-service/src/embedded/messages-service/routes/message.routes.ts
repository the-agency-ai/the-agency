/**
 * Message Routes
 *
 * HTTP API endpoints for messaging.
 */

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import type { MessageService } from '../service/message.service';
import { createMessageSchema, markReadSchema, listMessagesQuerySchema } from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('message-routes');

/**
 * Create message routes
 */
export function createMessageRoutes(messageService: MessageService): Hono {
  const app = new Hono();

  /**
   * GET /message - List messages with filters
   */
  app.get('/', zValidator('query', listMessagesQuerySchema), async (c) => {
    const query = c.req.valid('query');
    const result = await messageService.listMessages(query);
    return c.json(result);
  });

  /**
   * GET /message/inbox/:recipientType/:recipientName - Get inbox for an entity
   */
  app.get('/inbox/:recipientType/:recipientName', async (c) => {
    const recipientType = c.req.param('recipientType');
    const recipientName = c.req.param('recipientName');
    const unreadOnly = c.req.query('unreadOnly') === 'true';

    if (!['agent', 'principal'].includes(recipientType)) {
      return c.json({
        error: 'Bad Request',
        message: 'recipientType must be agent or principal',
      }, 400);
    }

    const messages = await messageService.getInbox(
      recipientType as 'agent' | 'principal',
      recipientName,
      unreadOnly
    );

    return c.json({ messages, count: messages.length });
  });

  /**
   * GET /message/stats/:recipientType/:recipientName - Get message stats for an entity
   */
  app.get('/stats/:recipientType/:recipientName', async (c) => {
    const recipientType = c.req.param('recipientType');
    const recipientName = c.req.param('recipientName');

    if (!['agent', 'principal'].includes(recipientType)) {
      return c.json({
        error: 'Bad Request',
        message: 'recipientType must be agent or principal',
      }, 400);
    }

    const stats = await messageService.getStats(
      recipientType as 'agent' | 'principal',
      recipientName
    );

    return c.json(stats);
  });

  /**
   * GET /message/:id - Get a specific message
   */
  app.get('/:id', async (c) => {
    const id = parseInt(c.req.param('id'), 10);
    if (isNaN(id)) {
      return c.json({ error: 'Bad Request', message: 'Invalid message ID' }, 400);
    }

    const message = await messageService.getMessage(id);
    if (!message) {
      return c.json({ error: 'Not Found', message: `Message ${id} not found` }, 404);
    }

    return c.json(message);
  });

  /**
   * POST /message - Send a new message
   */
  app.post('/', zValidator('json', createMessageSchema), async (c) => {
    const data = c.req.valid('json');
    const user = c.get('user');

    // Use authenticated user as sender if not specified
    const fromName = data.fromName || user?.name || 'unknown';
    const fromType = data.fromType || user?.type || 'system';

    try {
      const message = await messageService.sendMessage({
        ...data,
        fromName,
        fromType,
      });

      logger.info({
        messageId: message.id,
        from: `${fromType}:${fromName}`,
        to: data.toType === 'broadcast' ? 'broadcast' : `${data.toType}:${data.toName}`,
      }, 'Message sent via API');

      return c.json(message, 201);
    } catch (error) {
      if (error instanceof Error) {
        return c.json({ error: 'Bad Request', message: error.message }, 400);
      }
      throw error;
    }
  });

  /**
   * POST /message/:id/read - Mark a message as read
   */
  app.post('/:id/read', zValidator('json', markReadSchema), async (c) => {
    const id = parseInt(c.req.param('id'), 10);
    if (isNaN(id)) {
      return c.json({ error: 'Bad Request', message: 'Invalid message ID' }, 400);
    }

    const data = c.req.valid('json');
    const result = await messageService.markAsRead(
      id,
      data.recipientType,
      data.recipientName
    );

    if (result) {
      logger.info({
        messageId: id,
        reader: `${data.recipientType}:${data.recipientName}`,
      }, 'Message marked as read via API');
    }

    return c.json({ success: result, messageId: id });
  });

  /**
   * POST /message/read-all - Mark all messages as read for an entity
   */
  app.post('/read-all', zValidator('json', markReadSchema), async (c) => {
    const data = c.req.valid('json');
    const count = await messageService.markAllAsRead(
      data.recipientType,
      data.recipientName
    );

    logger.info({
      reader: `${data.recipientType}:${data.recipientName}`,
      count,
    }, 'All messages marked as read via API');

    return c.json({ success: true, count });
  });

  /**
   * DELETE /message/:id - Delete a message
   */
  app.delete('/:id', async (c) => {
    const id = parseInt(c.req.param('id'), 10);
    if (isNaN(id)) {
      return c.json({ error: 'Bad Request', message: 'Invalid message ID' }, 400);
    }

    const deleted = await messageService.deleteMessage(id);
    if (!deleted) {
      return c.json({ error: 'Not Found', message: `Message ${id} not found` }, 404);
    }

    logger.info({ messageId: id }, 'Message deleted via API');
    return c.json({ success: true, messageId: id });
  });

  return app;
}
