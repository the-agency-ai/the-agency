/**
 * Dispatch Repository
 *
 * Data access layer for dispatch queue and instance registry.
 * Handles atomic claiming, TTL expiry, and tiered queue lookup.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import type {
  DispatchItem,
  DispatchInstance,
  EnqueueItemInput,
  ClaimItemInput,
  ListDispatchQuery,
  RegisterInstanceInput,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('dispatch-repository');

/**
 * Database row types
 */
interface DispatchItemRow {
  id: string;
  queue_type: string;
  agent_name: string | null;
  work_type: string;
  work_id: string | null;
  title: string;
  description: string | null;
  prompt: string | null;
  priority: number;
  status: string;
  claimed_by: string | null;
  claimed_at: string | null;
  claim_expires_at: string | null;
  created_at: string;
  started_at: string | null;
  completed_at: string | null;
  error: string | null;
  result: string | null;
  source: string | null;
  metadata: string;
}

interface DispatchInstanceRow {
  id: string;
  agent_name: string;
  workstream: string | null;
  pid: number | null;
  status: string;
  current_item_id: string | null;
  last_heartbeat: string;
  registered_at: string;
  metadata: string;
}

function rowToItem(row: DispatchItemRow): DispatchItem {
  return {
    id: row.id,
    queueType: row.queue_type as DispatchItem['queueType'],
    agentName: row.agent_name,
    workType: row.work_type as DispatchItem['workType'],
    workId: row.work_id,
    title: row.title,
    description: row.description,
    prompt: row.prompt,
    priority: row.priority,
    status: row.status as DispatchItem['status'],
    claimedBy: row.claimed_by,
    claimedAt: row.claimed_at,
    claimExpiresAt: row.claim_expires_at,
    createdAt: row.created_at,
    startedAt: row.started_at,
    completedAt: row.completed_at,
    error: row.error,
    result: row.result,
    source: row.source,
    metadata: JSON.parse(row.metadata || '{}'),
  };
}

function rowToInstance(row: DispatchInstanceRow): DispatchInstance {
  return {
    id: row.id,
    agentName: row.agent_name,
    workstream: row.workstream,
    pid: row.pid,
    status: row.status as DispatchInstance['status'],
    currentItemId: row.current_item_id,
    lastHeartbeat: row.last_heartbeat,
    registeredAt: row.registered_at,
    metadata: JSON.parse(row.metadata || '{}'),
  };
}

export class DispatchRepository {
  constructor(private db: DatabaseAdapter) {}

  /**
   * Initialize dispatch schema
   */
  async initialize(): Promise<void> {
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS dispatch_items (
        id TEXT PRIMARY KEY,
        queue_type TEXT NOT NULL DEFAULT 'agent',
        agent_name TEXT,
        work_type TEXT NOT NULL DEFAULT 'custom',
        work_id TEXT,
        title TEXT NOT NULL,
        description TEXT,
        prompt TEXT,
        priority INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        claimed_by TEXT,
        claimed_at TEXT,
        claim_expires_at TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        started_at TEXT,
        completed_at TEXT,
        error TEXT,
        result TEXT,
        source TEXT,
        metadata TEXT DEFAULT '{}'
      )
    `);

    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS dispatch_instances (
        id TEXT PRIMARY KEY,
        agent_name TEXT NOT NULL,
        workstream TEXT,
        pid INTEGER,
        status TEXT NOT NULL DEFAULT 'active',
        current_item_id TEXT,
        last_heartbeat TEXT DEFAULT (datetime('now')),
        registered_at TEXT DEFAULT (datetime('now')),
        metadata TEXT DEFAULT '{}'
      )
    `);

    // Indexes for dispatch items
    await this.db.execute(`
      CREATE INDEX IF NOT EXISTS idx_dispatch_agent_pending
        ON dispatch_items(agent_name, priority DESC, created_at ASC)
        WHERE status = 'pending'
    `);

    await this.db.execute(`
      CREATE INDEX IF NOT EXISTS idx_dispatch_shared_pending
        ON dispatch_items(priority DESC, created_at ASC)
        WHERE queue_type = 'shared' AND status = 'pending'
    `);

    await this.db.execute(`
      CREATE INDEX IF NOT EXISTS idx_dispatch_status
        ON dispatch_items(status)
    `);

    await this.db.execute(`
      CREATE INDEX IF NOT EXISTS idx_dispatch_claimed_by
        ON dispatch_items(claimed_by)
        WHERE claimed_by IS NOT NULL
    `);

    // Indexes for instances
    await this.db.execute(`
      CREATE INDEX IF NOT EXISTS idx_dispatch_instances_agent
        ON dispatch_instances(agent_name)
    `);

    await this.db.execute(`
      CREATE INDEX IF NOT EXISTS idx_dispatch_instances_status
        ON dispatch_instances(status)
    `);

    logger.info('Dispatch schema initialized');
  }

  /**
   * Generate a UUID
   */
  private generateId(): string {
    return crypto.randomUUID();
  }

  // ==================== Dispatch Items ====================

  /**
   * Enqueue a work item
   */
  async enqueue(data: EnqueueItemInput): Promise<DispatchItem> {
    const id = this.generateId();

    await this.db.execute(
      `INSERT INTO dispatch_items
         (id, queue_type, agent_name, work_type, work_id, title, description, prompt, priority, source, metadata)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        data.queueType,
        data.agentName || null,
        data.workType,
        data.workId || null,
        data.title,
        data.description || null,
        data.prompt || null,
        data.priority,
        data.source || null,
        JSON.stringify(data.metadata || {}),
      ]
    );

    const item = await this.findById(id);
    if (!item) {
      throw new Error('Failed to enqueue item');
    }

    logger.info({ itemId: id, queue: data.queueType, agent: data.agentName }, 'Item enqueued');
    return item;
  }

  /**
   * Find item by ID
   */
  async findById(id: string): Promise<DispatchItem | null> {
    const row = await this.db.get<DispatchItemRow>(
      'SELECT * FROM dispatch_items WHERE id = ?',
      [id]
    );
    return row ? rowToItem(row) : null;
  }

  /**
   * Claim next available item for an agent (agent queue first, then shared)
   */
  async claim(data: ClaimItemInput): Promise<DispatchItem | null> {
    const expiresAt = new Date(Date.now() + data.ttlMinutes * 60 * 1000).toISOString();

    // First: try agent-specific queue
    let row = await this.db.get<DispatchItemRow>(
      `UPDATE dispatch_items
       SET status = 'claimed',
           claimed_by = ?,
           claimed_at = datetime('now'),
           claim_expires_at = ?
       WHERE id = (
         SELECT id FROM dispatch_items
         WHERE queue_type = 'agent'
           AND agent_name = ?
           AND status = 'pending'
         ORDER BY priority DESC, created_at ASC
         LIMIT 1
       )
       RETURNING *`,
      [data.agentName, expiresAt, data.agentName]
    );

    // Second: try shared queue
    if (!row) {
      row = await this.db.get<DispatchItemRow>(
        `UPDATE dispatch_items
         SET status = 'claimed',
             claimed_by = ?,
             claimed_at = datetime('now'),
             claim_expires_at = ?
         WHERE id = (
           SELECT id FROM dispatch_items
           WHERE queue_type = 'shared'
             AND status = 'pending'
           ORDER BY priority DESC, created_at ASC
           LIMIT 1
         )
         RETURNING *`,
        [data.agentName, expiresAt]
      );
    }

    if (!row) {
      return null;
    }

    const item = rowToItem(row);

    // Update instance's current item if instanceId provided
    if (data.instanceId) {
      await this.db.update(
        `UPDATE dispatch_instances SET current_item_id = ? WHERE id = ?`,
        [item.id, data.instanceId]
      );
    }

    logger.info({ itemId: item.id, agent: data.agentName }, 'Item claimed');
    return item;
  }

  /**
   * Release a claimed item back to pending
   */
  async release(id: string): Promise<boolean> {
    const changes = await this.db.update(
      `UPDATE dispatch_items
       SET status = 'pending',
           claimed_by = NULL,
           claimed_at = NULL,
           claim_expires_at = NULL
       WHERE id = ? AND status IN ('claimed', 'active')`,
      [id]
    );

    if (changes > 0) {
      logger.info({ itemId: id }, 'Item released');
    }
    return changes > 0;
  }

  /**
   * Mark item as active (work started)
   */
  async activate(id: string): Promise<boolean> {
    const changes = await this.db.update(
      `UPDATE dispatch_items
       SET status = 'active', started_at = datetime('now')
       WHERE id = ? AND status = 'claimed'`,
      [id]
    );
    return changes > 0;
  }

  /**
   * Complete an item
   */
  async complete(id: string, result?: string): Promise<boolean> {
    const changes = await this.db.update(
      `UPDATE dispatch_items
       SET status = 'completed',
           completed_at = datetime('now'),
           result = ?
       WHERE id = ? AND status IN ('claimed', 'active')`,
      [result || null, id]
    );

    if (changes > 0) {
      logger.info({ itemId: id }, 'Item completed');
    }
    return changes > 0;
  }

  /**
   * Fail an item
   */
  async fail(id: string, error: string): Promise<boolean> {
    const changes = await this.db.update(
      `UPDATE dispatch_items
       SET status = 'failed',
           completed_at = datetime('now'),
           error = ?
       WHERE id = ? AND status IN ('claimed', 'active')`,
      [error, id]
    );

    if (changes > 0) {
      logger.info({ itemId: id, error }, 'Item failed');
    }
    return changes > 0;
  }

  /**
   * Cancel a pending item
   */
  async cancel(id: string): Promise<boolean> {
    const changes = await this.db.update(
      `UPDATE dispatch_items
       SET status = 'cancelled', completed_at = datetime('now')
       WHERE id = ? AND status = 'pending'`,
      [id]
    );

    if (changes > 0) {
      logger.info({ itemId: id }, 'Item cancelled');
    }
    return changes > 0;
  }

  /**
   * Peek at next available item without claiming
   */
  async peekNext(agentName: string): Promise<DispatchItem | null> {
    // Try agent queue first
    let row = await this.db.get<DispatchItemRow>(
      `SELECT * FROM dispatch_items
       WHERE queue_type = 'agent'
         AND agent_name = ?
         AND status = 'pending'
       ORDER BY priority DESC, created_at ASC
       LIMIT 1`,
      [agentName]
    );

    // Then shared queue
    if (!row) {
      row = await this.db.get<DispatchItemRow>(
        `SELECT * FROM dispatch_items
         WHERE queue_type = 'shared'
           AND status = 'pending'
         ORDER BY priority DESC, created_at ASC
         LIMIT 1`,
      );
    }

    return row ? rowToItem(row) : null;
  }

  /**
   * List dispatch items with filtering
   */
  async list(query: ListDispatchQuery): Promise<{ items: DispatchItem[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];

    if (query.agentName) {
      conditions.push('(agent_name = ? OR claimed_by = ?)');
      params.push(query.agentName, query.agentName);
    }

    if (query.status) {
      conditions.push('status = ?');
      params.push(query.status);
    }

    if (query.queueType) {
      conditions.push('queue_type = ?');
      params.push(query.queueType);
    }

    if (query.workType) {
      conditions.push('work_type = ?');
      params.push(query.workType);
    }

    const whereClause = conditions.length > 0
      ? `WHERE ${conditions.join(' AND ')}`
      : '';

    const countSql = 'SELECT COUNT(*) as count FROM dispatch_items ' + whereClause;
    const countRow = await this.db.get<{ count: number }>(countSql, params);
    const total = countRow?.count ?? 0;

    const listSql = 'SELECT * FROM dispatch_items ' + whereClause +
      ' ORDER BY priority DESC, created_at ASC LIMIT ? OFFSET ?';
    const rows = await this.db.query<DispatchItemRow>(
      listSql,
      [...params, query.limit, query.offset]
    );

    return {
      items: rows.map(rowToItem),
      total,
    };
  }

  /**
   * Sweep expired claims back to pending
   */
  async sweepExpiredClaims(): Promise<number> {
    const changes = await this.db.update(
      `UPDATE dispatch_items
       SET status = 'pending',
           claimed_by = NULL,
           claimed_at = NULL,
           claim_expires_at = NULL
       WHERE status = 'claimed'
         AND claim_expires_at < datetime('now')`
    );

    if (changes > 0) {
      logger.info({ count: changes }, 'Expired claims swept');
    }
    return changes;
  }

  /**
   * Get queue statistics
   */
  async getStats(): Promise<{
    total: number;
    pending: number;
    claimed: number;
    active: number;
    completed: number;
    failed: number;
    cancelled: number;
    activeInstances: number;
  }> {
    const itemStats = await this.db.get<{
      total: number;
      pending: number;
      claimed: number;
      active: number;
      completed: number;
      failed: number;
      cancelled: number;
    }>(
      `SELECT
         COUNT(*) as total,
         SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
         SUM(CASE WHEN status = 'claimed' THEN 1 ELSE 0 END) as claimed,
         SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active,
         SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
         SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
         SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled
       FROM dispatch_items`
    );

    const instanceStats = await this.db.get<{ count: number }>(
      `SELECT COUNT(*) as count FROM dispatch_instances WHERE status IN ('active', 'idle')`
    );

    return {
      total: itemStats?.total ?? 0,
      pending: itemStats?.pending ?? 0,
      claimed: itemStats?.claimed ?? 0,
      active: itemStats?.active ?? 0,
      completed: itemStats?.completed ?? 0,
      failed: itemStats?.failed ?? 0,
      cancelled: itemStats?.cancelled ?? 0,
      activeInstances: instanceStats?.count ?? 0,
    };
  }

  // ==================== Instance Registry ====================

  /**
   * Register an instance
   */
  async registerInstance(data: RegisterInstanceInput): Promise<DispatchInstance> {
    // Upsert: update if exists, insert if not
    await this.db.execute(
      `INSERT INTO dispatch_instances (id, agent_name, workstream, pid, status, metadata)
       VALUES (?, ?, ?, ?, 'active', ?)
       ON CONFLICT(id) DO UPDATE SET
         agent_name = excluded.agent_name,
         workstream = excluded.workstream,
         pid = excluded.pid,
         status = 'active',
         last_heartbeat = datetime('now'),
         metadata = excluded.metadata`,
      [
        data.id,
        data.agentName,
        data.workstream || null,
        data.pid || null,
        JSON.stringify(data.metadata || {}),
      ]
    );

    const instance = await this.findInstance(data.id);
    if (!instance) {
      throw new Error('Failed to register instance');
    }

    logger.info({ instanceId: data.id, agent: data.agentName }, 'Instance registered');
    return instance;
  }

  /**
   * Find instance by ID
   */
  async findInstance(id: string): Promise<DispatchInstance | null> {
    const row = await this.db.get<DispatchInstanceRow>(
      'SELECT * FROM dispatch_instances WHERE id = ?',
      [id]
    );
    return row ? rowToInstance(row) : null;
  }

  /**
   * Heartbeat: update last_heartbeat
   */
  async heartbeat(id: string): Promise<boolean> {
    const changes = await this.db.update(
      `UPDATE dispatch_instances SET last_heartbeat = datetime('now') WHERE id = ?`,
      [id]
    );
    return changes > 0;
  }

  /**
   * Deregister an instance
   */
  async deregisterInstance(id: string): Promise<boolean> {
    const changes = await this.db.delete(
      'DELETE FROM dispatch_instances WHERE id = ?',
      [id]
    );

    if (changes > 0) {
      logger.info({ instanceId: id }, 'Instance deregistered');
    }
    return changes > 0;
  }

  /**
   * Release all claims held by an instance
   */
  async releaseAllByInstance(instanceId: string): Promise<number> {
    // Find the agent name for this instance
    const instance = await this.findInstance(instanceId);
    if (!instance) return 0;

    const changes = await this.db.update(
      `UPDATE dispatch_items
       SET status = 'pending',
           claimed_by = NULL,
           claimed_at = NULL,
           claim_expires_at = NULL
       WHERE claimed_by = ? AND status IN ('claimed', 'active')`,
      [instance.agentName]
    );

    // Clear current item on instance
    await this.db.update(
      `UPDATE dispatch_instances SET current_item_id = NULL WHERE id = ?`,
      [instanceId]
    );

    if (changes > 0) {
      logger.info({ instanceId, count: changes }, 'Released all claims for instance');
    }
    return changes;
  }

  /**
   * List instances
   */
  async listInstances(): Promise<DispatchInstance[]> {
    const rows = await this.db.query<DispatchInstanceRow>(
      'SELECT * FROM dispatch_instances ORDER BY registered_at DESC'
    );
    return rows.map(rowToInstance);
  }
}
