---
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(pnpm lint:*), Bash(pnpm typecheck:*), Bash(pnpm run test:*), Bash(git checkout:*), Bash(git merge:*), Bash(git branch:*), Bash(git worktree:*), Bash(git status:*), Bash(git add:*), Bash(git commit:*)
description: Run checks, squash-merge multiple prototypes into a combined prototype via git operations
---

# Merge Prototypes

Merge two or more separately validated prototypes into a single combined prototype using git squash-merges and code-level integration.

## Arguments

- $ARGUMENTS: Space-separated list of prototype names to merge, plus the target name. Format: `<source1> <source2> [<sourceN>...] --into <target-name>`

Example: `/prototype-merge checkout-v2 smart-prescriptions --into unified-checkout`

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty:

1. Read `docs/data-model/prototypes.md` and list active prototypes.
2. Ask: "Which prototypes do you want to merge? (space-separated)"
3. Ask: "What should the merged prototype be called?"

If `--into` is missing from `$ARGUMENTS`:

1. Ask the user for the target name.

### Step 1: Validate

1. Validate all source prototypes exist in `docs/data-model/prototypes.md` and have status `Active`.
2. Verify branch `proto/<source>` exists for each source prototype.
3. If the target name matches an existing prototype, confirm with the user that they want to merge into it (additive merge). Otherwise, a new prototype will be created.

### Step 2: Run checks on each source

For each source prototype:

1. Run lint: `pnpm lint`
2. Run typecheck: `pnpm typecheck`
3. Run tests: `pnpm run test --testPathPattern prototype/<source> --coverage`
4. If lint or typecheck fails on any source, report errors and stop.
5. If tests fail, report failures and stop. Warn if no tests exist.

### Step 3: Create target branch

1. `git branch proto/<target>` from main (or from current HEAD if target already exists).

### Step 4: Squash-merge each source

For each source prototype, in order:

1. `git checkout proto/<target>`
2. `git merge --squash proto/<source>`
3. `git add -A`
4. `git commit -m "merge: incorporate <source> into <target>"`

### Step 5: Conflict handling

If merge conflicts occur during any squash-merge:

1. Show `git status` to display conflicted files.
2. Pause and ask the user for resolution guidance.
3. Convention: prototypes should be isolated enough that conflicts don't happen. If they do, it likely means shared files were modified and manual resolution is needed.

### Step 6: Create worktree

1. `git worktree add .worktrees/<target> proto/<target>`

### Step 7: Code-level merge

Working in `.worktrees/<target>/`:

1. **Backend**: Combine source modules into the target module in `apps/backend/src/prototype/prototype.module.ts` — ensure all source modules are imported and registered in RouterModule children.
2. **Prisma**: Combine all models from source `proto_<source>_*.prisma` files into `proto_<target_snake>.prisma`. Rename models and `@@map` directives to use the target prefix.
3. **Frontend**: Ensure all source routes exist under `apps/prototype-fe/app/<target>/` or remain as separate routes. Update `prototypeApi()` calls if needed.
4. **Build manifest**: Create a fresh `build-manifest.json` for the target with zero values at `docs/prototype/<target>/build-manifest.json`. Source manifests remain in their respective `docs/prototype/<source>/` directories (they'll be marked as merged in the registry).

### Step 8: Update registry

1. In `docs/data-model/prototypes.md`:
   - Update source prototypes' status to `Merged → <target>`
   - Add or update the target prototype entry with combined table and frontend info
2. Update the `prototypes` array in `apps/prototype-fe/app/page.tsx` — remove source entries, add/update target entry.

### Step 9: Cleanup

Ask the user if they want to:

- **Keep source worktrees and branches** (for reference, marked as merged in registry)
- **Remove source worktrees and branches** (`git worktree remove .worktrees/<source>`, `git branch -D proto/<source>` for each)

### Step 10: Summary

Print:

- All files created/moved/modified
- Git branches: `proto/<target>` with squash-merged history
- Worktree: `.worktrees/<target>/`
- Any manual follow-up steps (migrations, testing)
- The merged prototype's routes: backend API paths and frontend URLs
- **How to work in the merged prototype:**
  - Switch current session: `cd .worktrees/<target>/`
  - Start new Claude session: `cd .worktrees/<target>/ && claude`
