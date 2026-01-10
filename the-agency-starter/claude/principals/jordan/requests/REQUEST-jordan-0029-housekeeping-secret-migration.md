# REQUEST-jordan-0029: Migrate Secrets to Secret Service

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Pending

**Priority:** High

**Created:** 2026-01-10

## Summary

After SecretBench is complete, migrate existing secrets into the secret-service and start using it for all credential management.

## Background

We now have:
- `secret-service` embedded in agency-service with full API
- `SecretBench` UX page for managing secrets

We need to:
1. Populate the vault with our existing secrets
2. Update tools/agents to retrieve secrets from the service
3. Document the new workflow

## Scope

### Phase 1: Populate the Vault

Migrate these secrets to secret-service:
- GitHub tokens (for `gh` CLI)
- Anthropic API keys (for Claude Code)
- Any service API keys

### Phase 2: Update Tools

Update tools to retrieve secrets from secret-service:
- `./tools/myclaude` - get Anthropic API key from service
- `./tools/gh-*` - get GitHub token from service
- Shell integration (`secret env`, `secret dotenv`)

### Phase 3: Documentation

- Document how to add new secrets
- Document how to grant access to agents
- Document recovery process

## Acceptance Criteria

1. All existing secrets migrated to secret-service
2. Tools retrieve credentials from service instead of hardcoded/env vars
3. Audit log shows secret access
4. Recovery codes generated and stored securely

## Dependencies

- REQUEST-jordan-0011 (agency-service Phase 1) - Complete
- secret-service implementation - Complete
- SecretBench UX - Complete

## Notes

This is a high-priority item because it:
1. Centralizes credential management
2. Enables audit logging
3. Prepares us for multi-principal deployment
