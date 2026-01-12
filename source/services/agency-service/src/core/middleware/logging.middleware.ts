/**
 * Request Logging Middleware
 *
 * Structured logging for all HTTP requests.
 * Logs request details, response status, and timing.
 */

import type { Context, Next } from 'hono';
import { createServiceLogger } from '../lib/logger';

const logger = createServiceLogger('http');

export function loggingMiddleware() {
  return async (c: Context, next: Next) => {
    const start = Date.now();
    const requestId = c.req.header('X-Request-ID') || crypto.randomUUID();

    // Log request
    logger.info({
      requestId,
      method: c.req.method,
      path: c.req.path,
      query: c.req.query(),
      userAgent: c.req.header('User-Agent'),
    }, 'Request received');

    // Add request ID to response headers
    c.header('X-Request-ID', requestId);

    try {
      await next();

      // Log response
      const duration = Date.now() - start;
      logger.info({
        requestId,
        method: c.req.method,
        path: c.req.path,
        status: c.res.status,
        duration,
      }, 'Request completed');
    } catch (error) {
      // Log error
      const duration = Date.now() - start;
      logger.error({
        requestId,
        method: c.req.method,
        path: c.req.path,
        duration,
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined,
      }, 'Request failed');

      throw error;
    }
  };
}

export default loggingMiddleware;
