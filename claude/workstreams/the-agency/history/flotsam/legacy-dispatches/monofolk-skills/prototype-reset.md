---
allowed-tools: Read, Glob, Grep, Bash(doppler run -- pnpm prototype:reset *)
description: Full reset of a prototype (containers, DB, manifest, worktree changes)
---

# Prototype Reset

Fully reset a prototype instance: stop containers, wipe DB, reset manifest, discard worktree changes, and re-push schema.

## Arguments

- $ARGUMENTS: The prototype name to reset (e.g., `checkout-v2`)

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty:

1. Read `docs/data-model/prototypes.md` and list active prototypes.
2. Ask: "Which prototype do you want to reset?"
3. Warn: "This will stop containers, wipe all DB tables, reset the build manifest to zero, discard uncommitted worktree changes, and re-push the Prisma schema. This is destructive and cannot be undone."

### Step 1: Run reset

Run `doppler run -- pnpm prototype:reset <name>` — this handles:

1. Stop containers (`docker-compose -p proto-<name> down -v`)
2. Truncate all `proto_<snake>_%` tables with CASCADE
3. Reset `build-manifest.json` to zero state
4. Discard uncommitted changes in `.worktrees/<name>/`
5. Re-push Prisma schema (`prisma db push` in worktree)

The script will prompt for confirmation before proceeding.

### Step 2: Summary

Report what was reset and any errors encountered.
