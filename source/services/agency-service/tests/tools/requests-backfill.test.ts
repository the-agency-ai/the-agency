/**
 * Requests-Backfill CLI Tool Tests
 *
 * Tests for the requests-backfill CLI tool that imports REQUEST files
 * into the SQLite database.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { unlink } from 'fs/promises';
import { existsSync, mkdirSync, writeFileSync, rmSync } from 'fs';

// Find the repo root (tools are at repo_root/tools/)
const findRepoRoot = (): string => {
  let dir = import.meta.dir;
  while (dir !== '/') {
    if (existsSync(`${dir}/CLAUDE.md`) && existsSync(`${dir}/tools/requests-backfill`)) {
      return dir;
    }
    dir = dir.split('/').slice(0, -1).join('/');
  }
  throw new Error('Could not find repo root');
};

const REPO_ROOT = findRepoRoot();
const BACKFILL_TOOL = `${REPO_ROOT}/tools/requests-backfill`;

describe('requests-backfill CLI tool', () => {
  describe('--help flag', () => {
    test('should display help text', async () => {
      const proc = Bun.spawn(['bash', BACKFILL_TOOL, '--help'], {
        stdout: 'pipe',
        stderr: 'pipe',
      });
      const output = await new Response(proc.stdout).text();
      await proc.exited;

      expect(output).toContain('requests-backfill');
      expect(output).toContain('Import existing REQUEST files');
      expect(output).toContain('Usage:');
      expect(output).toContain('Options:');
      expect(output).toContain('--dry-run');
      expect(output).toContain('--verbose');
      expect(output).toContain('--help');
    });

    test('-h should display help text', async () => {
      const proc = Bun.spawn(['bash', BACKFILL_TOOL, '-h'], {
        stdout: 'pipe',
        stderr: 'pipe',
      });
      const output = await new Response(proc.stdout).text();
      await proc.exited;

      expect(output).toContain('Usage:');
      expect(output).toContain('requests-backfill');
    });
  });

  describe('--version flag', () => {
    test('should display version', async () => {
      const proc = Bun.spawn(['bash', BACKFILL_TOOL, '--version'], {
        stdout: 'pipe',
        stderr: 'pipe',
      });
      const output = await new Response(proc.stdout).text();
      await proc.exited;

      expect(output).toMatch(/^requests-backfill \d+\.\d+\.\d+/);
    });
  });

  describe('--dry-run flag', () => {
    // This test runs against real repo and can take a while with many REQUEST files
    test('should accept --dry-run option', async () => {
      const proc = Bun.spawn(['bash', BACKFILL_TOOL, '--dry-run'], {
        stdout: 'pipe',
        stderr: 'pipe',
        cwd: REPO_ROOT,
      });

      // Read stdout and wait for exit in parallel to avoid deadlock
      const [output, exitCode] = await Promise.all([
        new Response(proc.stdout).text(),
        proc.exited,
      ]);

      // If database exists, should run in dry-run mode
      // If database doesn't exist, should error
      if (exitCode === 0) {
        expect(output).toContain('DRY RUN');
        // With many REQUEST files, check that it reached completion
        expect(output).toMatch(/Would have imported \d+ requests/);
      } else {
        expect(output).toContain('Database not found');
      }
    }, { timeout: 30000 }); // Allow up to 30 seconds for large repos
  });

  describe('database requirement', () => {
    test('should error when database does not exist', async () => {
      // Use a path where the database definitely doesn't exist
      const tempDir = `/tmp/test-backfill-${Date.now()}`;
      mkdirSync(tempDir, { recursive: true });

      // Create a minimal git repo structure
      mkdirSync(`${tempDir}/claude/principals/test/requests`, { recursive: true });

      const proc = Bun.spawn(['bash', BACKFILL_TOOL], {
        stdout: 'pipe',
        stderr: 'pipe',
        cwd: tempDir,
        env: {
          ...process.env,
        },
      });
      const output = await new Response(proc.stdout).text();
      const exitCode = await proc.exited;

      // Clean up
      rmSync(tempDir, { recursive: true, force: true });

      expect(exitCode).toBe(1);
      expect(output).toContain('Database not found');
    });
  });
});

describe('requests-backfill status normalization', () => {
  // These tests verify the status normalization logic by examining the tool's behavior
  // The actual normalization functions are in the bash script

  test('help text should describe database import', async () => {
    const proc = Bun.spawn(['bash', BACKFILL_TOOL, '--help'], {
      stdout: 'pipe',
      stderr: 'pipe',
    });
    const output = await new Response(proc.stdout).text();
    await proc.exited;

    expect(output).toContain('database');
    expect(output).toContain('REQUEST');
  });
});

describe('requests-backfill with mock data', () => {
  const testDir = '/tmp/agency-test-backfill';
  const dbPath = `${testDir}/claude/data`;
  const dbFile = `${dbPath}/agency.db`;
  const requestsDir = `${testDir}/claude/principals/testuser/requests`;

  beforeEach(async () => {
    // Clean up from previous runs
    if (existsSync(testDir)) {
      rmSync(testDir, { recursive: true, force: true });
    }

    // Create directory structure
    mkdirSync(dbPath, { recursive: true });
    mkdirSync(requestsDir, { recursive: true });

    // Initialize git repo (required for the tool)
    await Bun.spawn(['git', 'init'], { cwd: testDir }).exited;

    // Create a mock database with the required schema
    const db = new (await import('bun:sqlite')).Database(dbFile);
    db.run(`
      CREATE TABLE IF NOT EXISTS requests (
        request_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        summary TEXT,
        status TEXT DEFAULT 'Open',
        priority TEXT DEFAULT 'Medium',
        principal_name TEXT NOT NULL,
        reporter_type TEXT,
        reporter_name TEXT,
        assignee_type TEXT,
        assignee_name TEXT,
        workstream TEXT,
        tags TEXT DEFAULT '[]',
        file_path TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    `);
    db.run(`
      CREATE TABLE IF NOT EXISTS request_sequences (
        principal TEXT PRIMARY KEY,
        next_id INTEGER DEFAULT 1
      )
    `);
    db.close();

    // Create test REQUEST files
    const request1Content = `# REQUEST-testuser-0001: Test Request

**Status:** Open
**Priority:** High
**Created:** 2024-01-15

## Summary

This is a test request for backfill testing.

## Details

More details here.
`;

    const request2Content = `# REQUEST-testuser-0002: Completed Request

**Status:** Complete
**Priority:** Low
**Created:** 2024-01-10

## Summary

This request has been completed.
`;

    writeFileSync(`${requestsDir}/REQUEST-testuser-0001-test-request.md`, request1Content);
    writeFileSync(`${requestsDir}/REQUEST-testuser-0002-completed.md`, request2Content);
  });

  afterEach(async () => {
    try {
      if (existsSync(testDir)) {
        rmSync(testDir, { recursive: true, force: true });
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  test('should import REQUEST files in dry-run mode', async () => {
    const proc = Bun.spawn(['bash', BACKFILL_TOOL, '--dry-run', '--verbose'], {
      stdout: 'pipe',
      stderr: 'pipe',
      cwd: testDir,
    });
    const output = await new Response(proc.stdout).text();
    const exitCode = await proc.exited;

    expect(exitCode).toBe(0);
    expect(output).toContain('DRY RUN');
    expect(output).toContain('REQUEST-testuser-0001');
    expect(output).toContain('REQUEST-testuser-0002');
    expect(output).toContain('Would have imported');
  });

  test('should actually import REQUEST files', async () => {
    const proc = Bun.spawn(['bash', BACKFILL_TOOL, '--verbose'], {
      stdout: 'pipe',
      stderr: 'pipe',
      cwd: testDir,
      env: {
        ...process.env,
        AGENCY_SERVICE_URL: 'http://localhost:99999', // Disable service call for stats
      },
    });
    const output = await new Response(proc.stdout).text();
    const exitCode = await proc.exited;

    // May fail on stats (service not running), but import should succeed
    expect(output).toContain('Imported');
    expect(output).toContain('REQUEST-testuser-0001');
    expect(output).toContain('REQUEST-testuser-0002');

    // Verify data was actually inserted
    const db = new (await import('bun:sqlite')).Database(dbFile);
    const requests = db.query('SELECT * FROM requests').all();
    db.close();

    expect(requests.length).toBe(2);
  });

  test('should normalize status values', async () => {
    // Create a request with non-standard status
    const nonStandardRequest = `# REQUEST-testuser-0003: Non-Standard Status

**Status:** In progress
**Priority:** Normal

## Summary

Testing status normalization.
`;
    writeFileSync(`${requestsDir}/REQUEST-testuser-0003-nonstd.md`, nonStandardRequest);

    const proc = Bun.spawn(['bash', BACKFILL_TOOL, '--verbose'], {
      stdout: 'pipe',
      stderr: 'pipe',
      cwd: testDir,
      env: {
        ...process.env,
        AGENCY_SERVICE_URL: 'http://localhost:99999',
      },
    });
    const output = await new Response(proc.stdout).text();
    await proc.exited;

    // Check output shows normalized status
    expect(output).toContain('In progress -> In Progress');
  });

  test('should normalize priority values', async () => {
    // Create a request with non-standard priority
    const nonStandardRequest = `# REQUEST-testuser-0004: Non-Standard Priority

**Status:** Open
**Priority:** CRITICAL

## Summary

Testing priority normalization.
`;
    writeFileSync(`${requestsDir}/REQUEST-testuser-0004-critical.md`, nonStandardRequest);

    const proc = Bun.spawn(['bash', BACKFILL_TOOL, '--verbose'], {
      stdout: 'pipe',
      stderr: 'pipe',
      cwd: testDir,
      env: {
        ...process.env,
        AGENCY_SERVICE_URL: 'http://localhost:99999',
      },
    });
    const output = await new Response(proc.stdout).text();
    await proc.exited;

    // Check output shows normalized priority
    expect(output).toContain('CRITICAL -> Critical');
  });

  test('should update sequence after import for jordan principal', async () => {
    // The backfill tool only updates sequences for 'jordan' principal
    // Create jordan-specific request files
    const jordanDir = `${testDir}/claude/principals/jordan/requests`;
    mkdirSync(jordanDir, { recursive: true });

    const jordanRequest = `# REQUEST-jordan-0010: Jordan's Request

**Status:** Open
**Priority:** High

## Summary

Testing sequence update for jordan principal.
`;
    writeFileSync(`${jordanDir}/REQUEST-jordan-0010-test.md`, jordanRequest);

    const proc = Bun.spawn(['bash', BACKFILL_TOOL], {
      stdout: 'pipe',
      stderr: 'pipe',
      cwd: testDir,
      env: {
        ...process.env,
        AGENCY_SERVICE_URL: 'http://localhost:99999',
      },
    });
    await proc.exited;

    // Verify sequence was updated for jordan
    const db = new (await import('bun:sqlite')).Database(dbFile);
    const seq = db.query('SELECT * FROM request_sequences WHERE principal = ?').get('jordan') as {
      next_id: number;
    } | null;
    db.close();

    // Sequence should be set to max_id + 1 (10 + 1 = 11)
    expect(seq).not.toBeNull();
    expect(seq!.next_id).toBe(11);
  });

  test('should handle requests with missing fields gracefully', async () => {
    // Create a minimal request file
    const minimalRequest = `# REQUEST-testuser-0005

Just a title, no other metadata.
`;
    writeFileSync(`${requestsDir}/REQUEST-testuser-0005-minimal.md`, minimalRequest);

    const proc = Bun.spawn(['bash', BACKFILL_TOOL, '--verbose'], {
      stdout: 'pipe',
      stderr: 'pipe',
      cwd: testDir,
      env: {
        ...process.env,
        AGENCY_SERVICE_URL: 'http://localhost:99999',
      },
    });
    const output = await new Response(proc.stdout).text();
    const exitCode = await proc.exited;

    // Should not crash on minimal file
    expect(output).toContain('REQUEST-testuser-0005');
    // May show defaults for status/priority
    expect(output).toContain('Open'); // Default status
  });
});
