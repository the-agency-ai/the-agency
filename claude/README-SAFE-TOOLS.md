# Safe Tools — Overview

The Agency's safe tools are wrapped versions of shell commands that hookify blocks in their raw form. Raw `git commit`, `cp`, `gh pr create`, `gh pr merge`, and `gh release create` are blocked because they bypass the framework's safety checks, commit conventions, and worktree discipline. Safe tools are the approved path — they enforce the rules at the tool layer so hookify can trust them.

## Why This Exists

Raw git commands cause real problems: `git add -A` stages secrets and binaries, `git push` sends to main, `cp` silently crosses worktree boundaries and loses change tracking, and `gh pr create` ships without a Quality Gate receipt. Hookify blocks these patterns, but that creates a vacuum — agents need a path that works. Safe tools fill that vacuum.

## The Enforcement Triangle

Each safe tool is one leg of a three-part enforcement model:

- **Tool** — the wrapper with built-in guards (what this document covers)
- **Skill** — the `/`-invocable interface that invokes the tool correctly
- **Hookify** — the behavioral rule that blocks the raw command and redirects to the tool

All three must exist for a pattern to be enforced. The tool guards the unsafe action. The skill makes the tool easy to use. Hookify closes the loop by blocking the dangerous shortcut.

## The Family

### `git-safe` — Read + Merge + Safety Ops (all agents)

Safe read-only and lightly-guarded write operations for any agent. Subcommands: `status`, `log`, `diff`, `branch`, `show`, `blame`, `add`, `merge-from-master`, `mv`, `unstage`, `restore`.

The `add` subcommand blocks `-A`, `--all`, `.`, directories, and glob wildcards — it requires explicit file paths. `merge-from-master` auto-detects `main` vs `master`, refuses on a dirty tree, and merges with `--no-edit`. `mv` moves files with path traversal protection. `unstage` wraps `git reset HEAD --`. `restore` uses atomic temp-file-then-rename to avoid the shell redirect self-clobber trap.

### `git-captain` — Privileged Ops (captain only)

Captain-level operations: `merge-to-master`, `checkout-branch`, `switch-branch`, `push`, `fetch`, `tag`, `branch-delete`, `merge-continue`.

Guards include: merge-to-master verifies you are on main before merging; push blocks main/master targets and bare `--force` (requires `--force-with-lease`); checkout-branch validates branch naming conventions; branch-delete uses `-d` by default (not `-D`) so unmerged branches are protected, with `--force` gated for post-merge cleanup.

### `git-safe-commit` — QG-Aware Commit Wrapper

Structured commit formatting with work item tracking. Builds standardized commit messages, adds per-agent attribution trailers, dispatches a commit notification to captain. Use via the `/git-safe-commit` skill or `/iteration-complete`.

### `git-push` — Push to Origin

Thin push wrapper that blocks pushes to `main`/`master`. Accepts `--force-with-lease` for PR branch updates. Defaults to the current branch. Used by `/sync` and `/release`.

### `cp-safe` — Same-Worktree Copy

Wraps `cp` with worktree boundary validation. Resolves real paths for source and destination, verifies both are in the same worktree (or main checkout), and blocks cross-worktree copies. Supports `-r`/`-R`/`--recursive`. For syncing across worktrees use `/worktree-sync` instead.

### `pr-create` — QG-Gated PR Creation

Wraps `gh pr create` with three mandatory checks before the PR is created:

1. Must be on a branch (not main/master)
2. A valid receipt must exist and pass `receipt-verify` (three-tier search: per-workstream `qgr/` → legacy `claude/receipts/` → old `usr/**/qgr-*.md`)
3. `claude/config/manifest.json` must be changed (version bumped) relative to origin/main

All `gh pr create` flags pass through after validation. Use via the `/release` skill for the full release flow.

### `pr-merge` — Safe PR Merge

Wraps `gh pr merge` with true merge commit enforcement (never squash, never rebase). Respects branch protection by default; `--principal-approved` is required to enable `--admin` override. Logged for audit.

## Reference

Full subcommand specs, exit codes, and exemption rules: `claude/REFERENCE-SAFE-TOOLS.md`
