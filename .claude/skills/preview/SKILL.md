---
description: Preview the current project using the configured infrastructure provider
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Preview

Launch a local or remote preview of the project using the configured infrastructure provider.

## Arguments

- $ARGUMENTS: Optional flags:
  - `--status` — check current preview status
  - `--stop` — stop running preview
  - `--logs` — show preview logs
  - (default) — start/update preview

## How to Execute

### Step 1: Resolve Provider

Read the preview provider from `claude/config/agency.yaml` under `preview.provider`.

```yaml
# agency.yaml
preview:
  provider: "docker-compose"  # or "fly", "vercel", "cloudflare"
```

The provider maps to a tool: `./claude/tools/preview-{provider}`

### Step 2: Check Provider Tool Exists

Verify `./claude/tools/preview-{provider}` exists and is executable. If not:
- List available preview tools: `ls ./claude/tools/preview-*`
- Tell the user which providers are available
- Suggest adding the provider tool if none exist

### Step 3: Dispatch to Provider

Execute: `./claude/tools/preview-{provider} {verb} {args}`

Where verb is one of: `start`, `stop`, `status`, `logs` (mapped from flags above, default: `start`).

### Step 4: Report

Show the user:
- Preview URL (if started)
- Status (running, stopped, error)
- Any relevant logs or errors

## Provider Contract

Each `preview-{provider}` tool must support these verbs:
- `start` — launch preview, print URL to stdout
- `stop` — tear down preview
- `status` — print current state (running/stopped/error)
- `logs` — stream or print recent logs

## Error Handling

- If no provider configured in agency.yaml, suggest adding the `preview` section
- If provider tool missing, list available alternatives
- If provider command fails, show stderr and suggest troubleshooting
