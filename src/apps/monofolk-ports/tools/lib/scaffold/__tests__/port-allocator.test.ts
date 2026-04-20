import { describe, expect, it, beforeEach, afterEach } from 'vitest';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { allocatePort, isPortInUse, RANGES } from '../port-allocator';

let dir: string;

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), 'port-alloc-'));
});

afterEach(() => {
  rmSync(dir, { recursive: true, force: true });
});

describe('allocatePort', () => {
  it('returns range start when no ports used', () => {
    writeFileSync(join(dir, 'docker-compose.dev.yml'), 'services: {}\n');
    expect(allocatePort(RANGES.frontend, dir)).toBe(4100);
    expect(allocatePort(RANGES.backend, dir)).toBe(4010);
  });

  it('skips used ports', () => {
    const compose = `services:
  foo:
    ports:
      - "4100:4100"
      - "4101:4101"
`;
    writeFileSync(join(dir, 'docker-compose.dev.yml'), compose);
    expect(allocatePort(RANGES.frontend, dir)).toBe(4102);
  });

  it('works when compose file missing', () => {
    expect(allocatePort(RANGES.frontend, dir)).toBe(4100);
  });

  it('throws when range exhausted', () => {
    const lines = ['services:', '  foo:', '    ports:'];
    for (let p = 4100; p <= 4199; p++) lines.push(`      - "${p}:${p}"`);
    writeFileSync(join(dir, 'docker-compose.dev.yml'), lines.join('\n') + '\n');
    expect(() => allocatePort(RANGES.frontend, dir)).toThrow(/No free port/);
  });

  it('extracts ports from both dev and default compose files', () => {
    writeFileSync(
      join(dir, 'docker-compose.yml'),
      'services:\n  a:\n    ports:\n      - "4100:4100"\n',
    );
    writeFileSync(
      join(dir, 'docker-compose.dev.yml'),
      'services:\n  b:\n    ports:\n      - "4101:4101"\n',
    );
    expect(allocatePort(RANGES.frontend, dir)).toBe(4102);
  });
});

describe('isPortInUse', () => {
  it('detects used ports', () => {
    writeFileSync(
      join(dir, 'docker-compose.dev.yml'),
      'services:\n  a:\n    ports:\n      - "4010:4010"\n',
    );
    expect(isPortInUse(4010, dir)).toBe(true);
    expect(isPortInUse(4011, dir)).toBe(false);
  });

  it('detects ports from apps/*/package.json scripts (TEST-4 coverage)', () => {
    const { mkdirSync } = require('node:fs') as typeof import('node:fs');
    mkdirSync(join(dir, 'apps', 'foo'), { recursive: true });
    writeFileSync(
      join(dir, 'apps', 'foo', 'package.json'),
      JSON.stringify({ name: 'foo', scripts: { dev: 'next dev --port 4105' } }),
    );
    expect(isPortInUse(4105, dir)).toBe(true);
    expect(isPortInUse(4106, dir)).toBe(false);
  });
});

// --- TEST-4: shell-default var form extraction ----------------------------

describe('allocatePort — shell-default var form', () => {
  it('extracts default port from ${NAME:-4100}:3000', () => {
    writeFileSync(
      join(dir, 'docker-compose.dev.yml'),
      'services:\n  foo:\n    ports:\n      - "${DOCTOR_FE_PORT:-4100}:3000"\n',
    );
    expect(allocatePort(RANGES.frontend, dir)).toBe(4101);
  });

  it('extracts from unquoted ${NAME:-4100}:3000', () => {
    // Unquoted form (less common but valid YAML)
    writeFileSync(
      join(dir, 'docker-compose.dev.yml'),
      'services:\n  foo:\n    ports:\n      - ${DOCTOR_FE_PORT:-4100}:3000\n',
    );
    expect(allocatePort(RANGES.frontend, dir)).toBe(4101);
  });

  it('scans apps/*/package.json next dev --port (sequential ui-add guard)', () => {
    const { mkdirSync } = require('node:fs') as typeof import('node:fs');
    // Simulate: one app already allocated port 4100 via /ui-add but
    // docker-compose hasn't been updated yet.
    mkdirSync(join(dir, 'apps', 'foo'), { recursive: true });
    writeFileSync(
      join(dir, 'apps', 'foo', 'package.json'),
      JSON.stringify({ name: 'foo', scripts: { dev: 'next dev --port 4100' } }),
    );
    // Allocating next port should skip 4100
    expect(allocatePort(RANGES.frontend, dir)).toBe(4101);
  });

  it('scans apps/*/package.json for next start -p N form', () => {
    const { mkdirSync } = require('node:fs') as typeof import('node:fs');
    mkdirSync(join(dir, 'apps', 'foo'), { recursive: true });
    writeFileSync(
      join(dir, 'apps', 'foo', 'package.json'),
      JSON.stringify({ name: 'foo', scripts: { start: 'next start -p 4101' } }),
    );
    // Should see 4100 free but 4101 taken
    expect(allocatePort(RANGES.frontend, dir)).toBe(4100);
    writeFileSync(
      join(dir, 'apps', 'foo', 'package.json'),
      JSON.stringify({ name: 'foo', scripts: { dev: 'next dev -p 4100' } }),
    );
    expect(allocatePort(RANGES.frontend, dir)).toBe(4101);
  });

  it('exhausts the gateway range', () => {
    writeFileSync(join(dir, 'docker-compose.dev.yml'), 'services: {}\n');
    expect(allocatePort(RANGES.gateway, dir)).toBe(4200);
  });
});
