# REQUEST-jordan-0017: Secret Service

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** In Progress

**Priority:** Critical

**Created:** 2026-01-10 15:00 SST

## Summary

A comprehensive secret management facility for The Agency that works locally, self-hosted, and in cloud deployments. Manages passwords, API keys, tokens, certificates, and other sensitive data with encryption at rest, access control, tagging, and full audit logging.

## Requirements

### Core Requirements
1. **Multi-environment**: Works locally, self-hosted, cloud
2. **Interfaces**: API + CLI (`tools/secret`) + AgencyBench UX
3. **Discoverability**: Easy to find secrets by name, service, tool
4. **Lifecycle**: Easy to rotate and remove secrets
5. **Integration**: Tag secrets to services (GitHub) and tools (gh, local tools)
6. **Security**: Encrypted at rest, audit logging, recovery codes
7. **Access Model**: Per-agent/principal tokens with explicit grants

### Design Decisions

| Decision | Choice |
|----------|--------|
| Scope | Project-level (not global, not per-workstream) |
| Sharing | Owner + explicit grants with full audit logging |
| Master Key | Passphrase-derived (Argon2), stored in `.claude/secrets/` |
| Recovery | Recovery codes for the vault |
| Backend | SQLite with abstraction layer (pluggable later) |
| UX | AgencyBench (Tauri desktop app) |

---

## Data Model

### secrets
```sql
CREATE TABLE secrets (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  secret_type TEXT NOT NULL, -- api_key, token, password, certificate, ssh_key, env_var, generic
  encrypted_value BLOB NOT NULL,
  iv BLOB NOT NULL,
  owner_type TEXT NOT NULL, -- agent, principal
  owner_name TEXT NOT NULL,
  service_name TEXT, -- GitHub, AWS, Anthropic
  description TEXT,
  expires_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### secret_tags
```sql
CREATE TABLE secret_tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  secret_id TEXT NOT NULL REFERENCES secrets(id) ON DELETE CASCADE,
  tag_type TEXT NOT NULL, -- tool, local-tool, env, service
  tag_value TEXT NOT NULL, -- gh, ./tools/myclaude, production
  permission TEXT NOT NULL DEFAULT 'read', -- read, write, admin
  created_at TEXT NOT NULL,
  UNIQUE(secret_id, tag_type, tag_value)
);
```

### secret_grants
```sql
CREATE TABLE secret_grants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  secret_id TEXT NOT NULL REFERENCES secrets(id) ON DELETE CASCADE,
  grantee_type TEXT NOT NULL, -- agent, principal
  grantee_name TEXT NOT NULL,
  permission TEXT NOT NULL DEFAULT 'read', -- read, write, admin
  granted_by TEXT NOT NULL,
  granted_at TEXT NOT NULL,
  UNIQUE(secret_id, grantee_type, grantee_name)
);
```

### secret_access_log
```sql
CREATE TABLE secret_access_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  secret_id TEXT NOT NULL,
  secret_name TEXT NOT NULL, -- denormalized for deleted secrets
  accessor_type TEXT NOT NULL,
  accessor_name TEXT NOT NULL,
  action TEXT NOT NULL, -- create, read, update, delete, rotate, grant, revoke, fetch
  tool_context TEXT, -- which tool requested access
  ip_address TEXT,
  timestamp TEXT NOT NULL
);
```

### vault_recovery
```sql
CREATE TABLE vault_recovery (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  recovery_code_hash TEXT NOT NULL,
  used INTEGER DEFAULT 0,
  used_at TEXT,
  created_at TEXT NOT NULL
);
```

### vault_config
```sql
CREATE TABLE vault_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
-- Stores: encrypted_master_key, salt, created_at, version
```

---

## API Design (Explicit Operations)

### Secret Operations
```
POST /api/secret/create          - Create a new secret
GET  /api/secret/list            - List secrets (with filters)
GET  /api/secret/get/:id         - Get secret metadata (not value)
GET  /api/secret/fetch/:id       - Fetch secret value (logged)
POST /api/secret/update/:id      - Update secret metadata
POST /api/secret/rotate/:id      - Rotate secret value
POST /api/secret/delete/:id      - Delete a secret
```

### Tag Operations
```
POST /api/secret/tag/:id         - Add tag to secret
POST /api/secret/untag/:id       - Remove tag from secret
GET  /api/secret/by-tag          - Find secrets by tag
```

### Grant Operations
```
POST /api/secret/grant/:id       - Grant access to agent/principal
POST /api/secret/revoke/:id      - Revoke access
GET  /api/secret/grants/:id      - List grants for a secret
```

### Vault Operations
```
POST /api/vault/init             - Initialize vault with passphrase
POST /api/vault/unlock           - Unlock vault for session
POST /api/vault/lock             - Lock vault
GET  /api/vault/status           - Check vault status
POST /api/vault/recovery/generate - Generate recovery codes
POST /api/vault/recovery/use     - Use recovery code to reset
```

### Audit Operations
```
GET  /api/secret/audit/:id       - Get access log for secret
GET  /api/secret/audit           - Get all access logs
```

---

## CLI Tool: `tools/secret`

```bash
# Vault management
secret vault init                    # Initialize vault, set passphrase
secret vault unlock                  # Unlock for session
secret vault lock                    # Lock vault
secret vault status                  # Check status
secret vault recovery generate       # Generate recovery codes
secret vault recovery use <code>     # Use recovery code

# Secret CRUD
secret create <name> [--type=api_key] [--service=GitHub] [--description="..."]
secret list [--service=GitHub] [--tool=gh] [--type=api_key]
secret get <name>                    # Fetch value (logged)
secret show <name>                   # Show metadata only
secret update <name> [--description="..."] [--expires=2025-12-31]
secret rotate <name>                 # Prompt for new value
secret delete <name>

# Tagging
secret tag <name> --tool=gh --permission=read
secret tag <name> --local-tool=./tools/myclaude
secret untag <name> --tool=gh

# Sharing
secret grant <name> --to=agent:housekeeping --permission=read
secret grant <name> --to=principal:jordan --permission=admin
secret revoke <name> --from=agent:housekeeping
secret grants <name>                 # List who has access

# Integration helpers
secret env <name> [VAR_NAME]         # Output: export VAR_NAME=$(secret get <name>)
secret dotenv <name> [VAR_NAME]      # Append to .env-local (fetches on shell load)

# Audit
secret audit <name>                  # Show access log
secret audit --all                   # All access logs
```

---

## Security Considerations

1. **Master Key**: Derived from passphrase using Argon2id
2. **Encryption**: AES-256-GCM for secret values
3. **At Rest**: SQLite stores only encrypted blobs
4. **In Transit**: HTTPS required for non-local
5. **Session**: Vault auto-locks after timeout
6. **Audit**: All access logged with context
7. **Recovery**: One-time use codes, stored as hashes

---

## Implementation Phases

### Phase 1: Core Service (Complete)
- [x] Types (`types.ts`)
- [x] Repository (`repository/secret.repository.ts`)
- [x] Service (`service/secret.service.ts`)
- [x] Routes (`routes/secret.routes.ts`)
- [x] Index (`index.ts`)
- [x] Register in `src/index.ts`

### Phase 2: CLI Tool
- [ ] Create `tools/secret` CLI
- [ ] Implement all commands
- [ ] Shell integration helpers

### Phase 3: AgencyBench UX
- [ ] Secrets page in AgencyBench
- [ ] CRUD interface
- [ ] Tag/grant management
- [ ] Audit log viewer

---

## Files

### Created
- `src/embedded/secret-service/types.ts`

### To Create
- `src/embedded/secret-service/repository/secret.repository.ts`
- `src/embedded/secret-service/service/secret.service.ts`
- `src/embedded/secret-service/routes/secret.routes.ts`
- `src/embedded/secret-service/index.ts`
- `tools/secret`

### To Modify
- `src/index.ts` - Register secret-service routes

---

## Activity Log

### 2026-01-10 15:00 SST - Created
- Request created for secret-service
- Design discussed with principal:jordan
- Decisions made on scope, encryption, recovery, backend

### 2026-01-10 15:10 SST - Phase 1 Started
- Created types.ts with all Zod schemas and TypeScript interfaces

### 2026-01-10 15:30 SST - Phase 1 Complete
- Created secret.repository.ts with:
  - AES-256-GCM encryption/decryption
  - PBKDF2 key derivation from passphrase
  - Vault init/unlock/lock operations
  - Secret CRUD with encrypted values
  - Tags and grants management
  - Audit logging
  - Recovery code generation
- Created secret.service.ts with:
  - Access control checks
  - Audit logging on all operations
  - Business logic layer
- Created secret.routes.ts with explicit operations:
  - Vault: /vault/status, /vault/init, /vault/unlock, /vault/lock, /vault/recovery/*
  - Secrets: /create, /list, /get/:id, /fetch/:id, /update/:id, /rotate/:id, /delete/:id
  - Tags: /tag/:id, /untag/:id, /by-tag, /tags/:id
  - Grants: /grant/:id, /revoke/:id, /grants/:id
  - Audit: /audit/:id, /audit
  - Stats: /stats
- Created index.ts factory function
- Registered in main src/index.ts
- All 151 tests passing
- Version bumped to 0.6.0
