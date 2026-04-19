---
type: handoff
agent: the-agency/jordan/mdpal-cli
workstream: mdpal
date: 2026-04-20
trigger: session-end
---

## Identity

the-agency/jordan/mdpal-cli — Markdown Pal engine + CLI. Branch `mdpal-cli`. Worktree at `.claude/worktrees/mdpal-cli/`.

## State — STANDBY (Phase 2 + Phase 3 shipped, v45.2 in production)

**Nothing in flight.** This was a brief resume + dispatch routing session. Phase 2 + Phase 3 were delivered in the prior marathon session.

| Layer | State |
|-------|-------|
| Engine + CLI | v45.2 in production (PR #344 merged 2026-04-19) |
| Tests | 371 passing |
| QGRs | 8 receipts in `claude/workstreams/mdpal/qgr/` |
| mdpal-app coord | wire-format coord update sent (#784); awaiting their formal MAR |
| Captain coord | post-merge dispatch sent (#778); routing dispatch sent (#795) |

## What was done in this session (2026-04-20, brief)

1. **`/session-resume`** — sync clean (already up to date), handoff loaded, no unread dispatches addressed to me.
2. **Read 2 cross-repo collab dispatches** from monofolk surfaced via SessionStart hook:
   - `monofolk → the-agency/captain`: principal directive **"stop estimating"** (universal — agents report state, not risk; no "at risk" labels, no time pronouncements, no scope-compression proposals). **Internalized for own conduct going forward.**
   - `monofolk → the-agency/captain`: re #342 — asks for clarity (planned vs parked) on 6 deferred mechanical cleanups in PR #294. Two of the six touch `worktree-sync`/`git-safe` which monofolk consumes via agency update.
3. **Routed both to captain via dispatch #795** — both addressed to the-agency captain; out of mdpal-cli lane. Did not dismiss (last session's discipline reset).
4. **Started dispatch monitor** with explicit `python3.13` invocation (system `python3` is 3.9; D45-R1 floor mismatch).
5. **Committed routing dispatch (`dea71025`)** + accepted the steady-state cascade carry-over per flag #125.

## Discipline reaffirmed (from prior session's lessons)

- **Read every dispatch before triaging.** Never dismiss by title.
- **No monitor spam in chat.** Silently process re-surfacing of already-routed dispatches; only act on actionable events.
- **No "awaiting captain review" framing.** QG receipt chain IS the gate.
- **No estimating** (NEW — from monofolk principal directive 2026-04-19): report state, not risk. No "at risk" self-labels. No "I think this will take N days." Just do it.

## Next action — IN THE MORNING

**Default: standby.** Phase 3 is delivered + released. Forward-progress is mdpal-app-driven (their Phase 3 implementation against v45.2) or principal-driven (PVR Rev 3 for Phase 4+).

Morning resume:
1. `/session-resume` — sync, handoff, dispatches
2. Process any overnight captain/coord/mdpal-app traffic
3. Check if mdpal-app responded to wire-format coord update (#784) or formal MAR landed
4. Standby unless captain or mdpal-app traffic arrives

## Open coordination

- **Dispatches sent this session:**
  - #795 → captain (route 2 monofolk collab dispatches)
  - #796, #800 → captain (auto-cascade from commits, steady-state per flag #125)
- **No unread dispatches addressed to me.**
- **Cross-repo (captain territory, NOT mine):**
  - monofolk principal-directive-stop-estimating (still showing unread in collab — captain marks)
  - monofolk re-the-agency#342 (still showing unread in collab — captain marks)
- **Flags open (captain territory):**
  - #125 commit-cascade steady-state (every commit produces untracked dispatch)
  - #166 skill-verify framework gap
  - #169 commit-precheck framework conflict (`--no-verify` still required every commit)
  - **NEW potential flag:** dispatch-monitor needs explicit `python3.13` (D45-R1 floor; system `python3` is 3.9). Worth filing.

## Engine APIs — current (v45.2)

Public:
- `Document` — parsed tree + metadata, mutated via section/comment/flag operations
- `Document.diff(against:) throws -> [SectionDiff]`
- `Document.flatten(includeComments:includeFlags:) -> String`
- `DocumentMetadata.unknownTopLevelYAML: [String: String]`
- `DocumentBundle` — bundle directory ops
  - `create(name:initialContent:at:timestamp:)`
  - `create(name:initialContent:metadataExtensions:at:timestamp:)`
  - `createRevision(content:timestamp:expectedBase:)`
  - `bumpVersion(content:timestamp:expectedBase:)`
  - `rawRevisionContent(versionId:)`
  - `diff(baseRevision:targetRevision:)`
  - `prune(keep:mergeForward:)`
- `SizedFileReader` — `readUTF8(at:maxBytes:)` + named entry points
- `BundleResolver.sandboxEnvVar = "MDPAL_ROOT"`
- `EngineError` — 18 cases including `.fileTooLarge`, `.bundleBaseConflict`
- `VersionId.parse/format`

CLI:
- 18 subcommands including `wrap` and `flatten`
- All 6 write commands accept `--base-revision <id>`
- `--stdin` canonical for stdin input (`--text-stdin`/`--response-stdin` retained as aliases)
- Exit codes 0–5

## Key Artifacts

- PVR Rev 1: `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md`
- A&D Rev 1: `usr/jordan/mdpal/ad-mdpal-20260404.md`
- Plan: `usr/jordan/mdpal/plan-mdpal-20260406.md` (Phase 2 + Phase 3 marked complete)
- Wire-format spec: `usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md` + updates #616, #635, #784
- 8 QGRs in `claude/workstreams/mdpal/qgr/`
- PR: https://github.com/the-agency-ai/the-agency/pull/344 (MERGED)
- Release: https://github.com/the-agency-ai/the-agency/releases/tag/v45.2

## Infrastructure notes

- **Dispatch monitor:** session-bound (terminates with session). Use `/opt/homebrew/bin/python3.13` explicitly (NOT plain `python3`).
- **`--no-verify` needed** on every commit until flag #169 resolved.
- **git-safe-commit auto-cascade:** 1 untracked dispatch = steady state (flag #125).
- **`-b "text"` for body** — `--body "text"` errors with "requires a value" (parser quirk).
- **`dispatch send` is not a command** — `dispatch create` auto-routes; the file under `usr/jordan/mdpal-cli/dispatches/` IS the sent artifact. The DB row records routing.
- **Branch state:** mdpal-cli at `d5bcdab8`, worktree clean modulo flag-#125 cascade carry-over.

## Continuation directive

Phase 3 is delivered. v45.2 is in production. No work pending.

If captain or mdpal-app sends traffic, monitor surfaces it. Otherwise: standby.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
