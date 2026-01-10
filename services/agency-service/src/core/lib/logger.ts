/**
 * Structured Logger with Rotating Files
 *
 * Uses Pino for structured logging with rotating-file-stream for file rotation.
 * Log files: services/agency-service/logs/log-YYYYMMDD-HHMM.log
 */

import pino from 'pino';
import { createStream } from 'rotating-file-stream';
import { getConfig } from '../config';
import fs from 'fs';
import path from 'path';

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

  // Targets for multi-destination logging
  const targets: pino.TransportTargetOptions[] = [];

  // Always log to rotating files
  if (config.logDir) {
    // We'll use pino.multistream for file + console
  }

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

export default getLogger;
