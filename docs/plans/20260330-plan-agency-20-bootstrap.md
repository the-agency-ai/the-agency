---
title: "Plan: Agency 2.0 Bootstrap"
slug: plan-agency-20-bootstrap
path: docs/plans/20260330-plan-agency-20-bootstrap.md
date: 2026-03-30
status: draft
branch: main
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: ee9d2ca8-7d2c-47e3-bc99-932128feb706
tags: [Backend, Infra]
---

# Plan: Agency 2.0 Bootstrap

**Branch:** `feat/agency2-bootstrap`
**Dispatch:** `dispatch-agency2-bootstrap-20260330.md`

## Context

Agency 2.0 introduced a class/instance model for agents. Classes (`claude/agents/{class}/agent.md`) define roles. Instances (`.claude/agents/{name}.md`) are registrations that point to a class + workstream. Currently:

- 7 dead agents clutter `claude/agents/`
- 3 class definitions are missing (marketing-lead, platform-specialist, researcher)
- 3 live agents have project-specific `agent.md` files in class-only space
- Test artifacts from previous test runs need cleanup

## Phase 1: Kill Dead Agents

Delete these directories from `claude/agents/`:

| Directory | What it is | Safe to delete? |
|-----------|-----------|-----------------|
| `foundation-alpha/` | Completed REQUEST-0053 worker (17 files) | Yes — work is done |
| `foundation-beta/` | Completed REQUEST-0053 worker (22 files) | Yes — work is done |
| `collaboration/` | Legacy collaboration inbox (50 dispatch files, no agent.md) | Yes — v1 artifact |
| `unknown/` | Orphaned session backups (165 files) | Yes — no agent |
| `hub/` | Dead meta-agent (4 files) | Yes — replaced by captain |
| `mission-control/` | GTM coordinator (7 files) | Yes — gtm agent replaces it |
| `research/` | v1-era research agent (19 files) | Yes — replaced by new researcher class |

Also clean up test artifacts:
- `claude/agents/test$agent/` directory
- `claude/agents/testname/` directory
- `.claude/agents/test$agent.md` registration
- `.claude/agents/testname.md` registration

**Total: ~284 files removed across 9 directories + 2 registration files.**

## Phase 2: Build 3 Agent Class Definitions

Follow the `tech-lead/agent.md` pattern: identity, class description, responsibilities, startup protocol, artifact lifecycle, handoff discipline, key directories.

### `claude/agents/marketing-lead/agent.md`

- Identity: marketing-lead — the GTM strategist
- Class mechanism: instances per-principal per-workstream
- Responsibilities:
  1. GTM Strategy (positioning, messaging, target audience)
  2. Launch Planning (timeline, channels, success metrics)
  3. Distribution (storefront, community, app stores)
  4. Measurement (analytics, conversion, engagement)
- Startup protocol: read handoff, check dispatches/guides, enter worktree, read KNOWLEDGE.md + seeds
- Handoff discipline: same as tech-lead

### `claude/agents/platform-specialist/agent.md`

- Identity: platform-specialist — the platform integrator
- Class mechanism: instances per-principal per-platform
- Responsibilities:
  1. Platform Operations (API integration, webhook handling, monitoring)
  2. Service Management (product listings, accounts, credentials)
  3. Automation (scheduled tasks, event-driven workflows)
  4. Reporting (metrics, health checks, status dashboards)
- Startup protocol: same pattern
- Note: gumroad, discord, apple agents are future platform-specialist instances

### `claude/agents/researcher/agent.md`

- Identity: researcher — the deep research specialist
- Class mechanism: subagent (spun up for specific research tasks, not standing)
- Responsibilities:
  1. Technical Research (docs, APIs, frameworks, tools)
  2. Synthesis (multi-source analysis, comparison, recommendation)
  3. Knowledge Production (KNOWLEDGE.md-style documents, cited)
  4. Evaluation (technology comparison, trade-off analysis)
- Tools: WebFetch, WebSearch, Browser MCP (when configured)
- Model: Sonnet (speed) or Opus (complex research)
- Key difference from other classes: no worktree, no plan, no handoff — produces knowledge documents and exits

## Phase 3: Re-Point Live Agents

### markdown-pal and mock-and-mark

Both registrations already point to `tech-lead/agent.md` — **this is correct**. They ARE tech-lead instances. However, both have project-specific `claude/agents/{name}/agent.md` files that belong in workstream knowledge, not in class space.

**Action:**
1. Compare `claude/agents/markdown-pal/agent.md` with `claude/workstreams/markdown-pal/KNOWLEDGE.md` — merge any unique content into KNOWLEDGE.md
2. Same for mock-and-mark
3. Delete `claude/agents/markdown-pal/` directory (class space is for classes only)
4. Delete `claude/agents/mock-and-mark/` directory

### gtm

Registration points to `claude/agents/gtm/agent.md` (project-specific, not a class). Should point to `marketing-lead`.

**Action:**
1. Update `.claude/agents/gtm.md` to read from `claude/agents/marketing-lead/agent.md`
2. Merge unique content from `claude/agents/gtm/agent.md` into `claude/workstreams/gtm/KNOWLEDGE.md`
3. Delete `claude/agents/gtm/` directory

### Service agents (gumroad, discord, apple)

These exist as `claude/agents/{name}/agent.md` but have NO registrations in `.claude/agents/`. They're not launchable. Leave as-is for now — they'll become platform-specialist instances when activated. Not in scope for this dispatch.

## Phase 4: Update CLAUDE.md Agent Table

Update the agent class table in CLAUDE.md to mark marketing-lead, platform-specialist, and researcher as defined (remove "definition pending" notes).

## Verification

1. `ls claude/agents/` — should only contain: captain, cos, project-manager, tech-lead, marketing-lead, platform-specialist, researcher, reviewer-code, reviewer-design, reviewer-security, reviewer-test, reviewer-scorer, templates, gumroad, discord, apple, housekeeping
2. `ls .claude/agents/` — should contain: gtm.md, markdown-pal.md, mock-and-mark.md, tech-lead.md (no test artifacts)
3. `cat .claude/agents/gtm.md` — should reference marketing-lead class
4. `cat .claude/agents/markdown-pal.md` — should reference tech-lead class (unchanged)
5. No broken references — grep for deleted agent names in CLAUDE.md, settings.json, registrations
6. `./tools/agency-verify` — still passes

## Phase 5: Artifact Capture

Save this plan to `docs/plans/20260330-plan-agency2-bootstrap.md` (follows the pattern from dispatch 1: `docs/plans/20260330-plan-plugin-provider-framework.md`).

## Key Files

- `claude/agents/tech-lead/agent.md` (103 lines) — pattern to follow for new classes
- `claude/agents/research/agent.md` (143 lines) — content to incorporate into researcher class
- `.claude/agents/gtm.md` (9 lines) — needs re-pointing
- `.claude/agents/markdown-pal.md` (9 lines) — verify correct
- `.claude/agents/mock-and-mark.md` (9 lines) — verify correct
- `claude/workstreams/*/KNOWLEDGE.md` — targets for content merge
