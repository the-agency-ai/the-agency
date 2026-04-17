---
type: handoff
agent: the-agency/jordan/mdpal-cli
workstream: mdpal
date: 2026-04-17
trigger: iteration-complete
---

## Identity

the-agency/jordan/mdpal-cli — Markdown Pal engine + CLI. Branch `mdpal-cli`. Worktree at `.claude/worktrees/mdpal-cli/`.

## Current state — Phase 2 iter 2.4 SHIPPED

**Phase 2 iters 2.1, 2.2, 2.3, 2.3 follow-up, 2.4 COMPLETE.** 16 of ~16 dispatched CLI commands shipped. mdpal-app **fully unblocked** (entire dispatched JSON spec is implemented and goldens lock the wire shapes).

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
| 2.4 | `8c8dbe1` | 291 | bundle commands + Diff API + Unicode slugs + 12 QG ACCEPT fixes |

## Commands shipped (16, the entire spec)

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
- `mdpal create <name> [--dir <path>] [--content <text>]`  ← 2.4
- `mdpal history <bundle>`  ← 2.4
- `mdpal version show/bump <bundle>`  ← 2.4
- `mdpal revision create <bundle> [--content | --stdin] [--base-revision <id>]`  ← 2.4
- `mdpal diff <rev1> <rev2> <bundle> [--include-unchanged]`  ← 2.4
- `mdpal prune <bundle> [--keep <n>]`  ← 2.4
- `mdpal refresh <slug> <bundle> [--base-revision <id>]`  ← 2.4

## What was done this session

1. Restarted dispatch monitor (task `bes5eyxnj`)
2. Built engine Diff API (`Document.diff`, `DocumentBundle.diff`, `SectionDiff`, `SectionDiffType`)
3. Built 7 new CLI commands (Create, History, Version show/bump, Revision create, Diff, Prune, Refresh) with consistent `BundleResolver`/`GlobalOutputOptions`/`EngineErrorMapper`/`JSONOutput` patterns
4. Initial /iteration-complete + QG: 4 reviewer agents flagged 26 findings, scorer kept 21 above threshold
5. Triaged into 12 ACCEPT, 9 originally-DEFER, 5 REJECT
6. **Principal directive mid-QG: "we don't defer"** — re-triaged the 9 deferred items into DO / WON'T DO / DISCUSS. All 9 became DO except the concurrent-writer test (already covered at engine level).
7. Asked principal about D4/D5 (error discriminator policy: codebase vs spec authoritative). Principal said "Autonomous". Chose option B (codebase authoritative; dispatch updated canonical 17-discriminator list to mdpal-app).
8. Implemented all 12 ACCEPT fixes + Unicode slug fix (H3 from Phase 1 backlog promoted) + 24 new tests including 8 wire-format goldens
9. Added engine `createRevision(content:expectedBase:)` overload + `EngineError.bundleBaseConflict` for atomic TOCTOU close
10. Added shared `StdinReader` (16 MiB cap, payloadTooLarge envelope) replacing 4 ad-hoc handlers
11. Sent dispatch #616 to mdpal-app describing additions; got #617 ack (no adjustments requested)
12. Filed flag #166 to captain re skill-verify framework gap (all 59 skills flagged as missing allowed-tools per intentional design)
13. Committed `8c8dbe1` (Phase 2.4) — 31 files, 291 tests passing
14. Receipt signed: `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-cli-mdpal-mdpal-qgr-iteration-complete-20260417-1509-53e3abe.md`

## Next action

**Iteration 2.5: Phase 2 hardening + phase-complete prep.**

Per the plan-mdpal-20260406.md iter 2.5 scope:
- E2E test: full create → edit → comment → flag → prune → diff lifecycle through CLI
- Subprocess timeout in CLISupport (deferred from 2.2/2.3/2.4)
- Performance: 100-revision bundle benchmarks
- Multi-process concurrent-CLI test
- Phase 1.5 deferred items still applicable: file-size limits beyond stdin (file inputs), name validation (mostly done in 2.4), CSV-style YAML billion-laughs guard
- Coverage: ≥90% engine, ≥80% CLI

Then `/phase-complete` for Phase 2 (deep QG, principal 1B1 required).

## Open coordination

- **Dispatch #608 from captain:** "Main updated — 10 PRs merged" (UNREAD as of last check; should review what landed in case it touches PR #179 base)
- **Dispatch #617 from mdpal-app** (ack of #616): READ. No adjustments requested. They'll extend CLIErrorDetails to cover the canonical 17 discriminators + payloadTooLarge in early Phase 2 iteration.
- **PR #179** still open with 16+ commits — captain may have reviewed; check captain dispatches first before iter 2.5
- **Cross-repo collab dispatches** to monofolk surfacing in monitor — captain territory
- **Flag #166** filed re skill-verify framework gap — captain/devex follow-up

## Wire format spec (CRITICAL — fully implemented)

`usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md`

Conventions established + tested + locked by goldens:
- camelCase keys (NO snake_case)
- Error envelope: `{error: "camelCaseDiscriminator", message, details: {...}}`
- Optional fields: explicit `null` (custom encode(to:))
- Exit codes: 0/1/2/3/4 (success/general/versionConflict/notFound/bundleConflict)
- Bundle path: `BundleResolver.resolve()` — handles `~`, `..`, relative, absolute
- Canonical 17 discriminators (per dispatch #616 to mdpal-app): parseError, metadataError, sectionNotFound, versionConflict, bundleConflict, fileError, fileNotFound, invalidArgument, commentNotFound, commentAlreadyResolved, sectionNotFlagged, unsupportedFormat, noFilePath, invalidBundlePath, invalidEncoding, stdinIsTTY, payloadTooLarge

## Engine APIs added this iteration

- `Document.diff(against other: Document) throws -> [SectionDiff]`
- `DocumentBundle.diff(baseRevision:, targetRevision:) throws -> [SectionDiff]`
- `DocumentBundle.createRevision(content:, timestamp:, expectedBase:)` overload
- `EngineError.bundleBaseConflict(expected: String, actual: String)`
- `SectionDiff` value type, `SectionDiffType` enum (added/removed/modified/unchanged with raw camelCase strings)
- Unicode-aware slug regex in `MarkdownParser.slug(for:)` — `[^\p{L}\p{N}\-]`

## Deferred (Phase 1.5 / Phase 2.5 backlogs — VERIFIED still active)

### Security hardening (Phase 1.5)
- C2 follow-up: Document(contentsOfFile:) follows symlinks in prune merge-forward (TOCTOU)
- Pointer file content validation
- File-size limits beyond stdin (CLI file argument paths, e.g., bundle path arg)
- YAML billion-laughs guard (file-size cap on YAML metadata block)
- BundleConfig name validation (mostly done in 2.4 for create-time names; runtime validation TBD)
- BundleResolver sandbox-root policy
- Path scrubbing in error messages

### Phase 2.5
- E2E test through CLI for full lifecycle
- 100-revision bundle benchmarks
- Multi-process concurrent CLI test
- Subprocess timeout in CLISupport
- Phase-complete deep QG

### From Phase 1 deferred
- ~~H5 Diff API~~ ✅ DONE in 2.4
- ~~H3 empty slug for non-ASCII~~ ✅ DONE in 2.4 (Unicode regex)
- H1 Revision metadata drift, H4 slug suffix scheme — still deferred
- H6 e2e Bundle+Document — fold into 2.5
- H7 byte-equal round-trip — partially addressed by F6 (version bump now byte-equal); broader scope still in 2.5

## Key Artifacts

- PVR: `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md`
- A&D: `usr/jordan/mdpal/ad-mdpal-20260404.md`
- Plan: `usr/jordan/mdpal/plan-mdpal-20260406.md` (Phase 2 marked complete through 2.4)
- Wire-format spec: `usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md`
- QGRs in `claude/workstreams/mdpal/qgr/`:
  - phase-complete `f1656c3`
  - pr-prep `8f2da0f`
  - iteration-complete 2.1 `fb1f7e3`
  - iteration-complete 2.2 `0374c18`
  - iteration-complete 2.3 `d57306b`
  - iteration-complete 2.4 `53e3abe` ← THIS ITERATION
- Coord dispatches: #616 (to mdpal-app), #617 (mdpal-app ack)
- Flag #166 (skill-verify framework gap)
- PR: https://github.com/the-agency-ai/the-agency/pull/179

## Infrastructure notes

- Dispatch monitor: TWO running (`b0mwsu3oj` from prior session, `bes5eyxnj` from this session). The older one is redundant — should TaskStop b0mwsu3oj. Both are reporting same events.
- git-safe-commit auto-dispatch cascade: 1 untracked dispatch = steady state (flag #125)
- Sparse worktree: `git status` shows ~1310 D files = normal
- ISCP_SCHEMA_VERSION=1
- Swift testing framework deprecated warnings (Swift 6 includes Testing native; Package.swift cleanup item)

## Continuation directive

Re-read this handoff. Process unread captain dispatch #608 first (10 PRs merged on main — check if any affect PR #179). Stop the redundant `b0mwsu3oj` task. Then proceed to Iteration 2.5 — start with the e2e CLI lifecycle test (highest unblocking value for phase-complete). Don't ask Jordan unless something genuinely blocks.

After 2.5 ships: `/phase-complete` (deep QG, principal 1B1 required, principal-approval gate).
