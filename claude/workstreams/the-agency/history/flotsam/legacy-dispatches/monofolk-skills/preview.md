---
allowed-tools: Read, Glob, Grep, Bash(pnpm preview:*), Bash(docker-compose *), Bash(docker *), Bash(curl http://localhost:*), Bash(git rev-parse *), Bash(git config *)
description: Preview environment management — local Docker stack, cloud deploys, status, teardown
---

# Preview

Manage preview environments for the current branch/worktree.

## Arguments

- $ARGUMENTS: subcommand and optional args (e.g., `local`, `dev my-feature`, `down auth-flow`, `list`)

## Subcommands

| Subcommand          | What                                                       |
| ------------------- | ---------------------------------------------------------- |
| `local [name]`      | Start local Docker stack. Name defaults to current branch. |
| `dev [name]`        | Deploy to cloud (Fly + Vercel). Name defaults to branch.   |
| `list [flavor]`     | Show all previews. Optional: dev, pr, agent, local.        |
| `status <name>`     | Detailed view: services, cost, health, URLs.               |
| `down <name>`       | Tear down a preview (local or cloud).                      |
| `logs <name> [svc]` | Tail logs. Optional service filter.                        |

Future subcommands (not yet implemented): `pr`, `agent`.

## Instructions

### Parse subcommand

Split `$ARGUMENTS` into the first word (subcommand) and the rest (args).

If `$ARGUMENTS` is empty, show the subcommand table above and ask which one to run.

### Subcommand: `local [name]`

Run `pnpm preview:local [name]`.

If on a `proto/*` branch, the script auto-detects the prototype name — no argument needed.

After the stack starts, suggest:

> Wait ~30s for containers to warm up, then verify with `curl http://localhost:{backendPort}/health`

The script prints next-step breadcrumbs automatically (e.g., `/preview dev` to share, `/prototype promote` to ship).

### Subcommand: `dev [name]`

Run `pnpm preview:dev [name]`.

This deploys to Fly.io (backend) and Vercel (frontends). Requires:

- `flyctl auth login` (check with `flyctl auth whoami`)
- `vercel login` (check with `vercel whoami`)
- Fly.io credit card on file

After deploy, show the URLs and cost estimate from the output.

### Subcommand: `list [flavor]`

Run `pnpm preview:list [flavor]`.

Shows both local (Docker) and cloud (Fly + Vercel) previews with URLs, status, and age.

### Subcommand: `status <name>`

Run `pnpm preview:status <name>`.

Shows detailed per-service status including health, cost/hr, and monthly estimate.

### Subcommand: `down <name>`

Detect whether this is a local or cloud preview:

- If `name` matches a local preview (in `tools/.ports.json`): run `pnpm preview:local:down <name>`
- If `name` matches a cloud preview (in `.preview-registry.json`): run `pnpm preview:dev:down <name>`
- If both: ask which one to tear down

### Subcommand: `logs <name> [service]`

Run `pnpm preview:logs <name> [service]`.

### Error handling

If a command fails, show the error output and suggest troubleshooting:

- Local failures: "Is Docker running?" / "Are ports in use?"
- Cloud failures: "Is flyctl authenticated?" / "Is Fly credit card added?"
- Not found: "Check `pnpm preview:list` to see active previews"
