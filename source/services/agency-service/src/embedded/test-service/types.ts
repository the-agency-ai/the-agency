/**
 * Test Service Types
 *
 * Domain models for test execution and history.
 */

import { z } from 'zod';

/**
 * Test run status
 */
export const TestRunStatus = {
  PENDING: 'pending',
  RUNNING: 'running',
  PASSED: 'passed',
  FAILED: 'failed',
  CANCELLED: 'cancelled',
} as const;

export type TestRunStatusType = (typeof TestRunStatus)[keyof typeof TestRunStatus];

/**
 * Test result status
 */
export const TestResultStatus = {
  PASSED: 'passed',
  FAILED: 'failed',
  SKIPPED: 'skipped',
} as const;

export type TestResultStatusType = (typeof TestResultStatus)[keyof typeof TestResultStatus];

/**
 * Trigger types
 */
export const TriggerType = {
  PRINCIPAL: 'principal',
  AGENT: 'agent',
  SYSTEM: 'system',
  CI: 'ci',
} as const;

export type TriggerTypeValue = (typeof TriggerType)[keyof typeof TriggerType];

/**
 * Test suite info
 */
export interface TestSuite {
  name: string;
  path: string;
  testCount: number;
}

/**
 * Test run entity
 */
export interface TestRun {
  id: string;
  suite: string;
  status: TestRunStatusType;
  triggeredByType: TriggerTypeValue;
  triggeredByName: string;
  startedAt: Date;
  completedAt: Date | null;
  duration: number | null;

  // Results
  total: number;
  passed: number;
  failed: number;
  skipped: number;

  // Git context
  gitBranch: string | null;
  gitCommit: string | null;
}

/**
 * Test result entity
 */
export interface TestResult {
  id: number;
  runId: string;
  testName: string;
  suite: string;
  file: string | null;
  status: TestResultStatusType;
  duration: number;
  errorMessage: string | null;
  errorStack: string | null;
  errorExpected: string | null;
  errorActual: string | null;
}

/**
 * Safe suite name pattern: alphanumeric, hyphens, underscores only
 * Prevents path traversal and shell injection
 */
const safeSuitePattern = /^[a-zA-Z0-9_-]+$/;

/**
 * Create test run request schema
 */
export const createTestRunSchema = z.object({
  suite: z.string().default('all').refine(
    (val) => safeSuitePattern.test(val) && !val.includes('..'),
    { message: 'Suite name must be alphanumeric with hyphens/underscores only' }
  ),
  triggeredByType: z.enum(['principal', 'agent', 'system', 'ci']).default('system'),
  triggeredByName: z.string().default('cli'),
  gitBranch: z.string().optional(),
  gitCommit: z.string().optional(),
});

export type CreateTestRunRequest = z.infer<typeof createTestRunSchema>;

/**
 * Query test runs parameters
 */
export const queryTestRunsSchema = z.object({
  suite: z.string().optional(),
  status: z.enum(['pending', 'running', 'passed', 'failed', 'cancelled']).optional(),
  since: z.string().optional(),
  limit: z.coerce.number().min(1).max(100).default(20),
  offset: z.coerce.number().min(0).default(0),
});

export type QueryTestRunsRequest = z.infer<typeof queryTestRunsSchema>;

/**
 * Test run list response
 */
export interface TestRunListResponse {
  runs: TestRun[];
  total: number;
  limit: number;
  offset: number;
}

/**
 * Test run with results
 */
export interface TestRunWithResults extends TestRun {
  results: TestResult[];
}

/**
 * Test stats
 */
export interface TestStats {
  totalRuns: number;
  passedRuns: number;
  failedRuns: number;
  passRate: number;
  avgDuration: number;
  lastRunAt: Date | null;
}

/**
 * Flaky test info
 */
export interface FlakyTest {
  testName: string;
  suite: string;
  passes: number;
  failures: number;
  total: number;
  flakinessScore: number;
}

/**
 * Bun test output types
 */
export interface BunTestResult {
  name: string;
  file: string;
  status: 'pass' | 'fail' | 'skip';
  duration: number;
  error?: {
    message: string;
    stack?: string;
  };
}

export interface BunTestOutput {
  success: boolean;
  results: BunTestResult[];
  summary: {
    pass: number;
    fail: number;
    skip: number;
    total: number;
    duration: number;
  };
}
