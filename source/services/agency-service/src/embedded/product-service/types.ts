/**
 * Product Service Types
 *
 * Types for PRD (Product Requirement Document) management.
 */

import { z } from 'zod';

/**
 * Product/PRD status
 */
export type ProductStatus = 'Draft' | 'Review' | 'Approved' | 'In Progress' | 'Complete' | 'Archived';

/**
 * Product priority
 */
export type ProductPriority = 'P0' | 'P1' | 'P2' | 'P3';

/**
 * Contributor role
 */
export type ContributorRole = 'owner' | 'contributor' | 'reviewer';

/**
 * Product/PRD entity
 */
export interface Product {
  id: string;
  prdId: string; // PRD-XXXX format
  title: string;
  summary: string;
  status: ProductStatus;
  priority: ProductPriority;
  workstream?: string;
  ownerType: 'principal' | 'agent';
  ownerName: string;
  createdAt: Date;
  updatedAt: Date;
  approvedAt?: Date;
  approvedBy?: string;
}

/**
 * Product contributor
 */
export interface ProductContributor {
  id: string;
  productId: string;
  contributorType: 'principal' | 'agent';
  contributorName: string;
  role: ContributorRole;
  addedAt: Date;
}

/**
 * Product with contributors
 */
export interface ProductWithContributors extends Product {
  contributors: ProductContributor[];
}

/**
 * Create product request
 */
export interface CreateProductRequest {
  title: string;
  summary: string;
  priority?: ProductPriority;
  workstream?: string;
  ownerType?: 'principal' | 'agent';
  ownerName?: string;
}

/**
 * Update product request
 */
export interface UpdateProductRequest {
  title?: string;
  summary?: string;
  status?: ProductStatus;
  priority?: ProductPriority;
  workstream?: string;
}

/**
 * List products query
 */
export interface ListProductsQuery {
  status?: ProductStatus;
  priority?: ProductPriority;
  workstream?: string;
  owner?: string;
  limit?: number;
  offset?: number;
}

/**
 * Add contributor request
 */
export interface AddContributorRequest {
  contributorType: 'principal' | 'agent';
  contributorName: string;
  role?: ContributorRole;
}

/**
 * Product stats
 */
export interface ProductStats {
  total: number;
  byStatus: Record<ProductStatus, number>;
  byPriority: Record<ProductPriority, number>;
}

// Zod schemas for validation

export const createProductSchema = z.object({
  title: z.string().min(1).max(200),
  summary: z.string().min(1).max(5000),
  priority: z.enum(['P0', 'P1', 'P2', 'P3']).optional().default('P2'),
  workstream: z.string().optional(),
  ownerType: z.enum(['principal', 'agent']).optional(),
  ownerName: z.string().optional(),
});

export const updateProductSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  summary: z.string().min(1).max(5000).optional(),
  status: z.enum(['Draft', 'Review', 'Approved', 'In Progress', 'Complete', 'Archived']).optional(),
  priority: z.enum(['P0', 'P1', 'P2', 'P3']).optional(),
  workstream: z.string().optional(),
});

export const listProductsQuerySchema = z.object({
  status: z.enum(['Draft', 'Review', 'Approved', 'In Progress', 'Complete', 'Archived']).optional(),
  priority: z.enum(['P0', 'P1', 'P2', 'P3']).optional(),
  workstream: z.string().optional(),
  owner: z.string().optional(),
  limit: z.coerce.number().min(1).max(100).optional().default(50),
  offset: z.coerce.number().min(0).optional().default(0),
});

export const addContributorSchema = z.object({
  contributorType: z.enum(['principal', 'agent']),
  contributorName: z.string().min(1),
  role: z.enum(['owner', 'contributor', 'reviewer']).optional().default('contributor'),
});

export const removeContributorSchema = z.object({
  contributorName: z.string().min(1),
});
