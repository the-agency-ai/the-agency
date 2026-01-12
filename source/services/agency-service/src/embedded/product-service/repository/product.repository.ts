/**
 * Product Repository
 *
 * Data access layer for products/PRDs.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import type {
  Product,
  ProductContributor,
  ProductWithContributors,
  CreateProductRequest,
  UpdateProductRequest,
  ListProductsQuery,
  AddContributorRequest,
  ProductStats,
  ProductStatus,
  ProductPriority,
} from '../types';
import { createServiceLogger } from '../../../core/lib/logger';

const logger = createServiceLogger('product-repository');

interface ProductRow {
  id: string;
  prd_id: string;
  title: string;
  summary: string;
  status: string;
  priority: string;
  workstream: string | null;
  owner_type: string;
  owner_name: string;
  created_at: string;
  updated_at: string;
  approved_at: string | null;
  approved_by: string | null;
}

interface ContributorRow {
  id: string;
  product_id: string;
  contributor_type: string;
  contributor_name: string;
  role: string;
  added_at: string;
}

interface SequenceRow {
  next_id: number;
}

interface CountRow {
  count: number;
}

interface StatusCountRow {
  status: string;
  count: number;
}

interface PriorityCountRow {
  priority: string;
  count: number;
}

function rowToProduct(row: ProductRow): Product {
  return {
    id: row.id,
    prdId: row.prd_id,
    title: row.title,
    summary: row.summary,
    status: row.status as ProductStatus,
    priority: row.priority as ProductPriority,
    workstream: row.workstream || undefined,
    ownerType: row.owner_type as 'principal' | 'agent',
    ownerName: row.owner_name,
    createdAt: new Date(row.created_at),
    updatedAt: new Date(row.updated_at),
    approvedAt: row.approved_at ? new Date(row.approved_at) : undefined,
    approvedBy: row.approved_by || undefined,
  };
}

function rowToContributor(row: ContributorRow): ProductContributor {
  return {
    id: row.id,
    productId: row.product_id,
    contributorType: row.contributor_type as 'principal' | 'agent',
    contributorName: row.contributor_name,
    role: row.role as 'owner' | 'contributor' | 'reviewer',
    addedAt: new Date(row.added_at),
  };
}

export class ProductRepository {
  constructor(private db: DatabaseAdapter) {}

  async initialize(): Promise<void> {
    // Products table
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        prd_id TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Draft',
        priority TEXT NOT NULL DEFAULT 'P2',
        workstream TEXT,
        owner_type TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        approved_at TEXT,
        approved_by TEXT
      )
    `);

    // Contributors table
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS product_contributors (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        contributor_type TEXT NOT NULL,
        contributor_name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'contributor',
        added_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
        UNIQUE(product_id, contributor_name)
      )
    `);

    // Sequence table
    await this.db.execute(`
      CREATE TABLE IF NOT EXISTS product_sequences (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        next_id INTEGER NOT NULL DEFAULT 1
      )
    `);

    // Initialize sequence if not exists
    await this.db.execute(`
      INSERT OR IGNORE INTO product_sequences (id, next_id) VALUES (1, 1)
    `);

    // Indexes
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_products_status ON products(status)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_products_priority ON products(priority)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_products_owner ON products(owner_name)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_products_workstream ON products(workstream)`);
    await this.db.execute(`CREATE INDEX IF NOT EXISTS idx_contributors_product ON product_contributors(product_id)`);

    logger.info('Product schema initialized');
  }

  async getNextPrdId(): Promise<string> {
    // Atomic increment - UPDATE first, then SELECT the previous value
    await this.db.execute(
      'UPDATE product_sequences SET next_id = next_id + 1 WHERE id = 1'
    );

    const row = await this.db.get<SequenceRow>(
      'SELECT next_id - 1 as next_id FROM product_sequences WHERE id = 1'
    );

    const nextId = row?.next_id || 1;
    return `PRD-${String(nextId).padStart(4, '0')}`;
  }

  async create(data: CreateProductRequest): Promise<Product> {
    const id = crypto.randomUUID();
    const prdId = await this.getNextPrdId();
    const now = new Date().toISOString();

    await this.db.execute(
      `INSERT INTO products (id, prd_id, title, summary, status, priority, workstream, owner_type, owner_name, created_at, updated_at)
       VALUES (?, ?, ?, ?, 'Draft', ?, ?, ?, ?, ?, ?)`,
      [
        id,
        prdId,
        data.title,
        data.summary,
        data.priority || 'P2',
        data.workstream || null,
        data.ownerType || 'principal',
        data.ownerName || 'unknown',
        now,
        now,
      ]
    );

    // Add owner as contributor
    await this.db.execute(
      `INSERT INTO product_contributors (id, product_id, contributor_type, contributor_name, role, added_at)
       VALUES (?, ?, ?, ?, 'owner', ?)`,
      [
        crypto.randomUUID(),
        id,
        data.ownerType || 'principal',
        data.ownerName || 'unknown',
        now,
      ]
    );

    const row = await this.db.get<ProductRow>(
      'SELECT * FROM products WHERE id = ?',
      [id]
    );

    logger.info({ prdId, title: data.title }, 'Product created');
    return rowToProduct(row!);
  }

  async getById(id: string): Promise<ProductWithContributors | null> {
    // Try by UUID or PRD-XXXX
    const row = await this.db.get<ProductRow>(
      'SELECT * FROM products WHERE id = ? OR prd_id = ?',
      [id, id]
    );

    if (!row) return null;

    const contributorRows = await this.db.query<ContributorRow>(
      'SELECT * FROM product_contributors WHERE product_id = ? ORDER BY added_at',
      [row.id]
    );

    return {
      ...rowToProduct(row),
      contributors: contributorRows.map(rowToContributor),
    };
  }

  async update(id: string, data: UpdateProductRequest): Promise<Product | null> {
    const existing = await this.db.get<ProductRow>(
      'SELECT * FROM products WHERE id = ? OR prd_id = ?',
      [id, id]
    );

    if (!existing) return null;

    const updates: string[] = ['updated_at = datetime("now")'];
    const params: unknown[] = [];

    if (data.title !== undefined) {
      updates.push('title = ?');
      params.push(data.title);
    }
    if (data.summary !== undefined) {
      updates.push('summary = ?');
      params.push(data.summary);
    }
    if (data.status !== undefined) {
      updates.push('status = ?');
      params.push(data.status);
    }
    if (data.priority !== undefined) {
      updates.push('priority = ?');
      params.push(data.priority);
    }
    if (data.workstream !== undefined) {
      updates.push('workstream = ?');
      params.push(data.workstream);
    }

    params.push(existing.id);

    await this.db.execute(
      `UPDATE products SET ${updates.join(', ')} WHERE id = ?`,
      params
    );

    const row = await this.db.get<ProductRow>(
      'SELECT * FROM products WHERE id = ?',
      [existing.id]
    );

    logger.info({ prdId: existing.prd_id, updates: Object.keys(data) }, 'Product updated');
    return rowToProduct(row!);
  }

  async list(query: ListProductsQuery): Promise<{ products: ProductWithContributors[]; total: number }> {
    const conditions: string[] = [];
    const params: unknown[] = [];

    if (query.status) {
      conditions.push('status = ?');
      params.push(query.status);
    }
    if (query.priority) {
      conditions.push('priority = ?');
      params.push(query.priority);
    }
    if (query.workstream) {
      conditions.push('workstream = ?');
      params.push(query.workstream);
    }
    if (query.owner) {
      conditions.push('owner_name = ?');
      params.push(query.owner);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    // Get total count
    const countRow = await this.db.get<CountRow>(
      `SELECT COUNT(*) as count FROM products ${whereClause}`,
      params
    );
    const total = countRow?.count || 0;

    // Get products
    const limit = query.limit || 50;
    const offset = query.offset || 0;

    const rows = await this.db.query<ProductRow>(
      `SELECT * FROM products ${whereClause} ORDER BY created_at DESC LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    );

    // Fetch contributors for each product
    const products: ProductWithContributors[] = [];
    for (const row of rows) {
      const contributorRows = await this.db.query<ContributorRow>(
        'SELECT * FROM product_contributors WHERE product_id = ?',
        [row.id]
      );
      products.push({
        ...rowToProduct(row),
        contributors: contributorRows.map(rowToContributor),
      });
    }

    return { products, total };
  }

  async addContributor(productId: string, data: AddContributorRequest): Promise<ProductContributor | null> {
    const product = await this.db.get<ProductRow>(
      'SELECT * FROM products WHERE id = ? OR prd_id = ?',
      [productId, productId]
    );

    if (!product) return null;

    const id = crypto.randomUUID();
    const now = new Date().toISOString();

    try {
      await this.db.execute(
        `INSERT INTO product_contributors (id, product_id, contributor_type, contributor_name, role, added_at)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [id, product.id, data.contributorType, data.contributorName, data.role || 'contributor', now]
      );
    } catch (e) {
      // Already exists
      logger.debug({ productId, contributor: data.contributorName }, 'Contributor already exists');
      return null;
    }

    const row = await this.db.get<ContributorRow>(
      'SELECT * FROM product_contributors WHERE id = ?',
      [id]
    );

    logger.info({ prdId: product.prd_id, contributor: data.contributorName }, 'Contributor added');
    return rowToContributor(row!);
  }

  async removeContributor(productId: string, contributorName: string): Promise<boolean> {
    const product = await this.db.get<ProductRow>(
      'SELECT * FROM products WHERE id = ? OR prd_id = ?',
      [productId, productId]
    );

    if (!product) return false;

    // Don't remove owner
    const contributor = await this.db.get<ContributorRow>(
      'SELECT * FROM product_contributors WHERE product_id = ? AND contributor_name = ?',
      [product.id, contributorName]
    );

    if (!contributor || contributor.role === 'owner') return false;

    await this.db.execute(
      'DELETE FROM product_contributors WHERE product_id = ? AND contributor_name = ?',
      [product.id, contributorName]
    );

    logger.info({ prdId: product.prd_id, contributor: contributorName }, 'Contributor removed');
    return true;
  }

  async approve(productId: string, approvedBy: string): Promise<Product | null> {
    const product = await this.db.get<ProductRow>(
      'SELECT * FROM products WHERE id = ? OR prd_id = ?',
      [productId, productId]
    );

    if (!product) return null;

    await this.db.execute(
      `UPDATE products SET status = 'Approved', approved_at = datetime('now'), approved_by = ?, updated_at = datetime('now') WHERE id = ?`,
      [approvedBy, product.id]
    );

    const row = await this.db.get<ProductRow>(
      'SELECT * FROM products WHERE id = ?',
      [product.id]
    );

    logger.info({ prdId: product.prd_id, approvedBy }, 'Product approved');
    return rowToProduct(row!);
  }

  async archive(productId: string): Promise<Product | null> {
    const product = await this.db.get<ProductRow>(
      'SELECT * FROM products WHERE id = ? OR prd_id = ?',
      [productId, productId]
    );

    if (!product) return null;

    await this.db.execute(
      `UPDATE products SET status = 'Archived', updated_at = datetime('now') WHERE id = ?`,
      [product.id]
    );

    const row = await this.db.get<ProductRow>(
      'SELECT * FROM products WHERE id = ?',
      [product.id]
    );

    logger.info({ prdId: product.prd_id }, 'Product archived');
    return rowToProduct(row!);
  }

  async delete(productId: string): Promise<boolean> {
    const product = await this.db.get<ProductRow>(
      'SELECT * FROM products WHERE id = ? OR prd_id = ?',
      [productId, productId]
    );

    if (!product) return false;

    await this.db.execute('DELETE FROM products WHERE id = ?', [product.id]);

    logger.info({ prdId: product.prd_id }, 'Product deleted');
    return true;
  }

  async getStats(): Promise<ProductStats> {
    const totalRow = await this.db.get<CountRow>('SELECT COUNT(*) as count FROM products');
    const total = totalRow?.count || 0;

    const statusRows = await this.db.query<StatusCountRow>(
      'SELECT status, COUNT(*) as count FROM products GROUP BY status'
    );

    const priorityRows = await this.db.query<PriorityCountRow>(
      'SELECT priority, COUNT(*) as count FROM products GROUP BY priority'
    );

    const byStatus: Record<ProductStatus, number> = {
      Draft: 0,
      Review: 0,
      Approved: 0,
      'In Progress': 0,
      Complete: 0,
      Archived: 0,
    };

    for (const row of statusRows) {
      byStatus[row.status as ProductStatus] = row.count;
    }

    const byPriority: Record<ProductPriority, number> = {
      P0: 0,
      P1: 0,
      P2: 0,
      P3: 0,
    };

    for (const row of priorityRows) {
      byPriority[row.priority as ProductPriority] = row.count;
    }

    return { total, byStatus, byPriority };
  }
}
