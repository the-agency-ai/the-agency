---
allowed-tools: Read, Glob, Grep, Bash(pnpm prototype:*), Bash(docker-compose *), Bash(docker *), Bash(curl http://localhost:*), Bash(git rev-parse *), Bash(git config *), Bash(doppler run -- *)
description: Prototype lifecycle management — create, build, run, inspect, promote, archive
---

# Prototype

Manage prototype lifecycle — from creation through promotion or archival.

## Arguments

- $ARGUMENTS: subcommand and args (e.g., `up checkout-v2`, `list`, `create my-proto`)

## Subcommands

| Subcommand                        | What                                                       |
| --------------------------------- | ---------------------------------------------------------- |
| `create <name>`                   | Scaffold a new prototype (BE module, Prisma, FE, worktree) |
| `up <name>`                       | Start Docker dev stack                                     |
| `down <name>`                     | Stop Docker dev stack, clean up .env.local                 |
| `list`                            | Show active prototypes with status                         |
| `ps`                              | List running Docker stacks with ports                      |
| `logs <name> [service]`           | Tail Docker container logs                                 |
| `health <name>`                   | Health check (manifest, worktree, containers, DB)          |
| `reset <name>`                    | Full reset (containers, DB, manifest, worktree)            |
| `build <name> [fe\|be\|both]`     | Register a build in the manifest                           |
| `preview <name>`                  | Run checks, push branch for remote preview deploy          |
| `promote <name>`                  | Run checks, squash-merge, create promotion PR              |
| `merge <sources> --into <target>` | Run checks, combine prototypes                             |
| `archive <name>`                  | Wipe data, remove code, clean up worktree/branch           |
| `help`                            | Show full reference table                                  |

## Instructions

### Parse subcommand

Split `$ARGUMENTS` into the first word (subcommand) and the rest (args).

If `$ARGUMENTS` is empty, show the subcommand table above and ask which one to run.

### Dispatch

Each subcommand maps to an existing `/prototype-{subcommand}` command or `pnpm prototype:{subcommand}` script. Dispatch accordingly:

| Subcommand              | Dispatch to                                                 |
| ----------------------- | ----------------------------------------------------------- |
| `create <name>`         | Run `/prototype-create <name>` skill                        |
| `up <name>`             | Run `pnpm prototype:up <name>`                              |
| `down <name>`           | Run `pnpm prototype:down <name>`                            |
| `list`                  | Run `/prototype-list` skill                                 |
| `ps`                    | Run `pnpm prototype:ps`                                     |
| `logs <name> [service]` | Run `pnpm prototype:logs <name> [service]`                  |
| `health <name>`         | Run `pnpm prototype:health <name>` (needs `doppler run --`) |
| `reset <name>`          | Run `pnpm prototype:reset <name>` (needs `doppler run --`)  |
| `build <name> [target]` | Run `pnpm prototype:build <name> [target]`                  |
| `preview <name>`        | Run `/prototype-preview <name>` skill                       |
| `promote <name>`        | Run `/prototype-promote <name>` skill                       |
| `merge <args>`          | Run `/prototype-merge <args>` skill                         |
| `archive <name>`        | Run `/prototype-archive <name>` skill                       |
| `help`                  | Run `/prototype-help` skill                                 |

### Error handling

If the subcommand is not recognized, show the subcommand table and ask the user to pick one.

If a script fails, show the error and suggest:

- `up` failures: "Is Docker running? Try `docker info`"
- `health` failures: "Needs Doppler. Try `doppler run -- pnpm prototype:health <name>`"
- `create` failures: "Does the prototype name already exist? Check `docs/data-model/prototypes.md`"
