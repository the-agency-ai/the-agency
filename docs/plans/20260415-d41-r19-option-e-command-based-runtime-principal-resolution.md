---
title: "D41-R19 — Option E (command-based runtime principal resolution)"
slug: d41-r19-option-e-command-based-runtime-principal-resolution
path: docs/plans/20260415-d41-r19-option-e-command-based-runtime-principal-resolution.md
date: 2026-04-15
status: draft
branch: jordandm-d41-r19
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: 996153b6-ab38-4aca-aebd-728d2af55af5
tags: [Frontend, Infra]
---

# D41-R19 — Option E (command-based runtime principal resolution)

## Context

Issue #111 (monofolk/jordan/captain): framework hardcodes `usr/jordan/` across `.claude/agents/*.md` registrations and two shipped tools. Second principal on an adopter repo (e.g. Peter `pyg → peter` on monofolk) cannot launch `claude --agent <any>` and resolve to their own sandbox. Every agent — captain, devex, iscp, designex, mdpal-app, mdpal-cli, mdslidepal-web, mdslidepal-mac, mock-and-mark — silently pins to Jordan's files.

**Decision on approach (principal-approved):** new `./claude/tools/agent-context` tool that loads the principal-scoped operating context at agent startup. The tool resolves `$USER → agency.yaml → principal` via existing `_path-resolve`, then emits the content of `usr/{principal}/{agent}/CLAUDE-{AGENT}.md` on stdout. Agent reads this as turn-1 context.

This preserves today's behavior (each principal gets their own CLAUDE-{AGENT}.md with its own identity, coordinated-agents table, collaborator relationships, file-discipline paths) while making the registration files principal-agnostic. No symlinks, no SessionStart hook, no filesystem magic, works on any platform, clean across worktrees.

## What this plan changes

### 1. New tool — `claude/tools/agent-context`

~40 lines of bash. Sources `claude/tools/lib/_path-resolve` to get `AGENCY_PRINCIPAL` + `AGENCY_PRINCIPAL_DIR`. Invokes `claude/tools/agent-identity --agent` to get the current agent name (fallback to `$CLAUDE_AGENT_NAME` env var). Resolves `usr/{principal}/{agent}/CLAUDE-{AGENT_UPPER}.md` with a sensible naming map (e.g. `captain → CLAUDE-CAPTAIN.md`, `devex → CLAUDE-DEVEX-AGENT.md`, `iscp → CLAUDE-ISCP.md`). Cats the file. If missing, emits a single-line note to stderr and exits 0 (not every agent has one).

Flags:
- `--path` prints the resolved path and exits (debugging)
- `--agent <name>` override (for tests)
- `--help`, `--version`

Provenance header per framework convention. `_log-helper` integration.

### 2. Rewrite all nine `.claude/agents/*.md`

Drop the `@usr/jordan/...` `@import` and principal-specific handoff paths. Keep `@claude/agents/{agent}/agent.md` (shared class doc — already principal-agnostic, confirmed in Phase-1).

Template (captain variant):

```markdown
---
name: captain
description: "Captain — coordination, dispatch routing, quality gates, PR lifecycle"
model: opus[1m]
---

@claude/agents/captain/agent.md

**On startup, immediately do these in order:**

1. `./claude/tools/agent-context` — load your principal-scoped operating context
2. `./claude/tools/handoff read` — your current handoff
3. Check ISCP: `./claude/tools/dispatch list` and `./claude/tools/flag list`
4. Check cross-repo: `./claude/tools/collaboration check`
5. Follow the "Next Action" in your handoff. Do not wait for a prompt.

**Tool usage:** All Agency tools work from ANY directory. Never prefix with `cd`. Use `./claude/tools/`.
```

mdpal-app / mdpal-cli variants: add a sibling step invoking `./claude/tools/handoff read --agent {counterpart}` if the flag exists, else read the runtime-resolved counterpart path.

Files:
- `.claude/agents/captain.md`
- `.claude/agents/devex.md`
- `.claude/agents/iscp.md`
- `.claude/agents/designex.md`
- `.claude/agents/mdpal-app.md`
- `.claude/agents/mdpal-cli.md`
- `.claude/agents/mdslidepal-web.md`
- `.claude/agents/mdslidepal-mac.md`
- `.claude/agents/mock-and-mark.md`

### 3. Fix `claude/tools/lib/_health-agent:82`

Replace the hardcoded `local principal_dir="$PROJECT_ROOT/usr/jordan"` + single-principal loop with a walk over `$PROJECT_ROOT/usr/*/` so captain-health scans every principal's agents:

```bash
local handoff=""
local principal_dir
for principal_dir in "$PROJECT_ROOT/usr/"*; do
    [[ -d "$principal_dir" ]] || continue
    for candidate in \
        "$principal_dir/$agent/$agent-handoff.md" \
        "$principal_dir/$agent/handoff.md" \
        "$principal_dir/captain/captain-handoff.md"; do
        if [[ "$agent" == "captain" && -f "$candidate" && "$candidate" == *"captain"* ]]; then
            handoff="$candidate"; break 2
        elif [[ "$agent" != "captain" && -f "$candidate" && "$candidate" == *"$agent"* ]]; then
            handoff="$candidate"; break 2
        fi
    done
done
```

### 4. Fix `claude/tools/commit-precheck:491`

Change `ls usr/jordan/*/qgr-*-"$current_hash"-*.md` to `ls usr/*/*/qgr-*-"$current_hash"-*.md`. Receipts may belong to any principal who contributed to the stage.

### 5. New BATS suite — `tests/tools/multi-principal-r19.bats`

Fixture with two principals (`jdm → jordan`, `pyg → peter`) and a populated `agency.yaml`. Test cases:

- `agent-context` as `$USER=jdm` returns contents of `usr/jordan/captain/CLAUDE-CAPTAIN.md`
- `agent-context` as `$USER=pyg` returns contents of `usr/peter/captain/CLAUDE-CAPTAIN.md`
- `agent-context` with no CLAUDE-{AGENT}.md present exits 0 silently, stderr note
- `agent-context --path` prints resolved path, no file read
- `handoff read` already resolves correctly per principal (regression anchor)
- `_health-agent` walks both principal dirs, finds both captains' handoffs
- `commit-precheck` finds a QGR under `usr/peter/` when `$USER=pyg` and the hash matches

Model fixture from `tests/tools/agent-identity.bats` (branch-keyed cache, $USER export, CLAUDE_PROJECT_DIR override).

### 6. Manifest bump + release plumbing

- `claude/config/manifest.json` → `agency_version: 41.19`, `updated_at`
- `/pr-prep` for full QG + MAR + RGR
- `/release` to cut PR
- Principal approval → `/pr-merge --merge`
- `/post-merge` for v41.19 release + `/sync-all`
- Comment-close #111 on merge

## Critical files

- `/Users/jdm/code/the-agency/claude/tools/agent-context` (new)
- `/Users/jdm/code/the-agency/.claude/agents/{captain,devex,iscp,designex,mdpal-app,mdpal-cli,mdslidepal-web,mdslidepal-mac,mock-and-mark}.md`
- `/Users/jdm/code/the-agency/claude/tools/lib/_health-agent` (lines 81–98)
- `/Users/jdm/code/the-agency/claude/tools/commit-precheck` (line 491)
- `/Users/jdm/code/the-agency/tests/tools/multi-principal-r19.bats` (new)
- `/Users/jdm/code/the-agency/claude/config/manifest.json`

## Existing helpers reused

- `claude/tools/lib/_path-resolve` — sets `AGENCY_PRINCIPAL`, `AGENCY_PRINCIPAL_DIR`, `AGENCY_PROJECT_ROOT`; resolves via `agency.yaml` → `$USER`
- `claude/tools/agent-identity` — `--agent`, `--principal`, `--json`; branch-keyed cache
- `claude/tools/handoff` — `read` already resolves via `_path-resolve` + `agent-identity`
- Multi-principal iteration pattern from `claude/tools/handoff:118` and `claude/tools/instruction-show:90`

## Out of scope for R19

- Migrating existing monofolk adopter `.claude/agents/*.md` files (monofolk side, they'll take `agency update` and re-run principal-onboard as needed)
- Long-term Option D (petition Anthropic for `${USER}` in `@import`)
- Content changes to `CLAUDE-{AGENT}.md` files — these stay as-is, principal-owned
- Any changes to `claude/agents/*/agent.md` class docs — already principal-agnostic

## Behavior trade-off acknowledged

`@import` primes the system prompt at session start. A tool call at turn 1 puts the content in conversation history instead. Practical difference is small; `/session-resume` re-runs the startup sequence so content is always loaded. Acceptable cost.

## Verification

1. `grep -rn "usr/jordan" .claude/agents/ claude/tools/` returns only fixtures/docstrings — no code paths hit
2. `bats tests/tools/multi-principal-r19.bats` all green
3. As `$USER=jdm` in this repo: `./claude/tools/agent-context` dumps `usr/jordan/captain/CLAUDE-CAPTAIN.md` content
4. Manually simulate `$USER=pyg` with a `usr/peter/` fixture in test scope → tool resolves to peter's context
5. Full MAR (parallel reviewer-code / security / design / test / scorer) + RGR at `/pr-prep`
6. Post-merge: `agency update` in monofolk pulls the change; Peter's `claude --agent captain` now resolves correctly

## Flow

1. Create branch `jordandm-d41-r19`
2. Write `claude/tools/agent-context` (new)
3. Rewrite nine `.claude/agents/*.md` (same template, per-agent name/model substitutions)
4. Fix `_health-agent`
5. Fix `commit-precheck`
6. Write BATS suite
7. Run BATS locally — must pass before `/pr-prep`
8. Run MAR (parallel agents) via `/pr-prep` → RGR
9. Bump manifest
10. `/release` → PR
11. Principal approval → `/pr-merge`
12. `/post-merge` → v41.19 release + `/sync-all`
13. Comment-close #111
