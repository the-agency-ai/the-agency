---
type: triage-record
date: 2026-04-07
participants: [jordan, captain]
topic: flag triage — Day 32
status: 16 flags resolved + cleared, 18 remaining for 1B1
---

# Flag Triage — Day 32

Triage of the captain's flag queue. 34 flags accumulated since Day 28. Categorized into three batches: already resolved, captured elsewhere, still live.

This document archives the 16 flags being cleared (with their resolutions) before they're removed from the active queue. The 18 still-live flags get 1B1'd separately.

---

## Batch 1: Already Resolved (cleared)

These flags were resolved by Day 32 work. The original observations were correct at the time; the work addressed them.

### Flag 1, 2, 3 — Permission prompts on basic ops

**Original (2026-04-05):** ISCP agent hitting permission prompts for basic operations (ls, git show, sqlite3, ~/.agency/, cd+git compound). Claude Code treats compound commands as bare repo attack vectors.

**Resolution:** Day 32 permissions overhaul. Replaced 100+ narrow patterns with `Bash(*)`, `Read(**)`, `Edit(**)`, `Write(**)` in `.claude/settings.json` and `claude/config/settings-template.json`. The project boundary is the security boundary; hookify rules handle behavioral enforcement, not the permission system. See commits `daf1148`, `e552885`, `26f7963`.

### Flag 17, 18 — Symlink dispatch payload architecture

**Original (2026-04-06):** Critical design — `~/.agency/{repo}/dispatches/` should hold symlinks to git payloads, not copies. Solves branch transparency without violating C3 (git as source of truth).

**Resolution:** Implemented in ISCP commit `1e610fd`. Already in production in the symlink-merge work that landed before Day 32. Recorded in valueflow A&D §8.

### Flag 19 — Day counting convention

**Original (2026-04-06):** Count days with commits per repo and per workstream. Day 30 = 30 days with commits since 2026-01-05. Propose as Agency model. Add to CLAUDE-THEAGENCY.md and valueflow PVR as a health metric.

**Resolution:** Documented in `agency/README-THEAGENCY.md` under the Day-PR Release Pattern section as part of Day 32 commit `f3022da`. Convention is now active — every Day 32 commit uses `Day 32:` prefix.

### Flag 16, 20 — Manual dispatch loop convention

**Original (2026-04-06):** Add to all agent registration startup sequences: 'Set a loop to check for dispatches every 5 minutes: /loop 5m dispatch check'.

**Resolution:** INVALIDATED by Day 32 friction analysis P2. The manual `/loop 5m dispatch check` setup was identified as wasted startup overhead (3 tool calls per session). Removed from all agent registrations. The `iscp-check` hook fires automatically on `SessionStart`, `UserPromptSubmit`, and `Stop` — no manual loop needed. See commit `e04dd56`.

### Flag 22 — Dispatch tool not pre-approved (--friction)

**Original (2026-04-06):** Agents blocked on sending dispatches — dispatch tool not pre-approved in worktree settings. The MAR review process is broken by permission friction. settings-template must ship dispatch permissions. This is the #1 DevEx priority.

**Resolution:** Resolved by the `Bash(*)` overhaul. Settings-template now ships with the broad permissions. No agent should hit a permission prompt on a tool again. See commit `2a151aa`.

### Flag 23, 25, 26 — One agent per worktree

**Original (2026-04-06):**
- Two agents (mdpal-cli and mdpal-app) sharing one worktree breaks identity, dispatch routing, git status, commit attribution.
- RULE: One agent, one worktree.
- CONVENTION: Agent/worktree naming — workstream prefix + agent name. mdpal → mdpal-cli, mdpal-app.

**Resolution:** Already implemented. mdpal worktree was split into `mdpal-cli` and `mdpal-app` worktrees during the Day 31 reboot. The "one agent, one worktree" rule is now reflected in `.claude/agents/mdpal-cli.md` and `.claude/agents/mdpal-app.md` as separate registrations. Worktree naming follows the convention.

### Flag 24 — Shared worktree multi-agent design

**Original (2026-04-06):** DESIGN: shared worktree model — multiple agents in one worktree (mdpal-cli + mdpal-app in mdpal worktree). Need: multi-agent identity or workstream-scoped dispatch visibility. ISCP needs to support this pattern — it's intentional for collaborating agents on the same codebase.

**Resolution:** INVALIDATED by Flag #25 (one agent per worktree rule). The shared worktree pattern was abandoned in favor of per-agent worktrees with collaboration via dispatches. No ISCP work needed.

### Flag 27 — agent-identity worktree resolution bug (--friction)

**Original (2026-04-07):** agent-identity resolves to captain on iscp worktree. Root cause: CLAUDE_PROJECT_DIR unset in Bash tool calls + no .agency-agent file in worktree + SCRIPT_DIR fallback goes to main checkout. Cascading failure: handoff tool writes to wrong agent path.

**Resolution:** ISCP agent fixed this in commit `de73c9c`. Added PWD-based worktree detection as middle tier between `CLAUDE_PROJECT_DIR` (only set in hooks) and `SCRIPT_DIR` fallback (resolves to main). The worktree's git rev-parse --show-toplevel now correctly resolves identity. 22/22 agent-identity tests pass.

### Flag 32 — Security skill broken

**Original (2026-04-07):** BUG: Security skill seems to be broken. Investigate.

**Resolution:** Found and fixed. Root cause: `/secret` existed only as a command (`.claude/commands/secret.md`) not a skill, AND the command body used `$CLAUDE_PROJECT_DIR` in a Bash example which is empty in agent shell sessions. Created `.claude/skills/secret/SKILL.md` as a proper SPEC-PROVIDER skill (third example after `/preview` and `/deploy`). Configured `doppler` as the active provider in `agency.yaml`. Shipped in commit `5e6d31e` (PR #47, Day 32 - Release 2). Doppler tool verification dispatched to monofolk/devex.

---

## Batch 2: Captured Elsewhere (cleared)

These flags became dispatches to other agents. The work is queued in their inbox; the flag is no longer the right tracking mechanism.

### Flag 29 — Worktree awareness check

**Original (2026-04-07):** SEED: detect when agent's shell CWD doesn't match its worktree root. Could be a PreToolUse hookify rule or a lightweight check in agent-identity. The ISCP agent self-corrected when it realized cd /Users/jdm/code/the-agency goes to main, not the worktree — but only after wasting tool calls.

**Resolution:** Dispatched to devex as #110. Two-layer plan: SessionStart hook (Layer 1) to catch wrong CWD at boot, PreToolUse hookify rule (Layer 2) to block any `cd` that takes the agent outside their worktree. Plan #116 from devex approved with all 4 decisions. Implementation in devex queue.

### Flag 30 — core.bare keeps flipping

**Original (2026-04-07):** BUG: git config core.bare keeps getting set to true on the main checkout. Happens during worktree merges (git -C worktree merge SHA). Breaks all git operations on main until manually fixed with git config core.bare false. Need to investigate root cause.

**Resolution:** Dispatched to devex as part of #109 (BATS test isolation work). DevEx investigated and concluded: not currently broken in live config, no test sets core.bare directly, hypothesis is worktree merge mechanics rather than test code. Recommendation: defer until we observe it again. Captain agreed in approval response to plan #115.

---

## What Was Cleared

16 flags cleared total. The active flag queue now has 18 items remaining for 1B1 triage.

The cleared flags are recorded here as the audit trail. The original observations + the resolutions both belong in history.

---

## Next: 1B1 the 18 remaining flags

See follow-up triage for the live items: provenance discipline, GTM seeds, command audit, Anthropic issues, MAR process improvements, agency-audit + structure.yaml seeds, V3 fragment registry, security pre-GTM concern, Granola workflow, agent mail business idea.
