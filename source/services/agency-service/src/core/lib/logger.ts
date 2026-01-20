/**
 * Structured Logger with Rotating Files + Log Service Dual-Write
 *
 * Uses Pino for structured logging with rotating-file-stream for file rotation.
 * Log files: services/agency-service/logs/log-YYYYMMDD-HHMM.log
 *
 * Supports dual-write to log-service for queryable logs via:
 *   enableLogServiceDualWrite(logService)
 */

import pino from 'pino';
import { createStream } from 'rotating-file-stream';
import { Writable } from 'stream';
import { getConfig } from '../config';
import fs from 'fs';
import path from 'path';
import type { LogService } from '../../embedded/log-service/service/log.service';

// Log service reference for dual-write
let _logService: LogService | null = null;

function createLogger() {
  const config = getConfig();

  // Ensure log directory exists
  if (config.logDir) {
    fs.mkdirSync(config.logDir, { recursive: true });
  }

  // Filename generator for rotation
  const filenameGenerator = (time: Date | number, index?: number): string => {
    if (!time) {
      // Initial filename
      const now = new Date();
      const timestamp = now.toISOString().replace(/[-:]/g, '').replace('T', '-').slice(0, 13);
      return `log-${timestamp}.log`;
    }

    // Rotated filename
    const date = time instanceof Date ? time : new Date(time);
    const timestamp = date.toISOString().replace(/[-:]/g, '').replace('T', '-').slice(0, 13);
    return index ? `log-${timestamp}-${index}.log` : `log-${timestamp}.log`;
  };

  // Create rotating file stream
  const fileStream = createStream(filenameGenerator, {
    path: config.logDir,
    size: '10M',      // Rotate every 10MB
    interval: '1d',   // Or daily
    compress: 'gzip', // Compress rotated files
    maxFiles: 30,     // Keep 30 days
  });

  // In development, also log pretty to console
  const streams: pino.StreamEntry[] = [
    { level: config.logLevel, stream: fileStream },
  ];

  if (config.nodeEnv === 'development') {
    // Pretty print to console in dev
    streams.push({
      level: config.logLevel,
      stream: pino.transport({
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:standard',
          ignore: 'pid,hostname',
        },
      }),
    });
  } else {
    // JSON to stdout in production
    streams.push({
      level: config.logLevel,
      stream: process.stdout,
    });
  }

  // Add log service dual-write stream
  const logServiceStream = createLogServiceStream();
  streams.push({
    level: config.logLevel,
    stream: logServiceStream,
  });

  return pino(
    {
      level: config.logLevel,
      base: {
        service: 'agency-service',
        version: '0.1.0',
      },
      timestamp: pino.stdTimeFunctions.isoTime,
    },
    pino.multistream(streams)
  );
}

/**
 * Create a writable stream that forwards logs to the log service
 */
function createLogServiceStream(): NodeJS.WritableStream {
  return new Writable({
    objectMode: true,
    write(chunk: Buffer | string, encoding: string, callback: () => void) {
      // Skip if no log service connected
      if (!_logService) {
        callback();
        return;
      }

      try {
        const logObj = typeof chunk === 'string' ? JSON.parse(chunk) : JSON.parse(chunk.toString());

        // Map pino log levels (numbers) to our level strings
        const levelMap: Record<number, string> = {
          10: 'trace',
          20: 'debug',
          30: 'info',
          40: 'warn',
          50: 'error',
          60: 'fatal',
        };

        const level = levelMap[logObj.level] || 'info';

        // Extract service name (from child logger or base)
        const service = logObj.service || 'agency-service';

        // Build log entry
        const entry = {
          service,
          level: level as 'trace' | 'debug' | 'info' | 'warn' | 'error' | 'fatal',
          message: logObj.msg || '',
          runId: logObj.runId,
          requestId: logObj.requestId,
          userId: logObj.userId,
          userType: logObj.userType,
          data: extractData(logObj),
          error: logObj.err ? {
            name: logObj.err.type || 'Error',
            message: logObj.err.message || '',
            stack: logObj.err.stack,
          } : undefined,
        };

        // Async ingest (fire and forget to avoid blocking)
        _logService.ingest(entry).catch(() => {
          // Silently ignore ingestion errors to avoid log loops
        });
      } catch {
        // Ignore parse errors
      }

      callback();
    },
  });
}

/**
 * Extract structured data from pino log object
 * Excludes standard pino fields
 */
function extractData(logObj: Record<string, unknown>): Record<string, unknown> | undefined {
  const excludeKeys = new Set([
    'level', 'time', 'msg', 'pid', 'hostname', 'service', 'version',
    'runId', 'requestId', 'userId', 'userType', 'err',
  ]);

  const data: Record<string, unknown> = {};
  let hasData = false;

  for (const [key, value] of Object.entries(logObj)) {
    if (!excludeKeys.has(key)) {
      data[key] = value;
      hasData = true;
    }
  }

  return hasData ? data : undefined;
}

// Singleton logger
let _logger: pino.Logger | null = null;

export function getLogger(): pino.Logger {
  if (!_logger) {
    _logger = createLogger();
  }
  return _logger;
}

// Create child logger for a specific service
export function createServiceLogger(serviceName: string): pino.Logger {
  return getLogger().child({ service: serviceName });
}

/**
 * Enable dual-write to log service
 * Call this after log service is initialized
 */
export function enableLogServiceDualWrite(logService: LogService): void {
  _logService = logService;
}

/**
 * Disable dual-write to log service
 */
export function disableLogServiceDualWrite(): void {
  _logService = null;
}

/**
 * Check if log service dual-write is enabled
 */
export function isLogServiceDualWriteEnabled(): boolean {
  return _logService !== null;
}

export default getLogger;
