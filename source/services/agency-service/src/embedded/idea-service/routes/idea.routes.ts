/**
 * Idea Routes
 *
 * HTTP API endpoints for idea management.
 * Uses explicit operation names (not HTTP verb semantics).
 */

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import type { IdeaService } from '../service/idea.service';
import { createIdeaSchema, updateIdeaSchema, promoteIdeaSchema, listIdeasQuerySchema } from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('idea-routes');

// Schema for adding/removing tags
const modifyTagsSchema = z.object({
  tags: z.array(z.string()).min(1, 'At least one tag is required'),
});

// Schema for ideaId path parameter
const ideaIdParamSchema = z.object({
  ideaId: z.string().regex(/^IDEA-\d{5}$/, 'Invalid idea ID format (expected IDEA-XXXXX)'),
});

/**
 * Helper to validate ideaId parameter
 */
function validateIdeaId(ideaId: string): boolean {
  return /^IDEA-\d{5}$/.test(ideaId);
}

/**
 * Create idea routes with explicit operation names
 */
export function createIdeaRoutes(ideaService: IdeaService): Hono {
  const app = new Hono();

  // Global error handler
  app.onError((err, c) => {
    logger.error({ error: err.message, stack: err.stack }, 'Idea route error');
    return c.json(
      { error: 'Internal Server Error', message: 'An unexpected error occurred' },
      500
    );
  });

  /**
   * POST /idea/create - Capture a new idea
   */
  app.post('/create', zValidator('json', createIdeaSchema), async (c) => {
    const data = c.req.valid('json');
    const user = c.get('user');

    // Use authenticated user as source if not specified
    const sourceName = data.sourceName || user?.name || 'unknown';
    const sourceType = data.sourceType || user?.type || 'system';

    const idea = await ideaService.createIdea({
      ...data,
      sourceName,
      sourceType,
    });

    logger.info({ ideaId: idea.ideaId, source: sourceName }, 'Idea captured via API');
    return c.json(idea, 201);
  });

  /**
   * GET /idea/list - List ideas with filters
   */
  app.get('/list', zValidator('query', listIdeasQuerySchema), async (c) => {
    const query = c.req.valid('query');
    const result = await ideaService.listIdeas(query);
    return c.json(result);
  });

  /**
   * GET /idea/get/:ideaId - Get a specific idea
   */
  app.get('/get/:ideaId', async (c) => {
    const ideaId = c.req.param('ideaId');
    if (!validateIdeaId(ideaId)) {
      return c.json({ error: 'Bad Request', message: 'Invalid idea ID format (expected IDEA-XXXXX)' }, 400);
    }

    const idea = await ideaService.getIdea(ideaId);

    if (!idea) {
      return c.json({ error: 'Not Found', message: `Idea ${ideaId} not found` }, 404);
    }

    return c.json(idea);
  });

  /**
   * POST /idea/update/:ideaId - Update an idea
   */
  app.post('/update/:ideaId', zValidator('json', updateIdeaSchema), async (c) => {
    const ideaId = c.req.param('ideaId');
    if (!validateIdeaId(ideaId)) {
      return c.json({ error: 'Bad Request', message: 'Invalid idea ID format (expected IDEA-XXXXX)' }, 400);
    }
    const data = c.req.valid('json');

    const idea = await ideaService.updateIdea(ideaId, data);

    if (!idea) {
      return c.json({ error: 'Not Found', message: `Idea ${ideaId} not found` }, 404);
    }

    logger.info({ ideaId, updates: Object.keys(data) }, 'Idea updated via API');
    return c.json(idea);
  });

  /**
   * POST /idea/promote/:ideaId - Promote idea to a REQUEST
   */
  app.post('/promote/:ideaId', zValidator('json', promoteIdeaSchema), async (c) => {
    const ideaId = c.req.param('ideaId');
    if (!validateIdeaId(ideaId)) {
      return c.json({ error: 'Bad Request', message: 'Invalid idea ID format (expected IDEA-XXXXX)' }, 400);
    }
    const { requestId } = c.req.valid('json');

    const idea = await ideaService.promoteIdea(ideaId, requestId);

    if (!idea) {
      return c.json({ error: 'Not Found', message: `Idea ${ideaId} not found or cannot be promoted` }, 404);
    }

    logger.info({ ideaId, requestId }, 'Idea promoted via API');
    return c.json(idea);
  });

  /**
   * POST /idea/explore/:ideaId - Start exploring an idea
   */
  app.post('/explore/:ideaId', async (c) => {
    const ideaId = c.req.param('ideaId');
    if (!validateIdeaId(ideaId)) {
      return c.json({ error: 'Bad Request', message: 'Invalid idea ID format (expected IDEA-XXXXX)' }, 400);
    }

    const idea = await ideaService.exploreIdea(ideaId);

    if (!idea) {
      return c.json({ error: 'Not Found', message: `Idea ${ideaId} not found` }, 404);
    }

    logger.info({ ideaId }, 'Idea exploration started via API');
    return c.json(idea);
  });

  /**
   * POST /idea/park/:ideaId - Park an idea for later
   */
  app.post('/park/:ideaId', async (c) => {
    const ideaId = c.req.param('ideaId');
    if (!validateIdeaId(ideaId)) {
      return c.json({ error: 'Bad Request', message: 'Invalid idea ID format (expected IDEA-XXXXX)' }, 400);
    }

    const idea = await ideaService.parkIdea(ideaId);

    if (!idea) {
      return c.json({ error: 'Not Found', message: `Idea ${ideaId} not found` }, 404);
    }

    logger.info({ ideaId }, 'Idea parked via API');
    return c.json(idea);
  });

  /**
   * POST /idea/discard/:ideaId - Discard an idea
   */
  app.post('/discard/:ideaId', async (c) => {
    const ideaId = c.req.param('ideaId');
    if (!validateIdeaId(ideaId)) {
      return c.json({ error: 'Bad Request', message: 'Invalid idea ID format (expected IDEA-XXXXX)' }, 400);
    }

    const idea = await ideaService.discardIdea(ideaId);

    if (!idea) {
      return c.json({ error: 'Not Found', message: `Idea ${ideaId} not found` }, 404);
    }

    logger.info({ ideaId }, 'Idea discarded via API');
    return c.json(idea);
  });

  /**
   * POST /idea/add-tags/:ideaId - Add tags to an idea
   */
  app.post('/add-tags/:ideaId', zValidator('json', modifyTagsSchema), async (c) => {
    const ideaId = c.req.param('ideaId');
    if (!validateIdeaId(ideaId)) {
      return c.json({ error: 'Bad Request', message: 'Invalid idea ID format (expected IDEA-XXXXX)' }, 400);
    }
    const { tags } = c.req.valid('json');

    const idea = await ideaService.addTags(ideaId, tags);

    if (!idea) {
      return c.json({ error: 'Not Found', message: `Idea ${ideaId} not found` }, 404);
    }

    logger.info({ ideaId, tagsAdded: tags }, 'Tags added via API');
    return c.json(idea);
  });

  /**
   * POST /idea/remove-tags/:ideaId - Remove tags from an idea
   */
  app.post('/remove-tags/:ideaId', zValidator('json', modifyTagsSchema), async (c) => {
    const ideaId = c.req.param('ideaId');
    if (!validateIdeaId(ideaId)) {
      return c.json({ error: 'Bad Request', message: 'Invalid idea ID format (expected IDEA-XXXXX)' }, 400);
    }
    const { tags } = c.req.valid('json');

    const idea = await ideaService.removeTags(ideaId, tags);

    if (!idea) {
      return c.json({ error: 'Not Found', message: `Idea ${ideaId} not found` }, 404);
    }

    logger.info({ ideaId, tagsRemoved: tags }, 'Tags removed via API');
    return c.json(idea);
  });

  /**
   * POST /idea/delete/:ideaId - Delete an idea
   */
  app.post('/delete/:ideaId', async (c) => {
    const ideaId = c.req.param('ideaId');
    if (!validateIdeaId(ideaId)) {
      return c.json({ error: 'Bad Request', message: 'Invalid idea ID format (expected IDEA-XXXXX)' }, 400);
    }
    const deleted = await ideaService.deleteIdea(ideaId);

    if (!deleted) {
      return c.json({ error: 'Not Found', message: `Idea ${ideaId} not found` }, 404);
    }

    logger.info({ ideaId }, 'Idea deleted via API');
    return c.json({ success: true, ideaId });
  });

  /**
   * GET /idea/stats - Get idea statistics
   */
  app.get('/stats', async (c) => {
    const stats = await ideaService.getStats();
    return c.json(stats);
  });

  return app;
}
