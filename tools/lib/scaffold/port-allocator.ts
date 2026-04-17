/**
 * port-allocator — finds the next free port in a range by scanning
 * docker-compose files AND apps/\*\/package.json Next.js dev scripts.
 *
 * Ranges (v1):
 *   - backend services:  4010..4099
 *   - frontend/UI apps:  4100..4199
 *   - gateways/special:  4200..4299
 *
 * Scanning apps/\*\/package.json closes the "sequential /ui-add collides"
 * gap: after `ui-add` runs, the new app's package.json has `next dev --port N`
 * before docker-compose is hand-edited, so subsequent allocations see the
 * port as taken.
 */

import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';

export interface PortRange {
  start: number;
  end: number;
}

export const RANGES = {
  backend: { start: 4010, end: 4099 },
  frontend: { start: 4100, end: 4199 },
  gateway: { start: 4200, end: 4299 },
} as const satisfies Record<string, PortRange>;

/**
 * Scan docker-compose files for port mappings. Handles:
 *   - "4010:3000"          → 4010
 *   - '- 4010:3000'         → 4010
 *   - ${BACKEND_PORT:-4010}:3000 → 4010 (shell-style default var)
 */
function extractComposePorts(repoRoot: string): Set<number> {
  const used = new Set<number>();
  const candidates = [
    resolve(repoRoot, 'docker-compose.dev.yml'),
    resolve(repoRoot, 'docker-compose.yml'),
  ];
  for (const path of candidates) {
    if (!existsSync(path)) continue;
    const contents = readFileSync(path, 'utf-8');
    // Pattern 1: shell-default var form ${NAME:-4010}:3000
    for (const m of contents.matchAll(/\$\{[A-Z0-9_]+:-([0-9]{2,5})\}\s*:\s*[0-9]{1,5}/g)) {
      used.add(parseInt(m[1], 10));
    }
    // Pattern 2: plain host:container form anchored to YAML list/quote start.
    // Requires a preceding `- ` (compose ports: syntax) or quote — this excludes
    // incidental matches like a timestamp "13:45:02" embedded in free text.
    for (const m of contents.matchAll(
      /(?:^|\s-\s|["'])([0-9]{2,5})\s*:\s*[0-9]{1,5}(?=["'\s]|$)/gm,
    )) {
      const host = parseInt(m[1], 10);
      if (!Number.isNaN(host)) used.add(host);
    }
  }
  return used;
}

/**
 * Scan apps/\*\/package.json for Next.js dev/start port declarations.
 * Matches `--port N` and `-p N` in script strings.
 */
function extractAppPackageJsonPorts(repoRoot: string): Set<number> {
  const used = new Set<number>();
  const appsDir = resolve(repoRoot, 'apps');
  if (!existsSync(appsDir)) return used;
  let entries;
  try {
    entries = readdirSync(appsDir, { withFileTypes: true });
  } catch {
    return used;
  }
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const pkgPath = resolve(appsDir, entry.name, 'package.json');
    if (!existsSync(pkgPath)) continue;
    let contents: string;
    try {
      contents = readFileSync(pkgPath, 'utf-8');
    } catch {
      continue;
    }
    for (const m of contents.matchAll(/(?:--port|\s-p)\s+([0-9]{2,5})/g)) {
      used.add(parseInt(m[1], 10));
    }
  }
  return used;
}

function extractUsedPorts(repoRoot: string): Set<number> {
  const used = new Set<number>();
  for (const p of extractComposePorts(repoRoot)) used.add(p);
  for (const p of extractAppPackageJsonPorts(repoRoot)) used.add(p);
  return used;
}

/**
 * Find the next free port in the given range.
 * Throws if no free port is available.
 */
export function allocatePort(range: PortRange, repoRoot: string): number {
  const used = extractUsedPorts(repoRoot);
  for (let p = range.start; p <= range.end; p++) {
    if (!used.has(p)) return p;
  }
  throw new Error(
    `No free port available in range ${range.start}-${range.end}. Used: ${[...used]
      .filter((p) => p >= range.start && p <= range.end)
      .join(', ')}`,
  );
}

/** Check whether a specific port is already in use. */
export function isPortInUse(port: number, repoRoot: string): boolean {
  return extractUsedPorts(repoRoot).has(port);
}
