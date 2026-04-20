import { describe, expect, it, beforeEach, afterEach } from 'vitest';
import { mkdtempSync, rmSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import {
  validateName,
  validateFreeText,
  validateTypeName,
  validateWorkstream,
  validateStarterPack,
  validateServiceCollision,
  validateUiCollision,
  toPascalCase,
  toCamelCase,
} from '../validators';

let root: string;

beforeEach(() => {
  root = mkdtempSync(join(tmpdir(), 'service-add-validators-'));
  mkdirSync(resolve(root, 'claude', 'workstreams', 'devex'), { recursive: true });
  mkdirSync(resolve(root, 'claude', 'starter-packs', 'nestjs-prototype'), { recursive: true });
  writeFileSync(
    resolve(root, 'claude', 'starter-packs', 'nestjs-prototype', 'install.sh'),
    '#!/bin/bash\n',
  );
  writeFileSync(
    resolve(root, 'claude', 'starter-packs', 'nestjs-prototype', 'manifest.yaml'),
    'name: test\n',
  );
});

afterEach(() => {
  rmSync(root, { recursive: true, force: true });
});

describe('validateName', () => {
  it('accepts kebab-case names', () => {
    expect(validateName('payments').ok).toBe(true);
    expect(validateName('payment-methods').ok).toBe(true);
    expect(validateName('a1-b2-c3').ok).toBe(true);
  });

  it('accepts single-letter name (lower bound of 1 char)', () => {
    expect(validateName('a').ok).toBe(true);
  });

  it('rejects empty name', () => {
    const r = validateName('');
    expect(r.ok).toBe(false);
    expect(r.error).toMatch(/required/i);
  });

  it('rejects non-kebab', () => {
    expect(validateName('PaymentsAPI').ok).toBe(false);
    expect(validateName('payments_api').ok).toBe(false);
    expect(validateName('payments api').ok).toBe(false);
    expect(validateName('2payments').ok).toBe(false); // can't start with digit
  });

  it('rejects trailing hyphen (PascalCase collision guard)', () => {
    // `foo-` → `Foo` collides with `foo` → `Foo`
    expect(validateName('payments-').ok).toBe(false);
  });

  it('rejects consecutive hyphens (PascalCase collision guard)', () => {
    // `foo--bar` and `foo-bar` both → `FooBar`
    expect(validateName('foo--bar').ok).toBe(false);
    expect(validateName('a---b').ok).toBe(false);
  });

  it('rejects leading hyphen', () => {
    expect(validateName('-payments').ok).toBe(false);
  });

  it('rejects reserved names', () => {
    expect(validateName('backend').ok).toBe(false);
    expect(validateName('gateway').ok).toBe(false);
    expect(validateName('tools').ok).toBe(false);
  });

  it('rejects names longer than 32 chars', () => {
    const long = 'a' + 'b'.repeat(32); // 33 chars
    expect(validateName(long).ok).toBe(false);
  });

  it('accepts 32-char names', () => {
    const ok = 'a' + 'b'.repeat(31); // 32 chars
    expect(validateName(ok).ok).toBe(true);
  });
});

describe('validateFreeText', () => {
  it('accepts normal descriptions', () => {
    expect(validateFreeText('A simple description.', '--description').ok).toBe(true);
    expect(validateFreeText('With numbers 123 and punctuation.', '--description').ok).toBe(true);
  });

  it('accepts undefined / empty (optional field)', () => {
    expect(validateFreeText(undefined, '--description').ok).toBe(true);
    expect(validateFreeText('', '--description').ok).toBe(true);
  });

  it('rejects shell command substitution', () => {
    // $(...) and backticks — live shell RCE primitives
    expect(validateFreeText('$(whoami)', '--description').ok).toBe(false);
    expect(validateFreeText('`id`', '--description').ok).toBe(false);
    expect(validateFreeText('pre $VAR post', '--description').ok).toBe(false);
  });

  it('rejects JSDoc close marker (comment breakout)', () => {
    // `*/` closes the JSDoc block and lets injected TS follow
    expect(validateFreeText('*/ injected /*', '--description').ok).toBe(false);
  });

  it("rejects backslash (string-literal breakout via \\\\\\')", () => {
    expect(validateFreeText("foo\\'; bad code; //", '--description').ok).toBe(false);
  });

  it('rejects newline / carriage return', () => {
    expect(validateFreeText('line1\nline2', '--description').ok).toBe(false);
    expect(validateFreeText('line1\rline2', '--description').ok).toBe(false);
  });

  it('enforces length cap (200 chars)', () => {
    const long = 'a'.repeat(201);
    const r = validateFreeText(long, '--description');
    expect(r.ok).toBe(false);
    expect(r.error).toMatch(/≤200/);
  });

  it('accepts exactly 200 chars', () => {
    expect(validateFreeText('a'.repeat(200), '--description').ok).toBe(true);
  });

  it('includes field name in error', () => {
    const r = validateFreeText('$(evil)', '--owner');
    expect(r.error).toMatch(/--owner/);
  });
});

describe('validateTypeName', () => {
  it('accepts existing pack names', () => {
    expect(validateTypeName('nestjs-prototype').ok).toBe(true);
    expect(validateTypeName('nextjs-app').ok).toBe(true);
  });

  it('rejects empty type', () => {
    expect(validateTypeName('').ok).toBe(false);
  });

  it('rejects path traversal attempts', () => {
    expect(validateTypeName('../etc/passwd').ok).toBe(false);
    expect(validateTypeName('./evil').ok).toBe(false);
    expect(validateTypeName('foo/bar').ok).toBe(false);
    expect(validateTypeName('foo\\bar').ok).toBe(false);
  });

  it('rejects type with uppercase', () => {
    expect(validateTypeName('NestJS-prototype').ok).toBe(false);
  });
});

describe('validateWorkstream', () => {
  it('accepts existing workstream', () => {
    expect(validateWorkstream('devex', root).ok).toBe(true);
  });

  it('rejects missing workstream', () => {
    const r = validateWorkstream('nonexistent', root);
    expect(r.ok).toBe(false);
    expect(r.error).toMatch(/not found/);
  });

  it('rejects empty name', () => {
    expect(validateWorkstream('', root).ok).toBe(false);
  });
});

describe('validateStarterPack', () => {
  it('accepts existing pack', () => {
    expect(validateStarterPack('nestjs-prototype', root).ok).toBe(true);
  });

  it('rejects missing pack', () => {
    const r = validateStarterPack('nonexistent', root);
    expect(r.ok).toBe(false);
    expect(r.error).toMatch(/not found/);
  });

  it('rejects pack missing install.sh', () => {
    mkdirSync(resolve(root, 'claude', 'starter-packs', 'broken'));
    writeFileSync(resolve(root, 'claude', 'starter-packs', 'broken', 'manifest.yaml'), '');
    const r = validateStarterPack('broken', root);
    expect(r.ok).toBe(false);
    expect(r.error).toMatch(/install\.sh/);
  });

  it('rejects pack missing manifest.yaml', () => {
    mkdirSync(resolve(root, 'claude', 'starter-packs', 'no-manifest'));
    writeFileSync(
      resolve(root, 'claude', 'starter-packs', 'no-manifest', 'install.sh'),
      '#!/bin/bash\n',
    );
    const r = validateStarterPack('no-manifest', root);
    expect(r.ok).toBe(false);
    expect(r.error).toMatch(/manifest\.yaml/);
  });
});

describe('validateServiceCollision', () => {
  it('accepts no collision', () => {
    expect(validateServiceCollision('new-thing', root).ok).toBe(true);
  });

  it('rejects collision', () => {
    mkdirSync(resolve(root, 'apps', 'backend', 'src', 'prototype', 'existing'), {
      recursive: true,
    });
    const r = validateServiceCollision('existing', root);
    expect(r.ok).toBe(false);
    expect(r.error).toMatch(/already exists/);
  });
});

describe('validateUiCollision', () => {
  it('accepts no collision', () => {
    expect(validateUiCollision('new-ui', root).ok).toBe(true);
  });

  it('rejects collision', () => {
    mkdirSync(resolve(root, 'apps', 'existing-ui'), { recursive: true });
    const r = validateUiCollision('existing-ui', root);
    expect(r.ok).toBe(false);
    expect(r.error).toMatch(/already exists/);
  });
});

describe('toPascalCase', () => {
  it('converts single word', () => {
    expect(toPascalCase('payments')).toBe('Payments');
  });

  it('converts multi-part kebab', () => {
    expect(toPascalCase('payment-methods')).toBe('PaymentMethods');
    expect(toPascalCase('a-b-c')).toBe('ABC');
  });

  it('handles empty string', () => {
    expect(toPascalCase('')).toBe('');
  });
});

describe('toCamelCase', () => {
  it('converts single word', () => {
    expect(toCamelCase('payments')).toBe('payments');
  });

  it('converts multi-part kebab', () => {
    expect(toCamelCase('payment-methods')).toBe('paymentMethods');
  });
});
