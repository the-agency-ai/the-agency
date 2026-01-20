/**
 * Test Discovery Service
 *
 * Discovers test directories and files within configured targets.
 */

import { readdir, stat } from 'fs/promises';
import { join, relative } from 'path';
import { createServiceLogger } from '../../../core/lib/logger';
import type { TestConfigService } from '../config/test-config.service';
import type { DiscoveredSuite, TestSuiteConfig } from '../config/test-config.types';

const logger = createServiceLogger('test-discovery');

/**
 * Test file extensions we look for
 */
const TEST_FILE_PATTERNS = ['.test.ts', '.spec.ts', '.test.js', '.spec.js'];

export class TestDiscoveryService {
  constructor(private configService: TestConfigService) {}

  /**
   * Discover all test directories in all configured targets
   */
  async discoverAll(): Promise<DiscoveredSuite[]> {
    const targets = this.configService.getTargets();
    const allDiscovered: DiscoveredSuite[] = [];

    for (const target of targets) {
      const discovered = await this.discoverInTarget(target.id);
      allDiscovered.push(...discovered);
    }

    return allDiscovered;
  }

  /**
   * Discover test directories in a specific target
   */
  async discoverInTarget(targetId: string): Promise<DiscoveredSuite[]> {
    const target = this.configService.getTarget(targetId);
    if (!target) {
      logger.warn({ targetId }, 'Target not found');
      return [];
    }

    const targetPath = this.configService.resolveTargetPath(targetId);
    if (!targetPath) {
      logger.warn({ targetId }, 'Could not resolve target path');
      return [];
    }

    const testsDir = join(targetPath, 'tests');
    const discovered: DiscoveredSuite[] = [];
    const registeredSuites = this.configService.getSuitesForTarget(targetId);

    try {
      // Check if tests directory exists
      await stat(testsDir);

      // Discover subdirectories
      const entries = await readdir(testsDir, { withFileTypes: true });

      for (const entry of entries) {
        if (entry.isDirectory()) {
          const suitePath = join(testsDir, entry.name);
          const hasTests = await this.containsTests(suitePath);

          if (hasTests) {
            const suiteId = this.generateSuiteId(targetId, entry.name);
            const testCount = await this.countTestFiles(suitePath);
            const isRegistered = registeredSuites.some((s) => s.id === suiteId || s.path === `tests/${entry.name}`);

            discovered.push({
              id: suiteId,
              name: this.formatSuiteName(entry.name),
              target: targetId,
              path: `tests/${entry.name}`,
              testFileCount: testCount,
              registered: isRegistered,
            });
          }
        }
      }

      // Also check root tests directory
      const rootTestCount = await this.countTestFilesInDir(testsDir);
      if (rootTestCount > 0) {
        const allSuiteId = this.generateSuiteId(targetId, 'all');
        const totalTestCount = await this.countTestFilesRecursive(testsDir);
        const isRegistered = registeredSuites.some((s) => s.id === 'all' || s.path === 'tests');

        discovered.unshift({
          id: allSuiteId,
          name: 'All Tests',
          target: targetId,
          path: 'tests',
          testFileCount: totalTestCount,
          registered: isRegistered,
        });
      }

      logger.info({ targetId, discovered: discovered.length }, 'Discovery complete');
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
        logger.debug({ targetId, testsDir }, 'No tests directory found');
      } else {
        logger.error({ targetId, error }, 'Discovery failed');
      }
    }

    return discovered;
  }

  /**
   * Generate a suite ID from target and directory name
   */
  generateSuiteId(targetId: string, dirName: string): string {
    // For the main target, just use the directory name
    if (targetId === 'agency-service') {
      return dirName;
    }
    // For other targets, prefix with target ID
    return `${targetId}-${dirName}`;
  }

  /**
   * Format a directory name as a suite name
   */
  private formatSuiteName(dirName: string): string {
    // Convert kebab-case or snake_case to Title Case
    return dirName
      .split(/[-_]/)
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ') + ' Tests';
  }

  /**
   * Check if a directory contains test files
   */
  async containsTests(dirPath: string): Promise<boolean> {
    try {
      const entries = await readdir(dirPath, { withFileTypes: true });

      for (const entry of entries) {
        if (entry.isFile()) {
          const isTestFile = TEST_FILE_PATTERNS.some((pattern) =>
            entry.name.endsWith(pattern)
          );
          if (isTestFile) return true;
        } else if (entry.isDirectory()) {
          // Recursively check subdirectories
          const hasTests = await this.containsTests(join(dirPath, entry.name));
          if (hasTests) return true;
        }
      }

      return false;
    } catch {
      return false;
    }
  }

  /**
   * Count test files in a directory (non-recursive)
   */
  private async countTestFilesInDir(dirPath: string): Promise<number> {
    try {
      const entries = await readdir(dirPath, { withFileTypes: true });
      return entries.filter((e) =>
        e.isFile() && TEST_FILE_PATTERNS.some((p) => e.name.endsWith(p))
      ).length;
    } catch {
      return 0;
    }
  }

  /**
   * Count test files in a directory (recursive)
   */
  private async countTestFilesRecursive(dirPath: string): Promise<number> {
    let count = 0;

    try {
      const entries = await readdir(dirPath, { withFileTypes: true });

      for (const entry of entries) {
        if (entry.isFile()) {
          if (TEST_FILE_PATTERNS.some((p) => entry.name.endsWith(p))) {
            count++;
          }
        } else if (entry.isDirectory()) {
          count += await this.countTestFilesRecursive(join(dirPath, entry.name));
        }
      }
    } catch {
      // Ignore errors
    }

    return count;
  }

  /**
   * Count test files (alias for recursive count)
   */
  async countTestFiles(dirPath: string): Promise<number> {
    return this.countTestFilesRecursive(dirPath);
  }

  /**
   * Get suggested suite config from a discovered suite
   */
  getSuggestedSuiteConfig(discovered: DiscoveredSuite): TestSuiteConfig {
    return {
      id: discovered.id,
      name: discovered.name,
      target: discovered.target,
      path: discovered.path,
      tags: this.inferTags(discovered.id),
      enabled: true,
    };
  }

  /**
   * Infer tags from suite ID
   */
  private inferTags(suiteId: string): string[] {
    const tags: string[] = ['unit'];

    if (suiteId === 'all') {
      return ['all'];
    }

    // Add service-specific tags
    if (suiteId.includes('log')) tags.push('log');
    if (suiteId.includes('test')) tags.push('test');
    if (suiteId.includes('bug')) tags.push('bug');
    if (suiteId.includes('message')) tags.push('message');
    if (suiteId.includes('request')) tags.push('request');
    if (suiteId.includes('core')) tags.push('core');

    return tags;
  }
}
