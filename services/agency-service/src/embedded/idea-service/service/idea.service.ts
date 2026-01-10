/**
 * Idea Service
 *
 * Business logic layer for idea management.
 * Handles validation, promotion workflow, and orchestration.
 */

import type { Idea, CreateIdeaRequest, UpdateIdeaRequest, ListIdeasQuery, IdeaListResponse } from '../types';
import type { IdeaRepository } from '../repository/idea.repository';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('idea-service');

export class IdeaService {
  constructor(private repository: IdeaRepository) {}

  /**
   * Create a new idea (quick capture)
   */
  async createIdea(data: CreateIdeaRequest): Promise<Idea> {
    // Generate idea ID
    const ideaId = await this.repository.getNextIdeaId();

    // Create the idea
    const idea = await this.repository.create(ideaId, data);

    logger.info({ ideaId: idea.ideaId, source: idea.sourceName }, 'Idea captured');
    return idea;
  }

  /**
   * Get an idea by its idea ID
   */
  async getIdea(ideaId: string): Promise<Idea | null> {
    return this.repository.findByIdeaId(ideaId);
  }

  /**
   * List ideas with filtering
   */
  async listIdeas(query: ListIdeasQuery): Promise<IdeaListResponse> {
    const { ideas, total } = await this.repository.list(query);

    return {
      ideas,
      total,
      limit: query.limit,
      offset: query.offset,
    };
  }

  /**
   * Update an idea
   */
  async updateIdea(ideaId: string, data: UpdateIdeaRequest): Promise<Idea | null> {
    const existingIdea = await this.repository.findByIdeaId(ideaId);
    if (!existingIdea) {
      return null;
    }

    // Cannot update a promoted idea (except to park/discard)
    if (existingIdea.status === 'promoted' && data.status !== 'parked' && data.status !== 'discarded') {
      logger.warn({ ideaId }, 'Cannot update promoted idea');
      return existingIdea;
    }

    const updatedIdea = await this.repository.update(ideaId, data);

    if (updatedIdea) {
      logger.info({
        ideaId,
        changes: Object.keys(data),
      }, 'Idea updated');
    }

    return updatedIdea;
  }

  /**
   * Update idea status (convenience method)
   */
  async updateStatus(ideaId: string, status: Idea['status']): Promise<Idea | null> {
    return this.updateIdea(ideaId, { status });
  }

  /**
   * Add tags to an idea
   */
  async addTags(ideaId: string, newTags: string[]): Promise<Idea | null> {
    const existingIdea = await this.repository.findByIdeaId(ideaId);
    if (!existingIdea) {
      return null;
    }

    const combinedTags = [...new Set([...existingIdea.tags, ...newTags])];
    return this.updateIdea(ideaId, { tags: combinedTags });
  }

  /**
   * Remove tags from an idea
   */
  async removeTags(ideaId: string, tagsToRemove: string[]): Promise<Idea | null> {
    const existingIdea = await this.repository.findByIdeaId(ideaId);
    if (!existingIdea) {
      return null;
    }

    const filteredTags = existingIdea.tags.filter(t => !tagsToRemove.includes(t));
    return this.updateIdea(ideaId, { tags: filteredTags });
  }

  /**
   * Promote an idea to a REQUEST
   * This marks the idea as promoted and links it to the created request
   */
  async promoteIdea(ideaId: string, requestId: string): Promise<Idea | null> {
    const existingIdea = await this.repository.findByIdeaId(ideaId);
    if (!existingIdea) {
      return null;
    }

    // Cannot promote an already promoted or discarded idea
    if (existingIdea.status === 'promoted') {
      logger.warn({ ideaId }, 'Idea already promoted');
      return existingIdea;
    }

    if (existingIdea.status === 'discarded') {
      logger.warn({ ideaId }, 'Cannot promote discarded idea');
      return null;
    }

    const promotedIdea = await this.repository.promote(ideaId, requestId);

    if (promotedIdea) {
      logger.info({
        ideaId,
        requestId,
      }, 'Idea promoted to request');
    }

    return promotedIdea;
  }

  /**
   * Park an idea (save for later)
   */
  async parkIdea(ideaId: string): Promise<Idea | null> {
    return this.updateStatus(ideaId, 'parked');
  }

  /**
   * Discard an idea
   */
  async discardIdea(ideaId: string): Promise<Idea | null> {
    return this.updateStatus(ideaId, 'discarded');
  }

  /**
   * Start exploring an idea
   */
  async exploreIdea(ideaId: string): Promise<Idea | null> {
    return this.updateStatus(ideaId, 'exploring');
  }

  /**
   * Delete an idea
   */
  async deleteIdea(ideaId: string): Promise<boolean> {
    const deleted = await this.repository.delete(ideaId);
    if (deleted) {
      logger.info({ ideaId }, 'Idea deleted');
    }
    return deleted;
  }

  /**
   * Get dashboard stats
   */
  async getStats(): Promise<{
    total: number;
    captured: number;
    exploring: number;
    promoted: number;
    parked: number;
    discarded: number;
  }> {
    return this.repository.getStats();
  }
}
