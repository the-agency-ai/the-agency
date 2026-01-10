/**
 * Product Service
 *
 * PRD (Product Requirement Document) management service.
 */

import type { Hono } from 'hono';
import type { DatabaseAdapter } from '../../core/adapters/database';
import { ProductService } from './service/product.service';
import { createProductRoutes } from './routes/product.routes';

export { ProductService } from './service/product.service';
export { ProductRepository } from './repository/product.repository';
export * from './types';

/**
 * Create and initialize the product service
 */
export async function createProductService(
  db: DatabaseAdapter
): Promise<{ service: ProductService; routes: Hono }> {
  const service = new ProductService(db);
  await service.initialize();

  const routes = createProductRoutes(service);

  return { service, routes };
}
