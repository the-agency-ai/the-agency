# Secrets Management

**CRITICAL: All secrets MUST be stored in the Secret Service. NEVER commit secrets to the codebase.**

The Agency provides a secure Secret Service for managing API keys, tokens, certificates, and other sensitive data.

## Quick Reference

### Most Common Operations

```bash
# Retrieve a secret (for use in scripts/tools)
./tools/secret get secret-name

# Store a new secret
./tools/secret create my-secret --type=api_key --service=GitHub

# List available secrets
./tools/secret list

# Unlock the vault (if locked)
./tools/secret vault unlock
```

## Vault Management

The vault protects all secrets with a master passphrase using Argon2id key derivation and AES-256-GCM encryption.

### Initialization (First Time)

```bash
./tools/secret vault init
```

You'll be prompted to create a master passphrase. This passphrase encrypts all secrets in the vault.

### Unlocking the Vault

```bash
./tools/secret vault unlock    # Unlock for session (30-min timeout)
./tools/secret vault lock      # Lock vault immediately
./tools/secret vault status    # Check vault status
```

The vault automatically locks after 30 minutes of inactivity for security.

### Session Tokens

When you launch an agent via `./tools/myclaude`, a session token is generated automatically if the vault is unlocked. This keeps the vault accessible during your Claude Code session without repeated unlocking.

## Creating Secrets

### Basic Usage

```bash
./tools/secret create secret-name --type=TYPE --service=SERVICE
```

You'll be prompted to enter the secret value securely (input is hidden).

### Secret Types

- `api_key` - API keys (Anthropic, OpenAI, GitHub, etc.)
- `token` - Access tokens (OAuth, PAT, etc.)
- `password` - Passwords
- `certificate` - SSL/TLS certificates
- `ssh_key` - SSH private keys
- `generic` - Other sensitive data

### With Description

```bash
./tools/secret create api-key \
  --type=api_key \
  --service=Anthropic \
  --description="Claude API key for production"
```

### From File

```bash
./tools/secret create cert --type=certificate --service=AWS --file=./cert.pem
```

## Retrieving Secrets

### Get Secret Value

```bash
./tools/secret get secret-name
```

**NOTE:** This operation is logged in the audit log for security tracking.

### Show Metadata Only

```bash
./tools/secret show secret-name
```

Shows metadata (type, service, description) without revealing the secret value. Not logged.

### List Secrets

```bash
./tools/secret list                      # List all secrets
./tools/secret list --service=GitHub     # Filter by service
./tools/secret list --type=api_key       # Filter by type
```

## Integration with Tools

### Tagging for Tool Use

Tag secrets for use by specific tools:

```bash
# Tag for GitHub CLI
./tools/secret tag github-token --tool=gh

# Tag for local Agency tool
./tools/secret tag my-secret --local-tool=./tools/myclaude

# Find secrets by tag
./tools/secret list --tool=gh
```

### Environment Variables

Export secrets as environment variables for scripts:

```bash
# Export for current shell
eval $(./tools/secret env my-token MY_TOKEN)
# Results in: export MY_TOKEN=<secret-value>

# Use in scripts
MY_TOKEN=$(./tools/secret get my-token)
```

## Access Control

### Granting Access

Share secrets with specific agents or principals:

```bash
# Grant read access to an agent
./tools/secret grant my-secret --to=agent:housekeeping --permission=read

# Grant admin access to a principal
./tools/secret grant my-secret --to=principal:jordan --permission=admin
```

**Permission Levels:**
- `read` - Can retrieve secret value
- `write` - Can update secret value
- `admin` - Can grant/revoke access, delete secret

### Revoking Access

```bash
./tools/secret revoke my-secret --from=agent:housekeeping
```

### Listing Grants

```bash
./tools/secret grants my-secret
```

## Audit Logging

All secret access is logged for security compliance.

### View Access Logs

```bash
# View access log for a specific secret
./tools/secret audit my-token

# View all access logs
./tools/secret audit --all

# Filter by date range
./tools/secret audit --since=2026-01-01
./tools/secret audit --since=2026-01-01 --until=2026-01-31
```

**Logged Operations:**
- `get` - Secret value retrieved
- `create` - Secret created
- `update` - Secret value changed
- `delete` - Secret removed
- `grant` - Access granted
- `revoke` - Access revoked

**Not Logged:**
- `show` - Metadata only (no secret value exposed)
- `list` - List operations
- `vault` operations (lock, unlock, status)

## Migration from .env Files

If you have existing secrets in `.env` files:

```bash
# Preview what will be migrated
./tools/secret-migrate --dry-run

# Run the migration
./tools/secret-migrate

# Verify migration
./tools/secret list
```

**IMPORTANT:** After migration, remove the `.env` file and ensure it's in `.gitignore`.

## Service Configuration

The Secret Service runs as part of `agency-service` on port 3141.

### Starting the Service

```bash
cd services/agency-service
bun run dev
```

### Environment Variables

```bash
SECRET_SERVICE_URL=http://localhost:3141/api/secret
AGENCY_USER=principal:jordan  # or agent:housekeeping
```

### Service Requirements

- **Bun runtime** (for agency-service)
- **SQLite** (built into Bun, no separate install needed)
- **Port 3141** (default, configurable)

## Security Model

### Encryption

- **Algorithm:** AES-256-GCM (Galois/Counter Mode)
- **Key Derivation:** Argon2id (memory-hard, side-channel resistant)
- **Salt:** Unique per-vault, stored with encrypted secrets
- **IV/Nonce:** Unique per-secret, stored with ciphertext

### Master Passphrase

- Used only for key derivation (never stored)
- Minimum length: 12 characters (recommended: 20+)
- Should be unique and not reused from other systems
- Lost passphrase = permanent data loss (no recovery mechanism)

### Session Tokens

- Generated per Claude Code session
- Expire after 30 minutes of inactivity
- Stored only in memory (not persisted)
- Automatically invalidated on session end

### Audit Trail

- All secret access is logged with timestamp, actor, and operation
- Logs are append-only (cannot be modified after creation)
- Stored in SQLite database at `services/agency-service/data/secrets.db`

## Best Practices

### Do:
- ✓ Use descriptive names (`github-pat-production`, not `token1`)
- ✓ Add service and description metadata
- ✓ Rotate secrets regularly
- ✓ Grant minimal necessary permissions
- ✓ Review audit logs periodically
- ✓ Use strong, unique master passphrase

### Don't:
- ✗ Commit secrets to git (ever)
- ✗ Share secrets via Slack/email
- ✗ Use `.env` files for secrets
- ✗ Grant broad access (`admin` to everyone)
- ✗ Reuse master passphrase from other systems
- ✗ Store secrets in Claude Code settings files

## Troubleshooting

### Vault Locked

**Error:** "Vault is locked"

**Solution:**
```bash
./tools/secret vault unlock
```

### Vault Uninitialized

**Error:** "Vault not initialized"

**Solution:**
```bash
./tools/secret vault init
```

### Service Not Running

**Error:** "Connection refused" or "ECONNREFUSED"

**Solution:**
```bash
cd services/agency-service
bun run dev
```

### Permission Denied

**Error:** "Permission denied for secret: xyz"

**Solution:**
- Verify you have access via `./tools/secret grants xyz`
- Request access from secret owner
- Check `AGENCY_USER` environment variable is set correctly

### Forgotten Master Passphrase

**Recovery:** None. The vault uses encryption with no backdoor. If you forget the master passphrase, all secrets are permanently lost.

**Prevention:**
- Store master passphrase in a password manager
- Consider using enterprise secret management (HashiCorp Vault, AWS Secrets Manager) for critical environments

## Migration Path

For teams transitioning from `.env` files or other secret management:

1. **Audit existing secrets:** Identify all secrets in `.env`, config files, scripts
2. **Initialize vault:** `./tools/secret vault init`
3. **Migrate secrets:** `./tools/secret-migrate` or manually create
4. **Update tools:** Replace hardcoded secrets with `./tools/secret get`
5. **Remove old files:** Delete `.env` files, add to `.gitignore`
6. **Verify:** Test all tools/scripts work with new secret retrieval
7. **Document:** Update team docs with new secret management process

## API Reference

The Secret Service provides a REST API (used by `./tools/secret`):

```
POST   /api/secret/create      # Create secret
GET    /api/secret/list        # List secrets
GET    /api/secret/get/:id     # Get secret value
POST   /api/secret/update/:id  # Update secret
POST   /api/secret/delete/:id  # Delete secret
GET    /api/secret/show/:id    # Get metadata only
POST   /api/secret/grant       # Grant access
POST   /api/secret/revoke      # Revoke access
GET    /api/secret/grants/:id  # List grants
GET    /api/secret/audit       # Audit logs
POST   /api/secret/vault/init  # Initialize vault
POST   /api/secret/vault/unlock # Unlock vault
POST   /api/secret/vault/lock  # Lock vault
GET    /api/secret/vault/status # Vault status
```

For programmatic access, use the provided `./tools/secret` CLI rather than calling the API directly.

## Related Documentation

- `CLAUDE.md` - Essential commands for agents
- `claude/docs/PERMISSIONS.md` - How to grant tool permissions
- `services/agency-service/README.md` - Service architecture
