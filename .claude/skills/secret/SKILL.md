---
description: Secret Management — set, get, list, delete, rotate, scan via configured provider
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Secret Management

Manage secrets through the configured provider (SPEC-PROVIDER pattern). Generic skill that dispatches to a provider tool based on `claude/config/agency.yaml`.

## Arguments

- `$ARGUMENTS`: One of:
  - `set <name> [value]` — store a secret (prompts if value omitted)
  - `get <name>` — retrieve a secret
  - `list` — list all secrets
  - `delete <name>` — remove a secret
  - `rotate <name>` — rotate a secret (get current → set new)
  - `scan` — scan codebase for leaked secrets

## Instructions

### Step 1: Resolve the provider

Read `claude/config/agency.yaml` for the secrets provider:

```yaml
secrets:
  provider: "vault"  # or "aws", "1password", etc.
```

The provider maps to a tool: `./claude/tools/secret-{provider}`

If no provider is configured, default to `vault`.

### Step 2: Verify the provider tool exists

Check `./claude/tools/secret-{provider}` exists and is executable. If not:
- List available provider tools: list files matching `./claude/tools/secret-*`
- Tell the user which providers are available
- Suggest configuring a different provider in `agency.yaml`

### Step 3: Map verbs to provider commands

Different providers use different verbs:

- **vault provider** (`./claude/tools/secret-vault`):
  - `set` → maps to `create`
  - `get`, `list`, `delete`, `rotate` pass through directly
- **other providers** (`./claude/tools/secret-{provider}`):
  - all verbs pass through directly
- **scan verb** (any provider): use `./claude/tools/secrets-scan` directly

### Step 4: Execute

Run the provider tool with the mapped verb:

```bash
./claude/tools/secret-vault create api-key
./claude/tools/secret-{provider} get database-url
./claude/tools/secrets-scan
```

**Use relative paths** — never `$CLAUDE_PROJECT_DIR/claude/tools/...` (the env var is empty in agent Bash calls).

### Step 5: Report

Show the user the result. Never echo secret values to the conversation — pipe them to the appropriate destination (env file, clipboard, etc.) or confirm completion without revealing the value.

## Error Handling

- **No provider configured:** default to `vault`, warn the user they should set `secrets.provider` in `agency.yaml`
- **Provider tool missing:** list `./claude/tools/secret-*` files, suggest alternatives
- **Verb not supported:** show the provider's `--help` output
- **Secret not found:** clear error message, do not invent values

## Security Rules

- **Never log secret values** to conversation, transcripts, or telemetry
- **Never commit secret values** to git
- **Never write secrets to a file in the project** unless it's already in `.gitignore`
- **Use the provider's own audit log** if it has one — don't roll your own

## SPEC-PROVIDER Pattern

This skill is one of several using the SPEC-PROVIDER pattern (see `claude/README-THEAGENCY.md` SPEC-PROVIDER section). The skill is generic; the provider implements the contract. Add new providers by creating `./claude/tools/secret-{name}` that supports the standard verbs.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
