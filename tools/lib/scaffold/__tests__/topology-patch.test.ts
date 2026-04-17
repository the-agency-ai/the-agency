import { describe, expect, it, beforeEach, afterEach } from 'vitest';
import { mkdtempSync, rmSync, writeFileSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { applyTopologyPatch, isServicePresent, type ServicePatch } from '../topology-patch';

const BASE_TOPOLOGY = `name: test
version: 1

services:
  # --- Compute ---

  backend:
    type: compute
    build: apps/backend
    health: /health

  # --- Frontends ---

  doctor-frontend:
    type: frontend
    build: apps/doctor-frontend
    wires_from:
      - backend
`;

let dir: string;
let topologyPath: string;

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), 'topology-patch-'));
  topologyPath = join(dir, 'topology.yaml');
  writeFileSync(topologyPath, BASE_TOPOLOGY, 'utf-8');
});

afterEach(() => {
  rmSync(dir, { recursive: true, force: true });
});

describe('applyTopologyPatch', () => {
  it('adds a new frontend service', () => {
    const patch: ServicePatch = {
      name: 'payments-ui',
      type: 'frontend',
      build: 'apps/payments-ui',
      wires_from: ['backend'],
      env: { NEXT_PUBLIC_API_URL: '{{backend.outputs.url}}' },
    };
    const result = applyTopologyPatch(patch, { topologyPath });
    expect(result.status).toBe('added');
    expect(result.message).toMatch(/Added "payments-ui"/);

    const after = readFileSync(topologyPath, 'utf-8');
    expect(after).toContain('payments-ui:');
    expect(after).toContain('type: frontend');
    expect(after).toContain('build: apps/payments-ui');
    expect(after).toContain('NEXT_PUBLIC_API_URL');
  });

  it('adds a new compute service', () => {
    const patch: ServicePatch = {
      name: 'payment-processor',
      type: 'compute',
      build: 'apps/payment-processor',
      health: '/health',
      depends_on: ['db-main'],
    };
    const result = applyTopologyPatch(patch, { topologyPath });
    expect(result.status).toBe('added');

    const after = readFileSync(topologyPath, 'utf-8');
    expect(after).toContain('payment-processor:');
    expect(after).toContain('type: compute');
    expect(after).toContain('depends_on:');
    expect(after).toContain('- db-main');
  });

  it('is idempotent for matching entries', () => {
    const patch: ServicePatch = {
      name: 'new-fe',
      type: 'frontend',
      build: 'apps/new-fe',
    };
    applyTopologyPatch(patch, { topologyPath });
    const second = applyTopologyPatch(patch, { topologyPath });
    expect(second.status).toBe('already-present');
  });

  it('reports conflict for mismatched entries', () => {
    const patch: ServicePatch = { name: 'new-fe', type: 'frontend', build: 'apps/new-fe' };
    applyTopologyPatch(patch, { topologyPath });
    const conflict = applyTopologyPatch(
      { name: 'new-fe', type: 'frontend', build: 'apps/different-path' },
      { topologyPath },
    );
    expect(conflict.status).toBe('conflict');
  });

  it('does not write when dry-run is true', () => {
    const patch: ServicePatch = { name: 'dry', type: 'frontend', build: 'apps/dry' };
    const before = readFileSync(topologyPath, 'utf-8');
    const result = applyTopologyPatch(patch, { topologyPath, dryRun: true });
    expect(result.status).toBe('added');
    expect(result.message).toMatch(/dry-run/);
    const after = readFileSync(topologyPath, 'utf-8');
    expect(after).toBe(before);
  });

  it('preserves existing services after adding', () => {
    const patch: ServicePatch = { name: 'new-fe', type: 'frontend', build: 'apps/new-fe' };
    applyTopologyPatch(patch, { topologyPath });
    const after = readFileSync(topologyPath, 'utf-8');
    // Existing entries must still be present
    expect(after).toContain('backend:');
    expect(after).toContain('doctor-frontend:');
    // Comments must still be there
    expect(after).toContain('# --- Compute ---');
  });

  it('returns yaml block in diff', () => {
    const patch: ServicePatch = {
      name: 'with-env',
      type: 'frontend',
      build: 'apps/with-env',
      env: { FOO: 'bar' },
    };
    const result = applyTopologyPatch(patch, { topologyPath, dryRun: true });
    expect(result.diff).toBeDefined();
    expect(result.diff).toContain('with-env:');
  });
});

describe('isServicePresent', () => {
  it('returns true for existing service', () => {
    expect(isServicePresent(topologyPath, 'backend')).toBe(true);
    expect(isServicePresent(topologyPath, 'doctor-frontend')).toBe(true);
  });

  it('returns false for missing service', () => {
    expect(isServicePresent(topologyPath, 'nonexistent')).toBe(false);
  });
});

// --- TEST-2: no services: section -----------------------------------------

describe('applyTopologyPatch — no services: section', () => {
  it('returns conflict when topology.yaml has no services: key', () => {
    writeFileSync(topologyPath, 'name: empty\nversion: 1\n', 'utf-8');
    const r = applyTopologyPatch(
      { name: 'foo', type: 'frontend', build: 'apps/foo' },
      { topologyPath },
    );
    expect(r.status).toBe('conflict');
    expect(r.message).toMatch(/no services: section/);
  });

  it('returns conflict when services: is null (empty block)', () => {
    writeFileSync(topologyPath, 'name: test\nversion: 1\nservices:\n', 'utf-8');
    const r = applyTopologyPatch(
      { name: 'foo', type: 'frontend', build: 'apps/foo' },
      { topologyPath },
    );
    expect(r.status).toBe('conflict');
  });
});

// --- TEST-3: entriesMatch env / migrate / wires_from ----------------------

describe('applyTopologyPatch — entriesMatch coverage', () => {
  it('reports already-present when wires_from matches', () => {
    const patch: ServicePatch = {
      name: 'new-fe',
      type: 'frontend',
      build: 'apps/new-fe',
      wires_from: ['backend'],
    };
    applyTopologyPatch(patch, { topologyPath });
    const second = applyTopologyPatch(patch, { topologyPath });
    expect(second.status).toBe('already-present');
  });

  it('reports conflict when wires_from differs', () => {
    applyTopologyPatch(
      { name: 'new-fe', type: 'frontend', build: 'apps/new-fe', wires_from: ['backend'] },
      { topologyPath },
    );
    const conflict = applyTopologyPatch(
      {
        name: 'new-fe',
        type: 'frontend',
        build: 'apps/new-fe',
        wires_from: ['backend', 'db-main'],
      },
      { topologyPath },
    );
    expect(conflict.status).toBe('conflict');
  });

  it('reports already-present when env matches', () => {
    const patch: ServicePatch = {
      name: 'new-fe',
      type: 'frontend',
      build: 'apps/new-fe',
      env: { NEXT_PUBLIC_API_URL: '{{backend.outputs.url}}', OTHER: 'val' },
    };
    applyTopologyPatch(patch, { topologyPath });
    const second = applyTopologyPatch(patch, { topologyPath });
    expect(second.status).toBe('already-present');
  });

  it('reports conflict when env values differ', () => {
    applyTopologyPatch(
      {
        name: 'new-fe',
        type: 'frontend',
        build: 'apps/new-fe',
        env: { NEXT_PUBLIC_API_URL: '{{backend.outputs.url}}' },
      },
      { topologyPath },
    );
    const conflict = applyTopologyPatch(
      {
        name: 'new-fe',
        type: 'frontend',
        build: 'apps/new-fe',
        env: { NEXT_PUBLIC_API_URL: 'https://different.example' },
      },
      { topologyPath },
    );
    expect(conflict.status).toBe('conflict');
  });

  it('reports conflict when env key sets differ', () => {
    applyTopologyPatch(
      { name: 'new-fe', type: 'frontend', build: 'apps/new-fe', env: { A: 'one' } },
      { topologyPath },
    );
    const conflict = applyTopologyPatch(
      { name: 'new-fe', type: 'frontend', build: 'apps/new-fe', env: { A: 'one', B: 'two' } },
      { topologyPath },
    );
    expect(conflict.status).toBe('conflict');
  });

  it('reports already-present when migrate matches', () => {
    const patch: ServicePatch = {
      name: 'new-svc',
      type: 'compute',
      build: 'apps/new-svc',
      migrate: { tool: 'prisma', command: 'migrate-deploy', order: 'before_deploy' },
    };
    applyTopologyPatch(patch, { topologyPath });
    const second = applyTopologyPatch(patch, { topologyPath });
    expect(second.status).toBe('already-present');
  });

  it('reports conflict when migrate presence differs', () => {
    applyTopologyPatch(
      { name: 'new-svc', type: 'compute', build: 'apps/new-svc' },
      { topologyPath },
    );
    const conflict = applyTopologyPatch(
      {
        name: 'new-svc',
        type: 'compute',
        build: 'apps/new-svc',
        migrate: { tool: 'prisma', command: 'migrate-deploy', order: 'before_deploy' },
      },
      { topologyPath },
    );
    expect(conflict.status).toBe('conflict');
  });

  it('reports conflict when migrate order differs', () => {
    applyTopologyPatch(
      {
        name: 'new-svc',
        type: 'compute',
        build: 'apps/new-svc',
        migrate: { tool: 'prisma', command: 'migrate-deploy', order: 'before_deploy' },
      },
      { topologyPath },
    );
    const conflict = applyTopologyPatch(
      {
        name: 'new-svc',
        type: 'compute',
        build: 'apps/new-svc',
        migrate: { tool: 'prisma', command: 'migrate-deploy', order: 'after_deploy' },
      },
      { topologyPath },
    );
    expect(conflict.status).toBe('conflict');
  });
});
