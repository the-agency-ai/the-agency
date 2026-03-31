---
allowed-tools: Read, Glob, Grep, Bash(git status:*), Bash(docker-compose:*)
description: Show active prototypes from the registry with build, worktree, and container status
---

# List Prototypes

Show all active prototypes and their status.

## Instructions

1. Read `docs/data-model/prototypes.md` and parse the registry table.
2. For each prototype listed, check:
   - Backend module exists at `apps/backend/src/prototype/<name>/`
   - Frontend route exists at `apps/prototype-fe/app/<name>/`
   - Prisma schema exists at `apps/backend/prisma/proto_<snake_name>.prisma`
   - Build numbers from `docs/prototype/<name>/build-manifest.json` (FE #, BE #)
   - Worktree status: does `.worktrees/<name>/` exist? If so, is it clean or dirty? (`git status --porcelain` in the worktree)
   - Container status: running or stopped? (`docker-compose -p proto-<name> ps --format json`)
3. Present a summary table showing:
   - Name, Status, Owner, Created date
   - Backend module: exists/missing
   - Frontend route: exists/missing
   - Prisma schema: exists/missing
   - Build: FE #N / BE #N (or "no manifest")
   - Worktree: clean/dirty/missing
   - Containers: running/stopped
4. If no prototypes are registered, say so and suggest running `/prototype-create`.
