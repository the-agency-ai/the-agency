---
description: Create a new workstream with scaffolded artifacts, agent registrations, and optional worktree
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Workstream Create

Create a new workstream with directory structure, shared project sandbox, and per-agent registrations. This is a captain skill — guides the principal through substance after scaffolding.

## Arguments

- $ARGUMENTS: `<name>` — workstream name in kebab-case. Followed by:
  - `--agent name[,class]` — agent name and optional class (default: tech-lead). **Repeatable** — one flag per agent.
  - `--description <text>` — one-line description of the workstream
  - `--worktree` — also create a git worktree for this workstream
  - `--scaffold-only` — skip the Phase B guided discussion instruction

If no `--agent` flags provided, create a single agent with the workstream name and tech-lead class.

## Examples

```
/workstream-create mdpal --agent mdpal-cli,tech-lead --agent mdpal-app,tech-lead
/workstream-create ops --agent ops-lead
/workstream-create folio --worktree
/workstream-create ci-tools --scaffold-only
```

## Model

```
Value stream (repo) → workstreams (standalone deployable units) → 1+ agents as workers
```

One workstream = one PVR, one A&D, one Plan, one shared project sandbox, 1+ agents.

## Phase A: Deterministic Scaffold

### Step 1: Parse and validate

1. Parse workstream name from first positional arg.
2. Parse all `--agent name[,class]` flags. Split on comma: first part is agent name, second (optional) is class (default: `tech-lead`).
3. Parse `--description`, `--worktree`, `--scaffold-only` if present.
4. If `$ARGUMENTS` is empty, ask for a workstream name.
5. Validate workstream name: must match `^[a-z0-9][a-z0-9_-]*$`, max 32 chars.
6. Validate each agent name: same regex.
7. Validate each agent class: check `claude/agents/<class>/agent.md` exists.
8. Check `claude/workstreams/<name>/` doesn't already exist.

### Step 2: Detect principal

Find the principal from `claude/config/agency.yaml` — match `$USER` key in `principals:` section, use its `name` field.

### Step 3: Create workstream directory

```
claude/workstreams/<name>/
  qgr/                      — quality gate receipts
  rgr/                      — release gate receipts
  drafts/                   — WIP before ratification (per {P}-{A} subdir)
  research/                 — MARFI outputs, investigations
  transcripts/              — 1B1 records, summaries, verbatim
  history/                  — superseded current versions
  history/flotsam/          — uncategorized archive
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
usr/<principal>/<agent>/
  tools/                    — agent-written scripts (persisted, reusable)
  tmp/                      — scratch space (gitignored)
  history/                  — personal archive
  history/flotsam/          — uncategorized personal items
```

Create `tmp/.gitignore` with `*` and `!.gitignore`.

**Note:** Shared content (seeds, transcripts, research, receipts) lives in `claude/workstreams/<name>/`, NOT here. Per-agent handoffs are flat files: `{agent}-handoff.md` in the agent directory. Written by agent-create in Step 5.

### Step 5: Create per-agent registrations via agent-create

For each `--agent name,class` flag, call the agent-create tool:

```bash
./claude/tools/agent-create <agent-name> <workstream> --type=<class> --description="<description>"
```

**agent-create is the single write path** for `.claude/agents/` registrations, workspace scaffolding (tools/, tmp/), and bootstrap handoff templates. Do NOT write registrations inline — always delegate to agent-create.

### Step 6: Create worktree (optional)

If `--worktree` was passed:

```bash
./claude/tools/worktree-create <name>
```

### Step 7: Report + Phase B instruction

Output the scaffold summary:

```
Workstream created: <name>

  claude/workstreams/<name>/          — workstream directory
  usr/<principal>/<name>/             — shared project sandbox
  .claude/agents/<agent-1>.md         — agent registration (<class>)
  .claude/agents/<agent-2>.md         — agent registration (<class>)
```

If `--scaffold-only` was NOT passed, append the Phase B instruction:

```
Bootstrap handoffs contain TODO placeholders. Run /discuss with these items:
  1. What is this workstream?
  2. What does <agent-1> own?
  3. What does <agent-2> own?
  4. What seeds do we have?
  5. What's the first action for each agent?

Then update each handoff with the resolved content:
  - usr/<principal>/<name>/<agent-1>-handoff.md
  - usr/<principal>/<name>/<agent-2>-handoff.md
```

If `--scaffold-only` was passed, append:

```
Next steps:
  1. Add seed materials to claude/workstreams/<name>/seeds/
  2. Fill in bootstrap handoffs at usr/<principal>/<name>/<agent>-handoff.md
  3. Launch an agent: claude --agent <agent-name>
```

## What this does NOT do

- **Write handoff substance** — the captain fills in handoffs via Phase B guided discussion
- **Write PVR/A&D** — part of the methodology flow, done by the launched agent
- **Drop seed material** — user responsibility
