---
allowed-tools: Read, Glob
description: Show all prototype commands and CLI scripts as a reference table
---

# Prototype Help

Show a reference table of all prototype commands and CLI scripts.

## Instructions

### Step 1: Read all prototype commands

Read all `.claude/commands/prototype-*.md` and `.claude/commands/worktree-*.md` files and extract their `description` from frontmatter.

### Step 2: Present reference table

Display the tables below:

**Prototype Commands (Claude Code):**

| Command                                      | Description                                       |
| -------------------------------------------- | ------------------------------------------------- |
| `/prototype-create <name>`                   | Scaffold a new prototype                          |
| `/prototype-list`                            | Show active prototypes                            |
| `/prototype-archive <name>`                  | Wipe data, remove code, clean up                  |
| `/prototype-preview <name>`                  | Run checks, push branch for preview deploy        |
| `/prototype-promote <name>`                  | Run checks, create promotion PR                   |
| `/prototype-merge <sources> --into <target>` | Combine prototypes                                |
| `/prototype-reset <name>`                    | Full reset (containers, DB, manifest, worktree)   |
| `/prototype-health <name>`                   | Health check (manifest, worktree, containers, DB) |
| `/prototype-up <name>`                       | Start Docker dev stack                            |
| `/prototype-down <name>`                     | Stop Docker dev stack                             |
| `/prototype-logs <name> [service]`           | Tail Docker container logs                        |
| `/prototype-help`                            | This reference table                              |

**Worktree Commands (Claude Code):**

| Command                                   | Description                                       |
| ----------------------------------------- | ------------------------------------------------- |
| `/worktree-create <name> [--from branch]` | Create worktree with bootstrapped dev environment |
| `/worktree-list`                          | List worktrees with status info                   |
| `/worktree-delete <name>`                 | Remove worktree and optionally delete branch      |

**Git Hygiene Commands (Claude Code):**

| Command            | Description                                    |
| ------------------ | ---------------------------------------------- |
| `/rebase [target]` | Rebase current branch (default: origin/master) |
| `/sync [target]`   | Rebase + force-push with --force-with-lease    |

**CLI Scripts:**

| Command                                      | Description                             |
| -------------------------------------------- | --------------------------------------- |
| `pnpm prototype:up <name>`                   | Start full Docker dev stack             |
| `pnpm prototype:down <name>`                 | Stop containers, clean up .env.local    |
| `pnpm prototype:ps`                          | List all instances and ports            |
| `pnpm prototype:build <name> [fe\|be\|both]` | Register a build                        |
| `pnpm prototype:check <name>`                | HTTP health checks on running stack     |
| `pnpm prototype:logs <name> [service]`       | Tail Docker container logs              |
| `pnpm prototype:doctor`                      | Scan for orphaned artifacts             |
| `pnpm prototype:wipe <name>`                 | Wipe DB tables (needs `doppler run --`) |
| `pnpm prototype:health <name>`               | Health check (needs `doppler run --`)   |
| `pnpm prototype:reset <name>`                | Full reset (needs `doppler run --`)     |

**Bootstrap:**

| Command                                     | Description                                  |
| ------------------------------------------- | -------------------------------------------- |
| `bash scripts/worktree-bootstrap.sh <path>` | Bootstrap a worktree (Doppler, pnpm, Prisma) |

**Framework Tools:**

| Command | Description |
|---------|-------------|
| `bash agency/tools/proto-module-scaffold <name>` | Generate backend module from template (called by /prototype-create) |

**Documentation:**

- Agent guidance: `apps/backend/src/prototype/CLAUDE.md` (conventions, patterns, shared libs)
- Architecture: `docs/prototype/architecture.md`
- Registry: `docs/data-model/prototypes.md`
- Living docs (during dev): `usr/<engineer>/docs/<name>/` (requirements, design, plan)
- Living docs (after promote): `docs/prototype/<name>/`
