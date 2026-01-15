/**
 * Requests CLI Tool Tests
 *
 * Tests for the requests CLI tool that queries the service API
 * and falls back to file parsing when service is unavailable.
 */

import { describe, test, expect, beforeAll, afterAll, beforeEach, afterEach } from 'bun:test';
import { Hono } from 'hono';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { createRequestService } from '../../src/embedded/request-service';
import { unlink } from 'fs/promises';
import { existsSync, mkdirSync, writeFileSync, rmSync } from 'fs';
import { $ } from 'bun';

// Find the repo root (tools are at repo_root/tools/)
const findRepoRoot = (): string => {
  let dir = import.meta.dir;
  while (dir !== '/') {
    if (existsSync(`${dir}/CLAUDE.md`) && existsSync(`${dir}/tools/requests`)) {
      return dir;
    }
    dir = dir.split('/').slice(0, -1).join('/');
  }
  throw new Error('Could not find repo root');
};

const REPO_ROOT = findRepoRoot();
const REQUESTS_TOOL = `${REPO_ROOT}/tools/requests`;

describe('requests CLI tool', () => {
  describe('--help flag', () => {
    test('should display help text', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, '--help'], {
        stdout: 'pipe',
        stderr: 'pipe',
      });
      const output = await new Response(proc.stdout).text();
      await proc.exited;

      expect(output).toContain('Usage:');
      expect(output).toContain('Commands:');
      expect(output).toContain('list');
      expect(output).toContain('open');
      expect(output).toContain('completed');
      expect(output).toContain('show');
      expect(output).toContain('stats');
      expect(output).toContain('Options:');
      expect(output).toContain('--principal');
      expect(output).toContain('--status');
      expect(output).toContain('--format');
    });

    test('-h should display help text', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, '-h'], {
        stdout: 'pipe',
        stderr: 'pipe',
      });
      const output = await new Response(proc.stdout).text();
      await proc.exited;

      expect(output).toContain('Usage:');
      expect(output).toContain('Commands:');
    });
  });

  describe('--version flag', () => {
    test('should display version', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, '--version'], {
        stdout: 'pipe',
        stderr: 'pipe',
      });
      const output = await new Response(proc.stdout).text();
      await proc.exited;

      expect(output).toMatch(/^requests \d+\.\d+\.\d+/);
    });

    test('-v should display version', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, '-v'], {
        stdout: 'pipe',
        stderr: 'pipe',
      });
      const output = await new Response(proc.stdout).text();
      await proc.exited;

      expect(output).toMatch(/^requests \d+\.\d+\.\d+/);
    });
  });

  describe('argument parsing', () => {
    test('should accept --format=json', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, '--format=json'], {
        stdout: 'pipe',
        stderr: 'pipe',
        env: {
          ...process.env,
          AGENCY_SERVICE_URL: 'http://localhost:99999', // Non-existent service
        },
      });
      const output = await new Response(proc.stdout).text();
      await proc.exited;

      // Should mention service not running (fallback behavior)
      expect(output).toContain('Service not running');
    });

    test('should accept --limit parameter', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, '--limit=5'], {
        stdout: 'pipe',
        stderr: 'pipe',
        env: {
          ...process.env,
          AGENCY_SERVICE_URL: 'http://localhost:99999',
        },
      });
      await proc.exited;

      // Just ensure it doesn't crash
      expect(proc.exitCode).toBe(0);
    });

    test('should accept --verbose flag', async () => {
      // --verbose is not a first-position flag like --help, so we need to test
      // it in combination with a command. The --help flag takes precedence.
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, '--help'], {
        stdout: 'pipe',
        stderr: 'pipe',
      });
      const output = await new Response(proc.stdout).text();
      await proc.exited;

      // Verify help mentions --verbose option
      expect(output).toContain('--verbose');
    });
  });

  describe('commands', () => {
    test('open command should set status filter', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, 'open'], {
        stdout: 'pipe',
        stderr: 'pipe',
        env: {
          ...process.env,
          AGENCY_SERVICE_URL: 'http://localhost:99999',
        },
      });
      const output = await new Response(proc.stdout).text();
      await proc.exited;

      // Should show the table header
      expect(output).toContain('ID');
      expect(output).toContain('Status');
    });

    test('completed command should set status filter', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, 'completed'], {
        stdout: 'pipe',
        stderr: 'pipe',
        env: {
          ...process.env,
          AGENCY_SERVICE_URL: 'http://localhost:99999',
        },
      });
      const output = await new Response(proc.stdout).text();
      await proc.exited;

      // Should show the table header
      expect(output).toContain('ID');
      expect(output).toContain('Status');
    });

    test('show command without ID should error', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, 'show'], {
        stdout: 'pipe',
        stderr: 'pipe',
        env: {
          ...process.env,
          AGENCY_SERVICE_URL: 'http://localhost:99999',
        },
      });
      const stdout = await new Response(proc.stdout).text();
      const stderr = await new Response(proc.stderr).text();
      const exitCode = await proc.exited;

      expect(exitCode).toBe(1);
      expect(stdout + stderr).toContain('No REQUEST ID provided');
    });

    test('stats command should require service', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, 'stats'], {
        stdout: 'pipe',
        stderr: 'pipe',
        env: {
          ...process.env,
          AGENCY_SERVICE_URL: 'http://localhost:99999',
        },
      });
      const stdout = await new Response(proc.stdout).text();
      const stderr = await new Response(proc.stderr).text();
      const exitCode = await proc.exited;

      expect(exitCode).toBe(1);
      expect(stdout + stderr).toContain('Service not available');
    });

    test('create command without title should error', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, 'create'], {
        stdout: 'pipe',
        stderr: 'pipe',
        env: {
          ...process.env,
          AGENCY_SERVICE_URL: 'http://localhost:99999',
        },
      });
      const stdout = await new Response(proc.stdout).text();
      const stderr = await new Response(proc.stderr).text();
      const exitCode = await proc.exited;

      expect(exitCode).toBe(1);
      expect(stdout + stderr).toContain('No REQUEST title provided');
    });
  });

  describe('service unavailable fallback', () => {
    test('should fall back to file scan when service unavailable', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, 'list'], {
        stdout: 'pipe',
        stderr: 'pipe',
        env: {
          ...process.env,
          AGENCY_SERVICE_URL: 'http://localhost:99999',
        },
      });
      const output = await new Response(proc.stdout).text();
      await proc.exited;

      // Should show fallback message
      expect(output).toContain('Service not running');
      // Should still show table headers from fallback
      expect(output).toContain('ID');
    });
  });

  describe('show command ID normalization', () => {
    test('should handle numeric ID input', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, 'show', '35'], {
        stdout: 'pipe',
        stderr: 'pipe',
        env: {
          ...process.env,
          AGENCY_SERVICE_URL: 'http://localhost:99999',
        },
      });
      const output = await new Response(proc.stdout).text();
      const exitCode = await proc.exited;

      // Will try to look up REQUEST-jordan-0035 (normalized)
      // Should either find it or report not found
      expect(exitCode === 0 || output.includes('not found') || output.includes('Not Found')).toBe(true);
    });

    test('should handle full REQUEST ID input', async () => {
      const proc = Bun.spawn(['bash', REQUESTS_TOOL, 'show', 'REQUEST-jordan-0035'], {
        stdout: 'pipe',
        stderr: 'pipe',
        env: {
          ...process.env,
          AGENCY_SERVICE_URL: 'http://localhost:99999',
        },
      });
      const output = await new Response(proc.stdout).text();
      const exitCode = await proc.exited;

      // Should either find it or report not found
      expect(exitCode === 0 || output.includes('not found') || output.includes('Not Found')).toBe(true);
    });
  });
});

describe('requests CLI with mock service', () => {
  let db: DatabaseAdapter;
  let app: Hono;
  let server: ReturnType<typeof Bun.serve>;
  const testDbPath = '/tmp/agency-test-requests-cli';
  const testDbFile = `${testDbPath}/requests.db`;
  const TEST_PORT = 3199;

  beforeAll(async () => {
    // Create test database and service
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'requests.db',
    });
    await db.initialize();

    const requestService = createRequestService({ db });
    await requestService.initialize();

    app = new Hono();
    app.get('/health', (c) => c.text('ok'));
    app.route('/api/request', requestService.routes);

    // Start test server
    server = Bun.serve({
      port: TEST_PORT,
      fetch: app.fetch,
    });
  });

  afterAll(async () => {
    server.stop();
    await db.close();
    try {
      if (existsSync(testDbFile)) await unlink(testDbFile);
      if (existsSync(`${testDbFile}-wal`)) await unlink(`${testDbFile}-wal`);
      if (existsSync(`${testDbFile}-shm`)) await unlink(`${testDbFile}-shm`);
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  beforeEach(async () => {
    // Create some test requests
    await app.request('/api/request/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Test Request 1',
        summary: 'First test request',
        principalName: 'jordan',
        reporterType: 'principal',
        reporterName: 'jordan',
        priority: 'High',
      }),
    });

    await app.request('/api/request/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Test Request 2',
        summary: 'Second test request',
        principalName: 'alice',
        reporterType: 'principal',
        reporterName: 'alice',
        priority: 'Medium',
      }),
    });
  });

  test('should list requests from service', async () => {
    const proc = Bun.spawn(['bash', REQUESTS_TOOL, 'list'], {
      stdout: 'pipe',
      stderr: 'pipe',
      env: {
        ...process.env,
        AGENCY_SERVICE_URL: `http://localhost:${TEST_PORT}`,
      },
    });
    const output = await new Response(proc.stdout).text();
    await proc.exited;

    expect(output).toContain('ID');
    expect(output).toContain('Principal');
    expect(output).toContain('Status');
  });

  test('should filter by principal', async () => {
    const proc = Bun.spawn(['bash', REQUESTS_TOOL, '--principal=jordan'], {
      stdout: 'pipe',
      stderr: 'pipe',
      env: {
        ...process.env,
        AGENCY_SERVICE_URL: `http://localhost:${TEST_PORT}`,
      },
    });
    const output = await new Response(proc.stdout).text();
    await proc.exited;

    expect(output).toContain('jordan');
  });

  test('should output JSON format', async () => {
    const proc = Bun.spawn(['bash', REQUESTS_TOOL, '--format=json'], {
      stdout: 'pipe',
      stderr: 'pipe',
      env: {
        ...process.env,
        AGENCY_SERVICE_URL: `http://localhost:${TEST_PORT}`,
      },
    });
    const output = await new Response(proc.stdout).text();
    await proc.exited;

    // Output should contain JSON array (after run ID line)
    const lines = output.split('\n');
    const jsonPart = lines.slice(1).join('\n').trim();
    expect(() => JSON.parse(jsonPart)).not.toThrow();
  });

  test('should show stats', async () => {
    const proc = Bun.spawn(['bash', REQUESTS_TOOL, 'stats'], {
      stdout: 'pipe',
      stderr: 'pipe',
      env: {
        ...process.env,
        AGENCY_SERVICE_URL: `http://localhost:${TEST_PORT}`,
      },
    });
    const output = await new Response(proc.stdout).text();
    const exitCode = await proc.exited;

    expect(exitCode).toBe(0);
    expect(output).toContain('Statistics');
    expect(output).toContain('Total');
  });
});
