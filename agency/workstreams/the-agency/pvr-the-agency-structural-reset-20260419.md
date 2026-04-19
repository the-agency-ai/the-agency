---
type: pvr
workstream: the-agency
slug: structural-reset
principal: jordan
agent: the-agency/jordan/captain
date_started: 2026-04-19
stage: define
status: in-progress
next_stage: design
seed: claude/workstreams/the-agency/seeds/seed-true-installer-bootstrap-20260419.md
related_issues: [270, 287, 332, 333, 334, 335, 336, 337]
driver: "Principal directive D45-R3 — 'This is required to get us in shipping shape'"
---

# PVR — The-Agency Structural Reset (v46.0)

Target: a coordinated **Great Rename + directory reorganization + cruft removal + reference sweep** that puts the-agency into shipping shape. Prerequisite for the installer Valueflow pass (#337). Breaking change for the single adopter (monofolk) — release notes bridge the gap.

## 1. Problem Statement

The-agency's framework root (`claude/`) has accumulated structural debt that blocks shipping at scale:

- **Wrong name in the filesystem** — the framework is called "the agency" but lives under `claude/`. Conflates Claude Code's private area (`.claude/`) with the agency's framework code in every mental model, every path, every import.
- **Flat REFERENCE + README root** — 36 `REFERENCE-*.md` files + 5 `README-*.md` files sit at `claude/` root with zero grouping. Adopters can't find things; framework maintainers have trouble organizing new ones.
- **Sprawl in framework root** — `docs/`, `integrations/`, `logs/`, `principals/`, `proposals/`, `receipts/`, `reviews/`, `schemas/` all sit at `claude/` root with unclear purpose, overlap, or legacy-only status.
- **Install surface is unmanaged** (#287) — no manifest, no install vs source distinction, no coherent story for what adopters get vs what framework developers see.
- **Duplicate + abandoned workstreams** — `workstreams/agency/` + `workstreams/the-agency/` + `workstreams/captain/` + `workstreams/housekeeping/` overlap / fragment. Plus `workstreams/test; rm -rf ` injection artifact, plus `workstreams/gtm/` that belongs in the-agency-group not this repo.
- **Legacy subsystems masquerading as active** — `claude/principals/` (v1 principal system, replaced by `usr/` + `agency.yaml`), `claude/receipts/` (pre-D42-R3, now lives in per-workstream qgr/ rgr/), dead DBs (`bug.db`, `bugs.db` from the just-killed `/agency-bug`).
- **500+ reference paths scattered throughout** — @imports, `required_reading:` frontmatter, hardcoded `claude/` in tool internals, hookify rules, settings.json. No central sweep has ever been done.

**Why now:** the installer Valueflow pass (#337) needs a clean tree to manifest against. Every day we wait adds more references to sweep when we finally do it. Monofolk is the only adopter; this is the last cheap moment to do a breaking structural change.

## 2. Target Users

- **Framework developer (Jordan, captain)** — works in the-agency repo daily. Must find things fast. Reference sweeps must actually update every live caller.
- **Adopter agent (monofolk, andrew-demo)** — uses the framework via `agency init` + `agency update`. Must NOT see transient breakage; must receive release notes that explain the migration.
- **Future adopters (post-v46)** — see the clean shipping-shape framework from day one. No exposure to pre-v46 naming.
- **Agents themselves (captain, devex, reviewer-*, etc.)** — session startup reads CLAUDE.md → @imports. Must resolve to new paths immediately on first post-v46 session.
- **CI / validation tooling** — skill-validation.bats, commit-precheck, agency-health — must be updated in lockstep.

## 3. Use Cases

### 3.1. Fresh `git clone the-agency-ai/the-agency` (framework-dev)
- Developer clones → sees `agency/` (not `claude/`) + organized `agency/REFERENCE/` + `agency/README/`
- No `claude/` directory in framework-source (except `.claude/` which is Claude Code's)
- All dead subdirs (`reviews/`, old `principals/`, `docs/`, duplicate workstreams) absent
- Normal agent session starts cleanly; @imports resolve to new paths

### 3.2. Existing adopter runs `agency update` from v45.x → v46.0
- Adopter's local `claude/` survives the update OR gets migrated (TBD in design — one-time migration script or no-touch)
- Adopter's `usr/` sandbox is preserved exactly
- Release notes walk the adopter through manual steps if any (accept breaking change per principal)

### 3.3. Captain reads a skill's `required_reading:` frontmatter
- Skills reference `agency/REFERENCE/REFERENCE-*.md` (new) vs `claude/REFERENCE-*.md` (old)
- Ref-injector hook resolves new paths
- Skill bundle validation passes

### 3.4. CI runs full test suite post-reset
- `bats tests/` — all pass against new paths
- `skill-validation.bats` — passes
- `commit-precheck` — passes
- `agency-health` — returns clean

### 3.5. Historical @import preserved via release notes / migration
- Old commit messages + PR bodies referencing `claude/` remain valid as historical record
- Migration script (if any) handles adopter's `.claude/settings.json` hook path rewrites + CLAUDE.md path updates

## 4. Functional Requirements

### 4.1. Great Rename

- `claude/` directory → `agency/` directory
- Every file under the old tree arrives at the new tree with identical content
- Git detects each as a rename (history preserved)
- `.claude/` (Claude Code's private) stays untouched in NAME — its INTERNAL path references may update if they point at framework content

### 4.2. Subdir reorganization within `agency/`

- `agency/REFERENCE/REFERENCE-*.md` — all 36 REFERENCE docs move here
- `agency/README/README-ENFORCEMENT.md`, `README-SAFE-TOOLS.md`, `README-RECEIPT-INFRASTRUCTURE.md` — moved to README/ subdir
- `agency/README-THEAGENCY.md` + `agency/README-GETTINGSTARTED.md` — stay at `agency/` root (top-level READMEs)
- `agency/CLAUDE-THEAGENCY.md` — stays at `agency/` root (bootloader)

### 4.3. Cruft removal

- DELETE `claude/workstreams/test; rm -rf ` (injection-test artifact, 1 file)
- DELETE `claude/reviews/` if verified dead
- DELETE `claude/data/bug.db`, `claude/data/bugs.db` if legacy from killed `/agency-bug`
- DELETE `claude/docs/` after 1B1 review of contents (principal directive — pending content review)
- DELETE `claude/receipts/` after verifying all receipts migrated to per-workstream `qgr/`/`rgr/`
- DELETE empty or redundant starter-pack contents (per content audit)

### 4.4. Workstream consolidation

- MERGE `claude/workstreams/agency/` content → `claude/workstreams/the-agency/history/legacy-agency-workstream-20260419/`
- MERGE `claude/workstreams/captain/` content → `claude/workstreams/the-agency/transcripts/` (where applicable)
- MERGE `claude/workstreams/housekeeping/` content → `claude/workstreams/the-agency/history/legacy-housekeeping-20260419/`
- Final result: only `the-agency/` (framework work) + per-app workstreams (`mdpal/`, `mdslidepal/`, `mock-and-mark/`, `iscp/`, `devex/`, `designex/`)

### 4.5. Archive legacy subsystems

- MOVE `claude/principals/` → `claude/workstreams/the-agency/history/flotsam/legacy-principals-20260419/` (v1 principal system, fully replaced by `usr/` + `agency.yaml`)
- Any content in `claude/docs/` that has historical value → `claude/workstreams/the-agency/history/flotsam/legacy-docs-20260419/`

### 4.6. the-agency-group moves (DEFERRED if collab repo not set up)

- `claude/workstreams/gtm/` → the-agency-group workstream (via cross-repo collaboration)
- `claude/proposals/` → the-agency-group archive (philosophy/ + projects/)
- IF collab repo not ready: leave in place with prominent `TODO-MOVE-TO-THE-AGENCY-GROUP.md` marker; do not block reset on this

### 4.7. Reference sweep (THE BIG ONE)

Every path reference to the old layout must update:

| Reference type | Old | New | Files affected (approx) |
|---|---|---|---|
| `@claude/REFERENCE-*.md` imports | `@claude/REFERENCE-FOO.md` | `@agency/REFERENCE/REFERENCE-FOO.md` | CLAUDE.md, CLAUDE-*.md (~20 files) |
| `@claude/README-*.md` imports | `@claude/README-SAFE-TOOLS.md` | `@agency/README/README-SAFE-TOOLS.md` | CLAUDE-*.md, skill docs (~15 files) |
| Hardcoded `claude/` in tools | `claude/tools/foo` | `agency/tools/foo` | Every bash tool with path refs (~100 files) |
| `required_reading:` frontmatter | `claude/REFERENCE-X.md` | `agency/REFERENCE/REFERENCE-X.md` | All .claude/skills/*/SKILL.md with required_reading (~10 files) |
| Settings.json hook paths | `$CLAUDE_PROJECT_DIR/claude/hooks/X.sh` | `$CLAUDE_PROJECT_DIR/agency/hooks/X.sh` | `.claude/settings.json` + adopter settings |
| Hookify rule docs | References to `claude/` paths | `agency/` paths | 40+ rule docs |
| agency-init scaffolding | scaffolds `claude/` | scaffolds `agency/` | `_agency-init` tool |
| worktree-sync logic | `.claude/settings.json` copy + workstream paths | Updated paths | `worktree-sync` tool |
| Test fixtures | Install framework files under `claude/` | Install under `agency/` | All .bats test fixtures |

### 4.8. CLAUDE.md at repo root

- Continues to exist at repo root (Claude Code convention)
- `@import` points updated: `@claude/CLAUDE-THEAGENCY.md` → `@agency/CLAUDE-THEAGENCY.md`

### 4.9. Framework tools (`agency/tools/`)

- All tools retain their current discoverable location `claude/tools/X` → `agency/tools/X`
- Safe-tools family updated (git-safe, git-captain, cp-safe, pr-create, etc.) — no behavior change, just path
- Invocation pattern: `./claude/tools/X` → `./agency/tools/X` for captain; documented in README-SAFE-TOOLS.md post-move

### 4.10. `.claude/` (Claude Code private) content

- `.claude/settings.json` — hook paths updated
- `.claude/skills/*/SKILL.md` — `required_reading:` paths updated; `allowed-tools` comments updated (references to `claude/tools/` → `agency/tools/`); script invocation paths updated
- `.claude/commands/*.md` — path references updated
- `.claude/agents/` — if registrations reference `claude/` paths, update

### 4.11. Release notes + migration guide

- **Release notes document:** human-readable "v46.0: Structural Reset" — what changed, why, what adopters need to do
- **Migration script:** optional — rewrites `.claude/settings.json` hook paths + any CLAUDE.md imports in adopter repo. Runs via `agency update --migrate`
- **Rollback:** git tag `v45.3-pre-reset` captured before reset; adopters can revert via `agency update --version v45.3`

## 5. Non-Functional Requirements

### 5.1. Verifiability
- CI passes: `bats tests/`, `commit-precheck`, `agency-health`, `skill-validation.bats`
- Smoke test: fresh `agency init` on a test dir produces clean v46.0 install
- `agency update` on monofolk: documented steps succeed

### 5.2. Atomicity
- Ideally one PR / one release — structural reset lands as an atomic unit
- Intermediate commits OK (Great Rename, subdir, cruft, reference sweep) — but merge as one PR

### 5.3. History preservation
- Git rename detection carries file history for every moved file
- No `rm` + `create` patterns that lose blame

### 5.4. Reversibility (safety net)
- Pre-reset git tag (`v45.3-pre-reset`) committed
- Documented rollback path for monofolk
- If reset goes wrong mid-way, can reset to tag

### 5.5. Tooling parity
- Every framework tool works identically after reset — just different path
- No test flakiness introduced
- No runtime path resolution regressions

### 5.6. Duration / scope control
- Fits in single focused session (per principal)
- Parallel subagents handle reference sweeps (not captain-serial)
- Handoff captures state at every phase boundary for compact-resume

## 6. Constraints

- **Single adopter (monofolk)** — breaking change acceptable with release notes; no backward compatibility shim needed
- **Git history preservation** — must use rename operations, not delete + create
- **No src/ split in this reset** — principal agreed: `src/` split is installer territory (#337), not this reset
- **No cross-repo collab moves in this reset** — gtm/ + proposals/ moves deferred if collab repo not ready
- **Hooks + hookify location stays** — per #336 decision, `agency/hooks/` and `agency/hookify/` are correct locations; only the `claude/` → `agency/` path changes
- **AGENCY_ALLOW_RAW=1 is the bypass for raw git operations** — per hookify escape hatch; alternative: temporary settings.json mutation (principal authorized if needed)
- **Current PR #294 state** — reset may ride on top of #294's branch or fork to a new branch; decision in design

## 7. Success Criteria

Concrete, measurable, pass/fail:

1. `claude/` directory does not exist at framework-source root; `agency/` does
2. `agency/REFERENCE/` contains all 36 REFERENCE docs; none at `agency/` root
3. `agency/README/` contains README-ENFORCEMENT, SAFE-TOOLS, RECEIPT-INFRASTRUCTURE; README-THEAGENCY + README-GETTINGSTARTED at `agency/` root
4. `claude/workstreams/test; rm -rf ` does not exist (or its successor)
5. No `claude/principals/` exists; its content preserved under history/flotsam
6. No `claude/reviews/` exists (if confirmed dead)
7. No `claude/docs/` or empty `docs/plans/` at repo root
8. `claude/workstreams/agency/`, `claude/workstreams/captain/`, `claude/workstreams/housekeeping/` do not exist (merged into `the-agency/`)
9. All `bats tests/` pass
10. `commit-precheck` passes on a no-op change
11. `agency-health` returns clean (0 critical, 0 warnings in baseline state)
12. `grep -rE 'claude/' <non-historical paths>` returns zero hits in ACTIVE code (tool internals, skill frontmatter, CLAUDE.md, settings.json)
13. Fresh `agency init` produces a clean v46.0 scaffold with `agency/` naming
14. Captain can operate (handoff read, dispatch list, flag list, session-resume) without errors
15. PR #294's tests all still pass on the reset branch
16. Release notes written + merged

## 8. Non-Goals

- **`src/` source + install split** — installer territory (#337), not this reset
- **Manifest-driven installer** — #337 Valueflow pass
- **`.claude/settings.json` redesign** — only path rewrites, no semantic changes
- **Hookify Enforcement Triangle refactor** — only path rewrites
- **Hook script rewrites** — only path + shebang adjustments
- **Starter-pack content changes** — only path rewrites to their internal references
- **`agency/integrations/`, `agency/schemas/`, `agency/assets/` restructuring** — keep current shape; just renamed path
- **Tool behavior changes** — no tool API or behavior modifications (safe-tools family unchanged)
- **Skill bundle semantic changes** — v2 methodology discussions continue at #314 separately
- **gtm/ + proposals/ move to the-agency-group** — blocked on collab repo setup; mark as follow-up
- **New features** — this is a structural change, not a feature delivery
- **Deletion of content principals might want to read** — archive to history/flotsam rather than rm

## 9. Open Questions

1. **Branching strategy** — reset-on-PR-#294 (monolith) OR new branch off #294's HEAD OR separate PR stack. Impact: review burden vs merge order.
2. **PR #294 interaction** — does the reset merge AFTER or ride WITH #294? Principal to decide.
3. **Migration script for monofolk** — build or hand-walk via release notes? (Monofolk is the only adopter.)
4. **docs/ contents review** — principal asked for 1B1. Need content audit before delete vs archive decision.
5. **reviews/ dead confirmation** — only one file (`REVIEW-captain-2026-03-28.md`). Delete or archive to history/flotsam?
6. **Legacy DBs (bug.db, bugs.db)** — query contents before decide delete vs archive?
7. **claude/logs/** — unreviewed. Delete, archive, or keep with path rename?
8. **claude/assets/theagency-logo-constellation.svg** — stays at `agency/assets/`? Or move to `agency/brand/`?
9. **claude/integrations/claude-desktop/** — what is it + purpose? Keep, move, delete?
10. **Principal authorization to disable hooks temporarily?** — already authorized; prefer `AGENCY_ALLOW_RAW=1` per-command for auditability unless speed requires
11. **Who merges the reset PR** — principal approval required given breaking change

---

## Completeness Scorecard

| # | Section | Status |
|---|---|---|
| 1 | Problem Statement | ✓ Complete |
| 2 | Target Users | ✓ Complete |
| 3 | Use Cases | ✓ Complete |
| 4 | Functional Requirements | ✓ Complete |
| 5 | Non-Functional Requirements | ✓ Complete |
| 6 | Constraints | ✓ Complete |
| 7 | Success Criteria | ✓ Complete |
| 8 | Non-Goals | ✓ Complete |
| 9 | Open Questions | 11 captured (answers resolve in A&D) |

**Score: 9/9 complete for PVR** — open questions are expected and resolve in the A&D stage.

## Transition

Next stage: `/design` — produce A&D covering:
- Migration strategy (big-bang vs phased within the reset)
- Branch strategy decision (ride PR #294 vs new branch)
- Reference sweep mechanics (subagent fan-out design)
- Validation gates (which checks at which phase)
- Rollback mechanics (git tag + documented revert)
- Release notes skeleton + migration script decision

MAR queued before transition.
