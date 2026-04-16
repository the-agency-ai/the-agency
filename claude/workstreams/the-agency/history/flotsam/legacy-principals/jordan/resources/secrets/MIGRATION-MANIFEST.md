# Secret Migration Manifest

**Created:** 2026-01-11
**For:** REQUEST-jordan-0029

This manifest documents all existing secrets that need to be migrated to the Secret Service.
**The original .env files will be preserved as backup.**

## Migration Strategy

1. **Non-destructive**: Original .env files are NEVER deleted
2. **Verify first**: Each secret is verified in vault before marking complete
3. **Rollback ready**: If vault has issues, original files remain usable

## Existing Secrets Inventory

### GitHub (`github.env`)

| Variable | Type | Service | Description | Expires |
|----------|------|---------|-------------|---------|
| AGENCY_TOKEN_WORKSHOP | token | GitHub | Read-only access to the-agency-ai/the-agency-starter | 2026-01-12 |
| AGENCY_TOKEN_ADMIN | token | GitHub | Full access to the-agency-ai org | Never |

### Discord (`discord.env`)

| Variable | Type | Service | Description | Expires |
|----------|------|---------|-------------|---------|
| DISCORD_CLIENT_ID | generic | Discord | OAuth2 Client ID (not secret) | Never |
| DISCORD_CLIENT_SECRET | token | Discord | OAuth2 Client Secret | Never |
| DISCORD_BOT_TOKEN | token | Discord | Bot authentication token | Never |

### Gumroad (`gumroad.env`)

| Variable | Type | Service | Description | Expires |
|----------|------|---------|-------------|---------|
| GUMROAD_APP_ID | generic | Gumroad | Application ID (not secret) | Never |
| GUMROAD_APP_SECRET | token | Gumroad | Application secret | Never |
| GUMROAD_ACCESS_TOKEN | token | Gumroad | API access token | Never |

## Migration Commands

```bash
# 1. Initialize vault (if not done)
./tools/secret vault init

# 2. Unlock vault
./tools/secret vault unlock

# 3. Migrate GitHub secrets
./tools/secret create agency-token-workshop --type=token --service=GitHub \
  --description="Read-only access to the-agency-starter (expires 2026-01-12)"
./tools/secret create agency-token-admin --type=token --service=GitHub \
  --description="Full admin access to the-agency-ai org"

# 4. Migrate Discord secrets
./tools/secret create discord-client-secret --type=token --service=Discord \
  --description="OAuth2 Client Secret"
./tools/secret create discord-bot-token --type=token --service=Discord \
  --description="Bot authentication token"

# 5. Migrate Gumroad secrets
./tools/secret create gumroad-app-secret --type=token --service=Gumroad \
  --description="Application secret"
./tools/secret create gumroad-access-token --type=token --service=Gumroad \
  --description="API access token"

# 6. Tag for tools
./tools/secret tag agency-token-admin --tool=gh
./tools/secret tag discord-bot-token --tool=discord

# 7. Verify migration
./tools/secret list --service=GitHub
./tools/secret list --service=Discord
./tools/secret list --service=Gumroad
```

## Post-Migration

After verifying all secrets in the vault:

1. Update tools to read from vault instead of .env files
2. Keep .env files as backup (do NOT delete)
3. Add .env files to `.gitignore` if not already

## Rollback

If vault migration fails:

1. Original .env files remain in place
2. Tools continue reading from .env files
3. No data loss occurs

## Status

| Secret | Migrated | Verified | Tool Updated |
|--------|----------|----------|--------------|
| agency-token-workshop | [ ] | [ ] | [ ] |
| agency-token-admin | [ ] | [ ] | [ ] |
| discord-client-secret | [ ] | [ ] | [ ] |
| discord-bot-token | [ ] | [ ] | [ ] |
| gumroad-app-secret | [ ] | [ ] | [ ] |
| gumroom-access-token | [ ] | [ ] | [ ] |
