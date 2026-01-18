/**
 * The Agency Service
 *
 * Central API layer for The Agency.
 * CLI tools and AgencyBench call this instead of direct SQLite access.
 *
 * Design principles:
 * - Fast cold start (~5ms) for CLI auto-launch
 * - Interface/adapter pattern for vendor neutrality
 * - Embedded services that can be extracted later
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { getConfig } from './core/config';
import { getLogger, createServiceLogger } from './core/lib/logger';
import { getDatabase, closeDatabase } from './core/adapters/database';
import { getQueue, closeQueue } from './core/adapters/queue';
import { authMiddleware, loggingMiddleware } from './core/middleware';
import { createBugService } from './embedded/bug-service';
import { createMessagesService } from './embedded/messages-service';
import { createLogService } from './embedded/log-service';
import { createTestService } from './embedded/test-service';
import { createProductService } from './embedded/product-service';
import { createSecretService } from './embedded/secret-service';
import { createIdeaService } from './embedded/idea-service';
import { createRequestService } from './embedded/request-service';
import { createObservationService } from './embedded/observation-service';

const logger = createServiceLogger('agency-service');

async function main() {
  const config = getConfig();
  const app = new Hono();

  logger.info({ config: { port: config.port, host: config.host, authMode: config.authMode } }, 'Starting Agency Service');

  // Global middleware - CORS origins configurable via AGENCY_CORS_ORIGINS env var
  const defaultOrigins = ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://localhost:3010', 'http://127.0.0.1:3010', 'tauri://localhost'];
  const corsOrigins = process.env.AGENCY_CORS_ORIGINS?.split(',').map(s => s.trim()) || defaultOrigins;
  app.use('*', cors({
    origin: corsOrigins,
    credentials: true,
  }));
  app.use('*', loggingMiddleware());
  app.use('/api/*', authMiddleware());

  // Health check (no auth required)
  app.get('/health', async (c) => {
    const db = await getDatabase();
    const dbHealthy = await db.healthCheck();

    return c.json({
      status: dbHealthy ? 'healthy' : 'unhealthy',
      version: '0.1.0',
      timestamp: new Date().toISOString(),
      services: {
        database: dbHealthy,
      },
    });
  });

  // Initialize infrastructure
  const db = await getDatabase();
  let queue;
  try {
    queue = await getQueue();
  } catch (error) {
    logger.warn({ error }, 'Queue not available, proceeding without it');
  }

  // Initialize embedded services
  const bugService = createBugService({ db, queue });
  await bugService.initialize();

  const messagesService = createMessagesService({ db, queue });
  await messagesService.initialize();

  const logServiceInstance = createLogService({ db });
  await logServiceInstance.initialize();

  const testServiceInstance = createTestService({ db, projectRoot: config.projectRoot || process.cwd() });
  await testServiceInstance.initialize();

  const productServiceInstance = await createProductService(db);

  const secretServiceInstance = createSecretService({ db });
  await secretServiceInstance.initialize();

  const ideaServiceInstance = createIdeaService({ db });
  await ideaServiceInstance.initialize();

  const requestServiceInstance = createRequestService({ db, queue });
  await requestServiceInstance.initialize();

  const observationServiceInstance = createObservationService({ db });
  await observationServiceInstance.initialize();

  // Mount embedded service routes
  app.route('/api/bug', bugService.routes);
  app.route('/api/message', messagesService.routes);
  app.route('/api/log', logServiceInstance.routes);
  app.route('/api/test', testServiceInstance.routes);
  app.route('/api/products', productServiceInstance.routes);
  app.route('/api/secret', secretServiceInstance.routes);
  app.route('/api/idea', ideaServiceInstance.routes);
  app.route('/api/request', requestServiceInstance.routes);
  app.route('/api/observation', observationServiceInstance.routes);

  // API info endpoint
  app.get('/api', (c) => {
    return c.json({
      name: 'The Agency Service',
      version: '0.6.0',
      services: {
        'bug-service': '/api/bug',
        'messages-service': '/api/message',
        'log-service': '/api/log',
        'test-service': '/api/test',
        'product-service': '/api/products',
        'secret-service': '/api/secret',
        'idea-service': '/api/idea',
        'request-service': '/api/request',
        'observation-service': '/api/observation',
      },
    });
  });

  // 404 handler
  app.notFound((c) => {
    return c.json({ error: 'Not Found', message: 'Endpoint not found' }, 404);
  });

  // Error handler
  app.onError((err, c) => {
    logger.error({ error: err.message, stack: err.stack }, 'Unhandled error');
    return c.json({
      error: 'Internal Server Error',
      message: config.nodeEnv === 'development' ? err.message : 'An error occurred',
    }, 500);
  });

  // Graceful shutdown
  const shutdown = async () => {
    logger.info('Shutting down...');
    await closeQueue();
    await closeDatabase();
    process.exit(0);
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);

  // Start server
  const server = Bun.serve({
    port: config.port,
    hostname: config.host,
    fetch: app.fetch,
  });

  logger.info({ port: config.port, host: config.host }, 'Agency Service started');
  console.log(`🚀 Agency Service running at http://${config.host}:${config.port}`);
  console.log(`   Health:   http://${config.host}:${config.port}/health`);
  console.log(`   API:      http://${config.host}:${config.port}/api`);
  console.log(`   Bug:      http://${config.host}:${config.port}/api/bug`);
  console.log(`   Message:  http://${config.host}:${config.port}/api/message`);
  console.log(`   Log:      http://${config.host}:${config.port}/api/log`);
  console.log(`   Test:     http://${config.host}:${config.port}/api/test`);
  console.log(`   Products: http://${config.host}:${config.port}/api/products`);
  console.log(`   Secret:   http://${config.host}:${config.port}/api/secret`);
  console.log(`   Idea:     http://${config.host}:${config.port}/api/idea`);
  console.log(`   Request:  http://${config.host}:${config.port}/api/request`);
  console.log(`   Observation: http://${config.host}:${config.port}/api/observation`);

  return server;
}

// Run if executed directly
main().catch((error) => {
  console.error('Failed to start Agency Service:', error);
  process.exit(1);
});
