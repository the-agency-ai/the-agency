---
title: "Plan: ISCP Rollout — Live Across All Agents + Cross-Repo"
slug: plan-iscp-rollout-live-across-all-agents-cross-repo
path: docs/plans/20260405-plan-iscp-rollout-live-across-all-agents-cross-repo.md
date: 2026-04-05
status: draft
branch: main
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: ee9d2ca8-7d2c-47e3-bc99-932128feb706
tags: [Infra]
---

# Plan: ISCP Rollout — Live Across All Agents + Cross-Repo

**Date:** 2026-04-05
**Context:** ISCP v1 is live in the-agency (DB at ~/.agency/the-agency/iscp.db, 142 tests green, iscp-check hook fires on SessionStart/UserPromptSubmit/Stop). But agents aren't using it yet — registrations don't mention ISCP, captain has no registration file, worktree payload friction exists, and monofolk has no ISCP tools. This plan makes ISCP the active communication backbone.

**Outcome:** Every agent in the-agency starts using ISCP on restart. Cross-repo dispatch channel to monofolk is operational. Monofolk has a PR to adopt ISCP.

---

## Phase 1: Agent Infrastructure (captain + all registrations)

### 1.1: Create captain agent registration

**Create:** `.claude/agents/captain.md`

```yaml
---
name: captain
description: "Captain — coordination, dispatch routing, quality gates, PR lifecycle"
model: opus
---
```

Startup sequence:
1. Read `usr/jordan/captain/handoff.md`
2. Check ISCP: `dispatch list` and `flag list` — process unread items first
3. Read `claude/agents/captain/agent.md` (if exists) for role
4. Enter coordination mode — sync worktrees, route dispatches, manage PRs

### 1.2: Update all agent registrations with ISCP startup step

Add step 2 to each agent's startup: **"Check ISCP: `dispatch list` and `flag list` — process any unread items before other work"**

**Files:**
- `.claude/agents/iscp.md` — strengthen existing step 4, add flag list
- `.claude/agents/mdpal-cli.md` — insert as step 2
- `.claude/agents/mdpal-app.md` — insert as step 2
- `.claude/agents/mock-and-mark.md` — add full startup sequence (currently minimal)

**Verify:** All 5 registrations have explicit ISCP step.

---

## Phase 2: Dispatch to ISCP — Build fetch/send/reply

**Goal:** Eliminate worktree/branch friction. Send directive dispatch to ISCP agent.

**Dispatch:** `dispatch create --to the-agency/jordan/iscp --type directive --priority high --subject "Build dispatch fetch, send, and reply subcommands"`

**Payload directives:**

1. **`dispatch fetch <id>`** — Read-only peek at payload without marking as read. Same logic as `cmd_read` but skips the `UPDATE status='read'` step. Agents can inspect before committing to process.

2. **`dispatch reply <id> "message"`** — Lightweight DB-only response. Creates new dispatch row with `in_reply_to` set, stores message in a new `payload_content TEXT` column. No git file needed for quick acknowledgments.

3. **Schema v2 migration** — `ALTER TABLE dispatches ADD COLUMN payload_content TEXT;` Bump `ISCP_SCHEMA_VERSION` to 2. When `payload_content` is non-null, `dispatch read`/`fetch` use it instead of reading the git file. File-based payloads remain for large dispatches.

4. **`dispatch send` improvement** — Document that `dispatch create` from worktrees already works (writes to main checkout via `_main_checkout()`), but the file is uncommitted. For small messages, use `payload_content` in DB instead. For large payloads, captain must commit the file after it lands on main checkout.

**ISCP agent files to modify:**
- `claude/tools/dispatch` — add `cmd_fetch`, `cmd_reply`, update `cmd_read` to check `payload_content`
- `claude/tools/lib/_iscp-db` — bump schema, add migration function
- `claude/tools/iscp-migrate` — add v1→v2 migration
- New BATS tests for fetch/reply

**Acceptance:** ISCP sends reply dispatch to captain confirming done. All tests green.

---

## Phase 3: Dispatch ISCP-is-live to all agents

**Goal:** When agents restart, they get a dispatch telling them ISCP is live.

**Four dispatches from captain:**
```bash
dispatch create --to the-agency/jordan/iscp --type directive --subject "ISCP is live — confirm tools working, then build fetch/send/reply"
dispatch create --to the-agency/jordan/mdpal-cli --type directive --subject "ISCP is live — you have mail capabilities"  
dispatch create --to the-agency/jordan/mdpal-app --type directive --subject "ISCP is live — you have mail capabilities"
dispatch create --to the-agency/jordan/mock-and-mark --type directive --subject "ISCP is live — you have mail capabilities"
```

**Each payload contains:**
- What ISCP is (one paragraph)
- Tools: `dispatch list/read/resolve`, `flag` (capture/list/discuss/clear), `agent-identity`
- What happens on startup: iscp-check fires, shows unread count
- How to process: `dispatch list` → `dispatch read <id>` → act → `dispatch resolve <id>`
- How to reply: `dispatch create --to <sender> --subject <text> --reply-to <id>`
- How to flag: `flag "quick note"` or `flag --to the-agency/jordan/captain "note for captain"`

**ISCP gets two separate dispatches:** the ISCP-is-live announcement (this phase) AND the build directive (Phase 2). Separate concerns — one announces, one assigns work.

**Depends on:** Phase 1 (registrations updated so agents know to check ISCP on startup).

---

## Phase 4: Cross-repo dispatch channel (collaboration-monofolk)

**Goal:** Set up collaboration-monofolk as the cross-repo dispatch channel.

**Repo:** `/Users/jdm/code/collaboration-monofolk/` (remote: the-agency-ai/collaboration-monofolk)

**Create structure:**
```
dispatches/
  the-agency-to-monofolk/    # Captain writes here
  monofolk-to-the-agency/    # Monofolk agent writes here
  README.md                  # Protocol contract
tracking/                    # Dispatch tracking (promised by existing README)
notes/                       # Coordination notes
```

**dispatches/README.md** — Cross-repo dispatch protocol:
- Format: YAML frontmatter (type/from/to/date/status/priority/subject) + markdown body
- Naming: `{type}-{slug}-{YYYYMMDD-HHMM}.md`
- Status tracking: writer sets `status: unread`, reader updates to `read`, resolver updates to `resolved`
- Both repos' captains are responsible for checking this repo periodically

**Initial dispatch:** `dispatches/the-agency-to-monofolk/directive-iscp-adoption-20260405.md` — ISCP adoption directive for monofolk/agency, referencing the PR from Phase 5.

**Commit and push** to origin.

---

## Phase 5: Monofolk ISCP adoption — dispatch via collaboration-monofolk

**Goal:** Give monofolk everything it needs to adopt ISCP, delivered as a comprehensive dispatch through the collaboration channel.

**Approach:** Dispatch-only. No local clone. Write a detailed directive dispatch in collaboration-monofolk that monofolk's agent can execute autonomously.

**Dispatch file:** `dispatches/the-agency-to-monofolk/directive-iscp-adoption-20260405.md`

**Dispatch content includes:**

1. **Tool manifest** — list of every file to create/copy, with full file contents embedded as code blocks:
   - `claude/tools/dispatch` (22.7KB)
   - `claude/tools/flag` (8.9KB)
   - `claude/tools/agent-identity` (6.6KB)
   - `claude/tools/iscp-check` (4.3KB)
   - `claude/tools/iscp-migrate` (15.2KB)
   - `claude/tools/dispatch-create` (577B wrapper)
   - `claude/tools/lib/_iscp-db` (shared DB library)
   - `claude/tools/lib/_address-parse` (address resolution)
   - `claude/tools/lib/_path-resolve` (path resolution)
   - `claude/tools/lib/_log-helper` (if not already present)

2. **Config changes** — exact JSON/YAML patches:
   - `claude/config/agency.yaml` — `principals:` mapping for monofolk users
   - `.claude/settings.json` — hooks (SessionStart/UserPromptSubmit/Stop → iscp-check)
   - `.claude/settings.json` — permissions for all ISCP tools

3. **Smoke test** — steps to verify identity resolution and dispatch round-trip

4. **Acceptance criteria** — monofolk agent creates a PR, runs tests, sends reply dispatch via collaboration-monofolk confirming adoption

**Note:** This is a large dispatch. The full tool contents will be embedded so monofolk's agent can create the files directly without needing access to the-agency repo.

---

## Phase 6: Article seed — "We Have To Talk"

**Create:** `/Users/jdm/code/the-agency-group/usr/jordan/captain/seeds/we-have-to-talk-20260405.md`

**Hook:** Your agents can't coordinate without messaging. You wouldn't run a team on sticky notes — why run an AI team without a communication protocol?

**Arc:**
1. The problem: agents working in isolation, no way to notify each other
2. What we tried: file-based dispatches (manual, slow, easy to miss)
3. What we built: ISCP — SQLite notifications + git payloads + automatic "you have mail"
4. It's live: dispatches flowing between captain and specialized agents
5. Lessons: notification must be automatic (hooks), identity must be resolved (not self-asserted), payload access must be zero-friction

**For:** LinkedIn + x.com. Co-authored with Jordan.

---

## Phase 7: Commit, handoff, compact

1. Commit all changes (agent registrations, dispatch payloads)
2. Write handoff with restart instructions
3. Compact

**Post-restart sequence:**
1. Bring captain up — verify ISCP check fires, read own dispatches
2. Send any final dispatches needed
3. Bring agents up one at a time — each should see "You have N dispatch(es)" on startup

---

## Dependency Graph

```
Phase 1 (agent infrastructure) ──────┐
                                      ├── Phase 3 (ISCP-is-live dispatches)
Phase 2 (dispatch to ISCP) ──────────┘
                                      
Phase 4 (collaboration-monofolk) ─────── Phase 5 (monofolk dispatch via collab)

Phase 6 (article seed) ─────────────── independent

Phase 7 (commit/compact) ─────────── after all others
```

Phases 1, 2, 4, 6 can run in parallel. Phase 3 depends on 1. Phase 5 depends on 4. Phase 7 is last.

---

## Critical Files

| File | Action | Phase |
|------|--------|-------|
| `.claude/agents/captain.md` | CREATE | 1.1 |
| `.claude/agents/iscp.md` | UPDATE | 1.2 |
| `.claude/agents/mdpal-cli.md` | UPDATE | 1.2 |
| `.claude/agents/mdpal-app.md` | UPDATE | 1.2 |
| `.claude/agents/mock-and-mark.md` | UPDATE | 1.2 |
| `usr/jordan/captain/dispatches/directive-*` | CREATE (dispatch tool) | 2, 3 |
| `/Users/jdm/code/collaboration-monofolk/dispatches/` | CREATE structure | 4 |
| monofolk clone: `.claude/settings.json` | UPDATE | 5 |
| monofolk clone: `claude/tools/` ISCP tools | COPY | 5 |
| `/Users/jdm/code/the-agency-group/usr/jordan/captain/seeds/` | CREATE | 6 |

## Verification

- `dispatch list` shows all sent dispatches with correct addresses
- `iscp-check` returns non-zero counts for each agent
- Agent registrations all contain ISCP startup step
- collaboration-monofolk pushed with dispatch structure
- monofolk PR created and linked in collaboration dispatch
- Article seed exists in the-agency-group
