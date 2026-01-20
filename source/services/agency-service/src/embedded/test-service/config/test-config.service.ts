/**
 * Test Configuration Service
 *
 * Manages test configuration from YAML file.
 */

import { readFile, writeFile, mkdir } from 'fs/promises';
import { join, dirname, resolve, relative } from 'path';
import { parse as parseYaml, stringify as stringifyYaml } from 'yaml';
import { createServiceLogger } from '../../../core/lib/logger';
import {
  testConfigSchema,
  type TestConfig,
  type TestRunner,
  type TestTarget,
  type TestSuiteConfig,
  type ConfigValidationResult,
} from './test-config.types';

/**
 * Allowed runner commands (first element of command array)
 * Only these executables are permitted for security
 */
const ALLOWED_RUNNER_COMMANDS = new Set([
  'bun',
  'npm',
  'npx',
  'node',
  'jest',
  'vitest',
  'mocha',
  'pnpm',
  'yarn',
]);

const logger = createServiceLogger('test-config');

/**
 * Default configuration path relative to project root
 */
const DEFAULT_CONFIG_PATH = '.agency/test-config.yaml';

/**
 * Default configuration if none exists
 */
function getDefaultConfig(): TestConfig {
  return {
    version: '1.0',
    runners: [
      {
        id: 'bun',
        command: ['bun', 'test'],
        outputFormat: 'bun',
      },
    ],
    targets: [
      {
        id: 'agency-service',
        path: 'source/services/agency-service',
        runner: 'bun',
        description: 'Main agency service tests',
      },
    ],
    suites: [
      {
        id: 'all',
        name: 'All Tests',
        target: 'agency-service',
        path: 'tests',
        tags: ['all'],
        enabled: true,
      },
    ],
  };
}

export class TestConfigService {
  private config: TestConfig | null = null;
  private configPath: string;
  private projectRoot: string;

  constructor(projectRoot: string, configPath?: string) {
    this.projectRoot = resolve(projectRoot);
    const proposedPath = configPath || join(projectRoot, DEFAULT_CONFIG_PATH);

    // Security: Ensure config path is within project root
    const resolvedConfigPath = resolve(proposedPath);
    const relativePath = relative(this.projectRoot, resolvedConfigPath);
    if (relativePath.startsWith('..') || resolve(relativePath) === relativePath) {
      throw new Error('Config path must be within project root');
    }

    this.configPath = resolvedConfigPath;
  }

  /**
   * Load configuration from YAML file
   */
  async load(): Promise<TestConfig> {
    try {
      const content = await readFile(this.configPath, 'utf-8');
      const raw = parseYaml(content);
      this.config = testConfigSchema.parse(raw);
      logger.info({ configPath: this.configPath }, 'Test config loaded');
      return this.config;
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
        logger.info('Config file not found, using defaults');
        this.config = getDefaultConfig();
        return this.config;
      }
      logger.error({ error }, 'Failed to load test config');
      throw error;
    }
  }

  /**
   * Save configuration to YAML file
   */
  async save(): Promise<void> {
    if (!this.config) {
      throw new Error('No configuration to save');
    }

    await mkdir(dirname(this.configPath), { recursive: true });

    const yaml = stringifyYaml(this.config, {
      indent: 2,
      lineWidth: 120,
    });

    await writeFile(this.configPath, yaml, 'utf-8');
    logger.info({ configPath: this.configPath }, 'Test config saved');
  }

  /**
   * Get the current configuration
   */
  getConfig(): TestConfig {
    if (!this.config) {
      throw new Error('Configuration not loaded. Call load() first.');
    }
    return this.config;
  }

  /**
   * Get a runner by ID
   */
  getRunner(id: string): TestRunner | null {
    if (!this.config) return null;
    return this.config.runners.find((r) => r.id === id) || null;
  }

  /**
   * Get a target by ID
   */
  getTarget(id: string): TestTarget | null {
    if (!this.config) return null;
    return this.config.targets.find((t) => t.id === id) || null;
  }

  /**
   * Get a suite by ID
   */
  getSuite(id: string): TestSuiteConfig | null {
    if (!this.config) return null;
    return this.config.suites.find((s) => s.id === id) || null;
  }

  /**
   * Get all runners
   */
  getRunners(): TestRunner[] {
    return this.config?.runners || [];
  }

  /**
   * Get all targets
   */
  getTargets(): TestTarget[] {
    return this.config?.targets || [];
  }

  /**
   * Get all suites
   */
  getSuites(): TestSuiteConfig[] {
    return this.config?.suites || [];
  }

  /**
   * Get suites for a target
   */
  getSuitesForTarget(targetId: string): TestSuiteConfig[] {
    return this.config?.suites.filter((s) => s.target === targetId) || [];
  }

  /**
   * Validate that all references are valid
   */
  validateReferences(): ConfigValidationResult {
    if (!this.config) {
      return { valid: false, errors: ['Configuration not loaded'] };
    }

    const errors: string[] = [];
    const runnerIds = new Set(this.config.runners.map((r) => r.id));
    const targetIds = new Set(this.config.targets.map((t) => t.id));

    // Security: Check runner commands are from allowlist
    for (const runner of this.config.runners) {
      const command = runner.command[0];
      if (!ALLOWED_RUNNER_COMMANDS.has(command)) {
        errors.push(`Runner '${runner.id}' uses disallowed command '${command}'. Allowed: ${[...ALLOWED_RUNNER_COMMANDS].join(', ')}`);
      }
    }

    // Check targets reference valid runners
    for (const target of this.config.targets) {
      if (!runnerIds.has(target.runner)) {
        errors.push(`Target '${target.id}' references unknown runner '${target.runner}'`);
      }
    }

    // Check suites reference valid targets
    for (const suite of this.config.suites) {
      if (!targetIds.has(suite.target)) {
        errors.push(`Suite '${suite.id}' references unknown target '${suite.target}'`);
      }
    }

    return {
      valid: errors.length === 0,
      errors,
    };
  }

  /**
   * Add a new suite
   */
  addSuite(suite: TestSuiteConfig): void {
    if (!this.config) {
      throw new Error('Configuration not loaded');
    }

    // Check for duplicate
    if (this.config.suites.some((s) => s.id === suite.id)) {
      throw new Error(`Suite '${suite.id}' already exists`);
    }

    // Validate target reference
    if (!this.config.targets.some((t) => t.id === suite.target)) {
      throw new Error(`Suite references unknown target '${suite.target}'`);
    }

    this.config.suites.push(suite);
    logger.info({ suiteId: suite.id }, 'Suite added to config');
  }

  /**
   * Remove a suite by ID
   */
  removeSuite(id: string): boolean {
    if (!this.config) return false;

    const index = this.config.suites.findIndex((s) => s.id === id);
    if (index === -1) return false;

    this.config.suites.splice(index, 1);
    logger.info({ suiteId: id }, 'Suite removed from config');
    return true;
  }

  /**
   * Resolve the absolute path for a target
   */
  resolveTargetPath(targetId: string): string | null {
    const target = this.getTarget(targetId);
    if (!target) return null;
    return join(this.projectRoot, target.path);
  }

  /**
   * Resolve the absolute path for a suite within its target
   */
  resolveSuitePath(suiteId: string): string | null {
    const suite = this.getSuite(suiteId);
    if (!suite) return null;

    const targetPath = this.resolveTargetPath(suite.target);
    if (!targetPath) return null;

    return join(targetPath, suite.path);
  }

  /**
   * Get the project root
   */
  getProjectRoot(): string {
    return this.projectRoot;
  }
}
