/**
 * Queue Adapter Tests
 *
 * Tests for SQLite-backed queue adapter.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteQueueAdapter, type QueueAdapter } from '../../src/core/adapters/queue';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('SQLite Queue Adapter', () => {
  let queue: QueueAdapter;
  const testDbPath = '/tmp/agency-test-queue';
  const testDbFile = `${testDbPath}/queue.db`;

  beforeEach(async () => {
    queue = createSQLiteQueueAdapter({
      adapter: 'sqlite',
      dbPath: testDbPath,
      pollInterval: 100, // Fast polling for tests
    });
    await queue.initialize();
  });

  afterEach(async () => {
    await queue.close();
    // Clean up test database
    try {
      if (existsSync(testDbFile)) await unlink(testDbFile);
      if (existsSync(`${testDbFile}-wal`)) await unlink(`${testDbFile}-wal`);
      if (existsSync(`${testDbFile}-shm`)) await unlink(`${testDbFile}-shm`);
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  test('should initialize and create database file', async () => {
    expect(existsSync(testDbFile)).toBe(true);
  });

  test('should pass health check', async () => {
    const healthy = await queue.healthCheck();
    expect(healthy).toBe(true);
  });

  test('should enqueue and return job ID', async () => {
    const jobId = await queue.enqueue('test-queue', {
      data: { message: 'hello' },
    });

    expect(jobId).toBeDefined();
    expect(typeof jobId).toBe('string');
    expect(jobId.length).toBeGreaterThan(0);
  });

  test('should dequeue jobs in FIFO order', async () => {
    await queue.enqueue('fifo-queue', { data: { order: 1 } });
    await queue.enqueue('fifo-queue', { data: { order: 2 } });
    await queue.enqueue('fifo-queue', { data: { order: 3 } });

    const job1 = await queue.dequeue<{ order: number }>('fifo-queue');
    const job2 = await queue.dequeue<{ order: number }>('fifo-queue');
    const job3 = await queue.dequeue<{ order: number }>('fifo-queue');

    expect(job1!.data.order).toBe(1);
    expect(job2!.data.order).toBe(2);
    expect(job3!.data.order).toBe(3);
  });

  test('should return null when queue is empty', async () => {
    const job = await queue.dequeue('empty-queue');
    expect(job).toBeNull();
  });

  test('should respect priority (higher first)', async () => {
    await queue.enqueue('priority-queue', { data: { name: 'low' }, priority: 1 });
    await queue.enqueue('priority-queue', { data: { name: 'high' }, priority: 10 });
    await queue.enqueue('priority-queue', { data: { name: 'medium' }, priority: 5 });

    const job1 = await queue.dequeue<{ name: string }>('priority-queue');
    const job2 = await queue.dequeue<{ name: string }>('priority-queue');
    const job3 = await queue.dequeue<{ name: string }>('priority-queue');

    expect(job1!.data.name).toBe('high');
    expect(job2!.data.name).toBe('medium');
    expect(job3!.data.name).toBe('low');
  });

  test('should complete jobs', async () => {
    const jobId = await queue.enqueue('complete-queue', { data: { task: 'do something' } });
    const job = await queue.dequeue('complete-queue');

    await queue.complete(job!.id!);

    // Job should not be available again
    const nextJob = await queue.dequeue('complete-queue');
    expect(nextJob).toBeNull();
  });

  test('should track pending count', async () => {
    expect(await queue.getPendingCount('count-queue')).toBe(0);

    await queue.enqueue('count-queue', { data: { n: 1 } });
    await queue.enqueue('count-queue', { data: { n: 2 } });
    await queue.enqueue('count-queue', { data: { n: 3 } });

    expect(await queue.getPendingCount('count-queue')).toBe(3);

    const job = await queue.dequeue('count-queue');
    await queue.complete(job!.id!);

    expect(await queue.getPendingCount('count-queue')).toBe(2);
  });

  test('should fail and retry jobs', async () => {
    await queue.enqueue('retry-queue', {
      data: { attempt: 0 },
      maxAttempts: 3,
    });

    // First attempt - fail it
    const job1 = await queue.dequeue<{ attempt: number }>('retry-queue');
    expect(job1!.attempts).toBe(1);
    await queue.fail(job1!.id!, 'First failure');

    // Wait for retry delay
    await new Promise(resolve => setTimeout(resolve, 2100));

    // Second attempt
    const job2 = await queue.dequeue<{ attempt: number }>('retry-queue');
    expect(job2!.attempts).toBe(2);
    await queue.complete(job2!.id!);

    // No more retries needed
    const job3 = await queue.dequeue('retry-queue');
    expect(job3).toBeNull();
  });

  test('should isolate queues by name', async () => {
    await queue.enqueue('queue-a', { data: { queue: 'a' } });
    await queue.enqueue('queue-b', { data: { queue: 'b' } });

    const jobA = await queue.dequeue<{ queue: string }>('queue-a');
    const jobB = await queue.dequeue<{ queue: string }>('queue-b');

    expect(jobA!.data.queue).toBe('a');
    expect(jobB!.data.queue).toBe('b');
  });
});
