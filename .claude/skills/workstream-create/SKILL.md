---
allowed-tools: Read, Write, Bash(mkdir:*), Bash(git rev-parse:*), Bash(git config:*), Glob, Skill
description: Create a new workstream with scaffolded artifacts and optional worktree
---

# Workstream Create

Create a new workstream with directory structure, scaffolded artifacts, and optionally a git worktree for isolated development.

## Arguments

- $ARGUMENTS: `<name>` — workstream name in kebab-case. Optionally followed by:
  - `--agent <class>` — agent class to assign (default: tech-lead)
  - `--worktree` — also create a git worktree for this workstream
  - `--description <text>` — one-line description

## Steps

### Step 1: Validate

1. If `$ARGUMENTS` is empty, ask for a workstream name.
2. Name must be kebab-case: `^[a-z0-9-]+$`
3. Check `claude/workstreams/<name>/` doesn't already exist.

### Step 2: Create workstream directory

```
claude/workstreams/<name>/
  seeds/                    — input materials
  reviews/                  — QGRs and review files
  history/                  — archived artifact versions
```

### Step 3: Scaffold initial artifacts

Create stub files:

**KNOWLEDGE.md:**
```markdown
# <name> — Workstream Knowledge

## Patterns and Conventions

<!-- Accumulate patterns discovered during development -->

## Key Decisions

<!-- Record architectural and design decisions with rationale -->
```

### Step 4: Create agent registration

If `--agent` specified (or default tech-lead), create `.claude/agents/<name>.md`:

```yaml
---
name: <name>
description: "<description or 'Define, design, and build <name>'>"
model: opus
---

Read your role and responsibilities from `claude/agents/<agent-class>/agent.md`.
Read seed materials from `claude/workstreams/<name>/seeds/`.
```

### Step 5: Create worktree (if --worktree)

If `--worktree` was passed, invoke `/worktree-create` via the Skill tool with the workstream name.

### Step 6: Report

```
Workstream created: <name>

  claude/workstreams/<name>/     — workstream directory
  .claude/agents/<name>.md       — agent registration (<class>)

Next steps:
  1. Add seed materials to claude/workstreams/<name>/seeds/
  2. Launch: claude --agent <name>
  3. Start with /define to build the PVR
```
