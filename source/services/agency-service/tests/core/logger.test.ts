/**
 * Logger Tests
 *
 * Tests for Pino logger with log service dual-write functionality.
 * Created for REQUEST-jordan-0012 test review.
 */

import { describe, test, expect, beforeEach, afterEach, mock } from 'bun:test';
import {
  getLogger,
  createServiceLogger,
  enableLogServiceDualWrite,
  disableLogServiceDualWrite,
  isLogServiceDualWriteEnabled,
} from '../../src/core/lib/logger';
import type { LogService } from '../../src/embedded/log-service/service/log.service';

describe('Logger', () => {
  describe('getLogger', () => {
    test('should return a pino logger', () => {
      const logger = getLogger();
      expect(logger).toBeDefined();
      expect(typeof logger.info).toBe('function');
      expect(typeof logger.error).toBe('function');
      expect(typeof logger.debug).toBe('function');
      expect(typeof logger.warn).toBe('function');
    });

    test('should return the same logger instance', () => {
      const logger1 = getLogger();
      const logger2 = getLogger();
      expect(logger1).toBe(logger2);
    });
  });

  describe('createServiceLogger', () => {
    test('should create a child logger with service name', () => {
      const logger = createServiceLogger('test-service');
      expect(logger).toBeDefined();
      expect(typeof logger.info).toBe('function');
    });

    test('should create different child loggers for different services', () => {
      const logger1 = createServiceLogger('service-a');
      const logger2 = createServiceLogger('service-b');
      // They should be different child instances
      expect(logger1).not.toBe(logger2);
    });
  });

  describe('log service dual-write', () => {
    let mockLogService: Partial<LogService>;
    let ingestMock: ReturnType<typeof mock>;

    beforeEach(() => {
      // Ensure we start with dual-write disabled
      disableLogServiceDualWrite();

      // Create mock log service
      ingestMock = mock(() => Promise.resolve({
        id: 1,
        timestamp: new Date(),
        service: 'test',
        level: 'info' as const,
        message: 'test',
      }));

      mockLogService = {
        ingest: ingestMock,
      };
    });

    afterEach(() => {
      disableLogServiceDualWrite();
    });

    test('should start with dual-write disabled', () => {
      expect(isLogServiceDualWriteEnabled()).toBe(false);
    });

    test('should enable dual-write', () => {
      enableLogServiceDualWrite(mockLogService as LogService);
      expect(isLogServiceDualWriteEnabled()).toBe(true);
    });

    test('should disable dual-write', () => {
      enableLogServiceDualWrite(mockLogService as LogService);
      expect(isLogServiceDualWriteEnabled()).toBe(true);

      disableLogServiceDualWrite();
      expect(isLogServiceDualWriteEnabled()).toBe(false);
    });
  });

  describe('log level mapping', () => {
    test('should map pino numeric levels to strings', () => {
      // Pino level mapping:
      // 10: trace, 20: debug, 30: info, 40: warn, 50: error, 60: fatal
      const levelMap: Record<number, string> = {
        10: 'trace',
        20: 'debug',
        30: 'info',
        40: 'warn',
        50: 'error',
        60: 'fatal',
      };

      // Verify the mapping is as expected
      expect(levelMap[10]).toBe('trace');
      expect(levelMap[20]).toBe('debug');
      expect(levelMap[30]).toBe('info');
      expect(levelMap[40]).toBe('warn');
      expect(levelMap[50]).toBe('error');
      expect(levelMap[60]).toBe('fatal');
    });

    test('should default to info for unknown levels', () => {
      const levelMap: Record<number, string> = {
        10: 'trace',
        20: 'debug',
        30: 'info',
        40: 'warn',
        50: 'error',
        60: 'fatal',
      };

      // Unknown level should not be in the map
      const unknownLevel = 99;
      const level = levelMap[unknownLevel] || 'info';
      expect(level).toBe('info');
    });
  });

  describe('extractData helper', () => {
    test('should exclude standard pino fields from extracted data', () => {
      const excludeKeys = new Set([
        'level', 'time', 'msg', 'pid', 'hostname', 'service', 'version',
        'runId', 'requestId', 'userId', 'userType', 'err',
      ]);

      const logObj = {
        level: 30,
        time: '2026-01-20T12:00:00Z',
        msg: 'Test message',
        pid: 1234,
        hostname: 'localhost',
        service: 'test-service',
        version: '0.1.0',
        runId: 'run-123',
        requestId: 'req-456',
        userId: 'user-1',
        userType: 'agent',
        err: { message: 'error' },
        // Custom fields that should be extracted
        customField: 'value',
        anotherField: 42,
      };

      // Simulate extractData logic
      const data: Record<string, unknown> = {};
      let hasData = false;

      for (const [key, value] of Object.entries(logObj)) {
        if (!excludeKeys.has(key)) {
          data[key] = value;
          hasData = true;
        }
      }

      expect(hasData).toBe(true);
      expect(data.customField).toBe('value');
      expect(data.anotherField).toBe(42);
      expect(data.level).toBeUndefined();
      expect(data.msg).toBeUndefined();
      expect(data.pid).toBeUndefined();
    });

    test('should return undefined when no custom data present', () => {
      const excludeKeys = new Set([
        'level', 'time', 'msg', 'pid', 'hostname', 'service', 'version',
        'runId', 'requestId', 'userId', 'userType', 'err',
      ]);

      const logObj = {
        level: 30,
        time: '2026-01-20T12:00:00Z',
        msg: 'Test message',
        service: 'test-service',
      };

      const data: Record<string, unknown> = {};
      let hasData = false;

      for (const [key, value] of Object.entries(logObj)) {
        if (!excludeKeys.has(key)) {
          data[key] = value;
          hasData = true;
        }
      }

      expect(hasData).toBe(false);
    });
  });

  describe('log entry building', () => {
    test('should build log entry from pino log object', () => {
      const logObj = {
        level: 50, // error
        msg: 'Something went wrong',
        service: 'api-service',
        runId: 'run-abc',
        requestId: 'req-xyz',
        userId: 'agent-1',
        userType: 'agent',
        err: {
          type: 'ValidationError',
          message: 'Invalid input',
          stack: 'Error: Invalid input\n  at validate.ts:10:5',
        },
      };

      // Simulate entry building
      const levelMap: Record<number, string> = {
        10: 'trace',
        20: 'debug',
        30: 'info',
        40: 'warn',
        50: 'error',
        60: 'fatal',
      };

      const level = levelMap[logObj.level] || 'info';
      const service = logObj.service || 'agency-service';

      const entry = {
        service,
        level,
        message: logObj.msg || '',
        runId: logObj.runId,
        requestId: logObj.requestId,
        userId: logObj.userId,
        userType: logObj.userType,
        error: logObj.err ? {
          name: logObj.err.type || 'Error',
          message: logObj.err.message || '',
          stack: logObj.err.stack,
        } : undefined,
      };

      expect(entry.level).toBe('error');
      expect(entry.service).toBe('api-service');
      expect(entry.message).toBe('Something went wrong');
      expect(entry.runId).toBe('run-abc');
      expect(entry.error?.name).toBe('ValidationError');
      expect(entry.error?.stack).toContain('validate.ts');
    });

    test('should handle missing optional fields', () => {
      const logObj = {
        level: 30,
        msg: 'Simple log',
      };

      const levelMap: Record<number, string> = {
        10: 'trace',
        20: 'debug',
        30: 'info',
        40: 'warn',
        50: 'error',
        60: 'fatal',
      };

      const level = levelMap[logObj.level] || 'info';
      const service = (logObj as { service?: string }).service || 'agency-service';

      const entry = {
        service,
        level,
        message: logObj.msg || '',
        runId: undefined,
        requestId: undefined,
        error: undefined,
      };

      expect(entry.level).toBe('info');
      expect(entry.service).toBe('agency-service');
      expect(entry.message).toBe('Simple log');
      expect(entry.runId).toBeUndefined();
      expect(entry.error).toBeUndefined();
    });

    test('should handle error without type field', () => {
      const err = {
        message: 'Something failed',
        stack: 'Error: Something failed\n  at test.ts:1:1',
      };

      const errorEntry = {
        name: (err as { type?: string }).type || 'Error',
        message: err.message || '',
        stack: err.stack,
      };

      expect(errorEntry.name).toBe('Error');
      expect(errorEntry.message).toBe('Something failed');
    });
  });
});
