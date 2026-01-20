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

  describe('logRetentionDays', () => {
    test('should have default value of 30', () => {
      const config = getConfig();
      expect(config.logRetentionDays).toBe(30);
    });

    test('should accept environment override', () => {
      process.env.AGENCY_LOG_RETENTION_DAYS = '60';
      resetConfig();

      const config = getConfig();
      expect(config.logRetentionDays).toBe(60);

      // Cleanup
      delete process.env.AGENCY_LOG_RETENTION_DAYS;
    });

    test('should handle minimum valid value (1)', () => {
      process.env.AGENCY_LOG_RETENTION_DAYS = '1';
      resetConfig();

      const config = getConfig();
      expect(config.logRetentionDays).toBe(1);

      // Cleanup
      delete process.env.AGENCY_LOG_RETENTION_DAYS;
    });

    test('should handle maximum valid value (365)', () => {
      process.env.AGENCY_LOG_RETENTION_DAYS = '365';
      resetConfig();

      const config = getConfig();
      expect(config.logRetentionDays).toBe(365);

      // Cleanup
      delete process.env.AGENCY_LOG_RETENTION_DAYS;
    });

    test('should throw for invalid string value', () => {
      process.env.AGENCY_LOG_RETENTION_DAYS = 'invalid';

      // Invalid string parsed as NaN, which fails Zod validation
      expect(() => {
        resetConfig();
        getConfig();
      }).toThrow();

      // Cleanup
      delete process.env.AGENCY_LOG_RETENTION_DAYS;
      resetConfig();
    });
  });
});
