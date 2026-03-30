# CoS Session Handoff

**Date:** 2026-03-30 ~02:30
**Branch:** `fix/claudemd-v2-and-fixes` (the-agency, from origin/main)
**Session:** CoS operating from monofolk on the-agency repo
**Last commit:** `cce930e` (QG review fixes)
**Context at handoff:** Good — mid-1B1 review of CLAUDE.md v2, Items 1-2 complete

## What Was Done This Session (continued from previous handoff)

### CLAUDE.md v2 1B1 Progress
- **Item 1: Project Structure / File Organization** — COMPLETE (previous session)
- **Item 2: Tools** — COMPLETE (this session)
- Items 3-17 remaining

### Item 2: Tools — Full Audit Results

**Tool location model:**
- `claude/tools/` — Agency framework tools, ships via `agency-init`
- `claude/tools/lib/` — sourced helpers (`_log-helper`, `_path-resolve`), not directly invocable
- `tools/` — repo's own dev/release tooling, not distributed

**Key pattern: token-conserving wrappers.** Every Agency tool wraps the actual operation, returns 3-line stdout to context, verbose to log service. Agent-facing layer over repo-native tooling.

**Tool categories resolved (all 11):**

| Category | Tools (keep/evolve) | Notes |
|----------|-------------------|-------|
| Framework Setup | `agency-init`, `agency-update`, `agency-verify`, `terminal-setup` (pluggable) | `setup-agency` deprecated |
| Scaffolding | `principal-create`, `agent-define` (new, creates class), `agent-create` (creates instance), `workstream-create`, `worktree-create`, `worktree-list`, `worktree-delete` | `add-principal` deprecated. Hookify rule blocks built-in EnterWorktree. |
| Git & Quality | `git-commit`, `git-tag`, `git-push`, `test-run` | All renamed noun-verb. QG is a skill, not a tool. Reviewers are subagents. |
| Secrets | `secret-vault` (bundled default), `secret-{provider}` (pluggable), `secrets-scan` (QG) | `/secret` skill is dispatcher |
| GitHub | `gh-pr`, `gh-release`, `gh-api` | `gh` namespace stays (it IS noun-verb) |
| Helpers | `_log-helper`, `_path-resolve` | Move to `claude/tools/lib/` |
| Context | `handoff` (read, write, bootstrap — first-class primitive) | All v1 session tools deprecated |
| Messaging | ALL KILLED | ISCP dispatch filed for redesign |
| v1 Work Items | ALL KILLED | Plan document is the work tracker |
| Starter/Distribution | ALL KILLED | `agency-init` + `agency-update` replace |
| Miscellaneous | `agency-whoami`, `tool-find`, `tool-create`, `now`, `dependency-check`, `dependency-install` | See details below |

**Misc keep details:**
- `whoami` + `agentname` merge → `agency-whoami`
- `tool-new` → `tool-create` (noun-verb, scaffolds Agency-ready tools)
- `now` stays — permission bypass for timestamps (real problem solved)
- `dependency-check` / `dependency-install` — spell out, refactor for 2.0
- `release` / `version-bump` / `version-next` — keep in `tools/` (internal dev), not `claude/tools/`

**Plugin provider framework identified:**

| Pattern | Dispatcher | Providers |
|---------|-----------|-----------|
| Secrets | `/secret` skill | `secret-vault`, `secret-doppler`, future |
| Terminal | `terminal-setup` | `terminal-setup-ghostty`, future |
| Platform | `platform-setup` | `platform-setup-macos`, `-linux`, `-windows` |
| Design | `design-diff`, `design-extract` | `*-figma`, future |

Existing tools refactor into the framework (not delete/replace):
- `ghostty-setup` → `terminal-setup-ghostty`
- `mac-setup` → `platform-setup-macos`
- `figma-diff` → `design-diff-figma`
- `figma-extract` → `design-extract-figma`

**Developer documentation pattern:** `claude/tools/CLAUDE.md` explains the tool framework for contributors. Same pattern for other dirs (`claude/agents/CLAUDE.md`, `claude/hookify/CLAUDE.md`).

### Dispatches Filed (3 total)
1. **ISCP** — `dispatch-iscp-design-20260330.md` — intra-session communication protocol
2. **Browser protocol** — `dispatch-browser-protocol-20260330.md` — agent browsing escalation ladder
3. **Plugin framework** — `dispatch-plugin-framework-20260330.md` — four provider patterns, ASAP priority

### gstack Analysis
- Three subagents analyzed gstack (architecture, testing/quality, skills model)
- Full artifact at `usr/jordan/captain/gstack-analysis-20260330.md`
- Top adoptions: template system, learnings JSONL, confidence scoring, decision classification, diff-scope for conditional QG

### Agent Audit (from previous session, still current)
- Kill 7 dead agents: foundation-alpha/beta, collaboration, unknown, hub, mission-control, research
- Build 4 agent classes: tech-lead, marketing-lead, platform-specialist, researcher
- Keep: captain, cos, project-manager, reviewer-*

## What's Next

1. **Resume CLAUDE.md 1B1** — Items 3-17:
   - 3: Tool Output Standard
   - 4: Agents
   - 5: The Work Pattern
   - 6: Development Methodology
   - 7: Quality Gate
   - 8: Discussion Protocol (1B1)
   - 9: Agent Startup Protocol
   - 10: Handoff Discipline
   - 11: Git & Remote Discipline
   - 12: Naming Conventions
   - 13: Worktrees
   - 14: Secrets
   - 15: Session Context
   - 16: Testing & Quality
   - 17: Bash Tool Usage
   - 18: Sandbox Principle
   - 19: What NOT to Do
2. **Build tech-lead agent class** — most instances depend on it
3. **Kill dead agents** — 7 to remove
4. **Plugin framework** — dispatch filed, ASAP
5. **ISCP design** — dispatch filed
6. **Browser protocol** — dispatch filed
7. **Push PR** — once CLAUDE.md 1B1 complete

## Git State

- **Branch:** `fix/claudemd-v2-and-fixes` (2 commits ahead of origin/main)
- **Working tree:** dirty (CLAUDE.md evolving through 1B1, dispatches added, gstack analysis)
- **Not pushed.** Awaiting approval after 1B1 completes.

## Key Files

- `/Users/jordan_of/code/the-agency/CLAUDE.md` — v2 in progress
- `usr/jordan/captain/gstack-analysis-20260330.md` — gstack analysis artifact
- `usr/jordan/captain/dispatch-iscp-design-20260330.md`
- `usr/jordan/captain/dispatch-browser-protocol-20260330.md`
- `usr/jordan/captain/dispatch-plugin-framework-20260330.md`
- `usr/jordan/captain/issues-agency2-setup-20260329.md`
- Memory: `project_file-org-decisions.md`, `project_tech-lead-class-hole.md`, `project_artifact-versioning-todo.md`, `project_ide-research-todo.md`
