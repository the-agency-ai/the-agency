---
title: "Plan — Issue #111 coordination (not R19 execution)"
slug: plan-issue-111-coordination-not-r19-execution
path: docs/plans/20260415-plan-issue-111-coordination-not-r19-execution.md
date: 2026-04-15
status: draft
branch: jordandm-d41-r19
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: 996153b6-ab38-4aca-aebd-728d2af55af5
tags: [Infra]
---

# Plan — Issue #111 coordination (not R19 execution)

## Context

Issue #111 (principal-scoped agent resolution broken — framework hardcodes `usr/jordan/`) was filed by monofolk/jordan/captain. Principal directed me to fix it as D41-R19. I entered plan mode.

While in plan mode, monofolk/captain sent cross-repo dispatch `dispatch-patch-incoming-issue-111-principal-scope-20260415.md` announcing **they are submitting the PR upstream themselves**. Monofolk is the canary (Peter Gao = $USER `pyg` = principal `peter` surfaced the bug), they have the best context, and they're contributing the fix via cross-repo PR.

**My role shifts from implementer to reviewer + coordinator.** I should not start a parallel R19. I should:
- Reply to their dispatch with my Phase-1 scope findings (they may have missed items)
- Ask clarifying questions about their patch scope
- Update issue #111 with the collaboration note
- Stand by to review their PR when it lands

## Phase-1 exploration findings

From Explore agent survey of `/Users/jdm/code/the-agency`:

**Framework-tool hardcodes (real bugs):**
- `claude/tools/lib/_health-agent:82-98` — `local principal_dir="$PROJECT_ROOT/usr/jordan"` + 2 more uses in candidate loop
- `claude/tools/commit-precheck:491` — `ls usr/jordan/*/qgr-*-"$current_hash"-*.md` (NOT mentioned in monofolk's dispatch)

**Framework-tool false positives (not bugs):**
- `agency/tools/safe-extract:37` — example text
- `agency/tools/iscp-migrate:5,372` — migration-legacy
- `agency/tools/tests/test-worktree-sync.sh:282-283` — test fixture

**Doc references (all illustrative placeholders, no action):**
- `claude/docs/REFERENCE-HANDOFF-SPEC.md:12`, `README-THEAGENCY.md:563,611-612`, `iscp-plan-20260404.md:165`

**Agent registrations (`.claude/agents/*.md`) — all 9 hardcode `usr/jordan/`:**
- captain.md, devex.md, iscp.md, mdpal-app.md, mdpal-cli.md, mdslidepal-web.md, mdslidepal-mac.md, designex.md, mock-and-mark.md

Key discovery (Explore agent): **these ARE framework artifacts** — `claude/tools/lib/_agency-init:215-227` symlinks `.claude/agents/` from framework into adopter repos. `principal-onboard` generates per-principal-prefixed versions. Monofolk's dispatch references `claude/templates/agents/{captain,of-mobile,healthos}.md` — **we don't have that directory** — ambiguity to clarify.

**Existing helpers to reuse:**
- `agency/tools/lib/_path-resolve` exports `AGENCY_PRINCIPAL`, `AGENCY_PRINCIPAL_DIR`, `AGENCY_REFS_DIR`, `AGENCY_PROJECT_ROOT`
- Multi-principal iteration pattern already used in: `handoff:118`, `instruction-show:90` — `for dir in "$PROJECT_ROOT"/usr/*/; do ... principal=$(basename "$dir")`

**Tests:**
- No existing multi-principal BATS tests. Fixtures pattern: `tests/tools/commit-precheck.bats:19`, `tests/tools/path-resolve.bats`. Multi-principal fixture setup pattern in `tests/tools/agency-update.bats`.

## Plan of action

### Step 1 — Reply to monofolk/captain via cross-repo dispatch

Subject: `Re: Patch incoming #111 — scope questions + findings`

Content:
- Share Phase-1 findings: the 9 `.claude/agents/*.md` files (not 3 templates), `commit-precheck:491` hardcode
- Ask questions Q1–Q5 (below)
- Commit to reviewing their PR on arrival

### Step 2 — Update issue #111

Add a comment noting:
- Cross-repo PR incoming from monofolk/captain
- Link to my expanded scope findings (already comment #4250255634)
- R19 execution transferred to monofolk

### Step 3 — Stand by

Wait for the PR. When it lands:
- Review via `/captain-review` if available, or direct GitHub review
- Verify scope matches Phase-1 findings (or scope intentionally reduced by monofolk)
- Merge via `/pr-merge` (never squash)
- `/post-merge` to cut release + sync

### Step 4 — Fast-follow R19 (only if monofolk PR doesn't cover)

If monofolk's PR is scoped narrower (e.g., only the 3 files they mentioned, not the full 9 + commit-precheck), queue a follow-up release to close the gap. Ship as D41-R19.

## Questions for monofolk/captain (to send via dispatch)

**Q1 (scope):** Dispatch mentions `claude/templates/agents/{captain,of-mobile,healthos}.md`. We don't have `claude/templates/agents/` in the framework — the hardcodes are in `.claude/agents/*.md` (9 files, not 3: captain, devex, iscp, mdpal-app, mdpal-cli, mdslidepal-web, mdslidepal-mac, designex, mock-and-mark). Can you confirm the target path + whether your PR covers all 9?

**Q2 (commit-precheck):** Line 491 of `claude/tools/commit-precheck` does `ls usr/jordan/*/qgr-*-"$current_hash"-*.md` — also a principal hardcode in receipt lookup. In scope for your PR, or should the-agency handle as fast-follow?

**Q3 (`./agency/tools/principal`):** Your dispatch says "runtime tool call to `./agency/tools/principal`". That tool doesn't exist in framework HEAD — did you mean `principal-onboard`, or is this a new tool your PR will add?

**Q4 (options mapping):** The issue proposed A=SessionStart-stamping, B=user-level-overrides, C=prefixed-names, D=petition-Anthropic. Your dispatch says "Options A + B hybrid — no SessionStart hook needed, just runtime tool calls". Your A/B appear to be different — confirm your A=dynamic-import-via-tool and B=tool-based-resolution and there's no drift between our vocabularies.

**Q5 (parallel work):** Want me to hold entirely, or is there a fast-follow slice (e.g., commit-precheck fix, BATS tests) you'd prefer I carry on the-agency side while your PR is in flight?

## What this plan does NOT do

- Does not write any framework code (monofolk is shipping it)
- Does not open a D41-R19 PR
- Does not touch `.claude/agents/*.md` files
- Does not modify `_health-agent` or `commit-precheck`

## Verification

- Cross-repo dispatch sent via `./agency/tools/collaboration send monofolk ...`
- #111 comment posted via `gh issue comment 111 ...`
- Monofolk's PR reviewed on arrival against Phase-1 findings
- Collab dispatch resolved after PR merges
