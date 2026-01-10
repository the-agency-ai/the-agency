# Test Plan: Secret Service & Log Service

## Prerequisites

1. Start agency-service:
```bash
cd services/agency-service && bun run dev
```

2. Start AgencyBench:
```bash
cd the-agency-starter/apps/agency-bench && bun run dev
```

---

## Part 1: Secret Service Tests

### 1.1 CLI - Vault Operations

```bash
# Check vault status (should be uninitialized)
./tools/secret vault status

# Initialize vault
./tools/secret vault init
# Enter passphrase twice, save recovery codes!

# Lock vault
./tools/secret vault lock

# Check status (should be locked)
./tools/secret vault status

# Unlock vault
./tools/secret vault unlock
```

**Expected:** Vault initializes, locks, unlocks correctly

### 1.2 CLI - Secret CRUD

```bash
# Create a test secret
./tools/secret create test-api-key --type=api_key --service=TestService --description="Test secret"
# Enter value when prompted

# List secrets
./tools/secret list

# Show metadata only
./tools/secret show test-api-key

# Get decrypted value
./tools/secret get test-api-key

# Update metadata
./tools/secret update test-api-key --description="Updated description"

# Rotate value
./tools/secret rotate test-api-key

# Delete
./tools/secret delete test-api-key
```

**Expected:** All CRUD operations work, values encrypted/decrypted correctly

### 1.3 Secret Migration

```bash
# Dry run first
./tools/migrate-secrets --dry-run

# Run migration
./tools/migrate-secrets

# Verify secrets copied
./tools/secret list
./tools/secret show github-admin-token
./tools/secret show discord-bot-token
./tools/secret show gumroad-access-token
```

**Expected:** 8 secrets migrated (2 GitHub, 3 Discord, 3 Gumroad)

### 1.4 AgencyBench - Secrets Page

1. Navigate to http://localhost:3000/bench/secrets
2. **Vault Status:** Should show locked/unlocked indicator
3. **Unlock:** Click unlock, enter passphrase
4. **Secret List:** Should show migrated secrets
5. **Create Secret:** Click create, fill form, submit
6. **View Details:** Click a secret to see detail panel
7. **Reveal Value:** Click reveal, confirm audit warning
8. **Grants:** Add a grant (e.g., agent:housekeeping, read)
9. **Audit Log:** Check audit tab shows access history

**Expected:** All UI operations work, match CLI behavior

---

## Part 2: Log Service Tests

### 2.1 CLI - Query Logs

```bash
# Recent logs
./tools/log

# Filter by level
./tools/log --level error
./tools/log --level warn

# Filter by service
./tools/log --service secret-service

# Time range
./tools/log --since 1h

# Search
./tools/log --search "vault"

# Stats
./tools/log stats

# List services
./tools/log services
```

**Expected:** Logs display with colors, filters work

### 2.2 CLI - Tool Run Tracking

```bash
# Start a run
RUN_ID=$(./tools/log run start "test-tool" --type=agency-tool --agent=housekeeping)
echo "Run ID: $RUN_ID"

# End the run
./tools/log run end "$RUN_ID" --status=success --exit-code=0 --output-size=1234

# Get run details
./tools/log run get "$RUN_ID"

# Get run errors (should be empty)
./tools/log run errors "$RUN_ID"
```

**Expected:** Run tracking works, details include new REQUEST-0012 fields

### 2.3 AgencyBench - Logs Page

1. Navigate to http://localhost:3000/bench/logs
2. **Log List:** Should show recent logs
3. **Filters:** Try level, service, time range filters
4. **Search:** Search for "secret" or "vault"
5. **Live Mode:** Toggle live/paused, verify polling
6. **Log Detail:** Click a log to see full details
7. **Run ID:** Logs with runId should show correlation

**Expected:** All UI operations work, real-time updates

### 2.4 Tool Logging Integration

```bash
# Enable logging
export LOG_SERVICE_URL=http://localhost:3456/api/log

# Run a tracked tool
./tools/tag test-item impl --dry-run

# Check logs for the run
./tools/log --search "tag"
./tools/log --since 5m

# Run myclaude (briefly)
./tools/myclaude housekeeping housekeeping "test" &
sleep 2
kill %1

# Check agent launch logged
./tools/log --search "myclaude"
```

**Expected:** Tool invocations appear in logs with toolType, args, agentName

---

## Part 3: Integration Tests

### 3.1 Cross-Service

```bash
# Create a secret and check audit log appears in log service
./tools/secret create integration-test --type=generic
./tools/secret get integration-test
./tools/log --search "integration-test"
```

**Expected:** Secret operations logged to log service

### 3.2 Auto-Lock

```bash
# Unlock vault
./tools/secret vault unlock

# Wait 31 minutes (or change AUTO_LOCK_TIMEOUT_MS for testing)
# Check vault locks automatically
./tools/secret vault status
```

**Expected:** Vault auto-locks after 30 minutes

---

## Cleanup

```bash
# Delete test secrets
./tools/secret delete test-api-key
./tools/secret delete integration-test

# Keep migrated secrets for production use
```

---

## Success Criteria

- [ ] Vault init/lock/unlock works via CLI and UI
- [ ] Secret CRUD works via CLI and UI
- [ ] Migration copies all 8 secrets
- [ ] Audit logging captures all accesses
- [ ] Log query/filter works via CLI and UI
- [ ] Tool run tracking captures REQUEST-0012 fields
- [ ] Tool logging integration works for myclaude, tag, commit, sync, collaborate
- [ ] AgencyBench pages render and function correctly
