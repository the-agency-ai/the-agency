/**
 * Test Configuration Service Tests
 *
 * Tests for configuration loading, saving, and validation.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { TestConfigService } from '../../src/embedded/test-service/config/test-config.service';
import { testConfigSchema } from '../../src/embedded/test-service/config/test-config.types';
import { mkdirSync, rmSync, existsSync, writeFileSync } from 'fs';
import { join } from 'path';

describe('Test Configuration Service', () => {
  const testProjectRoot = '/tmp/agency-test-config';
  const testConfigPath = join(testProjectRoot, '.agency/test-config.yaml');
  let configService: TestConfigService;

  beforeEach(() => {
    // Clean up any existing test directory
    if (existsSync(testProjectRoot)) {
      rmSync(testProjectRoot, { recursive: true, force: true });
    }
    mkdirSync(testProjectRoot, { recursive: true });
    configService = new TestConfigService(testProjectRoot);
  });

  afterEach(() => {
    try {
      rmSync(testProjectRoot, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  });

  describe('load', () => {
    test('should load defaults when config file does not exist', async () => {
      const config = await configService.load();

      expect(config.version).toBe('1.0');
      expect(config.runners.length).toBeGreaterThan(0);
      expect(config.targets.length).toBeGreaterThan(0);
    });

    test('should load config from file', async () => {
      mkdirSync(join(testProjectRoot, '.agency'), { recursive: true });
      writeFileSync(testConfigPath, `
version: "1.0"
runners:
  - id: custom
    command: ['custom', 'test']
    outputFormat: raw
targets:
  - id: custom-target
    path: custom/path
    runner: custom
suites: []
`);

      const config = await configService.load();

      expect(config.runners[0].id).toBe('custom');
      expect(config.targets[0].id).toBe('custom-target');
    });

    test('should throw on invalid config', async () => {
      mkdirSync(join(testProjectRoot, '.agency'), { recursive: true });
      writeFileSync(testConfigPath, `
version: "1.0"
runners: []
targets: []
`);

      await expect(configService.load()).rejects.toThrow();
    });
  });

  describe('save', () => {
    test('should save config to file', async () => {
      await configService.load();
      await configService.save();

      expect(existsSync(testConfigPath)).toBe(true);
    });

    test('should throw if config not loaded', async () => {
      await expect(configService.save()).rejects.toThrow('No configuration to save');
    });
  });

  describe('getConfig', () => {
    test('should throw if not loaded', () => {
      expect(() => configService.getConfig()).toThrow('Configuration not loaded');
    });

    test('should return config after load', async () => {
      await configService.load();
      const config = configService.getConfig();
      expect(config.version).toBeDefined();
    });
  });

  describe('getRunner', () => {
    test('should return null if not loaded', () => {
      expect(configService.getRunner('bun')).toBeNull();
    });

    test('should return runner by ID', async () => {
      await configService.load();
      const runner = configService.getRunner('bun');
      expect(runner).not.toBeNull();
      expect(runner!.id).toBe('bun');
    });

    test('should return null for unknown runner', async () => {
      await configService.load();
      expect(configService.getRunner('unknown')).toBeNull();
    });
  });

  describe('getTarget', () => {
    test('should return null if not loaded', () => {
      expect(configService.getTarget('agency-service')).toBeNull();
    });

    test('should return target by ID', async () => {
      await configService.load();
      const target = configService.getTarget('agency-service');
      expect(target).not.toBeNull();
      expect(target!.id).toBe('agency-service');
    });

    test('should return null for unknown target', async () => {
      await configService.load();
      expect(configService.getTarget('unknown')).toBeNull();
    });
  });

  describe('validateReferences', () => {
    test('should return error if not loaded', () => {
      const result = configService.validateReferences();
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Configuration not loaded');
    });

    test('should pass validation for valid config', async () => {
      await configService.load();
      const result = configService.validateReferences();
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    test('should fail if target references unknown runner', async () => {
      mkdirSync(join(testProjectRoot, '.agency'), { recursive: true });
      writeFileSync(testConfigPath, `
version: "1.0"
runners:
  - id: bun
    command: ['bun', 'test']
    outputFormat: bun
targets:
  - id: test
    path: test
    runner: unknown-runner
suites: []
`);

      await configService.load();
      const result = configService.validateReferences();
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('unknown runner'))).toBe(true);
    });

    test('should fail if suite references unknown target', async () => {
      mkdirSync(join(testProjectRoot, '.agency'), { recursive: true });
      writeFileSync(testConfigPath, `
version: "1.0"
runners:
  - id: bun
    command: ['bun', 'test']
    outputFormat: bun
targets:
  - id: test
    path: test
    runner: bun
suites:
  - id: all
    name: All
    target: unknown-target
    path: tests
`);

      await configService.load();
      const result = configService.validateReferences();
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('unknown target'))).toBe(true);
    });
  });

  describe('addSuite', () => {
    test('should throw if not loaded', () => {
      expect(() => configService.addSuite({
        id: 'new',
        name: 'New Suite',
        target: 'agency-service',
        path: 'tests/new',
        tags: [],
        enabled: true,
      })).toThrow('Configuration not loaded');
    });

    test('should add new suite', async () => {
      await configService.load();
      configService.addSuite({
        id: 'new-suite',
        name: 'New Suite',
        target: 'agency-service',
        path: 'tests/new',
        tags: ['unit'],
        enabled: true,
      });

      const suite = configService.getSuite('new-suite');
      expect(suite).not.toBeNull();
      expect(suite!.name).toBe('New Suite');
    });

    test('should throw on duplicate suite', async () => {
      await configService.load();
      const suites = configService.getSuites();

      if (suites.length > 0) {
        expect(() => configService.addSuite(suites[0])).toThrow('already exists');
      }
    });

    test('should throw if target does not exist', async () => {
      await configService.load();
      expect(() => configService.addSuite({
        id: 'new',
        name: 'New Suite',
        target: 'unknown-target',
        path: 'tests/new',
        tags: [],
        enabled: true,
      })).toThrow('unknown target');
    });
  });

  describe('removeSuite', () => {
    test('should return false if not loaded', () => {
      expect(configService.removeSuite('some-suite')).toBe(false);
    });

    test('should return false for non-existent suite', async () => {
      await configService.load();
      expect(configService.removeSuite('nonexistent')).toBe(false);
    });

    test('should remove existing suite', async () => {
      await configService.load();

      // Add a suite first
      configService.addSuite({
        id: 'temp-suite',
        name: 'Temp Suite',
        target: 'agency-service',
        path: 'tests/temp',
        tags: [],
        enabled: true,
      });

      expect(configService.getSuite('temp-suite')).not.toBeNull();

      const removed = configService.removeSuite('temp-suite');
      expect(removed).toBe(true);
      expect(configService.getSuite('temp-suite')).toBeNull();
    });
  });

  describe('resolveTargetPath', () => {
    test('should return null for unknown target', async () => {
      await configService.load();
      expect(configService.resolveTargetPath('unknown')).toBeNull();
    });

    test('should return absolute path for target', async () => {
      await configService.load();
      const path = configService.resolveTargetPath('agency-service');
      expect(path).not.toBeNull();
      expect(path).toContain(testProjectRoot);
    });
  });

  describe('getSuitesForTarget', () => {
    test('should return empty array if not loaded', () => {
      expect(configService.getSuitesForTarget('agency-service')).toHaveLength(0);
    });

    test('should return suites for target', async () => {
      await configService.load();
      const suites = configService.getSuitesForTarget('agency-service');
      // Default config has suites for agency-service
      expect(Array.isArray(suites)).toBe(true);
    });
  });

  // Security Tests
  describe('security: path traversal prevention', () => {
    test('should reject config path outside project root with ../', () => {
      expect(() => new TestConfigService(testProjectRoot, '../../../etc/passwd'))
        .toThrow('Config path must be within project root');
    });

    test('should reject config path that resolves outside project root', () => {
      expect(() => new TestConfigService(testProjectRoot, '/etc/passwd'))
        .toThrow('Config path must be within project root');
    });

    test('should reject config path with hidden traversal', () => {
      expect(() => new TestConfigService(testProjectRoot, '.agency/../../../etc/passwd'))
        .toThrow('Config path must be within project root');
    });

    test('should accept valid config path within project root', () => {
      // Should not throw
      const service = new TestConfigService(testProjectRoot, join(testProjectRoot, '.agency/test-config.yaml'));
      expect(service).toBeDefined();
    });

    test('should accept default config path', () => {
      // Should not throw
      const service = new TestConfigService(testProjectRoot);
      expect(service).toBeDefined();
    });
  });

  describe('security: runner command allowlist', () => {
    test('should fail validation for disallowed command (bash)', async () => {
      mkdirSync(join(testProjectRoot, '.agency'), { recursive: true });
      writeFileSync(testConfigPath, `
version: "1.0"
runners:
  - id: malicious
    command: ['bash', '-c', 'echo hacked']
    outputFormat: raw
targets:
  - id: test
    path: test
    runner: malicious
suites: []
`);

      await configService.load();
      const result = configService.validateReferences();
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('disallowed command'))).toBe(true);
    });

    test('should fail validation for disallowed command (curl)', async () => {
      mkdirSync(join(testProjectRoot, '.agency'), { recursive: true });
      writeFileSync(testConfigPath, `
version: "1.0"
runners:
  - id: malicious
    command: ['curl', 'http://evil.com']
    outputFormat: raw
targets:
  - id: test
    path: test
    runner: malicious
suites: []
`);

      await configService.load();
      const result = configService.validateReferences();
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('disallowed command'))).toBe(true);
    });

    test('should fail validation for disallowed command (sh)', async () => {
      mkdirSync(join(testProjectRoot, '.agency'), { recursive: true });
      writeFileSync(testConfigPath, `
version: "1.0"
runners:
  - id: malicious
    command: ['sh', '-c', 'whoami']
    outputFormat: raw
targets:
  - id: test
    path: test
    runner: malicious
suites: []
`);

      await configService.load();
      const result = configService.validateReferences();
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('disallowed command'))).toBe(true);
    });

    test('should pass validation for allowed command (bun)', async () => {
      await configService.load(); // Uses default config with 'bun'
      const result = configService.validateReferences();
      expect(result.valid).toBe(true);
    });

    test('should pass validation for allowed command (npm)', async () => {
      mkdirSync(join(testProjectRoot, '.agency'), { recursive: true });
      writeFileSync(testConfigPath, `
version: "1.0"
runners:
  - id: npm-runner
    command: ['npm', 'test']
    outputFormat: raw
targets:
  - id: test
    path: test
    runner: npm-runner
suites: []
`);

      await configService.load();
      const result = configService.validateReferences();
      expect(result.valid).toBe(true);
    });

    test('should pass validation for allowed command (jest)', async () => {
      mkdirSync(join(testProjectRoot, '.agency'), { recursive: true });
      writeFileSync(testConfigPath, `
version: "1.0"
runners:
  - id: jest-runner
    command: ['jest']
    outputFormat: jest
targets:
  - id: test
    path: test
    runner: jest-runner
suites: []
`);

      await configService.load();
      const result = configService.validateReferences();
      expect(result.valid).toBe(true);
    });
  });
});

describe('Test Configuration Schema', () => {
  describe('testConfigSchema', () => {
    test('should validate valid config', () => {
      const config = {
        version: '1.0',
        runners: [
          { id: 'bun', command: ['bun', 'test'], outputFormat: 'bun' },
        ],
        targets: [
          { id: 'main', path: 'src', runner: 'bun' },
        ],
        suites: [],
      };

      const result = testConfigSchema.safeParse(config);
      expect(result.success).toBe(true);
    });

    test('should reject invalid runner ID', () => {
      const config = {
        version: '1.0',
        runners: [
          { id: 'invalid/id', command: ['bun', 'test'], outputFormat: 'bun' },
        ],
        targets: [
          { id: 'main', path: 'src', runner: 'invalid/id' },
        ],
        suites: [],
      };

      const result = testConfigSchema.safeParse(config);
      expect(result.success).toBe(false);
    });

    test('should reject empty command', () => {
      const config = {
        version: '1.0',
        runners: [
          { id: 'empty', command: [], outputFormat: 'bun' },
        ],
        targets: [
          { id: 'main', path: 'src', runner: 'empty' },
        ],
        suites: [],
      };

      const result = testConfigSchema.safeParse(config);
      expect(result.success).toBe(false);
    });

    test('should require at least one runner', () => {
      const config = {
        version: '1.0',
        runners: [],
        targets: [
          { id: 'main', path: 'src', runner: 'bun' },
        ],
        suites: [],
      };

      const result = testConfigSchema.safeParse(config);
      expect(result.success).toBe(false);
    });

    test('should require at least one target', () => {
      const config = {
        version: '1.0',
        runners: [
          { id: 'bun', command: ['bun', 'test'], outputFormat: 'bun' },
        ],
        targets: [],
        suites: [],
      };

      const result = testConfigSchema.safeParse(config);
      expect(result.success).toBe(false);
    });
  });
});
