---
title: "Plan: Monofolk Dispatch Incorporation"
slug: plan-monofolk-dispatch-incorporation
path: docs/plans/20260331-plan-monofolk-dispatch-incorporation.md
date: 2026-03-31
status: draft
branch: main
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: ee9d2ca8-7d2c-47e3-bc99-932128feb706
tags: [Backend, Infra]
---

# Plan: Monofolk Dispatch Incorporation

**Date:** 2026-03-31
**Dispatch:** `dispatch-claudemd-template-finalized-20260331.md` (PR #21)
**Scope:** Port 35 framework skills, update tools, install templates, purge ADHOC, add licensing, update agents

## Context

Monofolk (a project using the-agency) has built out skills, tools, and templates during active development. This work needs to come back into the framework as generic, configurable, pluggable components so that agency-init can ship them to any project. The dispatch includes CLAUDE-THEAGENCY.md (286-line methodology template), README-THEAGENCY.md (655-line human orientation), 35 framework skills, 3 reference skills, 4 tools, and 9 action items.

Pre-init work (Phases 1-4) must complete before agency-init implementation. Post-init work (Phases 5-6) follows.

## Key Decisions

1. **Skills vs Commands:** Convert most monofolk "commands" to Claude Code skills (`.claude/skills/{name}/SKILL.md`). Skills support auto-loading, fork context, and skill-scoped hooks. Keep only truly user-invoked items as commands (`.claude/commands/{name}.md`). Existing commands (`discuss`, `secret`) stay as commands and get updated in place — they are NOT converted to skills.
2. **Stage-hash:** Keep as TypeScript. Both `tools/stage-hash.ts` (CLI) and `tools/lib/stage-hash.ts` (library) stay at project root for now — they need `tsx` and are imported by tests. Skills reference them via `tsx tools/stage-hash.ts`.
3. **ADHOC-WORKLOG:** Kill completely. All files, all references, the tool, the flag. Salt the earth.
4. **Licensing:** Open core model. MIT for the framework. Source-available for apps (mpal, mockandmark, future services). Per-directory LICENSE files.
5. **Genericization:** Rework, rewrite, make configurable/pluggable. Must work for monofolk AND other agency users.
6. **Dispatch tool:** Auto-stamp with datetime. Fix now.
7. **gstack patterns:** Template system, confidence scoring, diff-scope, learnings JSONL, decision classification. These inform skill design but are separate work items — NOT in this plan's scope. Tracked in backlog.
8. **Parameterization mechanism:** Skills resolve paths at RUNTIME via `agency-whoami` (principal detection) and `agency.yaml` (config). NOT install-time templating. Skills use globs like `usr/*/` rather than hardcoded `usr/jordan/`.
9. **Skill `allowed-tools` resolved:** Skills call `claude/tools/*` — that's the whole point of the tools directory. Skills have stable `allowed-tools` referencing framework tools (`Bash(./claude/tools/test-run:*)`, `Bash(./claude/tools/commit-precheck:*)`). Tools read project config from `agency.yaml` and run the right project-specific commands. This is the existing architecture — not a new pattern.
10. **Permission scope resolved:** Skills reference tools, not raw commands. No `Bash(doppler *)` or `Bash(tsx:*)` in skill frontmatter. Secret skill → `Bash(./claude/tools/secret-*:*)`. Stage-hash → `Bash(tsx tools/stage-hash.ts)` (specific file, not wildcard).
11. **Prototype skills (13):** Explicitly OUT OF SCOPE — monofolk-only per MANIFEST. Not ported.
12. **PR strategy:** One PR per phase. Keeps reviews manageable.
13. **Tools already merged:** `handoff` and `plan-capture` are identical in framework and dispatch — no work needed. `_log-helper` is also identical (only comment header differs) — no merge needed.

## Agent Architecture Update

### Classes (role templates in `claude/agents/{class}/`)

| Class | Type | Status | Notes |
|-------|------|--------|-------|
| captain | Standing | EXISTS | Coordination, dispatch, PR lifecycle |
| cos | Standing | EXISTS | Cross-repo coordination |
| tech-lead | Standing/workstream | EXISTS | Product work: define, design, implement |
| marketing-lead | Standing/workstream | EXISTS | GTM strategy, positioning, launch |
| platform-specialist | Standing/platform | EXISTS | Platform operations, integrations |
| project-manager | Subagent | EXISTS | Quality gates, process enforcement |
| researcher | Subagent | EXISTS | Deep research, synthesis |
| reviewer-code | Subagent | EXISTS | Code review |
| reviewer-design | Subagent | EXISTS | Design review |
| reviewer-test | Subagent | EXISTS | Test review |
| reviewer-security | Subagent | EXISTS | Security review |
| reviewer-scorer | Subagent | EXISTS | Confidence scoring, dedup |

### Instances (concrete deployments in `.claude/agents/{name}.md`)

| Instance | Class | Workstream | Status |
|----------|-------|------------|--------|
| captain | captain | housekeeping | Active (jordan) |
| gtm | marketing-lead | gtm | Active (jordan) |
| markdown-pal | tech-lead | markdown-pal | Active (jordan) — Reference Source License |
| mock-and-mark | tech-lead | mock-and-mark | Active (jordan) — Reference Source License |
| apple | platform-specialist | gtm | Active (jordan) |
| discord | platform-specialist | gtm | Active (jordan) |
| gumroad | platform-specialist | gtm | Active (jordan) |

### gstack-Inspired Additions (Phase 5+)

From gstack analysis, consider adding:
- **diff-scope classifier** — categorize changes to skip irrelevant reviewers
- **decision classifier** — Mechanical/Taste/User Challenge for review findings
- **learnings agent** — manages per-project learnings.jsonl

---

## Phase 1: Clean Slate — ADHOC Purge
**Slug:** `adhoc-purge`

### 1.1: Delete ADHOC Files
**Slug:** `adhoc-purge.delete-files`

Delete:
- `claude/agents/captain/ADHOC-WORKLOG.md`
- `claude/agents/gumroad/ADHOC-WORKLOG.md`
- `claude/agents/discord/ADHOC-WORKLOG.md`
- `claude/agents/apple/ADHOC-WORKLOG.md`
- `claude/tools/adhoc-log`
- `test/test-agency-project/claude/agents/housekeeping/ADHOC-WORKLOG.md`
- `test/the-agency-starter/claude/agents/captain/ADHOC-WORKLOG.md`
- `test/the-agency-starter/claude/agents/housekeeping/ADHOC-WORKLOG.md`
- `test/the-agency-starter/claude/agents/hub/ADHOC-WORKLOG.md`
- `test/the-agency-starter/tools/adhoc-log` (starter pack copy)

**Verify:** `find . -path ./.git -prune -o -name "*adhoc*" -print -o -name "*ADHOC*" -print | grep -v node_modules` returns zero.

### 1.2: Purge ADHOC References and Kill --adhoc Flag
**Slug:** `adhoc-purge.purge-refs`

- `claude/tools/git-commit` — remove `--adhoc` flag entirely, replace with `--no-work-item` (explicit escape hatch)
- `.claude/settings.json` — remove `Bash(./claude/tools/adhoc-log*)` permission
- `.agency/manifest.json` — remove adhoc-log entries
- `registry.json` — remove adhoc-log and ADHOC-WORKLOG protected paths
- `claude/agents/captain/KNOWLEDGE.md` — remove ADHOC references
- `claude/agents/templates/generic/ONBOARDING.md` — remove ADHOC mentions
- `claude/agents/apple/ONBOARDING.md`, `discord/ONBOARDING.md`, `gumroad/ONBOARDING.md` — remove
- `claude/docs/CONCEPTS.md`, `PRINCIPAL-GUIDE.md`, `STARTER-PACK-INTEGRATION.md` — remove
- `claude/tools/project-update`, `starter-release`, `agent-create` — remove ADHOC scaffolding
- `claude/integrations/claude-desktop/agency-server/index.ts` — remove adhoc refs
- `claude/docs/tutorials/` — remove from tutorials
- Tests: update `tests/tools/git-operations.bats`:
  - Rename test "commit: requires work item OR --adhoc flag" → "commit: requires work item OR --no-work-item flag"
  - Update assertion from `"--adhoc"` to `"--no-work-item"`
  - Rename test "commit: --adhoc flag accepted as escape hatch" → "commit: --no-work-item flag accepted"
  - Update invocation from `--adhoc` to `--no-work-item`
  - Add test: `"commit: --adhoc flag rejected as unknown"`
- Historical REQUEST files: leave as-is (they're records)
- Book content: leave as-is (historical)

**Verify:** `grep -ri "adhoc" --include="*.md" --include="*.sh" --include="*.ts" --include="*.json" --include="*.bats" . | grep -v node_modules | grep -v .git/ | grep -v principals/jordan/requests/ | grep -v principals/jordan/projects/ | grep -v dispatches/` returns zero.
**Verify:** `jq . .claude/settings.json > /dev/null` (valid JSON after edits)
**Verify:** `bats tests/tools/git-operations.bats` passes

---

## Phase 2: Licensing and Infrastructure
**Slug:** `licensing-infra`

### 2.1: Add Licenses
**Slug:** `licensing-infra.licenses`

Open core model:
- Root `LICENSE` — MIT License, scoped to framework (everything except app workstreams)
- `claude/workstreams/markdown-pal/LICENSE` — Source-available (view, contribute, no commercial redistribution)
- `claude/workstreams/mock-and-mark/LICENSE` — Source-available (same)
- Root README licensing section explaining the split

### 2.2: Project CLAUDE.md and README
**Slug:** `licensing-infra.project-docs`

Write the project-specific Layer 2 files for the-agency itself:

**Root `CLAUDE.md`** — small, agent-facing. Just project specifics:
- What this repo is (the-agency framework itself)
- `@claude/CLAUDE-THEAGENCY.md` import at the bottom

**Root `README.md`** — a paragraph pointing to `claude/README-THEAGENCY.md` for depth.

**`claude/README-GETTINGSTARTED.md`** — short: grab the agency command, run `agency-init`. That's it.

### 2.3: Move Files to Match Template Paths
**Slug:** `licensing-infra.align-paths`

CLAUDE-THEAGENCY.md describes the TARGET state. Move things to match:
- Move `tools/stage-hash.ts` and `tools/lib/stage-hash.ts` → `claude/tools/stage-hash` (or wrapper)
- Move `.agency/manifest.json` → `claude/config/manifest.json`
- Create `claude/config/settings-template.json` (stub for Phase 5.4)
- Fix `project-manager/agent.md` stale `refs/` path → `claude/docs/DEVELOPMENT-METHODOLOGY.md`
- Audit ref-injector.sh — confirm `claude/docs/` paths
- Default workstream: `ops/` in template vs `housekeeping` in repo — resolve

**Verify:** `grep -r "refs/" claude/ .claude/ --include="*.md" --include="*.sh" --include="*.json" --include="*.ts" --include="*.bats" | grep -v "refs/heads\|refs/tags\|refs/remotes\|show-ref"` returns zero stale paths.

### 2.4: Dispatch Tool Datetime Fix
**Slug:** `licensing-infra.dispatch-datetime`

Create or update `claude/tools/dispatch-create` to auto-stamp filenames with `YYYYMMDD-HHMM`.

---

## Phase 3: Skills Port — Commands to Skills Migration
**Slug:** `skills-port`

**Convention:** Skills go to `.claude/skills/{name}/SKILL.md` (each in its own directory). Commands stay at `.claude/commands/{name}.md`. Create `.claude/skills/` directory as first step.

**Classification:**

| Stays as Command (updated in place) | Reason |
|--------------------------------------|--------|
| `discuss` | User-invoked `/discuss`, add `Skill` to allowed-tools |
| `secret` | User-invoked `/secret`, genericize provider dispatch |
| `agency`, `agency-help`, `agency-welcome`, `agency-tutorial` | User-invoked framework UI |
| `agency-bug`, `agency-nit`, `agency-request` | User-invoked quick capture |
| `changelog` | User-invoked |

| New Skills (33 total) | Reason |
|----------------------|--------|
| `quality-gate` | Contextually triggered by boundary skills |
| `iteration-complete`, `phase-complete`, `plan-complete` | Boundary lifecycle |
| `pr-prep` | Pre-PR lifecycle |
| `pre-phase-review` | Triggered before phases |
| `git-commit` | QG-aware wrapper (skill wraps `claude/tools/git-commit` tool) |
| `transcript` | Invoked by discuss via `Skill` tool, not directly by user |
| `define`, `design` | Methodology lifecycle |
| `code-review`, `captain-review`, `review-pr`, `pr-respond` | Review lifecycle |
| `diff-summary` | Review support |
| `ship` | Lifecycle composite |
| `rebase`, `sync`, `sync-all`, `post-merge` | Git lifecycle |
| `sandbox-init`, `sandbox-create`, `sandbox-activate`, `sandbox-adopt`, `sandbox-deactivate`, `sandbox-list`, `sandbox-status`, `sandbox-try` | Sandbox lifecycle |
| `session-list`, `session-read` | Session management |
| `worktree-create`, `worktree-delete`, `worktree-list` | Worktree lifecycle |

**Explicitly OUT OF SCOPE:** 13 prototype-* skills (monofolk-only per MANIFEST): `prototype`, `prototype-archive`, `prototype-create`, `prototype-down`, `prototype-health`, `prototype-help`, `prototype-list`, `prototype-logs`, `prototype-merge`, `prototype-preview`, `prototype-promote`, `prototype-reset`, `prototype-up`.

**Per-iteration gate (run after EVERY Phase 3 sub-iteration):**
```bash
# No monofolk residue in newly created skills
grep -r "usr/jordan\|monofolk\|doppler\|prisma" .claude/skills/ | grep -v "# TODO" && echo "FAIL: monofolk residue" || echo "PASS"
# Valid JSON in settings.json
jq . .claude/settings.json > /dev/null
```

### 3.1: Quality Gate and Boundary Skills (7)
**Slug:** `skills-port.quality-boundary`

Port and parameterize:
- `quality-gate` — Replace `pnpx vitest`, `oxfmt`, `oxlint`, `pnpm` with configurable test/lint commands. Replace `tsx tools/stage-hash.ts` with `claude/tools/stage-hash`. Parameterize QGR receipt paths.
- `iteration-complete` — Parameterize `usr/jordan/` to principal-resolved paths
- `phase-complete` — Same
- `plan-complete` — Same + reference doc finalization
- `pr-prep` — NEW skill, parameterize
- `pre-phase-review` — Port, fix artifact glob patterns
- `git-commit` — QG-aware skill wrapping `claude/tools/git-commit`. Stage hash path fix.

**Critical files:**
- `usr/jordan/captain/dispatches/monofolk-skills/quality-gate.md`
- `usr/jordan/captain/dispatches/monofolk-skills/git-commit.md`

### 3.2: Git and Sync Skills (5)
**Slug:** `skills-port.git-sync`

Port (minimal changes — mostly framework-ready):
- `rebase` — No changes needed
- `sync` — No changes needed
- `sync-all` — Parameterize `.worktrees/` path, captain handoff path
- `post-merge` — Parameterize worktree path
- `ship` — Replace `pnpm lint`/`pnpm format:check` with configurable commands

### 3.3: Code Review Skills (4)
**Slug:** `skills-port.code-review`

- `code-review` — Parameterize `usr/jordan/` paths, CLAUDE.md search patterns, agent model selection
- `captain-review` — Same path parameterization
- `review-pr` — No changes needed
- `pr-respond` — No changes needed
- `diff-summary` — No changes needed

### 3.4: Discussion and Artifact Skills (4)
**Slug:** `skills-port.discussion`

- `discuss` — UPDATE existing `.claude/commands/discuss.md`: add `Skill` to allowed-tools for `/transcript`
- `transcript` — NEW skill. Parameterize `usr/jordan/{project}/transcripts/` and branch-to-project mapping
- `define` — Port. Parameterize PVR location pattern
- `design` — Port. Parameterize A&D location pattern

### 3.5: Sandbox Skills (8)
**Slug:** `skills-port.sandbox`

Port all 8 sandbox skills. Parameterize:
- Principal detection (via `agency-whoami`, not raw `git config user.name`)
- Sandbox root directory pattern (`usr/{principal}/`)
- Symlink naming conventions
- Discovery directory locations

Skills: `sandbox-init`, `sandbox-create`, `sandbox-activate`, `sandbox-adopt`, `sandbox-deactivate`, `sandbox-list`, `sandbox-status`, `sandbox-try`

### 3.6: Session and Worktree Skills (5)
**Slug:** `skills-port.session-worktree`

- `session-list` — Parameterize session storage path
- `session-read` — Same
- `worktree-create` — Remove Doppler/pnpm/Prisma specifics, make bootstrap configurable
- `worktree-delete` — Parameterize worktree dir
- `worktree-list` — Same, remove Doppler refs

### 3.7: Secret Skill Update
**Slug:** `skills-port.secret`

Update existing `.claude/commands/secret.md` to use provider dispatch via `agency.yaml` `secrets.provider` setting instead of hardcoded Doppler.

---

## Phase 4: Tool and Agent Updates
**Slug:** `tool-agent-updates`

### 4.1: Update git-commit Tool
**Slug:** `tool-agent-updates.git-commit`

Phase 1 killed `--adhoc`. Now ensure `--no-work-item` is wired correctly as the replacement escape hatch. Update help text, usage examples, error messages.

**Verify:** `bats tests/tools/git-operations.bats`

### 4.2: Update Project Manager Agent
**Slug:** `tool-agent-updates.pm-agent`

Merge dispatch changes into `claude/agents/project-manager/agent.md`:
- Add "do not touch git directly" clause
- Fix stale `refs/` path
- Remove monofolk-specific quality gate tooling refs

### 4.3: Wire Skills into settings.json and ref-injector
**Slug:** `tool-agent-updates.wire-skills`

Skills in `.claude/skills/` are auto-discovered by Claude Code — they do NOT need registration in settings.json. But:
- Add permissions in `.claude/settings.json` for any new tool invocations skills depend on
- Ensure no naming collisions between new skills and existing commands (e.g., `git-commit` skill vs `git-commit` tool — different namespaces, no collision)
- Validate settings.json remains valid JSON: `jq . .claude/settings.json > /dev/null`

Update `claude/hooks/ref-injector.sh` with new skill-to-reference mappings. Use EXACT match (not substring) for security:

| Skill trigger | Reference document |
|---------------|-------------------|
| `quality-gate`, `iteration-complete`, `phase-complete`, `plan-complete`, `pr-prep` | `claude/docs/QUALITY-GATE.md` |
| `pre-phase-review`, `define`, `design` | `claude/docs/DEVELOPMENT-METHODOLOGY.md` |
| `code-review`, `captain-review`, `review-pr`, `pr-respond`, `diff-summary` | `claude/docs/CODE-REVIEW-LIFECYCLE.md` |
| `ship`, `git-commit` | `claude/docs/QUALITY-GATE.md` + `claude/docs/CODE-REVIEW-LIFECYCLE.md` |
| `secret` | (no ref injection needed — self-contained) |

**Security note:** Replace substring matching (`*quality-gate*`) with exact matching in the `case` statement to prevent injection via malicious skill names.

---

## Phase 5: Post-Init Enhancements
**Slug:** `post-init-enhance`

### 5.1: Make Reference Skills Pluggable (preview, deploy, crawl-sites)
**Slug:** `post-init-enhance.pluggable-ref-skills`

Create provider-dispatch pattern for:
- `preview` — configurable infrastructure backend (Docker Compose, Fly.io, Vercel)
- `deploy` — configurable platform (Fly.io, AWS, Vercel)
- `crawl-sites` — configurable crawler engine and extraction rules

Config via `agency.yaml`:
```yaml
preview:
  provider: "docker-compose"
deploy:
  provider: "fly"
```

### 5.2: Build /workstream-create Skill
**Slug:** `post-init-enhance.workstream-create`

Higher-level than worktree-create:
- Creates project directory at `claude/workstreams/{name}/`
- Scaffolds artifacts (KNOWLEDGE.md, initial PVR stub, handoff)
- Assigns agent
- Calls worktree-create for the git worktree

### 5.3: Build Boundary Skill Verification
**Slug:** `post-init-enhance.boundary-verify`

At boundary commands, verify all skills in the project's tooling table exist. "If there's no skill for it, that's a bug."

### 5.4: Settings-Merge Tool
**Slug:** `post-init-enhance.settings-merge`

Build `claude/tools/settings-merge`:
- Read `claude/config/settings-template.json`
- Merge into `.claude/settings.json`
- Array union for permissions.allow (don't replace)

### 5.5: Web Content Retrieval Tools
**Slug:** `post-init-enhance.web-tools`

Replace manual escalation ladder with automated fallback tools.

~~5.6 moved to Phase 2.2~~

---

## Phase 6: Cleanup and Verification
**Slug:** `cleanup-verify`

### 6.1: Update agency-init to Install Skills
**Slug:** `cleanup-verify.agency-init-skills`

Update `claude/tools/agency-init` to:
- Create `.claude/skills/` in target
- Copy all framework skills
- Copy CLAUDE-THEAGENCY.md and README-THEAGENCY.md
- Wire `@claude/CLAUDE-THEAGENCY.md` into project CLAUDE.md

### 6.2: Update agency-update
**Slug:** `cleanup-verify.agency-update`

Ensure `claude/tools/agency-update` handles skills and templates in tier assignments.

### 6.3: Starter Pack and Test Fixture Integration
**Slug:** `cleanup-verify.starter-pack`

Update BOTH test fixture directories:
- `test/the-agency-starter/` — include skills, remove ADHOC remnants
- `test/test-agency-project/` — remove ADHOC remnants

### 6.4: Skill Validation Tests
**Slug:** `cleanup-verify.skill-tests`

Create `tests/skills/skill-validation.bats` — static tier testing for all 33 skills:
- Every `.claude/skills/{name}/SKILL.md` exists and is non-empty
- No SKILL.md contains `usr/jordan/`, `monofolk`, hardcoded `pnpm`, hardcoded `doppler`, hardcoded `prisma`
- No SKILL.md references non-existent tools (check `Bash(./claude/tools/{name}*)` patterns against actual files)
- Skill count matches expected (33 framework skills)
- Also validate stage-hash TypeScript tests: `npx vitest run tools/lib/stage-hash.test.ts` (if vitest available)

### 6.5: Final Verification
**Slug:** `cleanup-verify.final`

Full sweep:
- Zero `adhoc`/`ADHOC` hits in framework files
- Zero stale `refs/` paths (excluding git refs)
- Zero `usr/jordan` in framework skills/tools (only in `usr/jordan/` itself and historical files)
- Zero `monofolk`/hardcoded `pnpm`/`doppler`/`prisma` in framework skills
- All BATS tests pass: `bats tests/tools/` and `bats tests/skills/`
- All skills have valid SKILL.md with correct frontmatter
- License files present (MIT at root, RSL in mpal/mockandmark)
- `bash -n` passes on all shell tools
- `jq . .claude/settings.json > /dev/null` (valid JSON)
- `jq . .agency/manifest.json > /dev/null` (valid JSON)
- `jq . registry.json > /dev/null` (valid JSON)

---

## Dependency Graph

```
Phase 1 (adhoc-purge) ─────────────────────┐
                                            │
Phase 2 (licensing-infra) ──────────────────┤
                                            │
Phase 3 (skills-port) ─────────────────────┤ PRE-INIT
  3.1 quality-boundary                      │
  3.2 git-sync                              │
  3.3 code-review                           │
  3.4 discussion                            │
  3.5 sandbox                               │
  3.6 session-worktree                      │
  3.7 secret                                │
                                            │
Phase 4 (tool-agent-updates) ──────────────┘

Phase 5 (post-init-enhance) ───────────────┐ POST-INIT
                                            │
Phase 6 (cleanup-verify) ─────────────────┘
  6.1 agency-init skills
  6.2 agency-update
  6.3 starter-pack + test fixtures
  6.4 skill validation tests
  6.5 final verification
```

Phases 1-4: sequential (each depends on prior). Within Phase 3: 3.1 first (quality-gate, referenced by others), then 3.2-3.7 in any order. Phase 2.5 (dispatch tool) is independent and can run in parallel with 2.1-2.4.

## Risk Areas

1. **Skill format transition** — `.claude/skills/{name}/SKILL.md` requires a directory per skill (35 new directories). Different from monofolk's flat `.md` files.
2. **Quality-gate tool permissions** — RESOLVED. Skills call framework tools, tools read config.
3. **Ref-injector security** — substring matching enables injection. Fix: exact match in Phase 4.3.
4. **Settings.json validity** — at 230 lines, size is not a concern. But edits can corrupt JSON. Mitigated: `jq` validation after every edit.
5. **Genericization residue** — monofolk paths leaking into ported skills. Mitigated: per-iteration grep gate.
6. **Stage-hash TOCTOU** — staging area can change between QGR and commit. Low-probability, noted for later hardening.

## Critical Files

- `claude/tools/git-commit` — adhoc removal, --no-work-item addition
- `claude/tools/agency-init` — skill installation
- `claude/hooks/ref-injector.sh` — skill reference injection
- `.claude/settings.json` — permissions, hooks, skill registration
- `claude/agents/project-manager/agent.md` — "no git" clause
- `claude/CLAUDE-THEAGENCY.md` — verify against dispatch
- `claude/README-THEAGENCY.md` — verify against dispatch
- All 35 skill source files in `usr/jordan/captain/dispatches/monofolk-skills/`
