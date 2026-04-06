#!/usr/bin/env bats
#
# What Problem: The _iscp-db library is the foundation for all ISCP tools.
# If DB init, parameter handling, version checks, or path sanitization break,
# every ISCP primitive breaks. These tests catch regressions early.
#
# How & Why: BATS tests following existing test_helper.bash patterns. Each test
# creates an isolated temp directory for DB files so tests don't interfere.
# Tests cover: DB init (fresh + idempotent), schema creation (all 6 tables),
# parameter safety (SQL injection), version checking, path sanitization,
# CRUD operations, and graceful error handling.
#
# Written: 2026-04-04 during iscp session (Phase 1, Iteration 1.2)

load 'test_helper'

# Override HOME so we don't touch the real ~/.agency/
setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    iscp_test_isolation_setup

    # iscp-db.bats tests the library's path resolution logic directly.
    # ISCP_DB_PATH override would bypass that — unset it so we test the
    # real resolution (HOME override is sufficient for DB isolation here).
    unset ISCP_DB_PATH

    # Create a minimal git repo so repo name resolution works
    export MOCK_REPO="$BATS_TEST_TMPDIR/mock-repo"
    mkdir -p "$MOCK_REPO/claude/config"
    cd "$MOCK_REPO"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test" > README.md
    git add README.md
    git commit -m "init" --quiet

    # Set project dir to mock repo
    export CLAUDE_PROJECT_DIR="$MOCK_REPO"
    export AGENCY_PROJECT_ROOT="$MOCK_REPO"

    # Source the library
    source "$REPO_ROOT/claude/tools/lib/_iscp-db"
}

teardown() {
    iscp_test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# SQLite version check
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp_db_check_sqlite succeeds on this system" {
    run iscp_db_check_sqlite
    assert_success
}

@test "version comparison: equal versions" {
    run _iscp_version_gte "3.38.0" "3.38.0"
    assert_success
}

@test "version comparison: newer major" {
    run _iscp_version_gte "4.0.0" "3.38.0"
    assert_success
}

@test "version comparison: newer minor" {
    run _iscp_version_gte "3.39.0" "3.38.0"
    assert_success
}

@test "version comparison: older version fails" {
    run _iscp_version_gte "3.37.0" "3.38.0"
    assert_failure
}

@test "version comparison: older minor fails" {
    run _iscp_version_gte "3.37.9" "3.38.0"
    assert_failure
}

# ─────────────────────────────────────────────────────────────────────────────
# Repo name resolution and path sanitization
# ─────────────────────────────────────────────────────────────────────────────

@test "repo name resolves from git basename" {
    run _iscp_resolve_repo_name
    assert_success
    # Should be the basename of the mock repo
    [[ "$output" == "mock-repo" ]]
}

@test "repo name sanitized: uppercase to lowercase" {
    # Add a remote with uppercase
    cd "$MOCK_REPO"
    git remote add origin "https://github.com/Org/MyRepo.git"
    run _iscp_resolve_repo_name
    assert_success
    [[ "$output" == "myrepo" ]]
}

@test "repo name sanitized: special chars replaced" {
    cd "$MOCK_REPO"
    git remote add origin "https://github.com/org/my.weird+repo.git"
    run _iscp_resolve_repo_name
    assert_success
    # dots and plus should become dashes
    [[ "$output" =~ ^[a-z0-9_-]+$ ]]
}

@test "db path is under ~/.agency/" {
    run iscp_db_path
    assert_success
    [[ "$output" == "$HOME/.agency/"*"/iscp.db" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# DB initialization
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp_db_init creates database" {
    run iscp_db_init
    assert_success

    local db
    db=$(iscp_db_path)
    [[ -f "$db" ]]
}

@test "iscp_db_init is idempotent" {
    iscp_db_init
    run iscp_db_init
    assert_success
}

@test "iscp_db_init creates all 6 tables" {
    iscp_db_init
    local db
    db=$(iscp_db_path)

    for table in flags dispatches transcripts dropbox_items subscriptions notifications; do
        local count
        count=$(sqlite3 "$db" "SELECT count(*) FROM $table;" 2>/dev/null)
        [[ "$count" == "0" ]]
    done
}

@test "iscp_db_init sets schema version" {
    iscp_db_init
    local db
    db=$(iscp_db_path)
    local version
    version=$(sqlite3 "$db" "PRAGMA user_version;")
    [[ "$version" == "1" ]]
}

@test "iscp_db_init sets WAL mode" {
    iscp_db_init
    local db
    db=$(iscp_db_path)
    local mode
    mode=$(sqlite3 "$db" "PRAGMA journal_mode;")
    [[ "$mode" == "wal" ]]
}

@test "iscp_db_init creates directory with 700 permissions" {
    iscp_db_init
    local db
    db=$(iscp_db_path)
    local dir
    dir=$(dirname "$db")

    # Check permissions (macOS stat format differs from Linux)
    if [[ "$(uname)" == "Darwin" ]]; then
        local perms
        perms=$(stat -f '%Lp' "$dir")
        [[ "$perms" == "700" ]]
    else
        local perms
        perms=$(stat -c '%a' "$dir")
        [[ "$perms" == "700" ]]
    fi
}

@test "iscp_db_init fails gracefully if newer schema version" {
    iscp_db_init
    local db
    db=$(iscp_db_path)

    # Set a future schema version
    sqlite3 "$db" "PRAGMA user_version=999;"

    run iscp_db_init
    assert_failure
    assert_output_contains "newer than expected"
}

# ─────────────────────────────────────────────────────────────────────────────
# Schema: CHECK constraints
# ─────────────────────────────────────────────────────────────────────────────

@test "flags rejects invalid status" {
    iscp_db_init
    local db
    db=$(iscp_db_path)

    run sqlite3 "$db" "INSERT INTO flags (created_at, from_agent, to_agent, message, status) VALUES ('2026-01-01', 'a', 'b', 'test', 'bogus');"
    assert_failure
}

@test "dispatches rejects invalid type" {
    iscp_db_init
    local db
    db=$(iscp_db_path)

    run sqlite3 "$db" "INSERT INTO dispatches (created_at, from_agent, to_agent, type, subject, payload_path) VALUES ('2026-01-01', 'a', 'b', 'bogus', 'test', '/test');"
    assert_failure
}

@test "dispatches accepts all 8 valid types" {
    iscp_db_init
    local db
    db=$(iscp_db_path)

    local i=1
    for dtype in directive seed review review-response commit master-updated escalation dispatch; do
        sqlite3 "$db" "INSERT INTO dispatches (created_at, from_agent, to_agent, type, subject, payload_path) VALUES ('2026-01-01', 'a', 'b', '$dtype', 'test', '/test/$i');"
        ((i++))
    done

    local count
    count=$(sqlite3 "$db" "SELECT count(*) FROM dispatches;")
    [[ "$count" == "8" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Named parameter handling
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp_db_query with named parameters" {
    iscp_db_init
    local db
    db=$(iscp_db_path)

    # Insert a test flag directly
    sqlite3 "$db" "INSERT INTO flags (created_at, from_agent, to_agent, message, status) VALUES ('2026-01-01', 'repo/p/agent', 'repo/p/target', 'hello', 'unread');"

    run iscp_db_query "SELECT count(*) FROM flags WHERE to_agent = :agent AND status = :status" \
        ":agent" "repo/p/target" \
        ":status" "unread"
    assert_success
    [[ "$output" == "1" ]]
}

@test "parameter safety: single quotes in values" {
    iscp_db_init

    run iscp_db_insert_flag "repo/p/agent" "repo/p/target" "it's a test with 'quotes'" "session1" "main"
    assert_success

    run iscp_db_query "SELECT message FROM flags WHERE id = :id" ":id" "1"
    assert_success
    [[ "$output" == "it's a test with 'quotes'" ]]
}

@test "parameter safety: SQL injection attempt blocked" {
    iscp_db_init

    # Attempt SQL injection via message field
    run iscp_db_insert_flag "repo/p/agent" "repo/p/target" "'; DROP TABLE flags; --" "session1" "main"
    assert_success

    # Table should still exist and have the record
    run iscp_db_query "SELECT count(*) FROM flags"
    assert_success
    [[ "$output" == "1" ]]

    # The malicious string should be stored literally
    run iscp_db_query "SELECT message FROM flags WHERE id = :id" ":id" "1"
    assert_success
    [[ "$output" == "'; DROP TABLE flags; --" ]]
}

@test "parameter name validation: rejects names without colon prefix" {
    iscp_db_init

    run iscp_db_query "SELECT 1" "agent" "value"
    assert_failure
    assert_output_contains "parameter name must match"
}

# ─────────────────────────────────────────────────────────────────────────────
# Insert helpers
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp_db_insert_flag returns new id" {
    iscp_db_init

    run iscp_db_insert_flag "repo/p/from" "repo/p/to" "test message" "sess1" "main"
    assert_success
    [[ "$output" == "1" ]]

    run iscp_db_insert_flag "repo/p/from" "repo/p/to" "second message" "sess1" "main"
    assert_success
    [[ "$output" == "2" ]]
}

@test "iscp_db_insert_flag stores all fields" {
    iscp_db_init

    iscp_db_insert_flag "the-agency/jordan/captain" "the-agency/jordan/iscp" "review needed" "sess-abc" "iscp"

    run iscp_db_query "SELECT from_agent, to_agent, message, status, session_id, branch FROM flags WHERE id = :id" ":id" "1"
    assert_success
    assert_output_contains "the-agency/jordan/captain"
    assert_output_contains "the-agency/jordan/iscp"
    assert_output_contains "review needed"
    assert_output_contains "unread"
    assert_output_contains "sess-abc"
    assert_output_contains "iscp"
}

# ─────────────────────────────────────────────────────────────────────────────
# Status updates
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp_db_update_status changes flag to read with timestamp" {
    iscp_db_init
    iscp_db_insert_flag "repo/p/a" "repo/p/b" "test" "" ""

    iscp_db_update_status "flags" "1" "read"

    run iscp_db_query "SELECT status FROM flags WHERE id = :id" ":id" "1"
    assert_success
    [[ "$output" == "read" ]]

    # read_at should be set
    run iscp_db_query "SELECT read_at IS NOT NULL FROM flags WHERE id = :id" ":id" "1"
    assert_success
    [[ "$output" == "1" ]]
}

@test "iscp_db_update_status changes flag to processed" {
    iscp_db_init
    iscp_db_insert_flag "repo/p/a" "repo/p/b" "test" "" ""

    iscp_db_update_status "flags" "1" "processed"

    run iscp_db_query "SELECT status FROM flags WHERE id = :id" ":id" "1"
    assert_success
    [[ "$output" == "processed" ]]
}

@test "iscp_db_update_status rejects unknown table" {
    iscp_db_init

    run iscp_db_update_status "evil_table" "1" "read"
    assert_failure
    assert_output_contains "unknown table"
}

# ─────────────────────────────────────────────────────────────────────────────
# Count unread (iscp-check foundation)
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp_db_count_unread returns zeros when empty" {
    iscp_db_init

    run iscp_db_count_unread "repo/p/agent"
    assert_success
    [[ "$output" == "0|0|0|0" ]]
}

@test "iscp_db_count_unread counts flags" {
    iscp_db_init

    iscp_db_insert_flag "repo/p/other" "repo/p/target" "msg1" "" ""
    iscp_db_insert_flag "repo/p/other" "repo/p/target" "msg2" "" ""
    iscp_db_insert_flag "repo/p/other" "repo/p/different" "msg3" "" ""

    run iscp_db_count_unread "repo/p/target"
    assert_success
    [[ "$output" == "2|0|0|0" ]]
}

@test "iscp_db_count_unread ignores read flags" {
    iscp_db_init

    iscp_db_insert_flag "repo/p/other" "repo/p/target" "msg1" "" ""
    iscp_db_insert_flag "repo/p/other" "repo/p/target" "msg2" "" ""
    iscp_db_update_status "flags" "1" "read"

    run iscp_db_count_unread "repo/p/target"
    assert_success
    [[ "$output" == "1|0|0|0" ]]
}

@test "iscp_db_count_unread returns zeros for nonexistent DB" {
    # Don't init — DB doesn't exist
    run iscp_db_count_unread "repo/p/agent"
    assert_success
    [[ "$output" == "0|0|0|0" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Uniqueness constraints
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatches rejects duplicate payload_path" {
    iscp_db_init
    local db
    db=$(iscp_db_path)

    sqlite3 "$db" "INSERT INTO dispatches (created_at, from_agent, to_agent, type, subject, payload_path) VALUES ('2026-01-01', 'a', 'b', 'directive', 'test', '/path/one');"

    run sqlite3 "$db" "INSERT INTO dispatches (created_at, from_agent, to_agent, type, subject, payload_path) VALUES ('2026-01-02', 'c', 'd', 'review', 'test2', '/path/one');"
    assert_failure
}

@test "subscriptions rejects duplicate subscriber+event+filter" {
    iscp_db_init
    local db
    db=$(iscp_db_path)

    # filter defaults to '' (NOT NULL) so UNIQUE index works
    sqlite3 "$db" "INSERT INTO subscriptions (created_at, subscriber, event_pattern) VALUES ('2026-01-01', 'repo/p/agent', 'dispatch.created');"

    run sqlite3 "$db" "INSERT INTO subscriptions (created_at, subscriber, event_pattern) VALUES ('2026-01-02', 'repo/p/agent', 'dispatch.created');"
    assert_failure
}

# ─────────────────────────────────────────────────────────────────────────────
# UTF-8 support
# ─────────────────────────────────────────────────────────────────────────────

@test "flag handles UTF-8 content" {
    iscp_db_init

    iscp_db_insert_flag "repo/p/agent" "repo/p/target" "Hello 世界 🌍 café résumé" "" ""

    run iscp_db_query "SELECT message FROM flags WHERE id = :id" ":id" "1"
    assert_success
    [[ "$output" == "Hello 世界 🌍 café résumé" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Error handling
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# Bug-exposing tests (QG findings)
# ─────────────────────────────────────────────────────────────────────────────

@test "parameter safety: double quotes in values" {
    iscp_db_init

    run iscp_db_insert_flag "repo/p/agent" "repo/p/target" 'He said "hello world"' "" ""
    assert_success

    run iscp_db_query "SELECT message FROM flags WHERE id = :id" ":id" "1"
    assert_success
    [[ "$output" == 'He said "hello world"' ]]
}

@test "parameter safety: backslashes in values" {
    iscp_db_init

    run iscp_db_insert_flag "repo/p/agent" "repo/p/target" 'path C:\Users\test\file' "" ""
    assert_success

    run iscp_db_query "SELECT message FROM flags WHERE id = :id" ":id" "1"
    assert_success
    [[ "$output" == 'path C:\Users\test\file' ]]
}

@test "parameter safety: newlines in values handled" {
    iscp_db_init

    local msg=$'line one\nline two\nline three'
    run iscp_db_insert_flag "repo/p/agent" "repo/p/target" "$msg" "" ""
    assert_success

    run iscp_db_query "SELECT message FROM flags WHERE id = :id" ":id" "1"
    assert_success
    # Newlines should be preserved (stored as actual newlines in SQLite)
    [[ "$output" == "$msg" ]]
}

@test "parameter name validation: strict format" {
    iscp_db_init

    # Valid param names should work
    run iscp_db_query "SELECT 1" ":valid_name" "test"
    assert_success

    # Param name with spaces should be rejected
    run iscp_db_query "SELECT 1" ":bad name" "test"
    assert_failure
}

@test "odd parameter count is rejected" {
    iscp_db_init

    # Orphaned param name with no value — should error, not silently drop
    run iscp_db_query "SELECT 1" ":orphan"
    assert_failure
}

@test "iscp_db_insert_flag fails if DB not initialized" {
    run iscp_db_insert_flag "repo/p/a" "repo/p/b" "test" "" ""
    assert_failure
}

@test "iscp_db_exec succeeds for INSERT" {
    iscp_db_init

    run iscp_db_exec "INSERT INTO flags (created_at, from_agent, to_agent, message, status) VALUES ('2026-01-01', 'a', 'b', 'test', 'unread')"
    assert_success

    run iscp_db_query "SELECT count(*) FROM flags"
    assert_success
    [[ "$output" == "1" ]]
}

@test "iscp_db_exec succeeds for UPDATE with params" {
    iscp_db_init
    iscp_db_insert_flag "repo/p/a" "repo/p/b" "test" "" ""

    run iscp_db_exec "UPDATE flags SET message = :msg WHERE id = :id" ":msg" "updated" ":id" "1"
    assert_success

    run iscp_db_query "SELECT message FROM flags WHERE id = :id" ":id" "1"
    assert_success
    [[ "$output" == "updated" ]]
}

@test "iscp_db_insert_flag stores all fields with exact match" {
    iscp_db_init
    iscp_db_insert_flag "the-agency/jordan/captain" "the-agency/jordan/iscp" "review needed" "sess-abc" "feature-branch"

    # Use exact pipe-separated output match, not substring
    run iscp_db_query "SELECT from_agent, to_agent, message, status, session_id, branch FROM flags WHERE id = :id" ":id" "1"
    assert_success
    [[ "$output" == "the-agency/jordan/captain|the-agency/jordan/iscp|review needed|unread|sess-abc|feature-branch" ]]
}

@test "iscp_db_update_status works for dispatches" {
    iscp_db_init
    local db
    db=$(iscp_db_path)
    sqlite3 "$db" "INSERT INTO dispatches (created_at, from_agent, to_agent, type, subject, payload_path) VALUES ('2026-01-01', 'a', 'b', 'review', 'test', '/test/1');"

    iscp_db_update_status "dispatches" "1" "read"

    run iscp_db_query "SELECT status FROM dispatches WHERE id = :id" ":id" "1"
    assert_success
    [[ "$output" == "read" ]]
}

@test "iscp_db_count_unread counts dispatches and dropbox" {
    iscp_db_init
    local db
    db=$(iscp_db_path)

    # Insert unread dispatch
    sqlite3 "$db" "INSERT INTO dispatches (created_at, from_agent, to_agent, type, subject, payload_path, status) VALUES ('2026-01-01', 'a', 'repo/p/target', 'review', 'test', '/p1', 'unread');"

    # Insert pending dropbox item
    sqlite3 "$db" "INSERT INTO dropbox_items (created_at, to_agent, filename, filesystem_path, status) VALUES ('2026-01-01', 'repo/p/target', 'file.txt', '/tmp/file.txt', 'pending');"

    # Insert flag too
    iscp_db_insert_flag "repo/p/other" "repo/p/target" "msg" "" ""

    run iscp_db_count_unread "repo/p/target"
    assert_success
    [[ "$output" == "1|1|1|0" ]]
}

@test "repo name resolves from agency.yaml" {
    # Create agency.yaml with repo.name
    cat > "$MOCK_REPO/claude/config/agency.yaml" << 'YAML'
principals:
  jdm: jordan

repo:
  name: custom-repo-name
YAML

    run _iscp_resolve_repo_name
    assert_success
    [[ "$output" == "custom-repo-name" ]]
}

@test "DB file permissions are restrictive" {
    iscp_db_init
    local db
    db=$(iscp_db_path)

    if [[ "$(uname)" == "Darwin" ]]; then
        local perms
        perms=$(stat -f '%Lp' "$db")
        [[ "$perms" == "600" ]]
    else
        local perms
        perms=$(stat -c '%a' "$db")
        [[ "$perms" == "600" ]]
    fi
}

@test "iscp_db_query fails if DB not initialized" {
    run iscp_db_query "SELECT 1"
    assert_failure
    assert_output_contains "not initialized"
}

@test "iscp_db_exec fails if DB not initialized" {
    run iscp_db_exec "INSERT INTO flags VALUES (1)"
    assert_failure
    assert_output_contains "not initialized"
}
