/**
 * Product Service
 *
 * Business logic for PRD management.
 */

import type { DatabaseAdapter } from '../../../core/adapters/database';
import { ProductRepository } from '../repository/product.repository';
import type {
  Product,
  ProductWithContributors,
  ProductContributor,
  CreateProductRequest,
  UpdateProductRequest,
  ListProductsQuery,
  AddContributorRequest,
  ProductStats,
} from '../types';

export class ProductService {
  private repository: ProductRepository;

  constructor(db: DatabaseAdapter) {
    this.repository = new ProductRepository(db);
  }

  async initialize(): Promise<void> {
    await this.repository.initialize();
  }

  async create(data: CreateProductRequest): Promise<Product> {
    return this.repository.create(data);
  }

  async get(id: string): Promise<ProductWithContributors | null> {
    return this.repository.getById(id);
  }

  async update(id: string, data: UpdateProductRequest): Promise<Product | null> {
    return this.repository.update(id, data);
  }

  async list(query: ListProductsQuery): Promise<{ products: ProductWithContributors[]; total: number }> {
    return this.repository.list(query);
  }

  async addContributor(productId: string, data: AddContributorRequest): Promise<ProductContributor | null> {
    return this.repository.addContributor(productId, data);
  }

  async removeContributor(productId: string, contributorName: string): Promise<boolean> {
    return this.repository.removeContributor(productId, contributorName);
  }

  async approve(productId: string, approvedBy: string): Promise<Product | null> {
    return this.repository.approve(productId, approvedBy);
  }

  async archive(productId: string): Promise<Product | null> {
    return this.repository.archive(productId);
  }

  async delete(productId: string): Promise<boolean> {
    return this.repository.delete(productId);
  }

  async getStats(): Promise<ProductStats> {
    return this.repository.getStats();
  }
}
