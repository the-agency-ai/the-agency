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
 * - Per-service database isolation (each service gets its own .db file)
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { getConfig } from './core/config';
import { getLogger, createServiceLogger, enableLogServiceDualWrite } from './core/lib/logger';
import { createDatabaseRegistry } from './core/adapters/database';
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
import { createDispatchService } from './embedded/dispatch-service';

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

  // Per-service database isolation
  const registry = createDatabaseRegistry([
    'messages', 'dispatch', 'request', 'log', 'bug',
    'secret', 'test', 'idea', 'observation', 'product',
  ]);
  await registry.initializeAll();

  // Health check (no auth required)
  app.get('/health', async (c) => {
    const dbHealth = await registry.healthCheckAll();
    const allHealthy = Object.values(dbHealth).every(Boolean);

    return c.json({
      status: allHealthy ? 'healthy' : 'unhealthy',
      version: '0.1.0',
      timestamp: new Date().toISOString(),
      services: {
        databases: dbHealth,
      },
    });
  });

  // Initialize queue
  let queue;
  try {
    queue = await getQueue();
  } catch (error) {
    logger.warn({ error }, 'Queue not available, proceeding without it');
  }

  // Initialize embedded services (each gets its own database)
  const bugService = createBugService({ db: registry.adapters.get('bug')!, queue });
  await bugService.initialize();

  const messagesService = createMessagesService({ db: registry.adapters.get('messages')!, queue });
  await messagesService.initialize();

  const logServiceInstance = createLogService({
    db: registry.adapters.get('log')!,
    retentionDays: config.logRetentionDays,
  });
  await logServiceInstance.initialize();

  // Enable dual-write: Pino logs now also go to log-service database
  enableLogServiceDualWrite(logServiceInstance.service);

  const testServiceInstance = createTestService({ db: registry.adapters.get('test')!, projectRoot: config.projectRoot || process.cwd() });
  await testServiceInstance.initialize();

  const productServiceInstance = await createProductService(registry.adapters.get('product')!);

  const secretServiceInstance = createSecretService({ db: registry.adapters.get('secret')! });
  await secretServiceInstance.initialize();

  const ideaServiceInstance = createIdeaService({ db: registry.adapters.get('idea')! });
  await ideaServiceInstance.initialize();

  const requestServiceInstance = createRequestService({ db: registry.adapters.get('request')!, queue });
  await requestServiceInstance.initialize();

  const observationServiceInstance = createObservationService({ db: registry.adapters.get('observation')! });
  await observationServiceInstance.initialize();

  const dispatchServiceInstance = createDispatchService({ db: registry.adapters.get('dispatch')!, queue });
  await dispatchServiceInstance.initialize();

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
  app.route('/api/dispatch', dispatchServiceInstance.routes);

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
        'dispatch-service': '/api/dispatch',
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
    await registry.closeAll();
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
  console.log(`   Dispatch: http://${config.host}:${config.port}/api/dispatch`);

  return server;
}

// Run if executed directly
main().catch((error) => {
  console.error('Failed to start Agency Service:', error);
  process.exit(1);
});
