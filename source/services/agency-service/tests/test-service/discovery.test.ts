/**
 * Test Discovery Service Tests
 *
 * Tests for suite discovery functionality.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { TestConfigService } from '../../src/embedded/test-service/config/test-config.service';
import { TestDiscoveryService } from '../../src/embedded/test-service/service/discovery.service';
import { mkdirSync, rmSync, existsSync, writeFileSync } from 'fs';
import { join } from 'path';

describe('Test Discovery Service', () => {
  const testProjectRoot = '/tmp/agency-test-discovery';
  let configService: TestConfigService;
  let discoveryService: TestDiscoveryService;

  beforeEach(async () => {
    // Clean up any existing test directory
    if (existsSync(testProjectRoot)) {
      rmSync(testProjectRoot, { recursive: true, force: true });
    }

    // Create project structure with tests
    const targetPath = join(testProjectRoot, 'source/services/agency-service');
    mkdirSync(join(targetPath, 'tests/core'), { recursive: true });
    mkdirSync(join(targetPath, 'tests/integration'), { recursive: true });
    mkdirSync(join(targetPath, 'tests/empty'), { recursive: true });

    // Add test files
    writeFileSync(join(targetPath, 'tests/core/sample.test.ts'), 'export {}');
    writeFileSync(join(targetPath, 'tests/core/another.test.ts'), 'export {}');
    writeFileSync(join(targetPath, 'tests/integration/api.test.ts'), 'export {}');
    // Empty dir has no test files

    // Create config
    mkdirSync(join(testProjectRoot, '.agency'), { recursive: true });
    writeFileSync(join(testProjectRoot, '.agency/test-config.yaml'), `
version: "1.0"
runners:
  - id: bun
    command: ['bun', 'test']
    outputFormat: bun
targets:
  - id: agency-service
    path: source/services/agency-service
    runner: bun
suites:
  - id: core
    name: Core Tests
    target: agency-service
    path: tests/core
    tags: [unit]
`);

    configService = new TestConfigService(testProjectRoot);
    await configService.load();
    discoveryService = new TestDiscoveryService(configService);
  });

  afterEach(() => {
    try {
      rmSync(testProjectRoot, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  });

  describe('discoverAll', () => {
    test('should discover suites in all targets', async () => {
      const discovered = await discoveryService.discoverAll();

      // Should discover at least core and integration
      expect(discovered.length).toBeGreaterThan(0);
      expect(discovered.some(s => s.path.includes('core'))).toBe(true);
      expect(discovered.some(s => s.path.includes('integration'))).toBe(true);
    });
  });

  describe('discoverInTarget', () => {
    test('should return empty array for unknown target', async () => {
      const discovered = await discoveryService.discoverInTarget('unknown');
      expect(discovered).toHaveLength(0);
    });

    test('should discover test directories', async () => {
      const discovered = await discoveryService.discoverInTarget('agency-service');

      // Should find core and integration (empty has no test files)
      const ids = discovered.map(s => s.id);
      expect(ids.some(id => id.includes('core'))).toBe(true);
      expect(ids.some(id => id.includes('integration'))).toBe(true);
    });

    test('should mark registered suites', async () => {
      const discovered = await discoveryService.discoverInTarget('agency-service');

      // 'core' is registered in config
      const coreSuite = discovered.find(s => s.id === 'core' || s.path.includes('core'));
      expect(coreSuite?.registered).toBe(true);

      // 'integration' is not registered
      const integrationSuite = discovered.find(s => s.id === 'integration' || s.path.includes('integration'));
      expect(integrationSuite?.registered).toBe(false);
    });

    test('should count test files', async () => {
      const discovered = await discoveryService.discoverInTarget('agency-service');

      const coreSuite = discovered.find(s => s.path.includes('core'));
      expect(coreSuite?.testFileCount).toBe(2); // sample.test.ts and another.test.ts

      const integrationSuite = discovered.find(s => s.path.includes('integration'));
      expect(integrationSuite?.testFileCount).toBe(1); // api.test.ts
    });

    test('should not include empty directories', async () => {
      const discovered = await discoveryService.discoverInTarget('agency-service');

      const emptySuite = discovered.find(s => s.path.includes('empty'));
      expect(emptySuite).toBeUndefined();
    });
  });

  describe('generateSuiteId', () => {
    test('should use directory name for main target', () => {
      const id = discoveryService.generateSuiteId('agency-service', 'core');
      expect(id).toBe('core');
    });

    test('should prefix with target for other targets', () => {
      const id = discoveryService.generateSuiteId('starter', 'core');
      expect(id).toBe('starter-core');
    });
  });

  describe('containsTests', () => {
    test('should return true for directory with test files', async () => {
      const targetPath = join(testProjectRoot, 'source/services/agency-service');
      const hasTests = await discoveryService.containsTests(join(targetPath, 'tests/core'));
      expect(hasTests).toBe(true);
    });

    test('should return false for empty directory', async () => {
      const targetPath = join(testProjectRoot, 'source/services/agency-service');
      const hasTests = await discoveryService.containsTests(join(targetPath, 'tests/empty'));
      expect(hasTests).toBe(false);
    });

    test('should return false for non-existent directory', async () => {
      const hasTests = await discoveryService.containsTests('/nonexistent/path');
      expect(hasTests).toBe(false);
    });

    test('should detect nested test files', async () => {
      const targetPath = join(testProjectRoot, 'source/services/agency-service');
      const nestedDir = join(targetPath, 'tests/nested/deep');
      mkdirSync(nestedDir, { recursive: true });
      writeFileSync(join(nestedDir, 'deep.test.ts'), 'export {}');

      const hasTests = await discoveryService.containsTests(join(targetPath, 'tests/nested'));
      expect(hasTests).toBe(true);
    });
  });

  describe('countTestFiles', () => {
    test('should count test files recursively', async () => {
      const targetPath = join(testProjectRoot, 'source/services/agency-service');
      const count = await discoveryService.countTestFiles(join(targetPath, 'tests'));

      // core has 2, integration has 1
      expect(count).toBe(3);
    });

    test('should return 0 for empty directory', async () => {
      const targetPath = join(testProjectRoot, 'source/services/agency-service');
      const count = await discoveryService.countTestFiles(join(targetPath, 'tests/empty'));
      expect(count).toBe(0);
    });

    test('should return 0 for non-existent directory', async () => {
      const count = await discoveryService.countTestFiles('/nonexistent/path');
      expect(count).toBe(0);
    });
  });

  describe('getSuggestedSuiteConfig', () => {
    test('should generate suite config from discovered suite', () => {
      const discovered = {
        id: 'my-suite',
        name: 'My Suite',
        target: 'agency-service',
        path: 'tests/my-suite',
        testFileCount: 5,
        registered: false,
      };

      const config = discoveryService.getSuggestedSuiteConfig(discovered);

      expect(config.id).toBe('my-suite');
      expect(config.name).toBe('My Suite');
      expect(config.target).toBe('agency-service');
      expect(config.path).toBe('tests/my-suite');
      expect(config.enabled).toBe(true);
      expect(config.tags).toContain('unit');
    });

    test('should infer tags from suite ID', () => {
      const logSuite = {
        id: 'log-service',
        name: 'Log Service',
        target: 'agency-service',
        path: 'tests/log-service',
        testFileCount: 10,
        registered: false,
      };

      const config = discoveryService.getSuggestedSuiteConfig(logSuite);
      expect(config.tags).toContain('log');
    });

    test('should use "all" tag for all suite', () => {
      const allSuite = {
        id: 'all',
        name: 'All Tests',
        target: 'agency-service',
        path: 'tests',
        testFileCount: 50,
        registered: false,
      };

      const config = discoveryService.getSuggestedSuiteConfig(allSuite);
      expect(config.tags).toEqual(['all']);
    });
  });
});
