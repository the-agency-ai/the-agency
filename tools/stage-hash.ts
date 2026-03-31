#!/usr/bin/env tsx
/**
 * CLI wrapper for the stage hash utility.
 *
 * Usage:
 *   tsx tools/stage-hash.ts          # prints 7-char hash
 *   tsx tools/stage-hash.ts --json   # prints JSON with hash, fileCount, files
 */

import { computeStageHash } from './lib/stage-hash';

const json = process.argv.includes('--json');

try {
  const result = computeStageHash();
  if (json) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    console.log(result.hash);
  }
} catch (err) {
  console.error(`stage-hash: ${err instanceof Error ? err.message : String(err)}`);
  process.exit(1);
}
