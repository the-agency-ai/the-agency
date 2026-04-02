---
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(mv:*), Bash(git rev-parse:*), Bash(git config:*), Glob, Grep
description: Create a new workstream with scaffolded artifacts and optional worktree
---

# Workstream Create

Create a new workstream with directory structure, shared project sandbox, and per-agent instance registrations.

## Arguments

- $ARGUMENTS: `<name>` — workstream name in kebab-case. Followed by:
  - `--agent name[,class]` — agent name and optional class (default: tech-lead). **Repeatable** — one flag per agent.
  - `--description <text>` — one-line description of the workstream

If no `--agent` flags provided, create a single agent with the workstream name and tech-lead class.

## Examples

```
/workstream-create mdpal --agent mdpal-cli,tech-lead --agent mdpal-app,tech-lead
/workstream-create ops --agent ops-lead
/workstream-create folio
```

## Model

```
Value stream (repo) → workstreams (standalone deployable units) → 1+ agents as workers
```

One workstream = one PVR, one A&D, one Plan, one shared project sandbox, 1+ agents.

## Steps

### Step 1: Parse and validate

1. Parse workstream name from first positional arg.
2. Parse all `--agent name[,class]` flags. Split on comma: first part is agent name, second (optional) is class (default: `tech-lead`).
3. Parse `--description` if present.
4. If `$ARGUMENTS` is empty, ask for a workstream name.
5. Validate workstream name: must match `^[a-z0-9-]+$`.
6. Validate each agent name: must match `^[a-z0-9-]+$`.
7. Validate each agent class: check `claude/agents/<class>/agent.md` exists.
8. Check `claude/workstreams/<name>/` doesn't already exist.

### Step 2: Detect principal

Find the principal from `claude/config/agency.yaml` — match `$USER` key in `principals:` section, use its `name` field.

### Step 3: Create workstream directory

```
claude/workstreams/<name>/
  seeds/                    — input materials (user drops these)
  reviews/                  — QGRs and review files
  history/                  — archived artifact versions
  KNOWLEDGE.md              — patterns, conventions, key decisions
```

**KNOWLEDGE.md** scaffold:

```markdown
# <name> — Workstream Knowledge

## Patterns and Conventions

<!-- Accumulate patterns discovered during development -->

## Key Decisions

<!-- Record architectural and design decisions with rationale -->
```

### Step 4: Create shared project sandbox

```
usr/<principal>/<name>/
  handoffs/                 — per-agent handoff files (not captain's handoff.md)
  dispatches/               — incoming dispatches
  code-reviews/             — review and dispatch files
  transcripts/              — discussion transcripts
  history/                  — archived artifacts
```

### Step 5: Create per-agent instance registrations

For each `--agent name,class` flag, create `.claude/agents/<agent-name>.md`:

```markdown
---
name: <agent-name>
description: "<description or 'Define, design, and build <workstream-name>'>"
model: opus
---

Read your role and responsibilities from `claude/agents/<class>/agent.md`.
Read workstream knowledge from `claude/workstreams/<workstream-name>/KNOWLEDGE.md`.
Read seed materials from `claude/workstreams/<workstream-name>/seeds/`.
```

### Step 6: Report

```
Workstream created: <name>

  claude/workstreams/<name>/          — workstream directory
  usr/<principal>/<name>/             — shared project sandbox
  .claude/agents/<agent-1>.md         — agent registration (<class>)
  .claude/agents/<agent-2>.md         — agent registration (<class>)

Next steps:
  1. Add seed materials to claude/workstreams/<name>/seeds/
  2. Launch an agent: claude --agent <agent-name>
  3. Start with /define to build the PVR
```

## What this does NOT do

- **Create worktrees** — separate step via `/worktree-create`
- **Write PVR/A&D** — part of the methodology flow, done by the launched agent
- **Drop seed material** — user responsibility
