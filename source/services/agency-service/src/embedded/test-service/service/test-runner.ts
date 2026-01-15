/**
 * Test Runner
 *
 * Executes bun tests and parses results.
 */

import { spawn } from 'child_process';
import { resolve, relative } from 'path';
import { createServiceLogger } from '../../../core/lib/logger';
import type { BunTestOutput, BunTestResult } from '../types';

const logger = createServiceLogger('test-runner');

/**
 * Validate suite name to prevent path traversal
 * Only allows alphanumeric characters, hyphens, and underscores
 */
function validateSuiteName(suite: string): boolean {
  // Suite must be alphanumeric with hyphens/underscores only
  const safePattern = /^[a-zA-Z0-9_-]+$/;
  return safePattern.test(suite) && !suite.includes('..');
}

/**
 * Validate test file path to prevent path traversal
 * Ensures the resolved path is within the project root
 */
function validateTestFilePath(testFile: string, projectRoot: string): string | null {
  // Resolve the path relative to project root
  const resolvedPath = resolve(projectRoot, testFile);
  const relativePath = relative(projectRoot, resolvedPath);

  // Check if path escapes project root (would start with '..' or be absolute)
  if (relativePath.startsWith('..') || resolve(relativePath) === relativePath) {
    logger.warn({ testFile, resolvedPath }, 'Path traversal attempt detected');
    return null;
  }

  // Ensure it's a test file
  if (!relativePath.endsWith('.test.ts') && !relativePath.endsWith('.spec.ts')) {
    logger.warn({ testFile }, 'Not a valid test file extension');
    return null;
  }

  return relativePath;
}

export interface TestRunnerOptions {
  projectRoot: string;
  suite?: string;
  testFile?: string;
  timeout?: number;
}

/**
 * Parse bun test JSON output
 */
function parseBunOutput(stdout: string, stderr: string): BunTestOutput {
  // Try to find JSON output
  const lines = stdout.split('\n');
  const results: BunTestResult[] = [];
  let pass = 0;
  let fail = 0;
  let skip = 0;
  let totalDuration = 0;

  // Bun outputs test results in a specific format
  // We'll parse the human-readable output and convert to structured data
  for (const line of lines) {
    // Match test result lines: (pass) description (0.12ms)
    const passMatch = line.match(/\(pass\)\s+(.+?)\s+\[([0-9.]+)(?:ms|s)\]/);
    const failMatch = line.match(/\(fail\)\s+(.+?)\s+\[([0-9.]+)(?:ms|s)\]/);
    const skipMatch = line.match(/\(skip\)\s+(.+)/);

    if (passMatch) {
      const duration = parseFloat(passMatch[2]);
      results.push({
        name: passMatch[1].trim(),
        file: '',
        status: 'pass',
        duration,
      });
      pass++;
      totalDuration += duration;
    } else if (failMatch) {
      const duration = parseFloat(failMatch[2]);
      results.push({
        name: failMatch[1].trim(),
        file: '',
        status: 'fail',
        duration,
        error: {
          message: extractErrorMessage(stderr, failMatch[1].trim()),
        },
      });
      fail++;
      totalDuration += duration;
    } else if (skipMatch) {
      results.push({
        name: skipMatch[1].trim(),
        file: '',
        status: 'skip',
        duration: 0,
      });
      skip++;
    }
  }

  // Also try to parse summary line
  const summaryMatch = stdout.match(/(\d+)\s+pass.*?(\d+)\s+fail/i);
  if (summaryMatch && results.length === 0) {
    // Fallback: just use counts
    pass = parseInt(summaryMatch[1], 10);
    fail = parseInt(summaryMatch[2], 10);
  }

  return {
    success: fail === 0,
    results,
    summary: {
      pass,
      fail,
      skip,
      total: pass + fail + skip,
      duration: totalDuration,
    },
  };
}

/**
 * Extract error message for a failing test
 */
function extractErrorMessage(stderr: string, testName: string): string {
  // Look for the test name in stderr and grab following lines
  const lines = stderr.split('\n');
  const testIndex = lines.findIndex((l) => l.includes(testName));

  if (testIndex >= 0) {
    // Get a few lines after the test name
    const errorLines = lines.slice(testIndex, testIndex + 10).filter((l) => l.trim());
    return errorLines.join('\n');
  }

  return stderr.slice(0, 500);
}

/**
 * Run bun tests
 */
export async function runTests(options: TestRunnerOptions): Promise<BunTestOutput> {
  const { projectRoot, suite, testFile, timeout = 120000 } = options;

  logger.info({ projectRoot, suite, testFile }, 'Running tests');

  const args = ['test'];

  // Add specific test file or pattern (with path traversal protection)
  if (testFile) {
    const validatedPath = validateTestFilePath(testFile, projectRoot);
    if (!validatedPath) {
      logger.error({ testFile }, 'Invalid test file path - possible path traversal');
      return {
        success: false,
        results: [{
          name: 'validation-error',
          file: '',
          status: 'fail',
          duration: 0,
          error: { message: 'Invalid test file path' },
        }],
        summary: { pass: 0, fail: 1, skip: 0, total: 1, duration: 0 },
      };
    }
    args.push(validatedPath);
  } else if (suite && suite !== 'all') {
    if (!validateSuiteName(suite)) {
      logger.error({ suite }, 'Invalid suite name - possible path traversal');
      return {
        success: false,
        results: [{
          name: 'validation-error',
          file: '',
          status: 'fail',
          duration: 0,
          error: { message: 'Invalid suite name' },
        }],
        summary: { pass: 0, fail: 1, skip: 0, total: 1, duration: 0 },
      };
    }
    // Map suite to test pattern (safe after validation)
    args.push(`tests/${suite}/**/*.test.ts`);
  }

  // Add reporter flags for parseable output
  args.push('--reporter', 'default');

  return new Promise((resolve) => {
    let stdout = '';
    let stderr = '';

    const proc = spawn('bun', args, {
      cwd: projectRoot,
      env: {
        ...process.env,
        FORCE_COLOR: '0', // Disable colors for parsing
      },
    });

    const timer = setTimeout(() => {
      proc.kill('SIGTERM');
      resolve({
        success: false,
        results: [],
        summary: {
          pass: 0,
          fail: 0,
          skip: 0,
          total: 0,
          duration: timeout,
        },
      });
    }, timeout);

    proc.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    proc.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    proc.on('close', (code) => {
      clearTimeout(timer);

      logger.debug({ code, stdout: stdout.slice(0, 500), stderr: stderr.slice(0, 500) }, 'Test process completed');

      const output = parseBunOutput(stdout, stderr);

      // If we couldn't parse results but have an exit code, infer success/failure
      if (output.summary.total === 0 && code !== null) {
        output.success = code === 0;
      }

      resolve(output);
    });

    proc.on('error', (err) => {
      clearTimeout(timer);
      logger.error({ err }, 'Failed to spawn test process');

      resolve({
        success: false,
        results: [{
          name: 'spawn-error',
          file: '',
          status: 'fail',
          duration: 0,
          error: { message: err.message },
        }],
        summary: {
          pass: 0,
          fail: 1,
          skip: 0,
          total: 1,
          duration: 0,
        },
      });
    });
  });
}

/**
 * Discover available test suites
 */
export async function discoverSuites(projectRoot: string): Promise<string[]> {
  const { readdir } = await import('fs/promises');
  const { join } = await import('path');

  try {
    const testsDir = join(projectRoot, 'tests');
    const entries = await readdir(testsDir, { withFileTypes: true });
    const suites = entries
      .filter((e) => e.isDirectory())
      .map((e) => e.name);

    return ['all', ...suites];
  } catch {
    return ['all'];
  }
}
