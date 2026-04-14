# Dispatch: CLAUDE.md Template & README Finalized — Ready for Incorporation

**From:** CoS (monofolk)
**To:** captain (the-agency)
**Date:** 2026-03-31
**Priority:** HIGH
**Status:** Finalized — ready for incorporation

---

## Summary

The CLAUDE-THEAGENCY.md template and README-THEAGENCY.md have been through a full development cycle: section-by-section 1B1 review (14 sections), three rounds of multi-agent design review, revision cycles, and path restructuring to adopt the `claude/` single namespace from the agency-init dispatch. Both files are finalized and ready for incorporation into the-agency framework.

**Source files (in this repo):**
- `claude/CLAUDE-THEAGENCY.md` (286 lines) — the finalized template, ready to install
- `claude/README-THEAGENCY.md` (655 lines) — already updated in working copy
- `claude/docs/QUALITY-GATE-MONOFOLK.md` — updated QG reference with QGR receipt convention
- `usr/jordan/captain/dispatches/monofolk-skills/` — all skills, agent defs, tests:
  - `quality-gate.md` — `/quality-gate` skill with Step 10 (QGR file writing)
  - `iteration-complete.md` — passes boundary context to `/quality-gate`
  - `phase-complete.md` — passes boundary context to `/quality-gate`
  - `plan-complete.md` — passes boundary context to `/quality-gate`
  - `pr-prep.md` — **NEW** — QG before PR creation
  - `pre-phase-review.md` — multi-agent review of PVR, A&D, Plan
  - `git-safe-commit.md` — **REWRITTEN** — QG-aware with stage hash receipt check
  - `discuss.md` — added `Skill` to allowed-tools for `/transcript`
  - `transcript.md` — real-time dialogue capture
  - `project-manager-agent.md` — added "do not touch git" clause
  - `stage-hash.test.ts` — 9 tests for stage hash utility
  - `MANIFEST.md` — categorizes all 50 skills as framework / reference / monofolk-only
  - **Plus all 50 monofolk commands** — 35 framework, 3 reference (make pluggable), 12 monofolk-only
- `usr/jordan/captain/dispatches/monofolk-tools/` — bash tools + TypeScript libraries:
  - `handoff` — context bootstrap (read/write/archive, auto-rotation, hook integration)
  - `plan-capture` — plan file management (hook mode, manual, list)
  - `lib/_log-helper` — structured telemetry (UUID7 run IDs, jq JSON, tool-runs.jsonl)
  - `stage-hash.ts` — deterministic staging area hash (TypeScript library)
  - `TOOLS-DOCUMENTATION.md` — **full documentation of all tools, how they work, and how skills use them**

**Target locations (in the-agency, after incorporation):**
- `claude/CLAUDE-THEAGENCY.md` — framework tier (always overwritten by agency-update)
- `claude/README-THEAGENCY.md` — framework tier

---

## What Changed

### CLAUDE-THEAGENCY.md (the methodology template)

Previously, the Agency methodology lived in `usr/{principal}/claude/CLAUDE.md` — a 653-line personal file loaded every turn. Now it's a 286-line parameterized template at `claude/CLAUDE-THEAGENCY.md`, imported into project CLAUDE.md files via `@claude/CLAUDE-THEAGENCY.md`.

**14 sections, slim for every-turn loading:**

| # | Section | Lines | Detail lives in |
|---|---------|-------|-----------------|
| 1 | Preamble | 4 | README-THEAGENCY.md |
| 2 | Repo Structure | 45 | README (annotated tree with tiers) |
| 3 | Quality Gate Protocol | 25 | `/quality-gate` skill, `claude/docs/QUALITY-GATE.md` |
| 4 | Development Methodology | 40 | `claude/docs/DEVELOPMENT-METHODOLOGY.md` |
| 5 | Worktrees & Master | 22 | Captain agent definition |
| 6 | Session Handoff | 10 | `claude/tools/handoff`, hooks |
| 7 | Discussion Protocol | 10 | `/discuss` skill |
| 8 | Feedback & Bug Reports | 4 | `claude/docs/FEEDBACK-FORMAT.md` |
| 9 | Testing & Quality | 19 | README (philosophy) |
| 10 | Bash Tool Usage | 5 | README (alternatives table, tool ecosystem) |
| 11 | Web Content Retrieval | 8 | README (escalation detail, future tooling) |
| 12 | Git & Remote Discipline | 15 | Hookify rules (mechanical enforcement) |
| 13 | Local Setup / Sandbox | 12 | README (lifecycle, symlink mechanism) |
| 14 | Code Review & PR | 14 | Captain agent, `claude/docs/CODE-REVIEW-LIFECYCLE.md` |

**Parameters:** `{{principal}}`, `{{principal_name}}`, `{{principal_email}}`, `{{principal_github}}`

**Token reduction:** 753 lines loaded per turn → 362 lines (~52% reduction).

### README-THEAGENCY.md (human orientation)

655 lines. Mirrors CLAUDE.md section structure (same order) with human-oriented explanation. Includes:
- Full Claude Code Concepts Primer (incorporated, not referenced — self-contained)
- TheAgency bare repo structure with three-tier file model
- `@import` mechanism explanation
- Placeholder sections for: How Our Principals Work, Agent Startup Protocol, Naming Conventions, Secrets/Provider model, Common Pitfalls

### The `@import` Mechanism

Project CLAUDE.md files import the Agency template:

```markdown
# CLAUDE.md (project root)

## Project Overview
...project-specific content...

@claude/CLAUDE-THEAGENCY.md
```

Claude Code expands `@path/to/file.md` at session launch, recursively up to 5 levels. Two physical files, one logical CLAUDE.md. The project team maintains their CLAUDE.md; the Agency framework maintains CLAUDE-THEAGENCY.md.

---

## Action Items

### 1. Install CLAUDE-THEAGENCY.md as framework file

Copy `proposed-CLAUDE-THEAGENCY.md` from monofolk to `claude/CLAUDE-THEAGENCY.md` in the-agency. Framework tier — always overwritten by `agency-update`.

### 2. Update `agency-init` to install and wire the template

`claude/tools/agency-init` should:
- Copy `claude/CLAUDE-THEAGENCY.md` to the target repo
- Add `@claude/CLAUDE-THEAGENCY.md` to the scaffolded project `CLAUDE.md`
- Copy `claude/README-THEAGENCY.md` and `claude/README-GETTINGSTARTED.md`

### 3. Update `agency-update` tier assignments

Ensure the manifest assigns:
- `claude/CLAUDE-THEAGENCY.md` → framework tier (always overwrite)
- `claude/README-THEAGENCY.md` → framework tier
- `claude/README-GETTINGSTARTED.md` → framework tier

### 4. Update `ref-injector.sh` paths

Paths changed from `refs/` to `claude/docs/`:
- `refs/quality-gate.md` → `claude/docs/QUALITY-GATE.md`
- `refs/feedback-format.md` → `claude/docs/FEEDBACK-FORMAT.md`
- `refs/code-review-lifecycle.md` → `claude/docs/CODE-REVIEW-LIFECYCLE.md`
- `refs/development-methodology.md` → `claude/docs/DEVELOPMENT-METHODOLOGY.md`

The ref-injector hook must be updated to look in `claude/docs/` instead of `refs/`.

### 5. Review all tools for stale path references

The `usr/` → `claude/usr/` migration affects any tool that resolves principal/project paths:
- `claude/tools/handoff` — resolves `usr/{principal}/{project}/handoff.md`
- `claude/tools/plan-capture` — may reference plan file locations
- Session hooks — session-handoff.sh, ref-injector.sh
- Any tool using `_path-resolve`

Audit all tools in `claude/tools/` for hardcoded `usr/` paths.

---

## New Tools / Skills Requested

### 6. Build `/workstream-create` skill

Gap identified during template review. Higher-level than `/worktree-create`:
- Creates project directory at `claude/usr/{principal}/{project}/`
- Scaffolds artifacts (handoff, initial PVR stub)
- Assigns agent
- Calls `/worktree-create` for the git worktree + dev environment

Both `/workstream-create` and `/prototype-create` call `/worktree-create` as the shared foundation. A prototype is a sandboxed workstream with additional infrastructure (build manifest, Docker stack, registry).

### 7. Build boundary command skill verification

At `/iteration-complete`, `/phase-complete`, `/plan-complete`, and `/pr-prep`, verify that all skills listed in the project's tooling table actually exist in `.claude/commands/` or `.claude/skills/`. If any are missing, warn the agent. This mechanically enforces the "if there's no skill for it, that's a bug" contract.

### 8. Build web content retrieval tools

Replace the manual escalation ladder (WebFetch → Playwright snapshot → screenshot → run_code) with tools that:
- Handle the fallback automatically
- Cache results
- Extract structured content
- Integrate with telemetry/observability
- Handle blocked sites (Nitter mirrors, etc.)

### 9. Build `settings-merge` integration

The dispatch design references `claude/tools/settings-merge` for diffing `settings-template.json` against current `.claude/settings.json`. Ensure this is wired into `agency-update` and documented in README-GETTINGSTARTED.md.

---

## Decisions Made (from 1B1 review sessions)

| # | Decision | Transcript |
|---|----------|------------|
| 1 | QGR files are standalone receipts with stage hash naming | Session discussion (no transcript — pre-transcript tooling) |
| 2 | `/git-safe-commit` checks for QGR receipt via stage hash match | Session discussion |
| 3 | File Organization collapsed to pointer in Dev Methodology | `captain/transcripts/20260331-1914-discuss-claudemd-review-findings.md` |
| 4 | Docker tooling → `/preview local` + Docker Compose | Same transcript |
| 5 | Aspirational skills kept in table, "missing = bug" framing | Same transcript |
| 6 | Primer incorporated into README (not referenced externally) | Same transcript |
| 7 | `claude/` single namespace adopted from agency-init dispatch | Dispatch incorporation |
| 8 | `@import` mechanism for two-file CLAUDE.md architecture | Session discussion |
| 9 | Plan mode bias added to Dev Methodology | Session discussion |
| 10 | Worktrees & Master section added | Session discussion |

---

## Review History

- **Section-by-section 1B1 review:** 14 sections, each with present → feedback → revise → confirm cycle
- **Multi-agent design review pass 1:** 28 findings across 3 files, 4 items discussed via /discuss with transcript
- **Revision pass 1:** All findings addressed
- **Multi-agent design review pass 2:** 22 findings, mechanical fixes applied
- **Path restructure:** Adopted claude/ namespace from agency-init dispatch
- **Multi-agent design review pass 3:** 4 findings (path consistency), all fixed
- **Final state:** Clean — no open findings

---

## Tooling to Port from Monofolk

The following monofolk tooling was built or updated during this session and needs to be ported into the-agency's `claude/` namespace:

### Updated commands/skills (monofolk → the-agency)
- `usr/jordan/claude/commands/quality-gate.md` — added Step 10 (QGR receipt file writing)
- `usr/jordan/claude/commands/iteration-complete.md` — updated to pass boundary context
- `usr/jordan/claude/commands/phase-complete.md` — updated to pass boundary context
- `usr/jordan/claude/commands/plan-complete.md` — updated to pass boundary context
- `usr/jordan/claude/commands/pr-prep.md` — **NEW** — QG before PR creation
- `.claude/commands/git-safe-commit.md` — **REWRITTEN** — QG-aware wrapper with stage hash check
- `usr/jordan/claude/commands/discuss.md` — added `Skill` to allowed-tools for `/transcript` invocation

### Updated tools
- `tools/lib/stage-hash.ts` — **NEW** — deterministic staging area hash (already ported to `the-agency/tools/lib/stage-hash.ts`)
- `tools/stage-hash.ts` — **NEW** — CLI wrapper (already ported)
- `tools/__tests__/stage-hash.test.ts` — **NEW** — 9 tests

### Updated agents
- `usr/jordan/claude/agents/project-manager/agent.md` — added "do not touch git directly" clause

### Updated refs (now `claude/docs/`)
- `usr/jordan/claude/refs/quality-gate.md` — added QGR file convention, stage hash, `/pr-prep`

### Port instructions
These need to be adapted to the-agency's conventions:
- TypeScript tools (`stage-hash.ts`) → `claude/tools/stage-hash` (bash wrapper or native port)
- Monofolk-specific paths in skills → parameterized with `{{principal}}`
- Skills in `usr/jordan/claude/commands/` → `claude/tools/` or `.claude/skills/` per agency-init design
- Tests → `tests/tools/` or `claude/src/tests/` per the `--dev` convention

## Notes

- The `proposed-CLAUDE.md` in monofolk is monofolk-specific (Layer 2). It demonstrates how a project CLAUDE.md uses the `@import` mechanism. Other projects will write their own project CLAUDE.md.
- `claude/usr/{principal}/claude/CLAUDE.md` (the 653-line personal file) goes to zero after deployment. Everything it contained is now in CLAUDE-THEAGENCY.md or the project CLAUDE.md.
- README-THEAGENCY.md has placeholder sections (How Our Principals Work, Agent Startup Protocol, Naming Conventions, Secrets, Common Pitfalls) tracked in Revision Guidance.
- README-GETTINGSTARTED.md needs to be created — two flavors: generic (the-agency) and project-specific (e.g., monofolk).
