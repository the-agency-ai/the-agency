/**
 * Test Run Repository
 *
 * Data access layer for test runs and results.
 * Uses the database adapter interface.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import type {
  TestRun,
  TestResult,
  TestRunStatusType,
  TestResultStatusType,
  QueryTestRunsRequest,
  TestStats,
  FlakyTest,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('test-repository');

/**
 * Database row types (snake_case as stored in SQLite)
 */
interface TestRunRow {
  id: string;
  suite: string;
  target: string;
  status: string;
  triggered_by_type: string;
  triggered_by_name: string;
  started_at: string;
  completed_at: string | null;
  duration: number | null;
  total: number;
  passed: number;
  failed: number;
  skipped: number;
  git_branch: string | null;
  git_commit: string | null;
}

interface TestResultRow {
  id: number;
  run_id: string;
  test_name: string;
  suite: string;
  file: string | null;
  status: string;
  duration: number;
  error_message: string | null;
  error_stack: string | null;
  error_expected: string | null;
  error_actual: string | null;
}

/**
 * Convert database row to TestRun entity
 */
function rowToTestRun(row: TestRunRow): TestRun {
  return {
    id: row.id,
    suite: row.suite,
    target: row.target || 'default',
    status: row.status as TestRunStatusType,
    triggeredByType: row.triggered_by_type as TestRun['triggeredByType'],
    triggeredByName: row.triggered_by_name,
    startedAt: new Date(row.started_at),
    completedAt: row.completed_at ? new Date(row.completed_at) : null,
    duration: row.duration,
    total: row.total,
    passed: row.passed,
    failed: row.failed,
    skipped: row.skipped,
    gitBranch: row.git_branch,
    gitCommit: row.git_commit,
  };
}

/**
 * Convert database row to TestResult entity
 */
function rowToTestResult(row: TestResultRow): TestResult {
  return {
    id: row.id,
    runId: row.run_id,
    testName: row.test_name,
    suite: row.suite,
    file: row.file,
    status: row.status as TestResultStatusType,
    duration: row.duration,
    errorMessage: row.error_message,
    errorStack: row.error_stack,
    errorExpected: row.error_expected,
    errorActual: row.error_actual,
  };
}

export class TestRunRepository {
  constructor(private db: DatabaseAdapter) {}

  /**
   * Initialize the test schema
   */
  async initialize(): Promise<void> {
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS test_runs (
        id TEXT PRIMARY KEY,
        suite TEXT NOT NULL,
        target TEXT NOT NULL DEFAULT 'default',
        status TEXT NOT NULL DEFAULT 'pending',
        triggered_by_type TEXT NOT NULL,
        triggered_by_name TEXT NOT NULL,
        started_at TEXT NOT NULL DEFAULT (datetime('now')),
        completed_at TEXT,
        duration INTEGER,
        total INTEGER DEFAULT 0,
        passed INTEGER DEFAULT 0,
        failed INTEGER DEFAULT 0,
        skipped INTEGER DEFAULT 0,
        git_branch TEXT,
        git_commit TEXT
      )
    `);

    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS test_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        run_id TEXT NOT NULL,
        test_name TEXT NOT NULL,
        suite TEXT NOT NULL,
        file TEXT,
        status TEXT NOT NULL,
        duration INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        error_stack TEXT,
        error_expected TEXT,
        error_actual TEXT,
        FOREIGN KEY (run_id) REFERENCES test_runs(id)
      )
    `);

    // Create indexes (except target - created after migration)
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_test_runs_suite ON test_runs(suite)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_test_runs_status ON test_runs(status)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_test_runs_started_at ON test_runs(started_at)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_test_results_run_id ON test_results(run_id)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_test_results_test_name ON test_results(test_name)`);

    // Migration: add target column if missing (for existing databases)
    await this.migrateAddTargetColumn();

    // Create target index after migration ensures column exists
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_test_runs_target ON test_runs(target)`);

    logger.info('Test schema initialized');
  }

  /**
   * Migration: add target column to existing databases
   */
  private async migrateAddTargetColumn(): Promise<void> {
    try {
      // Check if column exists by querying table info
      const columns = await this.db.query<{ name: string }>(
        `PRAGMA table_info(test_runs)`
      );
      const hasTarget = columns.some((c) => c.name === 'target');

      if (!hasTarget) {
        await this.db.execute(
          `ALTER TABLE test_runs ADD COLUMN target TEXT DEFAULT 'default'`
        );
        logger.info('Migrated test_runs table: added target column');
      }
    } catch (error) {
      // Check if error is "no such table" which is expected during initial setup
      const errorMessage = error instanceof Error ? error.message : String(error);
      if (errorMessage.includes('no such table')) {
        logger.debug({ error: errorMessage }, 'Migration check skipped - table not yet created');
      } else {
        // Log unexpected errors at warning level
        logger.warn({ error: errorMessage }, 'Migration check encountered unexpected error');
      }
    }
  }

  /**
   * Create a new test run
   */
  async createRun(data: {
    id: string;
    suite: string;
    target?: string;
    triggeredByType: string;
    triggeredByName: string;
    gitBranch?: string;
    gitCommit?: string;
  }): Promise<TestRun> {
    await this.db.execute(
      `INSERT INTO test_runs (
        id, suite, target, status, triggered_by_type, triggered_by_name,
        git_branch, git_commit
      ) VALUES (?, ?, ?, 'pending', ?, ?, ?, ?)`,
      [
        data.id,
        data.suite,
        data.target || 'default',
        data.triggeredByType,
        data.triggeredByName,
        data.gitBranch || null,
        data.gitCommit || null,
      ]
    );

    const run = await this.findRunById(data.id);
    if (!run) {
      throw new Error(`Failed to create test run ${data.id}`);
    }

    logger.info({ runId: data.id, target: data.target }, 'Test run created');
    return run;
  }

  /**
   * Find a test run by ID
   */
  async findRunById(id: string): Promise<TestRun | null> {
    const row = await this.db.get<TestRunRow>(
      'SELECT * FROM test_runs WHERE id = ?',
      [id]
    );
    return row ? rowToTestRun(row) : null;
  }

  /**
   * Update test run status to running
   */
  async markRunning(id: string): Promise<void> {
    await this.db.execute(
      `UPDATE test_runs SET status = 'running' WHERE id = ?`,
      [id]
    );
  }

  /**
   * Complete a test run with results
   */
  async completeRun(
    id: string,
    status: 'passed' | 'failed' | 'cancelled',
    summary: { total: number; passed: number; failed: number; skipped: number; duration: number }
  ): Promise<void> {
    await this.db.execute(
      `UPDATE test_runs SET
        status = ?,
        completed_at = datetime('now'),
        duration = ?,
        total = ?,
        passed = ?,
        failed = ?,
        skipped = ?
      WHERE id = ?`,
      [
        status,
        summary.duration,
        summary.total,
        summary.passed,
        summary.failed,
        summary.skipped,
        id,
      ]
    );

    logger.info({ runId: id, status }, 'Test run completed');
  }

  /**
   * Add a test result to a run
   */
  async addResult(data: {
    runId: string;
    testName: string;
    suite: string;
    file?: string;
    status: TestResultStatusType;
    duration: number;
    errorMessage?: string;
    errorStack?: string;
    errorExpected?: string;
    errorActual?: string;
  }): Promise<TestResult> {
    await this.db.execute(
      `INSERT INTO test_results (
        run_id, test_name, suite, file, status, duration,
        error_message, error_stack, error_expected, error_actual
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        data.runId,
        data.testName,
        data.suite,
        data.file || null,
        data.status,
        data.duration,
        data.errorMessage || null,
        data.errorStack || null,
        data.errorExpected || null,
        data.errorActual || null,
      ]
    );

    const row = await this.db.get<TestResultRow>(
      'SELECT * FROM test_results WHERE run_id = ? AND test_name = ? ORDER BY id DESC LIMIT 1',
      [data.runId, data.testName]
    );

    if (!row) {
      throw new Error(`Failed to add test result`);
    }

    return rowToTestResult(row);
  }

  /**
   * Get results for a test run
   */
  async getResultsForRun(runId: string): Promise<TestResult[]> {
    const rows = await this.db.query<TestResultRow>(
      'SELECT * FROM test_results WHERE run_id = ? ORDER BY id',
      [runId]
    );
    return rows.map(rowToTestResult);
  }

  /**
   * Get failed results for a test run
   */
  async getFailedResultsForRun(runId: string): Promise<TestResult[]> {
    const rows = await this.db.query<TestResultRow>(
      "SELECT * FROM test_results WHERE run_id = ? AND status = 'failed' ORDER BY id",
      [runId]
    );
    return rows.map(rowToTestResult);
  }

  /**
   * List test runs with filtering
   */
  async listRuns(query: QueryTestRunsRequest): Promise<{ runs: TestRun[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];

    if (query.suite) {
      conditions.push('suite = ?');
      params.push(query.suite);
    }

    if (query.status) {
      conditions.push('status = ?');
      params.push(query.status);
    }

    if (query.since) {
      conditions.push('started_at >= ?');
      params.push(query.since);
    }

    const whereClause = conditions.length > 0
      ? `WHERE ${conditions.join(' AND ')}`
      : '';

    // Get total count
    const countRow = await this.db.get<{ count: number }>(
      `SELECT COUNT(*) as count FROM test_runs ${whereClause}`,
      params
    );
    const total = countRow?.count ?? 0;

    // Get paginated results
    const rows = await this.db.query<TestRunRow>(
      `SELECT * FROM test_runs ${whereClause}
       ORDER BY started_at DESC
       LIMIT ? OFFSET ?`,
      [...params, query.limit, query.offset]
    );

    return {
      runs: rows.map(rowToTestRun),
      total,
    };
  }

  /**
   * Get test stats
   */
  async getStats(suite?: string): Promise<TestStats> {
    const whereClause = suite ? 'WHERE suite = ?' : '';
    const params = suite ? [suite] : [];

    const statsRow = await this.db.get<{
      total_runs: number;
      passed_runs: number;
      failed_runs: number;
      avg_duration: number;
      last_run_at: string | null;
    }>(
      `SELECT
        COUNT(*) as total_runs,
        SUM(CASE WHEN status = 'passed' THEN 1 ELSE 0 END) as passed_runs,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed_runs,
        AVG(duration) as avg_duration,
        MAX(started_at) as last_run_at
      FROM test_runs ${whereClause}`,
      params
    );

    const totalRuns = statsRow?.total_runs ?? 0;
    const passedRuns = statsRow?.passed_runs ?? 0;

    return {
      totalRuns,
      passedRuns,
      failedRuns: statsRow?.failed_runs ?? 0,
      passRate: totalRuns > 0 ? (passedRuns / totalRuns) * 100 : 0,
      avgDuration: statsRow?.avg_duration ?? 0,
      lastRunAt: statsRow?.last_run_at ? new Date(statsRow.last_run_at) : null,
    };
  }

  /**
   * Find flaky tests (tests that sometimes pass, sometimes fail)
   */
  async getFlakyTests(limit: number = 10): Promise<FlakyTest[]> {
    const rows = await this.db.query<{
      test_name: string;
      suite: string;
      passes: number;
      failures: number;
      total: number;
    }>(
      `SELECT
        test_name,
        suite,
        SUM(CASE WHEN status = 'passed' THEN 1 ELSE 0 END) as passes,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failures,
        COUNT(*) as total
      FROM test_results
      GROUP BY test_name, suite
      HAVING passes > 0 AND failures > 0
      ORDER BY (CAST(failures AS FLOAT) / total) DESC
      LIMIT ?`,
      [limit]
    );

    return rows.map((row) => ({
      testName: row.test_name,
      suite: row.suite,
      passes: row.passes,
      failures: row.failures,
      total: row.total,
      flakinessScore: row.failures / row.total,
    }));
  }

  /**
   * Get the most recent run
   */
  async getLatestRun(suite?: string): Promise<TestRun | null> {
    const whereClause = suite ? 'WHERE suite = ?' : '';
    const params = suite ? [suite] : [];

    const row = await this.db.get<TestRunRow>(
      `SELECT * FROM test_runs ${whereClause} ORDER BY started_at DESC LIMIT 1`,
      params
    );

    return row ? rowToTestRun(row) : null;
  }

  /**
   * Delete old test runs (cleanup)
   */
  async deleteOldRuns(olderThan: Date): Promise<number> {
    // Get run IDs to delete
    const runs = await this.db.query<{ id: string }>(
      'SELECT id FROM test_runs WHERE started_at < ?',
      [olderThan.toISOString()]
    );

    if (runs.length === 0) {
      return 0;
    }

    const runIds = runs.map((r) => r.id);
    const placeholders = runIds.map(() => '?').join(',');

    // Delete results first
    await this.db.execute(
      `DELETE FROM test_results WHERE run_id IN (${placeholders})`,
      runIds
    );

    // Delete runs
    const changes = await this.db.delete(
      `DELETE FROM test_runs WHERE id IN (${placeholders})`,
      runIds
    );

    logger.info({ count: changes }, 'Old test runs deleted');
    return changes;
  }
}
