---
title: "CLAUDE-THEAGENCY.md Bootloader Refactoring — Plan"
slug: claude-theagencymd-bootloader-refactoring-plan
path: docs/plans/20260412-claude-theagencymd-bootloader-refactoring-plan.md
date: 2026-04-12
status: draft
branch: devex
worktree: devex
prototype: devex
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: 21ddb920-4e0b-4042-8a43-2b091499d498
tags: [Infra]
---

# CLAUDE-THEAGENCY.md Bootloader Refactoring — Plan

## Context

`claude/CLAUDE-THEAGENCY.md` is a ~6600-word monolith loaded into every agent's context on every session. Most of its content is protocol detail already enforced by hookify rules (40 rules) and/or available via skills (57 skills). Token cost is ~8K tokens per session, per agent. The mechanisms to replace it already exist — we just haven't used them to slim the monolith.

**Goal:** Slim to ~200-300 word bootloader. Every extracted rule remains reachable via skill invocation (which triggers ref-injector) or hookify enforcement. Nothing lost.

**Deadline:** Before Monday workshop (April 13).

## Phase 1: Create Missing Reference Docs (6 items)

All independent — can parallelize.

### 1A. NEW `claude/docs/AGENT-ADDRESSING.md`
- **Source:** Lines 98-266 of monolith (~1750 words — the biggest extraction)
- **Content:** Principal/agent definitions, name constraints, display_name safety, address hierarchy, resolution rules, dispatch/flag payload locations, cross-repo identity, reserved names, future extensions
- **Injected by:** dispatch, flag, collaborate, agent-identity skills

### 1B. UPDATE `claude/docs/DEVELOPMENT-METHODOLOGY.md`
- **Source:** Lines 293-365 (Valueflow, MAR/MARFI/MAP, three-bucket, plan mode)
- **Current state:** Has old 5-step flow, MISSING MAR/MARFI/MAP and three-bucket disposition
- **Action:** Update to canonical 9-step Valueflow, add MAR/MARFI/MAP table, add three-bucket
- **Already wired:** pre-phase-review, define, design → DEVELOPMENT-METHODOLOGY.md

### 1C. NEW `claude/docs/WORKTREE-DISCIPLINE.md`
- **Source:** Lines 366-419 (~800 words)
- **Content:** Master vs worktree rules, captain role, agent rules, cd-to-main block, naming convention
- **Injected by:** worktree-create, worktree-sync, worktree-list, worktree-delete

### 1D. NEW `claude/docs/PROVENANCE-HEADERS.md`
- **Source:** Lines 596-657 (~950 words — WHW headers + script discipline)
- **Content:** What Problem / How & Why / Written format, scope table, script persistence rules
- **Injected by:** git-commit, ship
- **Also:** Update hookify.whw-header-warn.md pointer from monolith anchor to new doc

### 1E. NEW `claude/docs/REPO-STRUCTURE.md`
- **Source:** Lines 6-97 (~1100 words)
- **Content:** Directory tree, scoped CLAUDE.md table, naming conventions
- **Injected by:** session-resume, workstream-create, sandbox-create

### 1F. NEW `claude/docs/QUALITY-DISCIPLINE.md`
- **Source:** Lines 538-587 (~1100 words minus Triangle/Ladder which is in README-ENFORCEMENT.md)
- **Content:** "Fix it" philosophy, no silent failures, no workarounds, verify don't assume, when something fails rules, web content retrieval escalation ladder
- **Injected by:** quality-gate, iteration-complete, phase-complete (alongside QUALITY-GATE.md)

### NOT creating new ref docs for:
- **Sandbox/Local Setup** — covered by /sandbox-* skills + README-ENFORCEMENT.md
- **Discussion Protocol** — /discuss skill IS the reference
- **Feedback** — FEEDBACK-FORMAT.md already exists
- **Git discipline** — GIT-MERGE-NOT-REBASE.md exists; role table goes into CODE-REVIEW-LIFECYCLE.md

## Phase 2: Wire ref-injector Mappings

**File:** `claude/hooks/ref-injector.sh`

New/updated case entries:

| Skills | Ref docs injected |
|--------|-------------------|
| handoff, session-end | HANDOFF-SPEC.md |
| session-resume | HANDOFF-SPEC.md + REPO-STRUCTURE.md |
| dispatch, dispatch-read, flag, flag-triage, monitor-dispatches | ISCP-PROTOCOL.md + AGENT-ADDRESSING.md |
| collaborate | ISCP-PROTOCOL.md + AGENT-ADDRESSING.md |
| worktree-create, worktree-sync, worktree-list, worktree-delete | WORKTREE-DISCIPLINE.md |
| workstream-create | WORKTREE-DISCIPLINE.md + REPO-STRUCTURE.md |
| sandbox-create, sandbox-activate, sandbox-adopt | REPO-STRUCTURE.md |
| git-commit, ship | (existing) + PROVENANCE-HEADERS.md |
| quality-gate, iteration-complete, phase-complete | (existing) + QUALITY-DISCIPLINE.md |

## Phase 3: Write the Bootloader

**File:** `claude/CLAUDE-THEAGENCY.md` — replace 738 lines with ~50 lines (~250 words)

**Structure:**
1. **What this is** (2 sentences) — framework dev repo, open core MIT + RSL
2. **Where things live** (5 bullets) — claude/, usr/, .claude/skills/, claude/hookify/, claude/docs/
3. **How you work** (5 bullets) — skills via `/`, hookify enforces, ref-injector provides docs on demand, handoff for context, ISCP for comms
4. **Key skills** (10 pointers) — /git-commit, /quality-gate, /handoff, /dispatch, /discuss, /session-resume, /session-end, /worktree-sync, /define, /design
5. **Reference docs table** (15 rows) — topic → doc path mapping
6. **Kittens footer**

## Phase 4: MAR Review + Fix

- Build coverage checklist: every rule from original monolith
- For each: verify reachable via ref doc (injected), skill, or hookify rule
- 3+ review agents scan bootloader + ref docs against original
- Three-bucket triage, fix autonomous items

## Phase 5: QG + PR

- /iteration-complete on full changeset
- Dispatch to captain for boundary review
- /pr-prep, /ship

## Verification

1. Run `bats tests/tools/` — no test regressions
2. Verify ref-injector fires correctly: check that skill invocation outputs include injected docs
3. Word count check: `wc -w claude/CLAUDE-THEAGENCY.md` should be ~250
4. Coverage audit: grep each major keyword from old monolith, verify it appears in a ref doc
5. Hookify pointer check: verify hookify.whw-header-warn.md points to new PROVENANCE-HEADERS.md

## Cross-repo Note

Monitor caught 2 monofolk collaboration dispatches (SPEC-PROVIDER status + "This Happened"). These are captain-only to read. Will flag for captain at first boundary dispatch.
