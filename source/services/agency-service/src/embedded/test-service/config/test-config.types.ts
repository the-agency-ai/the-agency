/**
 * Test Configuration Types
 *
 * Zod schemas for test configuration file structure.
 */

import { z } from 'zod';

/**
 * Safe identifier pattern: alphanumeric, hyphens, underscores only
 */
const safeIdPattern = /^[a-zA-Z0-9_-]+$/;

/**
 * Test runner schema
 */
export const testRunnerSchema = z.object({
  id: z.string().regex(safeIdPattern, 'Runner ID must be alphanumeric with hyphens/underscores'),
  command: z.array(z.string()).min(1, 'Command must have at least one element'),
  outputFormat: z.enum(['bun', 'jest', 'tap', 'raw']).default('bun'),
});

export type TestRunner = z.infer<typeof testRunnerSchema>;

/**
 * Test target schema
 */
export const testTargetSchema = z.object({
  id: z.string().regex(safeIdPattern, 'Target ID must be alphanumeric with hyphens/underscores'),
  path: z.string().min(1, 'Target path is required'),
  runner: z.string().regex(safeIdPattern, 'Runner ID must be alphanumeric'),
  description: z.string().optional(),
});

export type TestTarget = z.infer<typeof testTargetSchema>;

/**
 * Test suite configuration schema
 */
export const testSuiteConfigSchema = z.object({
  id: z.string().regex(safeIdPattern, 'Suite ID must be alphanumeric with hyphens/underscores'),
  name: z.string().min(1, 'Suite name is required'),
  target: z.string().regex(safeIdPattern, 'Target ID must be alphanumeric'),
  path: z.string().min(1, 'Suite path is required'),
  tags: z.array(z.string()).default([]),
  enabled: z.boolean().default(true),
});

export type TestSuiteConfig = z.infer<typeof testSuiteConfigSchema>;

/**
 * Full test configuration schema
 */
export const testConfigSchema = z.object({
  version: z.string().default('1.0'),
  runners: z.array(testRunnerSchema).min(1, 'At least one runner is required'),
  targets: z.array(testTargetSchema).min(1, 'At least one target is required'),
  suites: z.array(testSuiteConfigSchema).default([]),
});

export type TestConfig = z.infer<typeof testConfigSchema>;

/**
 * Discovered suite (not yet registered)
 */
export interface DiscoveredSuite {
  id: string;
  name: string;
  target: string;
  path: string;
  testFileCount: number;
  registered: boolean;
}

/**
 * Validation result for config references
 */
export interface ConfigValidationResult {
  valid: boolean;
  errors: string[];
}
