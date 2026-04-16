---
allowed-tools: Read, Glob, Grep, Bash(flyctl *), Bash(fly *), Bash(vercel *), Bash(git rev-parse *), Bash(git config *), Bash(curl http://localhost:*)
description: Deploy to staging or production — status, rollback, logs, history
---

# Deploy

Deploy promoted code to staging or production environments.

## Arguments

- $ARGUMENTS: subcommand and optional args (e.g., `staging`, `production`, `status staging`, `rollback staging`)

## Subcommands

| Subcommand          | What                                                    |
| ------------------- | ------------------------------------------------------- |
| `staging`           | Deploy current branch to staging                        |
| `production`        | Deploy to production (requires confirmation)            |
| `status [tier]`     | Show current deploy: SHA, uptime, health, cost          |
| `rollback [tier]`   | Rollback to previous release (production needs confirm) |
| `logs [tier] [svc]` | Tail logs from staging or production                    |
| `history [tier]`    | Recent deploys: SHA, timestamp, who, status             |

## Instructions

### Parse subcommand

Split `$ARGUMENTS` into the first word (subcommand) and the rest (args).

If `$ARGUMENTS` is empty, show the subcommand table above and ask which one to run.

### Important: This is the end of the developer journey

`/deploy` is the destination of the prototype → preview → deploy flow:

1. `/prototype create` — define and build
2. `/preview local` — validate locally
3. `/preview dev` — share with team
4. `/prototype promote` — create PR, merge to main
5. `/deploy staging` — deploy to staging
6. `/deploy production` — deploy to production

Only promoted and merged code should be deployed. If the user is on a `proto/*` branch, suggest they run `/prototype promote` first.

### Subcommand: `staging`

**Status: Not yet implemented** — blocked on Fly.io account setup (Phase 4).

When implemented, this will:

1. Verify current branch is `master` or a release branch
2. Build production Docker image
3. Deploy to `folio-api-staging` on Fly.io
4. Deploy frontend to Vercel staging
5. Run health checks
6. Report URLs and cost

For now, print:

> Staging deploy is not yet available. Fly.io account setup (Phase 4) is pending.
> See the deployment plan: `docs/plans/20260322-deployment-infrastructure.md`

### Subcommand: `production`

**Status: Not yet implemented** — blocked on Fly.io account setup (Phase 4).

When implemented, this will:

1. Require explicit confirmation: "Deploy to PRODUCTION? Type 'yes' to confirm."
2. Verify deploying from `master`
3. Use rolling deploy strategy
4. Run health checks post-deploy
5. Report URLs, cost, and previous version for rollback reference

For now, print the same pending message as staging.

### Subcommand: `status [tier]`

**Status: Not yet implemented.**

When implemented: show current deploy SHA, uptime, health endpoint result, cost/hr, monthly estimate.

For now, print pending message.

### Subcommand: `rollback [tier]`

**Status: Not yet implemented.**

When implemented: rollback to previous Fly.io release. Production requires confirmation.

For now, print pending message.

### Subcommand: `logs [tier] [service]`

**Status: Not yet implemented.**

When implemented: tail logs from Fly.io or Vercel.

For now, print pending message.

### Subcommand: `history [tier]`

**Status: Not yet implemented.**

When implemented: show recent deploys with SHA, timestamp, deployer, status.

For now, print pending message.

### Error handling

If the subcommand is not recognized, show the subcommand table and ask the user to pick one.

If on a prototype branch, suggest the correct next step:

> You're on branch `proto/<name>`. To deploy, first promote with `/prototype promote <name>`, merge the PR, then `/deploy staging`.
