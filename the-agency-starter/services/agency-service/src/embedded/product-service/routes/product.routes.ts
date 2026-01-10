/**
 * Product Routes
 *
 * HTTP API endpoints for PRD management.
 * Uses explicit operation names instead of HTTP verb semantics.
 */

import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import type { ProductService } from '../service/product.service';
import {
  createProductSchema,
  updateProductSchema,
  listProductsQuerySchema,
  addContributorSchema,
  removeContributorSchema,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('product-routes');

/**
 * Create product routes with explicit operation names
 */
export function createProductRoutes(productService: ProductService): Hono {
  const app = new Hono();

  // Global error handler
  app.onError((err, c) => {
    logger.error({ error: err.message, stack: err.stack }, 'Product route error');
    return c.json(
      { error: 'Internal Server Error', message: 'An unexpected error occurred' },
      500
    );
  });

  /**
   * POST /products/create - Create a new product/PRD
   */
  app.post('/create', zValidator('json', createProductSchema), async (c) => {
    try {
      const data = c.req.valid('json');
      const user = c.get('user');

      // Use authenticated user as owner if not specified
      const ownerName = data.ownerName || user?.name || 'unknown';
      const ownerType = data.ownerType || user?.type || 'principal';

      const product = await productService.create({
        ...data,
        ownerName,
        ownerType,
      });

      logger.info({ prdId: product.prdId, owner: ownerName }, 'Product created via API');
      return c.json(product, 201);
    } catch (error) {
      logger.error({ error }, 'Failed to create product');
      throw error;
    }
  });

  /**
   * GET /products/list - List products with filters
   */
  app.get('/list', zValidator('query', listProductsQuerySchema), async (c) => {
    try {
      const query = c.req.valid('query');
      const result = await productService.list(query);
      return c.json(result);
    } catch (error) {
      logger.error({ error }, 'Failed to list products');
      throw error;
    }
  });

  /**
   * GET /products/get/:id - Get a specific product
   */
  app.get('/get/:id', async (c) => {
    try {
      const id = c.req.param('id');
      const product = await productService.get(id);

      if (!product) {
        return c.json({ error: 'Not Found', message: `Product ${id} not found` }, 404);
      }

      return c.json(product);
    } catch (error) {
      logger.error({ error }, 'Failed to get product');
      throw error;
    }
  });

  /**
   * POST /products/update/:id - Update a product
   */
  app.post('/update/:id', zValidator('json', updateProductSchema), async (c) => {
    try {
      const id = c.req.param('id');
      const data = c.req.valid('json');

      const product = await productService.update(id, data);

      if (!product) {
        return c.json({ error: 'Not Found', message: `Product ${id} not found` }, 404);
      }

      logger.info({ prdId: product.prdId, updates: Object.keys(data) }, 'Product updated via API');
      return c.json(product);
    } catch (error) {
      logger.error({ error }, 'Failed to update product');
      throw error;
    }
  });

  /**
   * POST /products/add-contributor/:id - Add a contributor
   */
  app.post('/add-contributor/:id', zValidator('json', addContributorSchema), async (c) => {
    try {
      const id = c.req.param('id');
      const data = c.req.valid('json');

      const contributor = await productService.addContributor(id, data);

      if (!contributor) {
        return c.json(
          { error: 'Bad Request', message: 'Product not found or contributor already exists' },
          400
        );
      }

      logger.info({ productId: id, contributor: data.contributorName }, 'Contributor added via API');
      return c.json(contributor, 201);
    } catch (error) {
      logger.error({ error }, 'Failed to add contributor');
      throw error;
    }
  });

  /**
   * POST /products/remove-contributor/:id - Remove a contributor
   */
  app.post('/remove-contributor/:id', zValidator('json', removeContributorSchema), async (c) => {
    try {
      const id = c.req.param('id');
      const { contributorName } = c.req.valid('json');

      const removed = await productService.removeContributor(id, contributorName);

      if (!removed) {
        return c.json(
          { error: 'Bad Request', message: 'Product not found, contributor not found, or cannot remove owner' },
          400
        );
      }

      logger.info({ productId: id, contributor: contributorName }, 'Contributor removed via API');
      return c.json({ success: true });
    } catch (error) {
      logger.error({ error }, 'Failed to remove contributor');
      throw error;
    }
  });

  /**
   * POST /products/approve/:id - Approve a product
   */
  app.post('/approve/:id', async (c) => {
    try {
      const id = c.req.param('id');
      const user = c.get('user');
      const approvedBy = user?.name || 'unknown';

      const product = await productService.approve(id, approvedBy);

      if (!product) {
        return c.json({ error: 'Not Found', message: `Product ${id} not found` }, 404);
      }

      logger.info({ prdId: product.prdId, approvedBy }, 'Product approved via API');
      return c.json(product);
    } catch (error) {
      logger.error({ error }, 'Failed to approve product');
      throw error;
    }
  });

  /**
   * POST /products/archive/:id - Archive a product
   */
  app.post('/archive/:id', async (c) => {
    try {
      const id = c.req.param('id');

      const product = await productService.archive(id);

      if (!product) {
        return c.json({ error: 'Not Found', message: `Product ${id} not found` }, 404);
      }

      logger.info({ prdId: product.prdId }, 'Product archived via API');
      return c.json(product);
    } catch (error) {
      logger.error({ error }, 'Failed to archive product');
      throw error;
    }
  });

  /**
   * POST /products/delete/:id - Delete a product
   */
  app.post('/delete/:id', async (c) => {
    try {
      const id = c.req.param('id');

      const deleted = await productService.delete(id);

      if (!deleted) {
        return c.json({ error: 'Not Found', message: `Product ${id} not found` }, 404);
      }

      logger.info({ productId: id }, 'Product deleted via API');
      return c.json({ success: true });
    } catch (error) {
      logger.error({ error }, 'Failed to delete product');
      throw error;
    }
  });

  /**
   * GET /products/stats - Get product statistics
   */
  app.get('/stats', async (c) => {
    try {
      const stats = await productService.getStats();
      return c.json(stats);
    } catch (error) {
      logger.error({ error }, 'Failed to get stats');
      throw error;
    }
  });

  return app;
}
