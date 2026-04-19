---
type: handoff
agent: the-agency/jordan/mdpal-cli
workstream: mdpal
date: 2026-04-17
trigger: iteration-complete
---

## Identity

the-agency/jordan/mdpal-cli — Markdown Pal engine + CLI. Branch `mdpal-cli`. Worktree at `.claude/worktrees/mdpal-cli/`.

## Current state

**Phase 1 SHIPPED.** PR #179 open at https://github.com/the-agency-ai/the-agency/pull/179.

**Phase 2 Iterations 2.1 + 2.2 + 2.3 COMPLETE.** Working `mdpal` binary with sections + read + edit + comment + comments + resolve + flag + flags + clear-flag (9 commands). Full read/write/collaboration loop functional. Wire format strict-aligned with dispatched spec including explicit null encoding for absent optional fields.

| Phase / Iter | Commit | Tests | Content |
|--------------|--------|-------|---------|
| 1.1 | `9cf480b` | 33 | Core types, parser |
| 1.2 | `abbc746` | 80 | Document model, metadata |
| 1.3 | `904131e` | 124 | Section operations |
| 1.4 | `1a18718` | 175 | Bundle management |
| Phase 1 QG | `2a80f21` | 179 | C1+C2 critical fixes |
| pr-prep QG | `7c8a359` | 180 | DocumentInfo POSIX pin + test name |
| **2.1 staging** | `94d0169` | 193 | CLI scaffold (initial wire format) |
| **2.1 QG fixes** | `874ae16` | 192 | camelCase, error field, recursive tree, removed VersionCommand |
| **2.2 staging** | `f444ded` | 199 | EditCommand + GlobalOutputOptions |
| **2.2 QG fixes** | `0b26f86` | 204 | versionId in conflict envelope, TTY/encoding/bytes hardening |
| **2.3** | `6b312ad` | 221 | comment + flag lifecycle (6 commands) + Wire/ refactor + explicit null encoding |

## What was done this session

1. Session resume + dispatch monitor in place
2. **Phase 1 PR shipped:**
   - `/pr-prep` QG (5-hash chain, receipt `8f2da0f`) — fixed DocumentInfo POSIX/Gregorian + test name accuracy
   - `/release` — pushed `mdpal-cli` branch, opened PR #179
3. **Phase 2 Iteration 2.1 implemented + landed:**
   - Built ArgumentParser scaffold + 3 commands initially (version, sections, read)
   - QG caught CRITICAL contract drift: snake_case vs spec's camelCase, `code` vs `error`, flat vs recursive sections
   - Verified by reading the dispatched JSON spec directly
   - Fixed all critical findings + supporting items (BundleResolver `~`/`..`, ErrorEnvelope fallback preservation, CLISupport Fixture struct)
   - Removed VersionCommand (`version` reserved per spec for `version show/bump`); tool version now via root `--version` flag
   - 192 tests passing
   - Receipt: `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-cli-mdpal-mdpal-qgr-iteration-complete-20260417-1312-fb1f7e3.md`
4. Plan updated — Phase 2 iterations renumbered to reflect actual remaining CLI work

## Next action

**Iteration 2.4: Bundle commands + diff + prune + refresh.**

This rounds out the dispatched CLI spec — mdpal-app will be fully unblocked after this.

Commands to build:
- `mdpal create <name> [--dir]` — create new bundle with initial revision
- `mdpal history <bundle>` — list revisions newest-first with `latest: true` flag
- `mdpal version show <bundle>` — display current version + revision + versionId + timestamp
- `mdpal version bump <bundle>` — increment major version, reset revision to 1
- `mdpal revision create <bundle> [--content | --stdin] [--base-revision]` — explicit revision creation with optional concurrency check
- `mdpal diff <rev1> <rev2> <bundle>` — section-level diff (REQUIRES Phase 1.5 H5: Diff API in engine — build that first)
- `mdpal prune <bundle> [--keep <n>]` — prune old revisions with comment merge-forward
- `mdpal refresh <slug> <bundle>` — update stale comment hashes on a section

Plus deferred-from-2.2/2.3 hygiene:
- Subprocess timeout in CLISupport
- Slug edge case tests
- E2E collaboration test through CLI
- Wire-format goldens

Order:
1. Build engine Diff API (H5 from Phase 1 backlog) — needed for `mdpal diff`
2. CreateCommand, HistoryCommand
3. VersionShowCommand + VersionBumpCommand (group)
4. RevisionCreateCommand (subcommand of `revision`)
5. DiffCommand, PruneCommand, RefreshCommand
6. Iteration QG, commit, push

Then iter 2.4 ships and Phase 2 is complete. Don't wait for principal.

## Open coordination

- **PR #179** open, waiting for captain review/merge. mdpal-app already has Phase 1A-4 done (per dispatch #410); they're holding for the CLI.
- **mdpal-app dispatch #407** still open — they want a usable binary. With 2.1 + 2.2 they can integrate `sections`, `read`, `edit` (the core read/write loop).
- **Cross-repo collab dispatches** to monofolk are surfacing in my monitor (--include-collab) — captain territory, not mine.

## Deferred (Phase 1.5 / Phase 2 backlogs)

### Security hardening (Phase 1.5)
- C2 follow-up: Document(contentsOfFile:) follows symlinks in prune merge-forward (TOCTOU)
- Pointer file content validation
- File-size limits + YAML billion-laughs guard
- BundleConfig name validation
- BundleResolver sandbox-root policy
- Path scrubbing in error messages

### Phase 2 future iterations
- 2.2: edit command + slug edge cases + subprocess timeout
- 2.3: comment + flag commands + Wire/ directory split
- 2.4: bundle commands + diff API + prune + refresh
- 2.5: hardening + e2e + dispatch to mdpal-app

### From Phase 1 deferred (still relevant)
- H1 Revision metadata drift, H2 DocumentInfo blank() (FIXED in pr-prep), H3 empty slug for non-ASCII, H4 slug suffix scheme, H5 Diff API (needed for 2.4), H6 e2e Bundle+Document, H7 byte-equal round-trip

## Key Artifacts

- PVR: `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md`
- A&D: `usr/jordan/mdpal/ad-mdpal-20260404.md`
- Plan: `usr/jordan/mdpal/plan-mdpal-20260406.md` (Phase 2 iterations rewritten)
- Wire-format spec (CRITICAL — read before any CLI iteration): `usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md`
- Phase 1 QGR: `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-cli-mdpal-mdpal-qgr-phase-complete-20260416-1901-f1656c3.md`
- pr-prep QGR: `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-cli-mdpal-mdpal-qgr-pr-prep-20260417-1213-8f2da0f.md`
- Iter 2.1 QGR: `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-cli-mdpal-mdpal-qgr-iteration-complete-20260417-1312-fb1f7e3.md`
- PR: https://github.com/the-agency-ai/the-agency/pull/179

## Infrastructure notes

- Dispatch monitor running (task `b0mwsu3oj`, persistent, --include-collab)
- git-safe-commit auto-dispatch cascade: 1 untracked dispatch = steady state (flag #125)
- Sparse worktree: `git status` shows ~1310 D files = normal (always stage explicit paths)
- ISCP_SCHEMA_VERSION=1
