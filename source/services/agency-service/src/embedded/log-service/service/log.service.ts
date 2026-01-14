/**
 * Log Service
 *
 * Business logic layer for log management.
 * Supports tool run tracking and focused queries.
 */

import type {
  LogEntry,
  ToolRun,
  CreateLogEntryRequest,
  BatchCreateLogEntriesRequest,
  CreateToolRunRequest,
  EndToolRunRequest,
  QueryLogsRequest,
  LogListResponse,
  LogStats,
} from '../types';
import type { LogRepository } from '../repository/log.repository';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('log-service');

export class LogService {
  constructor(private repository: LogRepository) {}

  /**
   * Ingest a log entry
   */
  async ingest(data: CreateLogEntryRequest): Promise<LogEntry> {
    return this.repository.create(data);
  }

  /**
   * Ingest multiple log entries
   */
  async ingestBatch(data: BatchCreateLogEntriesRequest): Promise<{ count: number }> {
    const count = await this.repository.createBatch(data.entries);
    return { count };
  }

  /**
   * Query logs with filters
   */
  async query(params: QueryLogsRequest): Promise<LogListResponse> {
    const { logs, total } = await this.repository.query(params);
    return {
      logs,
      total,
      limit: params.limit,
      offset: params.offset,
    };
  }

  /**
   * Get all logs for a specific run
   * Focused query for debugging tool runs
   */
  async getRunLogs(
    runId: string,
    options?: { errorsOnly?: boolean }
  ): Promise<LogEntry[]> {
    const logs = await this.repository.getByRunId(runId);

    if (options?.errorsOnly) {
      return logs.filter(l => l.level === 'error' || l.level === 'fatal');
    }

    return logs;
  }

  /**
   * Get run details with logs summary
   */
  async getRunDetails(runId: string): Promise<{
    run: ToolRun | null;
    logs: LogEntry[];
    summary: {
      total: number;
      errors: number;
      warnings: number;
    };
  }> {
    const run = await this.repository.getToolRun(runId);
    const logs = await this.repository.getByRunId(runId);

    const summary = {
      total: logs.length,
      errors: logs.filter(l => l.level === 'error' || l.level === 'fatal').length,
      warnings: logs.filter(l => l.level === 'warn').length,
    };

    return { run, logs, summary };
  }

  /**
   * Get log statistics
   */
  async getStats(): Promise<LogStats> {
    return this.repository.getStats();
  }

  /**
   * Get list of services with logs
   */
  async getServices(): Promise<string[]> {
    return this.repository.getServices();
  }

  /**
   * Start a tool run
   */
  async startToolRun(data: CreateToolRunRequest): Promise<ToolRun> {
    const run = await this.repository.createToolRun(data);

    // Log the start
    await this.ingest({
      service: data.tool,
      level: 'info',
      message: `Tool run started: ${data.tool}`,
      runId: run.runId,
      userId: data.userId,
      userType: data.userType,
    });

    logger.info({ runId: run.runId, tool: data.tool }, 'Tool run started');
    return run;
  }

  /**
   * End a tool run
   */
  async endToolRun(runId: string, data: EndToolRunRequest): Promise<ToolRun | null> {
    const run = await this.repository.endToolRun(runId, data);

    if (run) {
      // Log the end
      await this.ingest({
        service: run.tool,
        level: data.status === 'success' ? 'info' : 'error',
        message: `Tool run ${data.status}: ${run.tool}${data.summary ? ` - ${data.summary}` : ''}`,
        runId: run.runId,
        userId: run.userId,
        userType: run.userType,
      });

      logger.info({
        runId: run.runId,
        tool: run.tool,
        status: data.status,
        duration: run.endedAt && run.startedAt
          ? run.endedAt.getTime() - run.startedAt.getTime()
          : null,
      }, 'Tool run ended');
    }

    return run;
  }

  /**
   * Get a tool run
   */
  async getToolRun(runId: string): Promise<ToolRun | null> {
    return this.repository.getToolRun(runId);
  }

  /**
   * Get tool usage statistics (telemetry)
   */
  async getToolStats(options?: { since?: string; tool?: string; toolType?: string }) {
    return this.repository.getToolStats(options);
  }

  /**
   * Get recent tool failures
   */
  async getRecentFailures(limit: number = 20) {
    return this.repository.getRecentFailures(limit);
  }

  /**
   * Clean up old logs
   */
  async cleanup(daysToKeep: number = 30): Promise<{ deleted: number }> {
    const deleted = await this.repository.cleanup(daysToKeep);
    return { deleted };
  }
}
