---
description: Deploy the project using the configured platform provider
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Deploy

Deploy the project to the configured platform.

## Arguments

- $ARGUMENTS: Optional flags:
  - `--status` — check deployment status
  - `--rollback` — rollback to previous deployment
  - `--logs` — show deployment logs
  - `--env <name>` — target environment (default: staging)
  - (default) — deploy current branch

## How to Execute

### Step 1: Resolve Provider

Read the deploy provider from `claude/config/agency.yaml` under `deploy.provider`.

```yaml
# agency.yaml
deploy:
  provider: "fly"  # or "aws", "vercel", "cloudflare", "railway"
```

The provider maps to a tool: `./claude/tools/deploy-{provider}`

### Step 2: Check Provider Tool Exists

Verify `./claude/tools/deploy-{provider}` exists and is executable. If not:
- List available deploy tools: `ls ./claude/tools/deploy-*`
- Tell the user which providers are available
- Suggest adding the provider tool if none exist

### Step 3: Pre-Deploy Checks

Before deploying:
1. Verify working tree is clean (`git status --porcelain`)
2. Confirm the target environment with the user
3. Show what will be deployed (current branch, latest commit)

### Step 4: Dispatch to Provider

Execute: `./claude/tools/deploy-{provider} {verb} {args}`

Where verb is one of: `deploy`, `status`, `rollback`, `logs` (mapped from flags above, default: `deploy`).

Pass `--env` value if specified.

### Step 5: Report

Show the user:
- Deployment URL
- Status (success, in-progress, failed)
- Any post-deploy verification results

## Provider Contract

Each `deploy-{provider}` tool must support these verbs:
- `deploy [--env <name>]` — deploy, print URL to stdout
- `status [--env <name>]` — print deployment state
- `rollback [--env <name>]` — revert to previous deployment
- `logs [--env <name>]` — show deployment logs

## Error Handling

- If no provider configured in agency.yaml, suggest adding the `deploy` section
- If provider tool missing, list available alternatives
- If deploy fails, show stderr, suggest rollback if available
- Always confirm with user before deploying to production
