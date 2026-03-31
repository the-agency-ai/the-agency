---
allowed-tools: Read, Glob, Grep, Bash(doppler run -- pnpm prototype:health *)
description: Health check for a prototype instance (manifest, worktree, containers, DB)
---

# Prototype Health

Run health checks on a prototype instance.

## Arguments

- $ARGUMENTS: The prototype name to check (e.g., `checkout-v2`)

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty:

1. Read `docs/data-model/prototypes.md` and list active prototypes.
2. Ask: "Which prototype do you want to check?"

### Step 1: Run health check

Run `doppler run -- pnpm prototype:health <name>`.

This checks:

1. **Manifest** — `docs/prototype/<name>/build-manifest.json` exists and is valid
2. **Worktree** — `.worktrees/<name>/` exists and working tree is clean
3. **Containers** — Docker Compose stack is running
4. **DB** — Build records exist and match the manifest

### Step 2: Report results

Present the pass/fail results. If any check failed, suggest remediation steps:

- Missing manifest → Run `pnpm prototype:build <name> both` to create one
- Dirty worktree → Review and commit or discard changes
- Containers stopped → Run `pnpm prototype:up <name>`
- Missing DB records → Restart the backend to seed from manifest
