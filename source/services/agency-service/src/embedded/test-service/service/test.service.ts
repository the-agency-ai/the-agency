/**
 * Test Service
 *
 * Business logic for test execution and history.
 */

import { randomUUID } from 'crypto';
import type { DatabaseAdapter } from '../../../core/adapters/database';
import { TestRunRepository } from '../repository/test-run.repository';
import { runTests, runTestsWithConfig } from './test-runner';
import { TestConfigService } from '../config/test-config.service';
import { TestDiscoveryService } from './discovery.service';
import type {
  TestRun,
  TestRunWithResults,
  CreateTestRunRequest,
  QueryTestRunsRequest,
  TestStats,
  FlakyTest,
  TestSuite,
} from '../types';
import type {
  TestConfig,
  TestRunner,
  TestTarget,
  TestSuiteConfig,
  DiscoveredSuite,
} from '../config/test-config.types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('test-service');

export class TestService {
  private repository: TestRunRepository;
  private projectRoot: string;
  private configService: TestConfigService;
  private discoveryService: TestDiscoveryService;

  constructor(db: DatabaseAdapter, projectRoot: string) {
    this.repository = new TestRunRepository(db);
    this.projectRoot = projectRoot;
    this.configService = new TestConfigService(projectRoot);
    this.discoveryService = new TestDiscoveryService(this.configService);
  }

  /**
   * Initialize the service
   */
  async initialize(): Promise<void> {
    await this.repository.initialize();
    await this.configService.load();
    logger.info('Test service initialized');
  }

  /**
   * Start a new test run
   */
  async startRun(request: CreateTestRunRequest): Promise<TestRun> {
    const id = randomUUID();

    // Resolve target from suite config if not specified
    let target = request.target;
    if (target === 'default') {
      const suiteConfig = this.configService.getSuite(request.suite);
      if (suiteConfig) {
        target = suiteConfig.target;
      } else {
        // Default to first target if no suite config
        const targets = this.configService.getTargets();
        target = targets.length > 0 ? targets[0].id : 'default';
      }
    }

    const run = await this.repository.createRun({
      id,
      suite: request.suite,
      target,
      triggeredByType: request.triggeredByType,
      triggeredByName: request.triggeredByName,
      gitBranch: request.gitBranch,
      gitCommit: request.gitCommit,
    });

    logger.info({ runId: id, suite: request.suite, target }, 'Test run started');
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

    logger.info({ runId, suite: run.suite, target: run.target }, 'Executing tests');

    // Get configuration for this run
    const suiteConfig = this.configService.getSuite(run.suite);
    const targetConfig = this.configService.getTarget(run.target);
    const runnerConfig = targetConfig
      ? this.configService.getRunner(targetConfig.runner)
      : null;

    // Run tests using configuration if available, otherwise fallback to legacy
    let output;
    if (targetConfig && runnerConfig) {
      output = await runTestsWithConfig({
        projectRoot: this.projectRoot,
        suite: run.suite,
        suitePath: suiteConfig?.path,
        target: targetConfig,
        runner: runnerConfig,
      });
    } else {
      // Fallback to legacy runner
      output = await runTests({
        projectRoot: this.projectRoot,
        suite: run.suite,
      });
    }

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
    if (!completedRun) {
      throw new Error(`Test run ${runId} not found after completion`);
    }
    const results = await this.repository.getResultsForRun(runId);

    return {
      ...completedRun,
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
    // Use configured suites if available
    const configuredSuites = this.configService.getSuites();
    if (configuredSuites.length > 0) {
      return configuredSuites.map((suite) => ({
        name: suite.name,
        path: suite.path,
        testCount: 0,
      }));
    }

    // Fallback: discover from filesystem
    const discovered = await this.discoveryService.discoverAll();
    return discovered.map((suite) => ({
      name: suite.name,
      path: suite.path,
      testCount: suite.testFileCount,
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

  // ─────────────────────────────────────────────────────────────
  // Configuration & Discovery
  // ─────────────────────────────────────────────────────────────

  /**
   * Get the test configuration
   */
  getConfig(): TestConfig {
    return this.configService.getConfig();
  }

  /**
   * Get all configured runners
   */
  getRunners(): TestRunner[] {
    return this.configService.getRunners();
  }

  /**
   * Get all configured targets
   */
  getTargets(): TestTarget[] {
    return this.configService.getTargets();
  }

  /**
   * Get all configured suites
   */
  getConfiguredSuites(): TestSuiteConfig[] {
    return this.configService.getSuites();
  }

  /**
   * Discover test suites in all targets
   */
  async discoverSuites(): Promise<DiscoveredSuite[]> {
    return this.discoveryService.discoverAll();
  }

  /**
   * Discover test suites in a specific target
   */
  async discoverSuitesInTarget(targetId: string): Promise<DiscoveredSuite[]> {
    return this.discoveryService.discoverInTarget(targetId);
  }

  /**
   * Register a discovered suite
   */
  async registerSuite(suite: {
    id: string;
    name: string;
    target: string;
    path: string;
    tags?: string[];
  }): Promise<TestSuiteConfig> {
    const suiteConfig: TestSuiteConfig = {
      id: suite.id,
      name: suite.name,
      target: suite.target,
      path: suite.path,
      tags: suite.tags || [],
      enabled: true,
    };

    this.configService.addSuite(suiteConfig);
    await this.configService.save();

    logger.info({ suiteId: suite.id }, 'Suite registered');
    return suiteConfig;
  }

  /**
   * Unregister a suite
   */
  async unregisterSuite(suiteId: string): Promise<boolean> {
    const removed = this.configService.removeSuite(suiteId);
    if (removed) {
      await this.configService.save();
      logger.info({ suiteId }, 'Suite unregistered');
    }
    return removed;
  }

  /**
   * Reload configuration from disk
   */
  async reloadConfig(): Promise<TestConfig> {
    return this.configService.load();
  }
}
