/**
 * Bug Service
 *
 * Business logic layer for bug management.
 * Handles notifications, validation, and orchestration.
 */

import type { Bug, CreateBugRequest, UpdateBugRequest, ListBugsQuery, BugListResponse } from '../types';
import type { BugRepository } from '../repository/bug.repository';
import type { QueueAdapter } from '../../../core/adapters/queue';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('bug-service');

/**
 * Notification job data
 */
interface NotificationJobData {
  type: 'bug_assigned' | 'bug_reassigned';
  bugId: string;
  recipientType: string;
  recipientName: string;
  subject: string;
  body: string;
}

export class BugService {
  constructor(
    private repository: BugRepository,
    private queue?: QueueAdapter
  ) {}

  /**
   * Create a new bug
   */
  async createBug(data: CreateBugRequest): Promise<Bug> {
    // Generate bug ID
    const bugId = await this.repository.getNextBugId(data.workstream);

    // Create the bug
    const bug = await this.repository.create(bugId, data);

    // Notify assignee if specified
    if (data.assigneeName && data.assigneeType) {
      await this.notifyAssignee(bug, 'bug_assigned');
    }

    logger.info({ bugId: bug.bugId, assignee: bug.assigneeName }, 'Bug created');
    return bug;
  }

  /**
   * Get a bug by its bug ID
   */
  async getBug(bugId: string): Promise<Bug | null> {
    return this.repository.findByBugId(bugId);
  }

  /**
   * List bugs with filtering
   */
  async listBugs(query: ListBugsQuery): Promise<BugListResponse> {
    const { bugs, total } = await this.repository.list(query);

    return {
      bugs,
      total,
      limit: query.limit,
      offset: query.offset,
    };
  }

  /**
   * Update a bug
   */
  async updateBug(bugId: string, data: UpdateBugRequest): Promise<Bug | null> {
    // Get existing bug for comparison
    const existingBug = await this.repository.findByBugId(bugId);
    if (!existingBug) {
      return null;
    }

    // Check if assignee is changing
    const assigneeChanging =
      data.assigneeName !== undefined &&
      data.assigneeName !== existingBug.assigneeName;

    // Update the bug
    const updatedBug = await this.repository.update(bugId, data);

    // Notify new assignee if changed
    if (assigneeChanging && updatedBug?.assigneeName && updatedBug?.assigneeType) {
      await this.notifyAssignee(updatedBug, 'bug_reassigned', existingBug.assigneeName);
    }

    if (updatedBug) {
      logger.info({
        bugId,
        changes: Object.keys(data),
        assigneeChanged: assigneeChanging,
      }, 'Bug updated');
    }

    return updatedBug;
  }

  /**
   * Update bug status (convenience method)
   */
  async updateStatus(bugId: string, status: Bug['status']): Promise<Bug | null> {
    return this.updateBug(bugId, { status });
  }

  /**
   * Assign a bug to someone
   */
  async assignBug(
    bugId: string,
    assigneeType: 'agent' | 'principal',
    assigneeName: string
  ): Promise<Bug | null> {
    return this.updateBug(bugId, { assigneeType, assigneeName });
  }

  /**
   * Delete a bug
   */
  async deleteBug(bugId: string): Promise<boolean> {
    const deleted = await this.repository.delete(bugId);
    if (deleted) {
      logger.info({ bugId }, 'Bug deleted');
    }
    return deleted;
  }

  /**
   * Get dashboard stats
   */
  async getStats(): Promise<{
    total: number;
    open: number;
    inProgress: number;
    fixed: number;
  }> {
    return this.repository.getStats();
  }

  /**
   * Notify assignee about a bug
   */
  private async notifyAssignee(
    bug: Bug,
    type: 'bug_assigned' | 'bug_reassigned',
    previousAssignee?: string | null
  ): Promise<void> {
    if (!bug.assigneeName || !bug.assigneeType) {
      return;
    }

    const subject =
      type === 'bug_assigned'
        ? `[${bug.bugId}] New bug assigned to you`
        : `[${bug.bugId}] Bug reassigned to you`;

    let body = `You have been ${type === 'bug_assigned' ? 'assigned a new bug' : 'assigned a bug'}.

Bug ID: ${bug.bugId}
Summary: ${bug.summary}
Reporter: ${bug.reporterName} (${bug.reporterType})
Workstream: ${bug.workstream}`;

    if (bug.description) {
      body += `\n\nDescription:\n${bug.description}`;
    }

    if (type === 'bug_reassigned' && previousAssignee) {
      body += `\n\nPreviously assigned to: ${previousAssignee}`;
    }

    body += `\n\nView in BugBench or run: ./tools/show-bug ${bug.bugId}`;

    // Queue notification if queue is available
    if (this.queue) {
      try {
        await this.queue.enqueue<NotificationJobData>('notifications', {
          data: {
            type,
            bugId: bug.bugId,
            recipientType: bug.assigneeType,
            recipientName: bug.assigneeName,
            subject,
            body,
          },
        });
        logger.debug({ bugId: bug.bugId, assignee: bug.assigneeName }, 'Notification queued');
      } catch (error) {
        // Log but don't fail - notification is not critical
        logger.warn({ error, bugId: bug.bugId }, 'Failed to queue notification');
      }
    } else {
      // Direct notification (sync) - for when queue is not configured
      logger.info({
        bugId: bug.bugId,
        to: `${bug.assigneeType}:${bug.assigneeName}`,
        subject,
      }, 'Notification (queue not available, logging only)');
    }
  }
}
