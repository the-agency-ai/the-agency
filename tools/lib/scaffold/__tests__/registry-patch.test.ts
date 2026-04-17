import { describe, expect, it, beforeEach, afterEach } from 'vitest';
import { mkdtempSync, rmSync, writeFileSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { applyRegistryPatch, isRegistryEntryPresent } from '../registry-patch';

const BASE_REGISTRY = `import type { Type } from '@nestjs/common';
import { AirmModule } from './airm/airm.module';
import { CatalogModule } from './catalog/catalog.module';

export interface PrototypeEntry {
  name: string;
  module: Type<unknown>;
  routes: string[];
  description?: string;
  owner?: string;
}

export const PROTOTYPE_REGISTRY: PrototypeEntry[] = [
  {
    name: 'airm',
    module: AirmModule,
    routes: ['GET /health'],
    description: 'AIRM',
    owner: 'Jordan',
  },
  {
    name: 'catalog',
    module: CatalogModule,
    routes: ['GET /health'],
    description: 'Catalog',
    owner: 'Jordan',
  },
];
`;

let dir: string;
let registryPath: string;

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), 'registry-patch-'));
  registryPath = join(dir, 'prototype.registry.ts');
  writeFileSync(registryPath, BASE_REGISTRY, 'utf-8');
});

afterEach(() => {
  rmSync(dir, { recursive: true, force: true });
});

describe('applyRegistryPatch', () => {
  it('adds import + entry for a new module', () => {
    const result = applyRegistryPatch(
      { name: 'payments', description: 'Payments', owner: 'Jordan' },
      { registryPath },
    );
    expect(result.status).toBe('added');

    const after = readFileSync(registryPath, 'utf-8');
    expect(after).toContain("import { PaymentsModule } from './payments/payments.module';");
    expect(after).toContain("name: 'payments'");
    expect(after).toContain('module: PaymentsModule');
    expect(after).toContain("description: 'Payments'");
  });

  it('handles multi-part kebab case names', () => {
    const result = applyRegistryPatch({ name: 'payment-methods' }, { registryPath });
    expect(result.status).toBe('added');
    const after = readFileSync(registryPath, 'utf-8');
    expect(after).toContain(
      "import { PaymentMethodsModule } from './payment-methods/payment-methods.module';",
    );
    expect(after).toContain('module: PaymentMethodsModule');
    expect(after).toContain("name: 'payment-methods'");
  });

  it('preserves existing entries', () => {
    applyRegistryPatch({ name: 'new-svc' }, { registryPath });
    const after = readFileSync(registryPath, 'utf-8');
    expect(after).toContain('AirmModule');
    expect(after).toContain('CatalogModule');
    expect(after).toContain("name: 'airm'");
    expect(after).toContain("name: 'catalog'");
  });

  it('is idempotent — already-present for re-add', () => {
    applyRegistryPatch({ name: 'payments' }, { registryPath });
    const second = applyRegistryPatch({ name: 'payments' }, { registryPath });
    expect(second.status).toBe('already-present');
  });

  it('does not write when dry-run', () => {
    const before = readFileSync(registryPath, 'utf-8');
    const result = applyRegistryPatch({ name: 'payments' }, { registryPath, dryRun: true });
    expect(result.status).toBe('added');
    expect(result.message).toMatch(/dry-run/);
    const after = readFileSync(registryPath, 'utf-8');
    expect(after).toBe(before);
  });

  it('uses default routes if not provided', () => {
    applyRegistryPatch({ name: 'payments' }, { registryPath });
    const after = readFileSync(registryPath, 'utf-8');
    expect(after).toContain("'GET /greet'");
    expect(after).toContain("'GET /build-info'");
    expect(after).toContain("'POST /register-build'");
  });

  it('uses custom routes if provided', () => {
    applyRegistryPatch(
      { name: 'payments', routes: ['POST /charge', 'GET /balance'] },
      { registryPath },
    );
    const after = readFileSync(registryPath, 'utf-8');
    expect(after).toContain("'POST /charge'");
    expect(after).toContain("'GET /balance'");
  });

  it('escapes single quotes in description', () => {
    applyRegistryPatch({ name: 'payments', description: "it's a payment thing" }, { registryPath });
    const after = readFileSync(registryPath, 'utf-8');
    expect(after).toContain("description: 'it\\'s a payment thing'");
  });

  // --- Security: string-literal breakout guards -----------------------------

  it('does not break the file when description contains a backslash', () => {
    // Pre-fix implementation used `.replace(/'/g, "\\'")` which missed backslash.
    // A description like `foo\'; bad = 1; //` would close the TS string mid-way
    // and execute `bad = 1` as live code.
    applyRegistryPatch({ name: 'payments', description: "foo\\'; bad = 1; //" }, { registryPath });
    const after = readFileSync(registryPath, 'utf-8');
    // The description line must end cleanly with `',` — not break mid-string.
    const descLine = after.split('\n').find((l) => l.trim().startsWith('description:'));
    expect(descLine).toBeDefined();
    expect(descLine!).toMatch(/',\s*$/);
    // The injected `bad = 1` must NOT appear as a live TS statement.
    expect(after).not.toMatch(/^\s*bad = 1/m);
  });

  it('does not break the file when description contains JSDoc close marker', () => {
    applyRegistryPatch(
      { name: 'payments', description: 'pre */ injected /* post' },
      { registryPath },
    );
    const after = readFileSync(registryPath, 'utf-8');
    const descLine = after.split('\n').find((l) => l.trim().startsWith('description:'));
    expect(descLine).toBeDefined();
    // The whole description stays inside a single string literal.
    expect(descLine!).toMatch(/',\s*$/);
  });

  // --- Coverage: TEST-1 conflict path (entry exists but import missing) -----

  it('reports conflict when entry exists but import is missing', () => {
    const partial = `import type { Type } from '@nestjs/common';
import { AirmModule } from './airm/airm.module';

export interface PrototypeEntry {
  name: string;
  module: Type<unknown>;
  routes: string[];
}

export const PROTOTYPE_REGISTRY: PrototypeEntry[] = [
  {
    name: 'airm',
    module: AirmModule,
    routes: [],
  },
  {
    name: 'payments',
    module: PaymentsModule,
    routes: [],
  },
];
`;
    writeFileSync(registryPath, partial, 'utf-8');
    const result = applyRegistryPatch({ name: 'payments' }, { registryPath });
    expect(result.status).toBe('conflict');
    expect(result.message).toMatch(/entry named "payments" but no import/);
  });

  // --- Coverage: empty-array bracket handling (CODE-1) ----------------------

  it('inserts into an empty PROTOTYPE_REGISTRY without producing a leading comma', () => {
    const empty = `import type { Type } from '@nestjs/common';

export interface PrototypeEntry {
  name: string;
  module: Type<unknown>;
  routes: string[];
}

export const PROTOTYPE_REGISTRY: PrototypeEntry[] = [];
`;
    writeFileSync(registryPath, empty, 'utf-8');
    const result = applyRegistryPatch({ name: 'payments' }, { registryPath });
    expect(result.status).toBe('added');
    const after = readFileSync(registryPath, 'utf-8');
    // Must NOT start the array body with `,` — that would be a TS syntax error.
    expect(after).not.toMatch(/=\s*\[\s*,/);
    expect(after).toContain("name: 'payments'");
    // Clean `= [\n  {` opening.
    expect(after).toMatch(/=\s*\[\s*\n\s*\{/);
  });

  // --- Idempotent re-add: file content stable after second call -------------

  it('second apply produces identical file content (strong idempotency)', () => {
    applyRegistryPatch({ name: 'payments' }, { registryPath });
    const afterFirst = readFileSync(registryPath, 'utf-8');
    const second = applyRegistryPatch({ name: 'payments' }, { registryPath });
    expect(second.status).toBe('already-present');
    const afterSecond = readFileSync(registryPath, 'utf-8');
    expect(afterSecond).toBe(afterFirst);
  });
});

describe('isRegistryEntryPresent', () => {
  it('returns true for existing entry', () => {
    expect(isRegistryEntryPresent(registryPath, 'airm')).toBe(true);
    expect(isRegistryEntryPresent(registryPath, 'catalog')).toBe(true);
  });

  it('returns false for missing entry', () => {
    expect(isRegistryEntryPresent(registryPath, 'nonexistent')).toBe(false);
  });
});
