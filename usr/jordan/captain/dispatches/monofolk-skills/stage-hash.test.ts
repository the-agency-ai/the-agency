import { describe, expect, it, beforeEach, afterAll } from 'vitest';
import { execFileSync, execSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { computeStageHash } from '../lib/stage-hash';

/**
 * Tests for the stage hash utility.
 *
 * Each test creates a temporary git repo with staged files to verify
 * determinism, ordering independence, and content sensitivity.
 */

const BASE_TMP = mkdtempSync(join(tmpdir(), 'stage-hash-test-'));

function createGitRepo(): string {
  const dir = mkdtempSync(join(BASE_TMP, 'repo-'));
  execFileSync('git', ['init', '--initial-branch=main'], { cwd: dir });
  execFileSync('git', ['config', 'user.email', 'test@test.com'], { cwd: dir });
  execFileSync('git', ['config', 'user.name', 'Test'], { cwd: dir });
  // Need at least one commit for ls-files to work properly
  writeFileSync(join(dir, '.gitkeep'), '');
  execFileSync('git', ['add', '.gitkeep'], { cwd: dir });
  execFileSync('git', ['commit', '-m', 'init'], { cwd: dir });
  return dir;
}

afterAll(() => {
  rmSync(BASE_TMP, { recursive: true, force: true });
});

describe('computeStageHash', () => {
  it('throws when nothing is staged', () => {
    const dir = createGitRepo();
    expect(() => computeStageHash(dir)).toThrow('No files are staged');
  });

  it('returns a 7-character hex hash', () => {
    const dir = createGitRepo();
    writeFileSync(join(dir, 'a.txt'), 'hello');
    execFileSync('git', ['add', 'a.txt'], { cwd: dir });

    const result = computeStageHash(dir);
    expect(result.hash).toMatch(/^[0-9a-f]{7}$/);
  });

  it('returns file count and file list', () => {
    const dir = createGitRepo();
    writeFileSync(join(dir, 'a.txt'), 'hello');
    writeFileSync(join(dir, 'b.txt'), 'world');
    execFileSync('git', ['add', 'a.txt', 'b.txt'], { cwd: dir });

    const result = computeStageHash(dir);
    expect(result.fileCount).toBe(2);
    expect(result.files).toEqual(['a.txt', 'b.txt']);
  });

  it('is deterministic — same staged content produces same hash', () => {
    const dir1 = createGitRepo();
    writeFileSync(join(dir1, 'a.txt'), 'hello');
    execFileSync('git', ['add', 'a.txt'], { cwd: dir1 });

    const dir2 = createGitRepo();
    writeFileSync(join(dir2, 'a.txt'), 'hello');
    execFileSync('git', ['add', 'a.txt'], { cwd: dir2 });

    const result1 = computeStageHash(dir1);
    const result2 = computeStageHash(dir2);
    expect(result1.hash).toBe(result2.hash);
  });

  it('changes when file content changes', () => {
    const dir = createGitRepo();
    writeFileSync(join(dir, 'a.txt'), 'hello');
    execFileSync('git', ['add', 'a.txt'], { cwd: dir });
    const hash1 = computeStageHash(dir).hash;

    // Unstage, modify, restage
    execFileSync('git', ['reset', 'HEAD', 'a.txt'], { cwd: dir });
    writeFileSync(join(dir, 'a.txt'), 'world');
    execFileSync('git', ['add', 'a.txt'], { cwd: dir });
    const hash2 = computeStageHash(dir).hash;

    expect(hash1).not.toBe(hash2);
  });

  it('changes when a different file is staged', () => {
    const dir = createGitRepo();
    writeFileSync(join(dir, 'a.txt'), 'hello');
    execFileSync('git', ['add', 'a.txt'], { cwd: dir });
    const hash1 = computeStageHash(dir).hash;

    execFileSync('git', ['reset', 'HEAD', 'a.txt'], { cwd: dir });
    writeFileSync(join(dir, 'b.txt'), 'hello');
    execFileSync('git', ['add', 'b.txt'], { cwd: dir });
    const hash2 = computeStageHash(dir).hash;

    expect(hash1).not.toBe(hash2);
  });

  it('is order-independent — staging a,b produces same hash as b,a', () => {
    const dir1 = createGitRepo();
    writeFileSync(join(dir1, 'a.txt'), 'aaa');
    writeFileSync(join(dir1, 'b.txt'), 'bbb');
    execFileSync('git', ['add', 'a.txt', 'b.txt'], { cwd: dir1 });

    const dir2 = createGitRepo();
    writeFileSync(join(dir2, 'b.txt'), 'bbb');
    writeFileSync(join(dir2, 'a.txt'), 'aaa');
    execFileSync('git', ['add', 'b.txt', 'a.txt'], { cwd: dir2 });

    expect(computeStageHash(dir1).hash).toBe(computeStageHash(dir2).hash);
  });

  it('handles staged deletions', () => {
    const dir = createGitRepo();
    writeFileSync(join(dir, 'a.txt'), 'hello');
    execFileSync('git', ['add', 'a.txt'], { cwd: dir });
    execFileSync('git', ['commit', '-m', 'add a'], { cwd: dir });

    // Stage deletion
    execFileSync('git', ['rm', 'a.txt'], { cwd: dir });
    const result = computeStageHash(dir);
    expect(result.hash).toMatch(/^[0-9a-f]{7}$/);
    expect(result.files).toContain('a.txt');
  });

  it('handles multiple files with nested paths', () => {
    const dir = createGitRepo();
    execSync(`mkdir -p src/lib`, { cwd: dir });
    writeFileSync(join(dir, 'src/lib/foo.ts'), 'export const foo = 1;');
    writeFileSync(join(dir, 'src/lib/bar.ts'), 'export const bar = 2;');
    writeFileSync(join(dir, 'README.md'), '# Hello');
    execFileSync('git', ['add', 'src/lib/foo.ts', 'src/lib/bar.ts', 'README.md'], { cwd: dir });

    const result = computeStageHash(dir);
    expect(result.fileCount).toBe(3);
    expect(result.files).toEqual(['README.md', 'src/lib/bar.ts', 'src/lib/foo.ts']);
  });
});
