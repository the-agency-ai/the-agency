---
type: handoff
agent: the-agency/jordan/mdpal-cli
workstream: mdpal
date: 2026-04-17
trigger: session-compact
---

## Identity

the-agency/jordan/mdpal-cli — Markdown Pal engine + CLI. Branch `mdpal-cli`. Worktree at `.claude/worktrees/mdpal-cli/`.

## Current state — MID-FLIGHT, KEEP GOING AFTER COMPACT

**Phase 1 SHIPPED.** PR #179 open at https://github.com/the-agency-ai/the-agency/pull/179 with 11 commits queued for review.

**Phase 2 iters 2.1, 2.2, 2.3 + follow-up COMPLETE.** 9 of ~16 CLI commands shipped. mdpal-app **functionally unblocked** (their CLIServiceProtocol can be wired to the real binary now for read/write/collaboration).

| Phase / Iter | Commit | Tests | Content |
|--------------|--------|-------|---------|
| 1.1 | `9cf480b` | 33 | Core types, parser |
| 1.2 | `abbc746` | 80 | Document model, metadata |
| 1.3 | `904131e` | 124 | Section operations |
| 1.4 | `1a18718` | 175 | Bundle management |
| Phase 1 QG | `2a80f21` | 179 | C1+C2 critical fixes |
| pr-prep QG | `7c8a359` | 180 | DocumentInfo POSIX pin + test name |
| 2.1 staging | `94d0169` | 193 | CLI scaffold (initial wire format) |
| 2.1 QG fixes | `874ae16` | 192 | camelCase, error field, recursive tree, removed VersionCommand |
| 2.2 staging | `f444ded` | 199 | EditCommand + GlobalOutputOptions |
| 2.2 QG fixes | `0b26f86` | 204 | versionId in conflict envelope, TTY/encoding/bytes hardening |
| 2.3 | `6b312ad` | 221 | comment + flag lifecycle (6 commands) + Wire/ refactor + explicit null encoding |
| 2.3 follow-up | `51e088e` | 225 | --tag (repeatable) + --text-stdin / --response-stdin (mdpal-app coord) |

## Commands shipped (9)

- `mdpal --version` (root flag)
- `mdpal sections <bundle>` — recursive tree + count + versionId
- `mdpal read <slug> <bundle>`
- `mdpal edit <slug> --version <hash> <bundle> [--content | --stdin]`
- `mdpal comment <slug> <bundle> --type --author [--text | --text-stdin] [--context] [--priority] [--tag ... --tag ...]`
- `mdpal comments <bundle> [--section] [--type] [--unresolved | --resolved]`
- `mdpal resolve <commentId> <bundle> [--response | --response-stdin] --by`
- `mdpal flag <slug> <bundle> --author [--note]`
- `mdpal flags <bundle>`
- `mdpal clear-flag <slug> <bundle>`

## What was done this session

1. Session resume + dispatch monitor in place
2. **Phase 1 PR shipped** (`/pr-prep` + `/release`): PR #179 created
3. **Phase 2 Iter 2.1**: CLI scaffold + sections/read; QG caught CRITICAL contract drift (snake_case→camelCase, code→error, recursive tree); fixed all
4. **Phase 2 Iter 2.2**: edit command + GlobalOutputOptions; QG caught CRITICAL spec violation (missing versionId in conflict envelope); fixed + TTY/encoding hardening
5. **Phase 2 Iter 2.3**: 6 collaboration commands + Wire/ directory; caught nil-optional encoding inline (custom encode(to:))
6. **Phase 2 Iter 2.3 follow-up**: addressed all 4 mdpal-app coord items from dispatch #575 (--tag repeatable, --stdin variants, commentNotFound already done, -- separator already free)
7. Replied to mdpal-app dispatch #579

## Next action — IMMEDIATELY AFTER COMPACT

**Iteration 2.4: Bundle commands + diff + prune + refresh.** Rounds out the dispatched CLI spec. mdpal-app fully unblocked after this.

Build order (engine work first, then commands):

1. **Build engine Diff API** (H5 from Phase 1.5 backlog). The `mdpal diff` command requires it. Suggested API:
   - `Document.diff(against other: Document) -> [SectionDiff]` where `SectionDiff` carries `slug`, `type: added|removed|modified|unchanged`, `summary: String`
   - Or bundle-level: `DocumentBundle.diff(_ rev1: String, _ rev2: String) -> [SectionDiff]` (loads both revs, walks sections, emits changes)
2. **CreateCommand**: `mdpal create <name> [--dir <path>]` — `DocumentBundle.create(name:initialContent:at:)` already exists; CLI just wraps + emits payload
3. **HistoryCommand**: `mdpal history <bundle>` — calls `bundle.listRevisions()`, emits sorted newest-first with `latest: true` flag on the matching one
4. **VersionCommand group**: `mdpal version show/bump <bundle>` — show reads currentDocument().info; bump calls `bundle.bumpVersion(content:)`
5. **RevisionCreateCommand**: `mdpal revision create <bundle> [--content | --stdin] [--base-revision <id>]` — base-revision optional concurrency check
6. **DiffCommand**: `mdpal diff <rev1> <rev2> <bundle>` — uses engine Diff API
7. **PruneCommand**: `mdpal prune <bundle> [--keep <n>]` — wraps `bundle.prune(keep:)`
8. **RefreshCommand**: `mdpal refresh <slug> <bundle>` — wraps `document.refreshSection(slug)`

Plus deferred-from-2.2/2.3 hygiene:
- Subprocess timeout in CLISupport
- Slug edge case tests (empty, leading slash)
- E2E test through CLI for full lifecycle
- Wire-format goldens

Then iteration-complete. Don't wait for principal.

## After 2.4: phase-complete + PR merge

After 2.4 ships:
- Run `/phase-complete` for Phase 2 (deep QG, principal approval REQUIRED — `/phase-complete` not auto-approved)
- Once PR #179 is merged, can ship Phase 2 work
- Or close PR #179 + open new PR for Phase 2 work (cleaner separation)

## Open coordination

- **PR #179** open with 12 commits — captain may have reviewed; check captain dispatches first
- **mdpal-app dispatch #579** (my reply) — they may dispatch back with confirmation/follow-ups
- **mdpal-app status:** Phase 1B complete, all 9 of their CLIServiceProtocol methods implemented against my dispatch #23 wire format. They can switch from FakeProcessRunner to RealProcessRunner against my binary now.
- **Cross-repo collab dispatches** to monofolk surfacing in monitor — captain territory

## Wire format spec (CRITICAL — keep handy for 2.4)

`usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md`

Key conventions established + tested:
- camelCase keys (NO snake_case)
- Error envelope: `{error: "camelCaseDiscriminator", message, details: {...}}`
- Optional fields: explicit `null` (custom encode(to:))
- Exit codes: 0/1/2/3/4 (success/general/versionConflict/notFound/bundleConflict)
- Bundle path: `BundleResolver.resolve()` — handles `~`, `..`, relative, absolute

## Deferred (Phase 1.5 / Phase 2 backlogs)

### Security hardening (Phase 1.5)
- C2 follow-up: Document(contentsOfFile:) follows symlinks in prune merge-forward (TOCTOU)
- Pointer file content validation
- File-size limits + YAML billion-laughs guard
- BundleConfig name validation
- BundleResolver sandbox-root policy
- Path scrubbing in error messages

### Phase 2 future
- 2.4: bundle commands + diff API + prune + refresh + e2e + hardening
- 2.5: Phase-complete + final coverage push

### From Phase 1 deferred (still relevant)
- H1 Revision metadata drift, H3 empty slug for non-ASCII, H4 slug suffix scheme
- H5 Diff API — IMPLEMENT IN 2.4
- H6 e2e Bundle+Document — IMPLEMENT IN 2.4
- H7 byte-equal round-trip — could fold into 2.5 hardening

## Key Artifacts

- PVR: `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md`
- A&D: `usr/jordan/mdpal/ad-mdpal-20260404.md`
- Plan: `usr/jordan/mdpal/plan-mdpal-20260406.md` (Phase 2 iterations marked complete through 2.3)
- Wire-format spec: `usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md`
- QGRs in `claude/workstreams/mdpal/qgr/`:
  - phase-complete `f1656c3`
  - pr-prep `8f2da0f`
  - iteration-complete 2.1 `fb1f7e3`
  - iteration-complete 2.2 `0374c18`
  - iteration-complete 2.3 `d57306b`
- PR: https://github.com/the-agency-ai/the-agency/pull/179

## Infrastructure notes

- Dispatch monitor running (task `b0mwsu3oj`, persistent, --include-collab)
- git-safe-commit auto-dispatch cascade: 1 untracked dispatch = steady state (flag #125)
- Sparse worktree: `git status` shows ~1310 D files = normal
- ISCP_SCHEMA_VERSION=1
- Swift testing framework deprecated warnings present (Swift 6 includes Testing native; small Package.swift cleanup item)

## Continuation directive after compact

Re-read this handoff. Verify dispatch monitor still running (start if not). Then PROCEED IMMEDIATELY to Iter 2.4 — no need to ask Jordan. Start with engine Diff API since it gates the `mdpal diff` command. Then ship the 7 commands. Then iteration-complete.
