/**
 * Stage hash utility — computes a deterministic hash from the git staging area.
 *
 * The hash ties a QGR (Quality Gate Report) file to the exact staged content.
 * Given the same staged changes, the hash is always the same, regardless of
 * platform or timing. This lets `/git-commit` verify that a QGR exists for
 * the current staged changes before committing.
 *
 * Algorithm:
 *   1. Get staged file entries from `git ls-files -s` (cached/index entries)
 *   2. Filter to only staged files (those in `git diff --cached --name-only`)
 *   3. Sort by file path
 *   4. Concatenate "mode objectHash path\n" for each entry
 *   5. SHA-256 the concatenation, take first 7 hex chars
 */

import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';

export interface StageHashResult {
  /** 7-character hex prefix of SHA-256 hash */
  hash: string;
  /** Number of staged files */
  fileCount: number;
  /** Sorted list of staged file paths */
  files: string[];
}

/**
 * Compute a deterministic hash from the current git staging area.
 *
 * @param cwd - Working directory (defaults to process.cwd())
 * @returns StageHashResult with hash, file count, and file list
 * @throws Error if no files are staged or git commands fail
 */
export function computeStageHash(cwd?: string): StageHashResult {
  const opts = { encoding: 'utf-8' as const, cwd };

  // Get list of staged file paths
  const stagedOutput = execFileSync('git', ['diff', '--cached', '--name-only'], opts).trim();
  if (!stagedOutput) {
    throw new Error('No files are staged');
  }

  const stagedFiles = stagedOutput.split('\n').filter(Boolean).sort();

  // Get index entries with object hashes
  const lsOutput = execFileSync('git', ['ls-files', '-s'], opts).trim();
  const indexEntries = new Map<string, string>();
  for (const line of lsOutput.split('\n')) {
    // Format: "mode objectHash stage\tpath"
    const match = line.match(/^(\d+)\s+([0-9a-f]+)\s+\d+\t(.+)$/);
    if (match) {
      indexEntries.set(match[3], `${match[1]} ${match[2]} ${match[3]}`);
    }
  }

  // Build hash input from staged files only, using their index entries
  const hashInput: string[] = [];
  for (const file of stagedFiles) {
    const entry = indexEntries.get(file);
    if (entry) {
      hashInput.push(entry);
    } else {
      // File is staged for deletion — use path only
      hashInput.push(`000000 0000000000000000000000000000000000000000 ${file}`);
    }
  }

  const hash = createHash('sha256').update(hashInput.join('\n')).digest('hex').slice(0, 7);

  return { hash, fileCount: stagedFiles.length, files: stagedFiles };
}
