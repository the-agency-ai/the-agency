/**
 * Database Adapter Tests
 *
 * Tests for SQLite database adapter.
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { createSQLiteAdapter, type DatabaseAdapter } from '../../src/core/adapters/database';
import { unlink } from 'fs/promises';
import { existsSync } from 'fs';

describe('SQLite Database Adapter', () => {
  let db: DatabaseAdapter;
  const testDbPath = '/tmp/agency-test-db';
  const testDbFile = `${testDbPath}/test.db`;

  beforeEach(async () => {
    db = createSQLiteAdapter({
      adapter: 'sqlite',
      path: testDbPath,
      filename: 'test.db',
    });
    await db.initialize();
  });

  afterEach(async () => {
    await db.close();
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
    const healthy = await db.healthCheck();
    expect(healthy).toBe(true);
  });

  test('should execute SQL', async () => {
    await db.execute('CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)');
    await db.execute('INSERT INTO test (name) VALUES (?)', ['Alice']);

    const rows = await db.query<{ id: number; name: string }>('SELECT * FROM test');
    expect(rows.length).toBe(1);
    expect(rows[0].name).toBe('Alice');
  });

  test('should query with parameters', async () => {
    await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)');
    await db.execute('INSERT INTO users (name, age) VALUES (?, ?)', ['Bob', 30]);
    await db.execute('INSERT INTO users (name, age) VALUES (?, ?)', ['Carol', 25]);

    const rows = await db.query<{ name: string; age: number }>(
      'SELECT * FROM users WHERE age > ?',
      [27]
    );
    expect(rows.length).toBe(1);
    expect(rows[0].name).toBe('Bob');
  });

  test('should get single row', async () => {
    await db.execute('CREATE TABLE items (id INTEGER PRIMARY KEY, value TEXT)');
    await db.execute('INSERT INTO items (value) VALUES (?)', ['test']);

    const row = await db.get<{ id: number; value: string }>('SELECT * FROM items WHERE id = ?', [1]);
    expect(row).not.toBeNull();
    expect(row!.value).toBe('test');
  });

  test('should return null for non-existent row', async () => {
    await db.execute('CREATE TABLE empty_table (id INTEGER PRIMARY KEY)');

    const row = await db.get<{ id: number }>('SELECT * FROM empty_table WHERE id = ?', [999]);
    expect(row).toBeNull();
  });

  test('should insert and return lastInsertRowid', async () => {
    await db.execute('CREATE TABLE seq (id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT)');

    const id1 = await db.insert('INSERT INTO seq (data) VALUES (?)', ['first']);
    const id2 = await db.insert('INSERT INTO seq (data) VALUES (?)', ['second']);

    expect(id1).toBe(1);
    expect(id2).toBe(2);
  });

  test('should update and return changes count', async () => {
    await db.execute('CREATE TABLE mutable (id INTEGER PRIMARY KEY, status TEXT)');
    await db.execute('INSERT INTO mutable (status) VALUES (?)', ['pending']);
    await db.execute('INSERT INTO mutable (status) VALUES (?)', ['pending']);
    await db.execute('INSERT INTO mutable (status) VALUES (?)', ['done']);

    const changes = await db.update('UPDATE mutable SET status = ? WHERE status = ?', ['done', 'pending']);
    expect(changes).toBe(2);
  });

  test('should delete and return changes count', async () => {
    await db.execute('CREATE TABLE deletable (id INTEGER PRIMARY KEY, keep INTEGER)');
    await db.execute('INSERT INTO deletable (keep) VALUES (?)', [1]);
    await db.execute('INSERT INTO deletable (keep) VALUES (?)', [0]);
    await db.execute('INSERT INTO deletable (keep) VALUES (?)', [0]);

    const changes = await db.delete('DELETE FROM deletable WHERE keep = ?', [0]);
    expect(changes).toBe(2);

    const remaining = await db.query<{ id: number }>('SELECT * FROM deletable');
    expect(remaining.length).toBe(1);
  });

  test('should handle transactions', async () => {
    await db.execute('CREATE TABLE account (id INTEGER PRIMARY KEY, balance INTEGER)');
    await db.execute('INSERT INTO account (id, balance) VALUES (?, ?)', [1, 100]);
    await db.execute('INSERT INTO account (id, balance) VALUES (?, ?)', [2, 50]);

    await db.transaction(async (tx) => {
      await tx.update('UPDATE account SET balance = balance - ? WHERE id = ?', [30, 1]);
      await tx.update('UPDATE account SET balance = balance + ? WHERE id = ?', [30, 2]);
    });

    const acc1 = await db.get<{ balance: number }>('SELECT balance FROM account WHERE id = ?', [1]);
    const acc2 = await db.get<{ balance: number }>('SELECT balance FROM account WHERE id = ?', [2]);

    expect(acc1!.balance).toBe(70);
    expect(acc2!.balance).toBe(80);
  });
});
