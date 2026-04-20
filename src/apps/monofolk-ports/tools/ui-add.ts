#!/usr/bin/env -S pnpm tsx
/**
 * ui-add — add a frontend app to an existing workstream.
 *
 * SPEC-PROVIDER: invokes a starter pack under claude/starter-packs/<type>/ which
 * scaffolds the Next.js (or other) app. This script handles arg parsing,
 * port allocation, validation, and topology.yaml updates.
 *
 * Usage:
 *   pnpm tsx tools/ui-add.ts <name> --workstream <ws> [--type nextjs-app] [--port N] [--dry-run]
 */

import { execFileSync } from 'node:child_process';
import { resolve } from 'node:path';
import {
  validateName,
  validateTypeName,
  validateWorkstream,
  validateStarterPack,
  validateUiCollision,
} from './lib/scaffold/validators';
import { applyTopologyPatch, isServicePresent } from './lib/scaffold/topology-patch';
import { allocatePort, isPortInUse, RANGES } from './lib/scaffold/port-allocator';

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

interface Args {
  name: string;
  workstream: string;
  type: string;
  port?: number;
  basePath?: string;
  dryRun: boolean;
}

function parseArgs(argv: string[]): Args {
  const args: Partial<Args> = { type: 'nextjs-app', dryRun: false };
  const positional: string[] = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--workstream') args.workstream = argv[++i];
    else if (a === '--type') args.type = argv[++i];
    else if (a === '--port') args.port = parseInt(argv[++i], 10);
    else if (a === '--base-path') args.basePath = argv[++i];
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
  if (positional.length !== 1) fail('Exactly one positional arg required (the UI name)');
  args.name = positional[0];
  if (!args.workstream) fail('--workstream is required');
  if (args.port !== undefined && Number.isNaN(args.port)) fail('--port must be an integer');
  return args as Args;
}

function printHelp(): void {
  console.log(
    `ui-add — add a frontend app to an existing workstream

Usage:
  pnpm tsx tools/ui-add.ts <name> --workstream <ws> [options]

Arguments:
  <name>                  kebab-case app name (1–32 chars); becomes apps/<name>/

Options:
  --workstream <ws>       existing workstream [required]
  --type <provider>       starter pack [default: nextjs-app]
  --port <num>            host port [default: next free in ${RANGES.frontend.start}–${RANGES.frontend.end}]
  --base-path <path>      Next.js basePath [default: /<name>]
  --dry-run               preview all writes without making changes
  -h, --help              show this help

Examples:
  pnpm tsx tools/ui-add.ts payments-ui --workstream payments --dry-run
  pnpm tsx tools/ui-add.ts admin --workstream ops --port 4150
`,
  );
}

function fail(msg: string): never {
  console.error(`[ui-add] ERROR: ${msg}`);
  process.exit(2);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main(): void {
  const args = parseArgs(process.argv.slice(2));
  const root = process.cwd();
  const topologyPath = resolve(root, 'claude', 'config', 'topology.yaml');

  // 1. Validate name
  const nameCheck = validateName(args.name);
  if (!nameCheck.ok) fail(nameCheck.error!);

  // 2. Validate workstream
  const wsCheck = validateWorkstream(args.workstream, root);
  if (!wsCheck.ok) fail(wsCheck.error!);

  // 3. Validate starter-pack type (path-traversal guard) then existence
  const typeCheck = validateTypeName(args.type);
  if (!typeCheck.ok) fail(typeCheck.error!);
  const packCheck = validateStarterPack(args.type, root);
  if (!packCheck.ok) fail(packCheck.error!);

  // 4. Validate no collision
  const collisionCheck = validateUiCollision(args.name, root);
  if (!collisionCheck.ok) {
    if (args.dryRun && isServicePresent(topologyPath, args.name)) {
      console.log(`[ui-add] ${args.name} already in topology.yaml — would be a no-op`);
      process.exit(0);
    }
    fail(collisionCheck.error!);
  }

  // 5. Allocate port
  let port: number;
  if (args.port !== undefined) {
    if (isPortInUse(args.port, root))
      fail(`Port ${args.port} already in use (per docker-compose.dev.yml)`);
    port = args.port;
  } else {
    port = allocatePort(RANGES.frontend, root);
  }
  const basePath = args.basePath ?? `/${args.name}`;

  console.log(`◆ ui-add ${args.name}`);
  console.log(`  workstream: ${args.workstream}`);
  console.log(`  type:       ${args.type}`);
  console.log(`  port:       ${port}`);
  console.log(`  base-path:  ${basePath}`);
  console.log(`  dry-run:    ${args.dryRun}`);
  console.log('');

  // 6. Invoke starter pack
  const installSh = resolve(root, 'claude', 'starter-packs', args.type, 'install.sh');
  const installArgs = [
    '--name',
    args.name,
    '--port',
    String(port),
    '--base-path',
    basePath,
    '--repo-root',
    root,
    ...(args.dryRun ? ['--dry-run'] : []),
  ];
  console.log(`  → invoking ${args.type} starter pack…`);
  try {
    execFileSync(installSh, installArgs, { stdio: 'inherit' });
  } catch (e) {
    fail(`Starter pack failed: ${e instanceof Error ? e.message : String(e)}`);
  }

  // 7. Update topology.yaml
  const patchResult = applyTopologyPatch(
    {
      name: args.name,
      type: 'frontend',
      build: `apps/${args.name}`,
      wires_from: ['backend'],
      env: { NEXT_PUBLIC_API_URL: '{{backend.outputs.url}}' },
    },
    { topologyPath, dryRun: args.dryRun },
  );
  console.log(`  → topology: ${patchResult.message}`);
  if (patchResult.status === 'conflict') {
    fail(patchResult.message!);
  }

  // 8. Report
  console.log('');
  console.log('◆ Result');
  console.log(
    `  ${args.dryRun ? '[dry-run] would add' : 'Added'} ${args.name} as a ${args.type} on port ${port}`,
  );
  if (!args.dryRun) {
    console.log('');
    console.log('Next steps:');
    console.log(`  1. Install deps: pnpm install`);
    console.log(`  2. Run locally: pnpm --filter ${args.name} dev`);
    console.log(`  3. Or with full stack: pnpm preview local --services ${args.name}`);
    console.log(`  4. Extend docker-compose.dev.yml to add a ${args.name} service block if needed`);
    console.log(`  5. Visit: http://localhost:${port}${basePath}`);
  }
}

main();
