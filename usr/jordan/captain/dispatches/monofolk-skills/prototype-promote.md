---
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(pnpm lint:*), Bash(pnpm typecheck:*), Bash(pnpm run test:*), Bash(git checkout:*), Bash(git merge:*), Bash(git branch:*), Bash(git worktree:*), Bash(git status:*), Bash(git add:*), Bash(git commit:*), Bash(gh pr create:*)
description: Run checks, squash-merge prototype to a PR branch, and create a pull request for promotion
---

# Promote Prototype

Promote a prototype by running static checks and tests, squash-merging its branch, and creating a pull request.

## Arguments

- $ARGUMENTS: The prototype name to promote (e.g., `checkout-v2`)

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty:

1. Read `docs/data-model/prototypes.md` and list active prototypes.
2. Ask: "Which prototype do you want to promote?"

### Step 1: Validate

1. Check `docs/data-model/prototypes.md` — confirm the prototype exists and has status `Active`.
2. Verify branch `proto/<name>` exists: `git branch --list proto/<name>`
3. If the branch doesn't exist, abort with an error.

### Step 2: Static checks

1. Run lint from the worktree: `pnpm lint`
2. Run typecheck from the worktree: `pnpm typecheck`
3. If either fails, report the errors and stop. Do not proceed until checks pass.

### Step 3: Tests and coverage

1. Run: `pnpm run test --testPathPattern prototype/<name> --coverage`
2. If no tests exist, warn the user but do not block promotion.
3. If tests fail, report failures and stop.

### Step 4: Squash-merge via PR branch

1. `git checkout master`
2. `git checkout -b promote/<name>`
3. `git merge --squash proto/<name>`
4. `git add -A`
5. `git commit -m "feat: promote prototype <name>"`

If there are merge conflicts, show `git status` and ask the user for resolution before continuing.

### Step 4.5: Migrate living docs from sandbox to shared

Living docs live in `usr/<engineer>/docs/<name>/` during prototyping. On promotion, copy them to `docs/prototype/<name>/`:

1. Detect the engineer name (look in `usr/*/docs/<name>/` or fall back to git config)
2. Copy `usr/<engineer>/docs/<name>/requirements.md` → `docs/prototype/<name>/requirements.md`
3. Copy `usr/<engineer>/docs/<name>/design.md` → `docs/prototype/<name>/design.md`
4. Copy `usr/<engineer>/docs/<name>/plan.md` → `docs/prototype/<name>/plan.md`
5. `git add` the new locations
6. If the sandbox docs don't exist (legacy prototype), skip this step silently

Note that the build manifest (`docs/prototype/<name>/build-manifest.json`) already lives in the shared docs directory — it is a build artifact, not a living doc.

### Step 5: Create pull request

Create a PR using:

```
gh pr create --title "[Mono] Promote prototype <name>" --body "## Summary

Promotes prototype **<name>** to production code.

### What this prototype validated
<Read from docs/prototype/<name>/design.md (or usr/<engineer>/docs/<name>/design.md if not found) — Goal and Success criteria sections. If neither exists, use placeholder: "See prototype docs for details.">

### Changes included
- Backend module: apps/backend/src/prototype/<name>/
- Prisma schema: apps/backend/prisma/proto_<snake_name>.prisma
- Frontend routes: apps/prototype-fe/app/<name>/

### Promotion Checklist
- [ ] Move `apps/backend/src/prototype/<name>/` → `apps/backend/src/<name>/`
- [ ] Strip `Proto` prefix from all Prisma model names
- [ ] Rename `@@map("proto_<snake>_...")` → `@@map("<snake>_...")`
- [ ] Rename Prisma schema file: `proto_<snake>.prisma` → `<snake>.prisma`
- [ ] Generate migration for table renames
- [ ] Replace `PrototypeAuthGuard` with production auth guard
- [ ] Remove build-info + register-build endpoints from controller
- [ ] Remove `OnModuleInit` manifest seed from service
- [ ] Remove `Proto<Name>Build` model from Prisma schema
- [ ] Delete `docs/prototype/<name>/build-manifest.json`
- [ ] Remove from `prototype.registry.ts`
- [ ] Add to `app.module.ts` imports + `RouterModule` routing
- [ ] Update import paths (`prismaJson` from `../../lib/` → adjusted for new location)
- [ ] Update controller route prefix to production path
- [ ] Move frontend to target app
- [ ] Update API paths from `/api/prototype/<name>/` to `/api/v1/<name>/`
- [ ] Run `prisma generate` + `tsc --noEmit` + tests
- [ ] Review all prototype code for production readiness

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

### Step 6: Post-merge cleanup instructions

After the PR is created, print instructions for post-merge cleanup:

1. After PR is merged, run these cleanup steps:
   - `git worktree remove .worktrees/<name>` (if worktree exists)
   - `git branch -D proto/<name>`
   - `git branch -D promote/<name>`
2. Update `docs/data-model/prototypes.md` — change status to `Promoted`
3. Remove the prototype entry from `apps/prototype-fe/app/page.tsx`
