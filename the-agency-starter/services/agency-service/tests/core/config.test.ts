/**
 * Config Tests
 *
 * Tests for environment-based configuration.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { getConfig, resetConfig } from '../../src/core/config';

describe('Config', () => {
  beforeEach(() => {
    resetConfig();
  });

  afterEach(() => {
    resetConfig();
  });

  test('should return default values', () => {
    const config = getConfig();

    expect(config.port).toBe(3141);
    expect(config.host).toBe('127.0.0.1');
    expect(config.authMode).toBe('local');
    expect(config.dbAdapter).toBe('sqlite');
    expect(config.queueAdapter).toBe('sqlite');
    expect(config.logLevel).toBe('info');
  });

  test('should use environment overrides', () => {
    process.env.AGENCY_SERVICE_PORT = '4000';
    process.env.AGENCY_AUTH_MODE = 'jwt';
    resetConfig();

    const config = getConfig();

    expect(config.port).toBe(4000);
    expect(config.authMode).toBe('jwt');

    // Cleanup
    delete process.env.AGENCY_SERVICE_PORT;
    delete process.env.AGENCY_AUTH_MODE;
  });

  test('should return singleton', () => {
    const config1 = getConfig();
    const config2 = getConfig();

    expect(config1).toBe(config2);
  });

  test('should have projectRoot set', () => {
    const config = getConfig();

    expect(config.projectRoot).toBeDefined();
    expect(typeof config.projectRoot).toBe('string');
    expect(config.projectRoot.length).toBeGreaterThan(0);
  });

  test('should set dbPath based on projectRoot', () => {
    const config = getConfig();

    expect(config.dbPath).toContain('claude/data');
  });

  test('should set logDir based on projectRoot', () => {
    const config = getConfig();

    expect(config.logDir).toContain('services/agency-service/logs');
  });
});
