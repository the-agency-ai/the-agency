/**
 * registry-patch — idempotent adder for apps/backend/src/prototype/prototype.registry.ts.
 *
 * Adds:
 *   1. `import { XxxModule } from './xxx/xxx.module';` at the top of the import block
 *   2. An entry in the PROTOTYPE_REGISTRY array before the closing `];`
 *
 * Uses anchor-based string insertion to avoid a full TS AST dependency.
 * Safe to re-run:
 *   - If the module is already imported, skips the import.
 *   - If an entry already exists for the name, skips the entry.
 *   - Reports conflict if the entry exists with a different module name.
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { toPascalCase } from './validators';

export interface RegistryPatch {
  name: string; // kebab-case service name
  description?: string;
  owner?: string;
  routes?: string[];
}

export interface RegistryPatchResult {
  status: 'added' | 'already-present' | 'conflict';
  message: string;
  diff?: string;
}

export interface ApplyRegistryOptions {
  registryPath: string;
  dryRun?: boolean;
}

function findRegistryEntry(contents: string, name: string): boolean {
  // Look for `name: '<name>',` or `name: "<name>",` within registry entries
  const re = new RegExp(`name:\\s*['"]${name.replace(/[.*+?^${}()|[\\]\\\\]/g, '\\\\$&')}['"]`);
  return re.test(contents);
}

function findImport(contents: string, moduleName: string): boolean {
  const re = new RegExp(`import\\s*\\{\\s*${moduleName}\\s*\\}\\s*from\\s*['"]`);
  return re.test(contents);
}

function renderImport(name: string, moduleName: string): string {
  return `import { ${moduleName} } from './${name}/${name}.module';`;
}

/**
 * Render a TS single-quoted string literal by going through JSON.stringify
 * (which returns a double-quoted JSON string with \, ", \n, control chars
 * all correctly escaped), then swapping to single-quote delimiters. This
 * ensures generated TS is well-formed for any input string and eliminates
 * string-literal breakouts.
 */
function tsSingleQuoted(value: string): string {
  const json = JSON.stringify(value); // "like \"this\""
  // Strip outer " quotes, un-escape the inner \" to plain ", then escape
  // plain ' to \'. Backslash, \n, \t, \u escapes from JSON remain intact.
  const body = json.slice(1, -1).replace(/\\"/g, '"').replace(/'/g, "\\'");
  return `'${body}'`;
}

function renderEntry(patch: RegistryPatch, moduleName: string): string {
  const routes = patch.routes ?? ['GET /greet', 'GET /build-info', 'POST /register-build'];
  const description = patch.description ?? `${patch.name} prototype`;
  const owner = patch.owner ?? 'TODO';
  return [
    '  {',
    `    name: ${tsSingleQuoted(patch.name)},`,
    `    module: ${moduleName},`,
    `    routes: [${routes.map(tsSingleQuoted).join(', ')}],`,
    `    description: ${tsSingleQuoted(description)},`,
    `    owner: ${tsSingleQuoted(owner)},`,
    '  },',
  ].join('\n');
}

/**
 * Insert a line into the import block of the registry file.
 * Anchor: last `import ... from '...';` line before `export interface PrototypeEntry`.
 */
function insertImport(contents: string, line: string): string {
  // Find the last import line before the `export` block
  const exportIdx = contents.search(/\nexport\s+(interface|const|type|function|class)\s+/);
  const region = exportIdx >= 0 ? contents.slice(0, exportIdx) : contents;
  const importMatches = [...region.matchAll(/(^|\n)import[^\n]*;/g)];
  if (importMatches.length === 0) {
    return `${line}\n${contents}`;
  }
  const lastMatch = importMatches[importMatches.length - 1];
  const insertAt = lastMatch.index! + lastMatch[0].length;
  return contents.slice(0, insertAt) + '\n' + line + contents.slice(insertAt);
}

/**
 * Insert an entry into the PROTOTYPE_REGISTRY array before its closing `];`.
 */
function insertEntry(contents: string, entry: string): string {
  // Find `export const PROTOTYPE_REGISTRY: PrototypeEntry[] = [`
  // Allow `[]` in the type annotation by matching up to `=` instead of up to `]`.
  const openRe = /export\s+const\s+PROTOTYPE_REGISTRY[^=]*=\s*\[/;
  const openMatch = contents.match(openRe);
  if (!openMatch) {
    throw new Error('Could not find PROTOTYPE_REGISTRY array declaration');
  }
  const openIdx = openMatch.index! + openMatch[0].length;

  // Find the matching `];` after openIdx. Scan forward counting brackets to be safe.
  let depth = 1;
  let closeIdx = -1;
  for (let i = openIdx; i < contents.length; i++) {
    const c = contents[i];
    if (c === '[') depth++;
    else if (c === ']') {
      depth--;
      if (depth === 0) {
        closeIdx = i;
        break;
      }
    }
  }
  if (closeIdx < 0) {
    throw new Error('Could not find closing `]` of PROTOTYPE_REGISTRY');
  }

  // Insert entry before the `]`. Make sure preceding content ends cleanly.
  const before = contents.slice(0, closeIdx).replace(/\s+$/, '');
  const after = contents.slice(closeIdx);
  // Ensure prior entry ends with a comma — but only if there IS a prior entry.
  // If the array is empty (just `[`), don't prepend a comma — that produces
  // `[,` which is a TypeScript syntax error.
  const needsComma = !before.endsWith('[') && !before.endsWith(',');
  const prefixed = needsComma ? before + ',' : before;
  return `${prefixed}\n${entry}\n${after}`;
}

export function applyRegistryPatch(
  patch: RegistryPatch,
  opts: ApplyRegistryOptions,
): RegistryPatchResult {
  const moduleName = `${toPascalCase(patch.name)}Module`;
  const contents = readFileSync(opts.registryPath, 'utf-8');

  const entryExists = findRegistryEntry(contents, patch.name);
  const importExists = findImport(contents, moduleName);

  if (entryExists && importExists) {
    return {
      status: 'already-present',
      message: `Registry entry for "${patch.name}" already present`,
    };
  }

  if (entryExists && !importExists) {
    return {
      status: 'conflict',
      message: `Registry has an entry named "${patch.name}" but no import for ${moduleName} — inspect manually`,
    };
  }

  let next = contents;
  if (!importExists) {
    next = insertImport(next, renderImport(patch.name, moduleName));
  }
  if (!entryExists) {
    next = insertEntry(next, renderEntry(patch, moduleName));
  }

  if (!opts.dryRun) {
    writeFileSync(opts.registryPath, next, 'utf-8');
  }

  return {
    status: 'added',
    message: opts.dryRun
      ? `[dry-run] would register "${patch.name}" (import + entry) in prototype.registry.ts`
      : `Registered "${patch.name}" in prototype.registry.ts`,
    diff: next,
  };
}

export function isRegistryEntryPresent(registryPath: string, name: string): boolean {
  const contents = readFileSync(registryPath, 'utf-8');
  return findRegistryEntry(contents, name);
}
