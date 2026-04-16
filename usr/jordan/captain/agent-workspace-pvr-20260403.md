# PVR: Agent Workspace & Bootstrap Quality

**Date:** 2026-04-03
**Principal:** jordan
**Agent:** the-agency/jordan/captain
**Status:** In Progress (MAR complete, discussion resolved)
**Origin:** Flag queue triage (9 items from mdpal bootstrap testing)

## Problem Statement

Agent bootstrap is unreliable. Testing with mdpal-cli and mdpal-app exposed multiple gaps: agents don't self-orient on startup, permission prompts block basic file reads, worktree agents can't pull updates from main, multi-agent worktrees have no handoff convention, and scripts get rewritten dozens of times per session because there's no persistent workspace.

These are not individual bugs — they're a missing layer. The framework ships tools and skills but doesn't ship a reliable agent workspace.

## Discussion Decisions (2026-04-03)

### DD1: Agent Identity Drives All Disambiguation

Agent knows its identity (from `--agent` flag and registration) → derives workstream assignment → knows where to find things. Naming convention (`{agent}-handoff.md`, `{agent}-dispatch-*.md`) enforced by tools, not agent discipline.

Within a workstream directory, agents read everything for context — their own items AND peers' items (unless they're the sender). We don't hide information or context.

Same pattern scales: intra-workstream (mdpal-cli ↔ mdpal-app), inter-workstream (mdpal ↔ captain), inter-agency (the-agency ↔ monofolk) via `_address-parse`.

**Implication for R5:** The session-handoff hook does NOT need `$CLAUDE_AGENT`. Agent registrations direct the read. Hook stays branch-scoped for captain path resolution. Per-agent handoff discovery is the agent's responsibility, enforced by tools.

### DD2: workstream-create and agent-create Are Guided Captain Skills

Not just scaffolding — interactive, `/discuss`-style processes where the captain guides the principal through the substance: what is this workstream, what agents does it need, what are the seeds, what's the first action.

The skill scaffolds structure + template handoff with TODOs. The captain fills in the substance through guided discussion with the principal. Keeps the skill deterministic while ensuring bootstrap content is actually useful.

Same pattern for agent-create: scaffold registration, tools/, tmp/, then guide through what the agent owns, who its peers are, bootstrap handoff content.

### DD3: merge-main Merges Freely, Defense in Depth Protects

merge-main is NOT gated. The protection model is defense in depth:
- QG+MAR before landing on main (`/phase-complete`)
- QG+MAR before PR (`/pr-prep`)
- MAR escalates to principal when findings warrant — principal is in the loop by exception, not by default

merge-main tool logs what changed in `claude/`/`.claude/` for observability. No blocking gate, no blanket principal acknowledgment.

*Skip the QG+MAR and today is a good day to be eaten by the kittens!*

## MAR Findings (2026-04-03)

### Incorporated

| ID | Finding | Resolution |
|----|---------|------------|
| S1 | Handoff files are prompt injection vectors | Handoffs are context, not commands. Tools enforce naming convention. MAR on main protects quality. |
| S2 | merge-main can import poisoned CLAUDE.md | Resolved by DD3: MAR gates main, merge is free, observability via logging |
| D1 | `$CLAUDE_AGENT` doesn't exist in hook env | Resolved by DD1: agent registration directs reads, hook stays branch-scoped |
| D2 | workstream-create scope too wide | Resolved by DD2: skill scaffolds structure, captain guides substance |
| D3 | Script discipline can't be enforced pre-execution | Detect positive (persisted runs in telemetry) not negative (inline scripts). Session-end warning if no scripts persisted but heredocs detected. |
| S3 | `unzip:*` wildcard allows zip slip | Scope to `Bash(unzip -d usr/*)` — restrict to sandbox subtree |
| S4 | Persisted scripts have no integrity check | Log hash at write time in header comment, warn on mismatch at reuse |
| D4 | merge-main may not need a new tool | Check if `Bash(git merge main)` already pre-approved. May only need skill wrapper + post-merge handoff step. |

### Test Coverage Required (from T-findings)

| ID | Test | Req |
|----|------|-----|
| T1 | BATS tests for tools/tmp scaffolding in agency-init, agent-create, workstream-create | R1 |
| T2 | `session-handoff.bats` for branch→captain resolution, type-aware injection | R5 |
| T3 | Integration test: init → scaffold → SessionStart → handoff injection | R1,R4,R5 |
| T4 | merge-main tool test stub (exists, --dry-run, exits 0) | R6 |
| T5 | settings-merge assertions for Read/Glob/unzip permissions | R7 |

## Requirements

### R1: Agent Workspace Scaffolding

Every agent gets `tools/` and `tmp/` in their sandbox (`usr/{principal}/{project}/`). `tmp/` is gitignored scratch space. `tools/` is committed, reusable scripts.

**Must scaffold in:** `agency init`, `agent-create`, `workstream-create`.

**Status:** Done in `agency-init`. Not yet in `agent-create` or `workstream-create`.

### R2: Script Discipline Enforcement

When agents write inline bash scripts, they must:
1. Add a header comment: `# Why did I write this script: ...` + `# Written: YYYY-MM-DD during <context>`
2. Save to `usr/{principal}/{project}/tools/`
3. Run from there — never rewrite the same script twice

**Enforcement (per D3/S4):** Detect positive behavior via telemetry (runs from `tools/`). Session-end warning if heredocs detected but no scripts persisted. Hash in header comment for integrity check on reuse.

**Status:** Documented in CLAUDE-THEAGENCY.md. Mechanical enforcement designed but not yet implemented.

### R3: Ad-Hoc Tool Telemetry

Instrument the Bash hook or `_log-helper` to detect and log runs from `usr/{principal}/{project}/tools/`. Mining these reveals patterns — scripts written repeatedly across sessions are candidates for promotion to `claude/tools/`.

**Status:** Not started. Depends on R2 adoption.

### R4: workstream-create Skill (DD2)

A **guided captain skill** that creates a full workstream through interactive discussion with the principal:
1. Scaffold structure: worktree, project directory (tools/, tmp/, seeds/, code-reviews/, dispatches/, transcripts/, history/)
2. Write template bootstrap handoff with TODOs
3. Guide principal through substance: what is this workstream, what agents, what seeds, what's the first action
4. Captain writes the artifacts based on the discussion
5. For multi-agent workstreams: scaffold per-agent handoff files via naming convention

**Status:** Skill file exists but is a stub. Design resolved (DD2).

### R5: Multi-Agent Disambiguation via Agent Identity (DD1)

Agent identity (from `--agent` flag and registration) drives all disambiguation:
- Tools enforce naming convention: `{agent}-handoff.md`, dispatches with `to:` field
- Agents read everything in their workstream directory for context
- Agent registrations direct specific reads on startup
- Session-handoff hook stays branch-scoped (resolves project directory, not agent identity)

**Status:** Implemented manually for mdpal. Tools need enforcement updates.

### R6: Worktree Merge-Main Tool (DD3)

Tool that does `git merge main` in a worktree. Merges freely — no blocking gate. Logs what changed in `claude/`/`.claude/` for observability. Defense in depth: QG+MAR protects main before changes land.

**Per D4:** Check if `Bash(git merge main)` is already pre-approved. May only need a skill wrapper + post-merge logging.

**Status:** Not started.

### R7: Permission Completeness

Agents must not be prompted for standard operations:
- Reading files in `usr/`, `claude/`, `.claude/` (fixed this session)
- Unzipping archives — scoped to `Bash(unzip -d usr/*)` per S3 (no zip slip)
- Running framework tools

**Status:** Read/Glob permissions added. Unzip not yet added.

### R8: / Command Audit

Review all slash commands for relevance. Do we need all of them? Do they still make sense given the skills migration?

**Status:** Not started. P3.

### R9: Bootstrap Transcript Review

Review mdpal-cli and mdpal-app bootstrap transcripts. Extract patterns for improving agent registration, handoff format, and session-handoff hook behavior.

**Status:** Transcripts exist. Not yet reviewed. P3.

## Priority

| Req | Impact | Effort | Priority |
|-----|--------|--------|----------|
| R1 | High (every agent) | Low (pattern exists) | P1 |
| R2 | High (token waste) | Medium (hookify + telemetry) | P1 |
| R4 | High (bootstrap quality) | Medium (guided skill) | P1 |
| R5 | High (multi-agent) | Medium (tool enforcement) | P1 |
| R6 | High (worktree workflow) | Low | P1 |
| R7 | Medium (friction) | Low (settings edits) | P2 |
| R3 | Medium (observability) | Medium | P2 |
| R8 | Low (housekeeping) | Low | P3 |
| R9 | Medium (learning) | Low | P3 |

## Success Criteria

1. `agency init` on a fresh repo → `claude` → agent reads bootstrap handoff and acts without prompting
2. `/workstream-create` guides principal through substance, scaffolds complete workspace with useful bootstrap handoff
3. Multi-agent worktrees: each agent finds and reads their own handoff on startup via naming convention
4. Zero permission prompts for reading framework/sandbox files or unzipping archives
5. Agents persist scripts to tools/ and never rewrite the same script twice in a session
6. merge-main merges freely with observability logging; QG+MAR gates main, not the merge
