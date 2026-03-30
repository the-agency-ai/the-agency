# Secret Management

Manage secrets through the configured provider.

## Usage

```
/secret <verb> [args...]
```

## Verbs

| Verb | Description | Example |
|------|-------------|---------|
| `set <name> [value]` | Store a secret (prompts if value omitted) | `/secret set api-key` |
| `get <name>` | Retrieve a secret | `/secret get api-key` |
| `list` | List all secrets | `/secret list` |
| `delete <name>` | Remove a secret | `/secret delete api-key` |
| `rotate <name>` | Rotate a secret (get current → set new) | `/secret rotate api-key` |
| `scan` | Scan codebase for leaked secrets | `/secret scan` |

## How to Execute

1. Read the secrets provider from `claude/config/agency.yaml` under `secrets.provider`
2. Determine the provider tool:
   - `vault` → `./tools/secret-vault`
   - `doppler` → `./tools/secret-doppler`
   - Pattern: `./tools/secret-{provider}`
3. Map the verb to the provider's command:
   - For **vault** provider: `set` maps to `create`, all others pass through directly
   - For **doppler** provider: all verbs pass through directly
4. Execute: `./tools/secret-{provider} {mapped-verb} {args}`

## Provider Detection

Read the provider with:
```bash
source "$CLAUDE_PROJECT_DIR/claude/tools/lib/_provider-resolve"
TOOL=$(resolve_provider "secrets")
```

Or simply check `claude/config/agency.yaml`:
```yaml
secrets:
  provider: "vault"  # or "doppler"
```

## Error Handling

- If the provider tool doesn't exist, tell the user which providers are available
- If the verb isn't supported by the provider, show the provider's help
- If no provider is configured, default to `vault`
