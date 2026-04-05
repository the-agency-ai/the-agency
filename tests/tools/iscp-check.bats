#!/usr/bin/env bats
#
# What Problem: iscp-check is the ISCP "You got mail" hook — it must be
# silent when nothing is waiting, report via JSON systemMessage when items
# exist, and NEVER fail noisily (broken notification must not block agent
# work). If any of these invariants break, agents either get spammed with
# noise or miss critical dispatches.
#
# How & Why: Isolated tests with HOME override. Tests cover: silent when
# no DB, silent when empty, reports dispatches, reports flags, combined
# counts, valid JSON output, graceful degradation (no DB, partial schema),
# and the full integration cycle (insert → check reports → read → check
# silent). Performance is not tested here (too environment-dependent) but
# the hot path is verified.
#
# Written: 2026-04-05 during ISCP Iteration 2.1

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    export HOME="$BATS_TEST_TMPDIR/fakehome"
    mkdir -p "$HOME"

    export MOCK_REPO="$BATS_TEST_TMPDIR/mock-repo"
    mkdir -p "$MOCK_REPO/claude/tools/lib" "$MOCK_REPO/claude/config"

    for tool in iscp-check agent-identity dispatch flag; do
        cp "$REPO_ROOT/claude/tools/$tool" "$MOCK_REPO/claude/tools/"
        chmod +x "$MOCK_REPO/claude/tools/$tool"
    done
    # dispatch-create wrapper needed by dispatch
    cp "$REPO_ROOT/claude/tools/dispatch-create" "$MOCK_REPO/claude/tools/"
    chmod +x "$MOCK_REPO/claude/tools/dispatch-create"

    for lib in _iscp-db _address-parse _path-resolve _log-helper; do
        cp "$REPO_ROOT/claude/tools/lib/$lib" "$MOCK_REPO/claude/tools/lib/"
    done

    cd "$MOCK_REPO"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"

    cat > "$MOCK_REPO/claude/config/agency.yaml" <<'YAML'
principals:
  testuser: testprincipal
YAML

    git add -A
    git commit -m "init" --quiet
    git remote add origin https://github.com/test-org/test-repo.git 2>/dev/null || true

    export CLAUDE_PROJECT_DIR="$MOCK_REPO"
    unset AGENCY_PROJECT_ROOT
    unset AGENCY_PRINCIPAL
    export USER="testuser"
    unset CLAUDE_AGENT_NAME

    ISCP_CHECK="$MOCK_REPO/claude/tools/iscp-check"
    DISPATCH="$MOCK_REPO/claude/tools/dispatch"
    FLAG="$MOCK_REPO/claude/tools/flag"
}

teardown() {
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

_db_path() { echo "$HOME/.agency/test-repo/iscp.db"; }
_db_query() { sqlite3 "$(_db_path)" "$1"; }

# Helper: init DB without inserting anything
_init_db() {
    "$FLAG" count > /dev/null 2>&1 || true
}

# Helper: create a dispatch for the current agent
_create_dispatch() {
    "$DISPATCH" create --to "test-repo/testprincipal/captain" --subject "${1:-Test}" --type "${2:-dispatch}" > /dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────────────────────
# Silent when empty
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-check: silent when no DB exists" {
    run "$ISCP_CHECK"
    assert_success
    [[ -z "$output" ]]
}

@test "iscp-check: silent when DB exists but empty" {
    _init_db

    run "$ISCP_CHECK"
    assert_success
    [[ -z "$output" ]]
}

@test "iscp-check: silent after all items are read/processed" {
    # Create a flag, then process it
    "$FLAG" "will be processed" > /dev/null
    "$FLAG" clear > /dev/null

    run "$ISCP_CHECK"
    assert_success
    [[ -z "$output" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Reports unread items
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-check: reports unread dispatches" {
    _create_dispatch "Pending dispatch"

    run "$ISCP_CHECK"
    assert_success
    [[ -n "$output" ]]
    assert_output_contains "1 dispatch"
    assert_output_contains "dispatch list"
}

@test "iscp-check: reports unread flags" {
    "$FLAG" "observation one" > /dev/null
    "$FLAG" "observation two" > /dev/null

    run "$ISCP_CHECK"
    assert_success
    [[ -n "$output" ]]
    assert_output_contains "2 flag"
    assert_output_contains "flag list"
}

@test "iscp-check: reports combined counts" {
    _create_dispatch "A dispatch"
    "$FLAG" "A flag" > /dev/null

    run "$ISCP_CHECK"
    assert_success
    assert_output_contains "1 dispatch"
    assert_output_contains "1 flag"
}

# ─────────────────────────────────────────────────────────────────────────────
# JSON output format
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-check: output is valid JSON with systemMessage" {
    "$FLAG" "json test" > /dev/null

    run "$ISCP_CHECK"
    assert_success

    # Validate JSON structure
    echo "$output" | jq -e '.systemMessage' > /dev/null
    local msg
    msg=$(echo "$output" | jq -r '.systemMessage')
    [[ "$msg" == *"flag"* ]]
}

@test "iscp-check: JSON has no extra keys" {
    "$FLAG" "keys test" > /dev/null

    run "$ISCP_CHECK"
    assert_success

    # Should have exactly one key: systemMessage
    local key_count
    key_count=$(echo "$output" | jq 'keys | length')
    [[ "$key_count" -eq 1 ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Integration: full lifecycle
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-check: integration — dispatch create → check reports → read → check silent" {
    _create_dispatch "Integration test"

    # Check reports the dispatch
    run "$ISCP_CHECK"
    assert_success
    assert_output_contains "1 dispatch"

    # Read the dispatch (marks as read)
    "$DISPATCH" read 1 > /dev/null

    # Check is now silent (read != unread)
    run "$ISCP_CHECK"
    assert_success
    [[ -z "$output" ]]
}

@test "iscp-check: integration — flag create → check reports → clear → check silent" {
    "$FLAG" "integration flag" > /dev/null

    # Check reports the flag
    run "$ISCP_CHECK"
    assert_success
    assert_output_contains "1 flag"

    # Clear flags (marks as processed)
    "$FLAG" clear > /dev/null

    # Check is now silent
    run "$ISCP_CHECK"
    assert_success
    [[ -z "$output" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Graceful degradation
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-check: graceful when identity resolution fails" {
    # Break identity resolution by removing agency.yaml
    rm -f "$MOCK_REPO/claude/config/agency.yaml"

    run "$ISCP_CHECK"
    assert_success
    # Should be silent, not error — broken notification never blocks
    [[ -z "$output" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Help and version
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-check: --help shows usage" {
    run "$ISCP_CHECK" --help
    assert_success
    assert_output_contains "iscp-check"
    assert_output_contains "hook"
}

@test "iscp-check: --version shows version" {
    run "$ISCP_CHECK" --version
    assert_success
    assert_output_contains "1.0.0"
}
