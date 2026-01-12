/**
 * Test Service
 *
 * Business logic for test execution and history.
 */

import { randomUUID } from 'crypto';
import type { DatabaseAdapter } from '../../../core/adapters/database';
import { TestRunRepository } from '../repository/test-run.repository';
import { runTests, discoverSuites } from './test-runner';
import type {
  TestRun,
  TestRunWithResults,
  CreateTestRunRequest,
  QueryTestRunsRequest,
  TestStats,
  FlakyTest,
  TestSuite,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('test-service');

export class TestService {
  private repository: TestRunRepository;
  private projectRoot: string;

  constructor(db: DatabaseAdapter, projectRoot: string) {
    this.repository = new TestRunRepository(db);
    this.projectRoot = projectRoot;
  }

  /**
   * Initialize the service
   */
  async initialize(): Promise<void> {
    await this.repository.initialize();
    logger.info('Test service initialized');
  }

  /**
   * Start a new test run
   */
  async startRun(request: CreateTestRunRequest): Promise<TestRun> {
    const id = randomUUID();

    const run = await this.repository.createRun({
      id,
      suite: request.suite,
      triggeredByType: request.triggeredByType,
      triggeredByName: request.triggeredByName,
      gitBranch: request.gitBranch,
      gitCommit: request.gitCommit,
    });

    logger.info({ runId: id, suite: request.suite }, 'Test run started');
    return run;
  }

  /**
   * Execute tests and record results
   */
  async executeRun(runId: string): Promise<TestRunWithResults> {
    const run = await this.repository.findRunById(runId);
    if (!run) {
      throw new Error(`Test run not found: ${runId}`);
    }

    // Mark as running
    await this.repository.markRunning(runId);

    logger.info({ runId, suite: run.suite }, 'Executing tests');

    // Run tests
    const output = await runTests({
      projectRoot: this.projectRoot,
      suite: run.suite,
    });

    // Record results
    for (const result of output.results) {
      await this.repository.addResult({
        runId,
        testName: result.name,
        suite: run.suite,
        file: result.file || undefined,
        status: result.status === 'pass' ? 'passed' : result.status === 'fail' ? 'failed' : 'skipped',
        duration: result.duration,
        errorMessage: result.error?.message,
        errorStack: result.error?.stack,
      });
    }

    // Complete the run
    const finalStatus = output.success ? 'passed' : 'failed';
    await this.repository.completeRun(runId, finalStatus, {
      total: output.summary.total,
      passed: output.summary.pass,
      failed: output.summary.fail,
      skipped: output.summary.skip,
      duration: output.summary.duration,
    });

    logger.info({
      runId,
      status: finalStatus,
      total: output.summary.total,
      passed: output.summary.pass,
      failed: output.summary.fail,
    }, 'Test run completed');

    // Return the completed run with results
    const completedRun = await this.repository.findRunById(runId);
    const results = await this.repository.getResultsForRun(runId);

    return {
      ...completedRun!,
      results,
    };
  }

  /**
   * Run tests (start + execute in one call)
   */
  async runTests(request: CreateTestRunRequest): Promise<TestRunWithResults> {
    const run = await this.startRun(request);
    return this.executeRun(run.id);
  }

  /**
   * Get a test run by ID
   */
  async getRun(id: string): Promise<TestRun | null> {
    return this.repository.findRunById(id);
  }

  /**
   * Get a test run with its results
   */
  async getRunWithResults(id: string): Promise<TestRunWithResults | null> {
    const run = await this.repository.findRunById(id);
    if (!run) return null;

    const results = await this.repository.getResultsForRun(id);
    return { ...run, results };
  }

  /**
   * Get failed results for a run
   */
  async getFailedResults(runId: string): Promise<TestRunWithResults | null> {
    const run = await this.repository.findRunById(runId);
    if (!run) return null;

    const results = await this.repository.getFailedResultsForRun(runId);
    return { ...run, results };
  }

  /**
   * List test runs with filtering
   */
  async listRuns(query: QueryTestRunsRequest): Promise<{
    runs: TestRun[];
    total: number;
    limit: number;
    offset: number;
  }> {
    const { runs, total } = await this.repository.listRuns(query);
    return {
      runs,
      total,
      limit: query.limit,
      offset: query.offset,
    };
  }

  /**
   * Get test stats
   */
  async getStats(suite?: string): Promise<TestStats> {
    return this.repository.getStats(suite);
  }

  /**
   * Get the most recent test run
   */
  async getLatestRun(suite?: string): Promise<TestRun | null> {
    return this.repository.getLatestRun(suite);
  }

  /**
   * Find flaky tests
   */
  async getFlakyTests(limit: number = 10): Promise<FlakyTest[]> {
    return this.repository.getFlakyTests(limit);
  }

  /**
   * Discover available test suites
   */
  async getSuites(): Promise<TestSuite[]> {
    const suiteNames = await discoverSuites(this.projectRoot);

    return suiteNames.map((name) => ({
      name,
      path: name === 'all' ? 'tests/' : `tests/${name}/`,
      testCount: 0, // We don't count files here
    }));
  }

  /**
   * Cancel a running test (future: integrate with process management)
   */
  async cancelRun(runId: string): Promise<boolean> {
    const run = await this.repository.findRunById(runId);
    if (!run || run.status !== 'running') {
      return false;
    }

    await this.repository.completeRun(runId, 'cancelled', {
      total: 0,
      passed: 0,
      failed: 0,
      skipped: 0,
      duration: 0,
    });

    logger.info({ runId }, 'Test run cancelled');
    return true;
  }

  /**
   * Clean up old test runs
   */
  async cleanup(olderThanDays: number = 30): Promise<number> {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - olderThanDays);

    return this.repository.deleteOldRuns(cutoff);
  }
}
