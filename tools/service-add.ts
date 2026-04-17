#!/usr/bin/env -S pnpm tsx
/**
 * service-add — add a backend service (prototype module) to an existing workstream.
 *
 * SPEC-PROVIDER: invokes a starter pack under claude/starter-packs/<type>/ which
 * scaffolds the files. This script handles arg parsing, validation, orchestration,
 * and registry/topology updates.
 *
 * Usage:
 *   pnpm tsx tools/service-add.ts <name> --workstream <ws> [--type nestjs-prototype] [--dry-run]
 */

import { execFileSync } from 'node:child_process';
import { resolve } from 'node:path';
import { existsSync } from 'node:fs';
import {
  validateName,
  validateFreeText,
  validateTypeName,
  validateWorkstream,
  validateStarterPack,
  validateServiceCollision,
  toPascalCase,
} from './lib/scaffold/validators';
import { applyRegistryPatch, isRegistryEntryPresent } from './lib/scaffold/registry-patch';

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

interface Args {
  name: string;
  workstream: string;
  type: string;
  description?: string;
  owner?: string;
  dryRun: boolean;
}

function parseArgs(argv: string[]): Args {
  const args: Partial<Args> = { type: 'nestjs-prototype', dryRun: false };
  const positional: string[] = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--workstream') args.workstream = argv[++i];
    else if (a === '--type') args.type = argv[++i];
    else if (a === '--description') args.description = argv[++i];
    else if (a === '--owner') args.owner = argv[++i];
    else if (a === '--dry-run') args.dryRun = true;
    else if (a === '-h' || a === '--help') {
      printHelp();
      process.exit(0);
    } else if (a.startsWith('--')) {
      fail(`Unknown flag: ${a}`);
    } else {
      positional.push(a);
    }
  }
  if (positional.length !== 1) fail('Exactly one positional arg required (the service name)');
  args.name = positional[0];
  if (!args.workstream) fail('--workstream is required');
  return args as Args;
}

function printHelp(): void {
  console.log(
    `service-add — add a backend prototype module to an existing workstream

Usage:
  pnpm tsx tools/service-add.ts <name> --workstream <ws> [options]

Arguments:
  <name>                  kebab-case service name (1–32 chars)

Options:
  --workstream <ws>       existing workstream name (claude/workstreams/<ws>/) [required]
  --type <provider>       starter pack under claude/starter-packs/<type>/ [default: nestjs-prototype]
  --description <text>    description used in scaffold + registry entry
  --owner <text>          owner attribution used in registry entry
  --dry-run               preview all writes without making changes
  -h, --help              show this help

Examples:
  pnpm tsx tools/service-add.ts payments --workstream checkout --dry-run
  pnpm tsx tools/service-add.ts ledger --workstream payments --description "transaction ledger"
`,
  );
}

function fail(msg: string): never {
  console.error(`[service-add] ERROR: ${msg}`);
  process.exit(2);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main(): void {
  const args = parseArgs(process.argv.slice(2));
  const root = process.cwd();

  // 1. Validate name
  const nameCheck = validateName(args.name);
  if (!nameCheck.ok) fail(nameCheck.error!);

  // 1b. Validate free-text inputs that will be interpolated into generated code.
  // Rejects shell metachars, backslash, newlines, and "*/" — prevents command
  // injection via heredoc and TS string-literal breakout.
  const descCheck = validateFreeText(args.description, '--description');
  if (!descCheck.ok) fail(descCheck.error!);
  const ownerCheck = validateFreeText(args.owner, '--owner');
  if (!ownerCheck.ok) fail(ownerCheck.error!);

  // 2. Validate workstream
  const wsCheck = validateWorkstream(args.workstream, root);
  if (!wsCheck.ok) fail(wsCheck.error!);

  // 3. Validate starter-pack type (path-traversal guard) then existence
  const typeCheck = validateTypeName(args.type);
  if (!typeCheck.ok) fail(typeCheck.error!);
  const packCheck = validateStarterPack(args.type, root);
  if (!packCheck.ok) fail(packCheck.error!);

  // 4. Validate no collision
  const collisionCheck = validateServiceCollision(args.name, root);
  if (!collisionCheck.ok) {
    // Allow if registry already knows about it AND we're just dry-running a re-check
    if (args.dryRun && isRegistryEntryPresent(registryPath(root), args.name)) {
      console.log(`[service-add] ${args.name} is already registered — would be a no-op`);
      process.exit(0);
    }
    fail(collisionCheck.error!);
  }

  // 5. Report plan
  const pascal = toPascalCase(args.name);
  console.log(`◆ service-add ${args.name}`);
  console.log(`  workstream: ${args.workstream}`);
  console.log(`  type:       ${args.type}`);
  console.log(`  pascal:     ${pascal}`);
  console.log(`  dry-run:    ${args.dryRun}`);
  console.log('');

  // 6. Invoke starter pack
  const installSh = resolve(root, 'claude', 'starter-packs', args.type, 'install.sh');
  const installArgs = [
    '--name',
    args.name,
    '--pascal-name',
    pascal,
    '--repo-root',
    root,
    ...(args.description ? ['--description', args.description] : []),
    ...(args.owner ? ['--owner', args.owner] : []),
    ...(args.dryRun ? ['--dry-run'] : []),
  ];
  console.log(`  → invoking ${args.type} starter pack…`);
  try {
    execFileSync(installSh, installArgs, { stdio: 'inherit' });
  } catch (e) {
    fail(`Starter pack failed: ${e instanceof Error ? e.message : String(e)}`);
  }

  // 7. Update prototype.registry.ts
  const regPath = registryPath(root);
  if (!existsSync(regPath)) {
    fail(`Registry not found at ${regPath}`);
  }
  const regResult = applyRegistryPatch(
    {
      name: args.name,
      description: args.description,
      owner: args.owner,
      routes: ['GET /greet', 'GET /build-info', 'POST /register-build'],
    },
    { registryPath: regPath, dryRun: args.dryRun },
  );
  console.log(`  → registry: ${regResult.message}`);
  if (regResult.status === 'conflict') {
    fail(regResult.message);
  }

  // 8. Report result
  console.log('');
  console.log('◆ Result');
  console.log(
    `  ${args.dryRun ? '[dry-run] would add' : 'Added'} ${args.name} as a ${args.type} prototype`,
  );
  if (!args.dryRun) {
    console.log('');
    console.log('Next steps:');
    console.log(`  1. Rebuild backend: pnpm --filter backend build`);
    console.log(`  2. Run tests: pnpm --filter backend test ${args.name}`);
    console.log(`  3. Start backend locally: pnpm preview local --services backend`);
    console.log(`  4. Hit the endpoint: curl http://localhost:4010/${args.name}/greet`);
  }
}

function registryPath(root: string): string {
  return resolve(root, 'apps', 'backend', 'src', 'prototype', 'prototype.registry.ts');
}

main();
