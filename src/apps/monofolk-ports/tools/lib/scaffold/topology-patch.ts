/**
 * topology-patch — idempotent adder for claude/config/topology.yaml.
 *
 * Adds a service entry (compute|frontend|db|...) to the topology manifest.
 * Preserves file formatting as much as possible. Safe to re-run:
 *   - If the service already exists with matching fields, reports "already present" and exits ok.
 *   - If the service exists with different fields, reports a conflict and exits error.
 *   - If absent, appends the entry at the end of the services map.
 *
 * Uses js-yaml for parse+validate, but writes with a targeted string insertion
 * to preserve comments and block ordering in the original YAML file.
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { load as loadYaml, dump as dumpYaml } from 'js-yaml';
import type { ServiceEntry, ServiceType } from '../deploy/v2/types';

export interface ServicePatch {
  name: string;
  type: ServiceType;
  build?: string;
  health?: string;
  engine?: string;
  depends_on?: string[];
  wires_from?: string[];
  env?: Record<string, string>;
  migrate?: {
    tool: string;
    command: string;
    order: 'before_deploy' | 'after_deploy';
  };
}

export interface PatchResult {
  status: 'added' | 'already-present' | 'conflict';
  diff?: string; // YAML block that was (or would be) inserted
  message?: string;
}

/**
 * Compute the YAML block that represents this service entry.
 * Uses a leading comment-style header that matches topology.yaml's style.
 */
function renderServiceBlock(patch: ServicePatch): string {
  // Build a minimal object preserving field order matching existing entries
  const entry: Record<string, unknown> = { type: patch.type };
  if (patch.build !== undefined) entry.build = patch.build;
  if (patch.health !== undefined) entry.health = patch.health;
  if (patch.engine !== undefined) entry.engine = patch.engine;
  if (patch.depends_on && patch.depends_on.length > 0) entry.depends_on = patch.depends_on;
  if (patch.wires_from && patch.wires_from.length > 0) entry.wires_from = patch.wires_from;
  if (patch.env && Object.keys(patch.env).length > 0) entry.env = patch.env;
  if (patch.migrate) entry.migrate = patch.migrate;

  // Dump the entry as a YAML block scoped under the service name
  const wrapped = { [patch.name]: entry };
  const yaml = dumpYaml(wrapped, {
    indent: 2,
    lineWidth: -1,
    noRefs: true,
    quotingType: '"',
    forceQuotes: false,
  });

  // Indent under `services:` — two spaces for the service name
  return yaml
    .split('\n')
    .map((line) => (line ? '  ' + line : line))
    .join('\n');
}

/**
 * Compare two service entries for idempotency.
 * Returns true if the existing entry matches the patch exactly.
 */
function entriesMatch(existing: ServiceEntry, patch: ServicePatch): boolean {
  const fields: (keyof ServicePatch)[] = ['type', 'build', 'health', 'engine'];
  for (const f of fields) {
    if (existing[f as keyof ServiceEntry] !== patch[f]) return false;
  }
  const arrayFields: ('depends_on' | 'wires_from')[] = ['depends_on', 'wires_from'];
  for (const f of arrayFields) {
    const a = (existing[f] ?? []).slice().toSorted();
    const b = (patch[f] ?? []).slice().toSorted();
    if (a.length !== b.length) return false;
    if (a.some((v, i) => v !== b[i])) return false;
  }
  // env equality by key+value
  const envA = existing.env ?? {};
  const envB = patch.env ?? {};
  const keysA = Object.keys(envA).toSorted();
  const keysB = Object.keys(envB).toSorted();
  if (keysA.length !== keysB.length) return false;
  if (keysA.some((k, i) => k !== keysB[i])) return false;
  for (const k of keysA) {
    if (envA[k] !== envB[k]) return false;
  }
  // migrate equality
  const mA = existing.migrate;
  const mB = patch.migrate;
  if ((mA && !mB) || (!mA && mB)) return false;
  if (mA && mB) {
    if (mA.tool !== mB.tool || mA.command !== mB.command || mA.order !== mB.order) return false;
  }
  return true;
}

export interface ApplyOptions {
  topologyPath: string;
  dryRun?: boolean;
}

/**
 * Apply a patch to topology.yaml.
 * Returns the patch result; writes file on success unless dryRun is true.
 */
export function applyTopologyPatch(patch: ServicePatch, opts: ApplyOptions): PatchResult {
  const contents = readFileSync(opts.topologyPath, 'utf-8');
  const parsed = loadYaml(contents) as { services?: Record<string, ServiceEntry> } | null;

  if (!parsed || typeof parsed !== 'object' || !parsed.services) {
    return {
      status: 'conflict',
      message: `topology.yaml has no services: section at ${opts.topologyPath}`,
    };
  }

  const existing = parsed.services[patch.name];
  const block = renderServiceBlock(patch);

  if (existing) {
    if (entriesMatch(existing, patch)) {
      return {
        status: 'already-present',
        diff: block,
        message: `Service "${patch.name}" already exists in topology.yaml with matching fields`,
      };
    }
    return {
      status: 'conflict',
      diff: block,
      message: `Service "${patch.name}" exists in topology.yaml with different fields — not overwriting. Edit manually or remove first.`,
    };
  }

  // Append the block to the end of the file after a blank-line separator.
  // topology.yaml ends with infrastructure entries; appending preserves YAML
  // semantics at the cost of `# --- XX ---` section headers. Acceptable for v1 —
  // the file is still valid YAML and topology-resolve doesn't depend on order.
  const existingContent = contents.replace(/\n+$/, '');
  const newContent = `${existingContent}\n\n${block}`.replace(/\n{3,}/g, '\n\n');

  // Ensure single trailing newline
  const finalContent = newContent.endsWith('\n') ? newContent : newContent + '\n';

  if (!opts.dryRun) {
    writeFileSync(opts.topologyPath, finalContent, 'utf-8');
  }

  return {
    status: 'added',
    diff: block,
    message: opts.dryRun
      ? `[dry-run] would add "${patch.name}" to topology.yaml`
      : `Added "${patch.name}" to topology.yaml`,
  };
}

/** Check whether a service is already present. */
export function isServicePresent(topologyPath: string, name: string): boolean {
  const contents = readFileSync(topologyPath, 'utf-8');
  const parsed = loadYaml(contents) as { services?: Record<string, ServiceEntry> } | null;
  return Boolean(parsed?.services && name in parsed.services);
}
