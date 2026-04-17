/**
 * Argument validators shared by service-add and ui-add.
 *
 * Validates:
 *   - service/ui name (kebab-case, length, reserved words)
 *   - workstream existence
 *   - starter pack existence
 *   - collision with existing files/services
 *
 * All validators return { ok: true } or { ok: false, error: string }.
 */

import { existsSync, statSync } from 'node:fs';
import { resolve } from 'node:path';

export interface ValidationResult {
  ok: boolean;
  error?: string;
}

// Strict kebab-case: starts with a letter, single internal hyphens only, no trailing hyphen.
// Length 1–32 enforced after regex via explicit length check.
const KEBAB_CASE = /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/;
const MAX_NAME_LEN = 32;

const RESERVED_NAMES = new Set([
  'backend',
  'gateway',
  'dns',
  'secrets',
  'db',
  'test',
  'tests',
  'node_modules',
  'dist',
  'build',
  'src',
  'lib',
  'tools',
  'apps',
  'claude',
]);

// Free-text input (description, owner) — rejects shell metacharacters, TS
// string-literal breakouts, JSDoc close markers, and newlines. Caps length
// at 200 chars. Scoped to the *minimum* charset that can safely flow through
// a bash heredoc, a TypeScript single-quoted string, and a JSDoc comment.
const FREE_TEXT_MAX_LEN = 200;
const FREE_TEXT_FORBIDDEN = /[`$\\\r\n]|\*\//;

export function validateName(name: string): ValidationResult {
  if (!name) return { ok: false, error: 'Name is required' };
  if (name.length > MAX_NAME_LEN) {
    return {
      ok: false,
      error: `Name must be ≤${MAX_NAME_LEN} chars. Got: "${name}" (${name.length} chars)`,
    };
  }
  if (!KEBAB_CASE.test(name)) {
    return {
      ok: false,
      error: `Name must be strict kebab-case (letters/digits, single internal hyphens, no trailing hyphen, start with a letter). Got: "${name}"`,
    };
  }
  if (RESERVED_NAMES.has(name)) {
    return { ok: false, error: `Name "${name}" is reserved` };
  }
  return { ok: true };
}

/**
 * Validate a free-text user input destined for generated code (description, owner).
 *
 * Rejects characters that enable shell command substitution (`$`, `` ` ``),
 * string-literal breakouts (backslash), JSDoc comment-close (`*` `/`),
 * and newlines (which would break TS single-quoted strings). Enforces a
 * length cap so freeform text can't bloat generated files.
 */
export function validateFreeText(value: string | undefined, field: string): ValidationResult {
  if (value === undefined || value === '') return { ok: true };
  if (value.length > FREE_TEXT_MAX_LEN) {
    return {
      ok: false,
      error: `${field} must be ≤${FREE_TEXT_MAX_LEN} chars. Got ${value.length} chars.`,
    };
  }
  if (FREE_TEXT_FORBIDDEN.test(value)) {
    return {
      ok: false,
      error: `${field} contains forbidden characters (shell metachars, backslash, newline, or "*/"). Got: "${value}"`,
    };
  }
  return { ok: true };
}

/**
 * Validate a starter-pack type name. Same shape as validateName — kebab-case,
 * ≤32 chars, not reserved. Prevents path traversal via "../evil".
 */
export function validateTypeName(type: string): ValidationResult {
  if (!type) return { ok: false, error: '--type is required' };
  if (type.length > MAX_NAME_LEN) {
    return { ok: false, error: `--type must be ≤${MAX_NAME_LEN} chars` };
  }
  if (!KEBAB_CASE.test(type)) {
    return {
      ok: false,
      error: `--type must be strict kebab-case. Got: "${type}"`,
    };
  }
  return { ok: true };
}

export function validateWorkstream(name: string, repoRoot: string): ValidationResult {
  if (!name) return { ok: false, error: '--workstream is required' };
  const dir = resolve(repoRoot, 'claude', 'workstreams', name);
  if (!existsSync(dir)) {
    return {
      ok: false,
      error: `Workstream "${name}" not found at claude/workstreams/${name}/ — create it first with /workstream-create`,
    };
  }
  if (!statSync(dir).isDirectory()) {
    return { ok: false, error: `claude/workstreams/${name} exists but is not a directory` };
  }
  return { ok: true };
}

export function validateStarterPack(type: string, repoRoot: string): ValidationResult {
  if (!type) return { ok: false, error: '--type is required' };
  const dir = resolve(repoRoot, 'claude', 'starter-packs', type);
  if (!existsSync(dir)) {
    return {
      ok: false,
      error: `Starter pack "${type}" not found at claude/starter-packs/${type}/`,
    };
  }
  const install = resolve(dir, 'install.sh');
  const manifest = resolve(dir, 'manifest.yaml');
  if (!existsSync(install)) {
    return { ok: false, error: `Starter pack "${type}" is missing install.sh` };
  }
  if (!existsSync(manifest)) {
    return { ok: false, error: `Starter pack "${type}" is missing manifest.yaml` };
  }
  return { ok: true };
}

export function validateServiceCollision(name: string, repoRoot: string): ValidationResult {
  const protoDir = resolve(repoRoot, 'apps', 'backend', 'src', 'prototype', name);
  if (existsSync(protoDir)) {
    return {
      ok: false,
      error: `Service "${name}" already exists at apps/backend/src/prototype/${name}/`,
    };
  }
  return { ok: true };
}

export function validateUiCollision(name: string, repoRoot: string): ValidationResult {
  const appDir = resolve(repoRoot, 'apps', name);
  if (existsSync(appDir)) {
    return { ok: false, error: `UI "${name}" already exists at apps/${name}/` };
  }
  return { ok: true };
}

/** Convert kebab-case to PascalCase (payments-api → PaymentsApi). */
export function toPascalCase(kebab: string): string {
  return kebab
    .split('-')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join('');
}

/** Convert kebab-case to camelCase (payments-api → paymentsApi). */
export function toCamelCase(kebab: string): string {
  const pascal = toPascalCase(kebab);
  return pascal.charAt(0).toLowerCase() + pascal.slice(1);
}
