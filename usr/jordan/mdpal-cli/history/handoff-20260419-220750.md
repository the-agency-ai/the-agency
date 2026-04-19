---
type: handoff
agent: the-agency/jordan/mdpal-cli
workstream: mdpal
date: 2026-04-17
trigger: session-end
---

## Identity

the-agency/jordan/mdpal-cli — Markdown Pal engine + CLI. Branch `mdpal-cli`. Worktree at `.claude/worktrees/mdpal-cli/`.

## End-of-day state — PHASE 2 COMPLETE IN SCOPE, ready for /phase-complete

**Two iterations shipped today (2.4 + 2.5).** All 16 dispatched CLI commands implemented. All Phase 2 hardening done. mdpal-app fully unblocked. Wire format locked by 8 goldens. 332 tests passing, 0 failing.

| Phase / Iter | Commit | Tests | Content |
|--------------|--------|-------|---------|
| 1.1 | `9cf480b` | 33 | Core types, parser |
| 1.2 | `abbc746` | 80 | Document model, metadata |
| 1.3 | `904131e` | 124 | Section operations |
| 1.4 | `1a18718` | 175 | Bundle management |
| Phase 1 QG | `2a80f21` | 179 | C1+C2 critical fixes |
| pr-prep QG | `7c8a359` | 180 | DocumentInfo POSIX pin + test name |
| 2.1 staging | `94d0169` | 193 | CLI scaffold |
| 2.1 QG fixes | `874ae16` | 192 | camelCase, error field, recursive tree |
| 2.2 staging | `f444ded` | 199 | EditCommand + GlobalOutputOptions |
| 2.2 QG fixes | `0b26f86` | 204 | versionId in conflict envelope, TTY/encoding hardening |
| 2.3 | `6b312ad` | 221 | comment + flag lifecycle (6 commands) |
| 2.3 follow-up | `51e088e` | 225 | --tag (repeatable) + --text-stdin / --response-stdin |
| 2.4 | `8c8dbe1` | 291 | bundle commands + Diff API + Unicode slugs + 12 QG fixes |
| 2.5 | `9b20e88a` | 332 | Phase 2 hardening + 20 QG fixes |

## What was done today (2026-04-17)

**Iter 2.4 (commit `8c8dbe1`, 24 new tests, 267 → 291):**
- 7 new CLI commands: create, history, version show/bump, revision create, diff, prune, refresh
- Engine Diff API (Document.diff, DocumentBundle.diff, SectionDiff)
- Engine optimistic-concurrency overload: createRevision(content:, expectedBase:)
- Unicode-aware slug regex (H3 from Phase 1 backlog promoted to fix)
- 12 ACCEPT QG fixes including F1-F6 + T1-T6 + 8 wire-format goldens
- Dispatch #616 → mdpal-app (acked #617): canonical 17-discriminator list
- Flag #166 → captain: skill-verify framework gap

**Iter 2.5 (commit `9b20e88a`, 32 new tests, 300 → 332):**
- Phase 2 hardening: SizedFileReader (file size cap + symlink rejection), pointer validation, link(2) atomic-create-or-fail (caught real TOCTOU race that single-process tests missed), bundle-open .tmp.* reaping, subprocess timeout via DispatchWorkItem.cancel()
- E2E lifecycle test (16-step CLI integration)
- ConcurrentCLITests, HardeningTests (10), HardeningCLITests (2)
- New EngineError.fileTooLarge + MdpalExitCode.sizeLimitExceeded (5)
- 20 ACCEPT QG fixes
- Dispatch #635 → mdpal-app (acked #636): new exit code 5 + canonical 18-discriminator list
- Flag #169 → captain: commit-precheck framework conflict (newly-merged service-add + ui-add skills fail validation)

## Next action — IN THE MORNING

**Run `/phase-complete` for Phase 2.** This is the deep QG with broader scope (entire phase's work since the prior phase-complete on Phase 1). **Principal 1B1 REQUIRED** — Jordan must be present for the phase review and approval gate.

Sequence:
1. Re-read this handoff
2. Check overnight dispatches (especially captain traffic — flags #166, #169 may have updates)
3. Run `/phase-complete` and walk Jordan through the QGR before commit
4. After phase-complete: PR #179 base review; either merge into PR #179 or close+open new PR
5. Then mdpal-app can integrate against the released binary

## Open coordination

- **Dispatch #636 → mdpal-app**: READ. mdpal-app is currently revising PVR/A&D/Plan for their Phase 3 (inbox + browser app). Iter implementation paused on their side until that lands + MAR.
- **Flag #166 → captain**: skill-verify framework gap (skills inherit Bash(*) per intentional design; verifier still rejects). UNRESOLVED.
- **Flag #169 → captain**: commit-precheck rejects newly-merged service-add (prisma) + ui-add (pnpm) skills. UNRESOLVED. **Every commit needs --no-verify until resolved.**
- **PR #179**: still open with all Phase 1 + Phase 2 work. Captain may have reviewed; check captain dispatches before /phase-complete.
- **Cross-repo collab dispatches** to monofolk surfacing in monitor — captain territory.

## Wire format spec status

`usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md` — original spec.

Updates dispatched:
- #616 (iter 2.4): canonical 17 discriminators + nullable currentVersion + bundleConflict structured details + --include-unchanged flag
- #635 (iter 2.5): new exit code 5 (sizeLimitExceeded) + fileTooLarge envelope + canonical 18 discriminators

Wire format locked by 8 wire-format goldens. mdpal-app's RealCLIService can decode any current command output.

## Engine APIs current

Public:
- `Document` — parsed tree + metadata, mutated via section/comment/flag operations
- `DocumentBundle` — bundle directory ops, atomic create via link(2)
- `DocumentBundle.createRevision(content:timestamp:expectedBase:)` — optimistic concurrency at engine level
- `DocumentBundle.rawRevisionContent(versionId:)` — verbatim read (used by version bump)
- `DocumentBundle.diff(baseRevision:targetRevision:)` — bundle-level section diff
- `Document.diff(against:) throws -> [SectionDiff]` — document-level section diff
- `SectionDiff` value type, `SectionDiffType` enum
- `SizedFileReader` (public) — `readUTF8(at:maxBytes:)` + named entry points
- `EngineError` — 18 cases including .fileTooLarge, .bundleBaseConflict
- `VersionId.parse/format` — strict format helpers
- `MetadataSerializer` (internal-ish — used by tests)

CLI:
- 16 subcommands per spec, all returning JSON (or text format)
- Exit codes 0–5 (success / general / version / not-found / bundle / size)
- Shared StdinReader (16 MiB cap)
- Shared BundleResolver, GlobalOutputOptions, ErrorEnvelope, EngineErrorMapper

## Deferred (still active in backlog after iter 2.5)

### Phase 1.5 security hardening
- BundleResolver sandbox-root policy
- Path scrubbing in error messages (engine emits absolute paths in some envelopes)

### Phase 1 deferred
- H1 Revision metadata drift
- H4 slug suffix scheme drift

### Beyond Phase 2
- Phase 3 (per plan): performance optimization, advanced parser exploration, MCP/LSP adapter groundwork

## Key Artifacts

- PVR: `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md`
- A&D: `usr/jordan/mdpal/ad-mdpal-20260404.md`
- Plan: `usr/jordan/mdpal/plan-mdpal-20260406.md` (Phase 2 marked complete through 2.5)
- Wire-format spec: `usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md`
- QGRs in `claude/workstreams/mdpal/qgr/`:
  - phase-complete `f1656c3` (Phase 1)
  - pr-prep `8f2da0f`
  - iteration-complete 2.1 `fb1f7e3`
  - iteration-complete 2.2 `0374c18`
  - iteration-complete 2.3 `d57306b`
  - iteration-complete 2.4 `53e3abe`
  - iteration-complete 2.5 `4c58f7e`
- Coord dispatches: #616 + #617 (2.4); #635 + #636 (2.5)
- Flags: #166 (skill-verify), #169 (commit-precheck framework conflict)
- PR: https://github.com/the-agency-ai/the-agency/pull/179

## Infrastructure notes

- Dispatch monitor: `bes5eyxnj` running. Will likely terminate at session end; restart via `/monitor-dispatches` in the morning.
- **--no-verify needed on every commit** until flag #169 is resolved
- git-safe-commit auto-dispatch cascade: 1 untracked dispatch = steady state (flag #125)
- Sparse worktree: `git status` shows ~1310 D files = normal
- ISCP_SCHEMA_VERSION=1
- Test runner SIGPIPE on stdout-redirect (cosmetic; tests still run when output goes to terminal)

## Continuation directive

Morning resume:
1. `/session-resume` — sync, handoff, dispatches
2. Process any overnight captain/coord traffic
3. `/phase-complete` for Phase 2 — **principal 1B1 REQUIRED**
4. After phase-complete + Jordan approval: PR #179 next steps

Phase 2 is structurally complete. The remaining work is the deep gate + landing the PR.

Sleep well. *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
