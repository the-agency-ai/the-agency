---
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(doppler run -- pnpm prototype:wipe *), Bash(rm -rf apps/backend/src/prototype/*), Bash(rm -rf apps/prototype-fe/app/*), Bash(rm apps/backend/prisma/proto_*), Bash(rm -rf docs/prototype/*), Bash(git worktree:*), Bash(git branch:*)
description: Wipe data, remove code, clean up worktree/branch, and update registry for a prototype
---

# Archive Prototype

Archive a prototype by wiping its data, removing its code, cleaning up its git worktree and branch, and updating the registry.

## Arguments

- $ARGUMENTS: The prototype name to archive (e.g., `checkout-v2`)

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty:

1. Read `docs/data-model/prototypes.md` and list active prototypes.
2. Ask: "Which prototype do you want to archive?"

### Step 1: Validate

1. Check `docs/data-model/prototypes.md` — confirm the prototype exists and is not already archived.
2. Show the user what will be removed and ask for confirmation before proceeding.

### Step 2: Wipe data

1. Run the wipe script: `doppler run -- pnpm prototype:wipe <name>`
2. This truncates all `proto_<snake>_%` DB tables and resets the build manifest to zero.
3. Report the result.

### Step 3: Remove backend module

1. Remove the module directory: `apps/backend/src/prototype/<name>/`
2. In `apps/backend/src/prototype/prototype.module.ts`:
   - Remove the import for the module
   - Remove the `{ path: '<name>', module: ... }` entry from RouterModule children
   - Remove the module from the `imports` array

### Step 4: Remove Prisma schema

1. Remove `apps/backend/prisma/proto_<snake_name>.prisma`
2. Remind the user to create a migration to drop the tables: `prisma migrate dev --name proto_<snake_name>_drop`

### Step 5: Remove frontend route

1. Remove `apps/prototype-fe/app/<name>/` directory
2. Remove the prototype entry from the `prototypes` array in `apps/prototype-fe/app/page.tsx`

### Step 6: Archive design docs

1. The `docs/prototype/<name>/` directory contains the design spec, plan, and `build-manifest.json`.
2. Ask the user: keep the docs for reference, or delete them?
3. If keeping: the manifest is preserved alongside other docs. Warn that re-creating a prototype with the same name could pick up stale build numbers from this manifest.
4. If deleting: remove `docs/prototype/<name>/` entirely (manifest goes too).

### Step 7: Remove git worktree and branch

1. If worktree exists at `.worktrees/<name>`, remove it: `git worktree remove .worktrees/<name>`
2. If branch `proto/<name>` exists, delete it: `git branch -D proto/<name>`

### Step 8: Update registry

1. In `docs/data-model/prototypes.md`, change the prototype's status to `Archived`.

### Step 9: Summary

Print a summary of what was removed and any manual follow-up steps (e.g., creating a drop migration).
