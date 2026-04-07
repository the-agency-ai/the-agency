#!/usr/bin/env bats
#
# What Problem: flag v2 must store flags in the ISCP SQLite DB, support
# agent-addressable routing, and maintain the three-state lifecycle
# (unread → read → processed). If any of these break, the observation
# capture system is unreliable.
#
# How & Why: Isolated tests with HOME override. Tests cover: capture,
# --to routing, list (marks read), count, discuss (marks processed),
# clear, empty queue handling, and the Slack-style seen behavior.
#
# Written: 2026-04-05 during ISCP Iteration 1.6

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    iscp_test_isolation_setup

    export MOCK_REPO="$BATS_TEST_TMPDIR/mock-repo"
    mkdir -p "$MOCK_REPO/claude/tools/lib" "$MOCK_REPO/claude/config"

    for tool in flag agent-identity; do
        cp "$REPO_ROOT/claude/tools/$tool" "$MOCK_REPO/claude/tools/"
        chmod +x "$MOCK_REPO/claude/tools/$tool"
    done
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

    FLAG="$MOCK_REPO/claude/tools/flag"
}

teardown() {
    iscp_test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

_db_path() { echo "$ISCP_DB_PATH"; }
_db_query() { sqlite3 "$(_db_path)" "$1"; }

# ─────────────────────────────────────────────────────────────────────────────
# Capture
# ─────────────────────────────────────────────────────────────────────────────

@test "flag: captures message to self" {
    run "$FLAG" "test observation"
    assert_success
    assert_output_contains "Flagged"
    assert_output_contains "1 unread"

    local count
    count=$(_db_query "SELECT count(*) FROM flags")
    [[ "$count" -eq 1 ]]
}

@test "flag: stores correct fields in DB" {
    "$FLAG" "important note"

    local msg to_ag from_ag status
    msg=$(_db_query "SELECT message FROM flags WHERE id=1")
    to_ag=$(_db_query "SELECT to_agent FROM flags WHERE id=1")
    from_ag=$(_db_query "SELECT from_agent FROM flags WHERE id=1")
    status=$(_db_query "SELECT status FROM flags WHERE id=1")

    [[ "$msg" == "important note" ]]
    [[ "$to_ag" == "test-repo/testprincipal/captain" ]]
    [[ "$from_ag" == "test-repo/testprincipal/captain" ]]
    [[ "$status" == "unread" ]]
}

@test "flag --to: routes to specific agent" {
    run "$FLAG" --to "test-repo/testprincipal/iscp" "for iscp agent"
    assert_success

    local to_ag
    to_ag=$(_db_query "SELECT to_agent FROM flags WHERE id=1")
    [[ "$to_ag" == "test-repo/testprincipal/iscp" ]]
}

@test "flag: empty message fails" {
    run "$FLAG" ""
    assert_failure
    assert_output_contains "message is required"
}

# ─────────────────────────────────────────────────────────────────────────────
# List
# ─────────────────────────────────────────────────────────────────────────────

@test "flag list: shows flags and marks as read" {
    "$FLAG" "observation one" > /dev/null
    "$FLAG" "observation two" > /dev/null

    run "$FLAG" list
    assert_success
    assert_output_contains "observation one"
    assert_output_contains "observation two"
    echo "$output" | grep -q "2 item"
    assert_output_contains "[NEW]"

    # After list, flags should be read
    local unread
    unread=$(_db_query "SELECT count(*) FROM flags WHERE status='unread'")
    [[ "$unread" -eq 0 ]]
}

@test "flag list: empty queue handled" {
    run "$FLAG" list
    assert_success
    assert_output_contains "no flags"
}

# ─────────────────────────────────────────────────────────────────────────────
# Count
# ─────────────────────────────────────────────────────────────────────────────

@test "flag count: returns unread count" {
    "$FLAG" "one" > /dev/null
    "$FLAG" "two" > /dev/null

    run "$FLAG" count
    assert_success
    [[ "$output" == "2" ]]
}

@test "flag count: 0 when empty" {
    run "$FLAG" count
    assert_success
    [[ "$output" == "0" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Discuss
# ─────────────────────────────────────────────────────────────────────────────

@test "flag discuss: formats agenda and marks processed" {
    "$FLAG" "item alpha" > /dev/null
    "$FLAG" "item beta" > /dev/null

    run "$FLAG" discuss
    assert_success
    assert_output_contains "1. item alpha"
    assert_output_contains "2. item beta"
    echo "$output" | grep -q "2 item"
    assert_output_contains "/discuss"

    # All should be processed
    local processed
    processed=$(_db_query "SELECT count(*) FROM flags WHERE status='processed'")
    [[ "$processed" -eq 2 ]]
}

@test "flag discuss: empty queue handled" {
    run "$FLAG" discuss
    assert_success
    assert_output_contains "no flags to discuss"
}

# ─────────────────────────────────────────────────────────────────────────────
# Clear
# ─────────────────────────────────────────────────────────────────────────────

@test "flag clear: marks all as processed" {
    "$FLAG" "to clear" > /dev/null

    run "$FLAG" clear
    assert_success
    echo "$output" | grep -q "1 item"
    echo "$output" | grep -q "marked as processed"

    local processed
    processed=$(_db_query "SELECT count(*) FROM flags WHERE status='processed'")
    [[ "$processed" -eq 1 ]]
}

@test "flag clear: nothing to clear when empty" {
    run "$FLAG" clear
    assert_success
    assert_output_contains "nothing to clear"
}

# ─────────────────────────────────────────────────────────────────────────────
# Resolve (per-flag)
# ─────────────────────────────────────────────────────────────────────────────

@test "flag resolve: marks specific flag as processed" {
    "$FLAG" "keep this" > /dev/null
    "$FLAG" "resolve this" > /dev/null

    run "$FLAG" resolve 2
    assert_success
    assert_output_contains "1 resolved"

    # Flag 2 should be processed, flag 1 should still be unread
    local status1 status2
    status1=$(_db_query "SELECT status FROM flags WHERE id=1")
    status2=$(_db_query "SELECT status FROM flags WHERE id=2")
    [[ "$status1" == "unread" ]]
    [[ "$status2" == "processed" ]]
}

@test "flag resolve: handles multiple IDs" {
    "$FLAG" "one" > /dev/null
    "$FLAG" "two" > /dev/null
    "$FLAG" "three" > /dev/null

    run "$FLAG" resolve 1 3
    assert_success
    assert_output_contains "2 resolved"

    # 1 and 3 processed, 2 still unread
    local s2
    s2=$(_db_query "SELECT status FROM flags WHERE id=2")
    [[ "$s2" == "unread" ]]
}

@test "flag resolve: fails for nonexistent ID" {
    run "$FLAG" resolve 999
    assert_success
    assert_output_contains "not found"
}

@test "flag resolve: requires at least one ID" {
    run "$FLAG" resolve
    assert_failure
    assert_output_contains "requires"
}

# ─────────────────────────────────────────────────────────────────────────────
# Help and version
# ─────────────────────────────────────────────────────────────────────────────

@test "flag --help shows usage" {
    run "$FLAG" --help
    assert_success
    assert_output_contains "Usage"
}

@test "flag --version shows version" {
    run "$FLAG" --version
    assert_success
    assert_output_contains "2.0.1"
}

# ─────────────────────────────────────────────────────────────────────────────
# Flag categories (Iteration 2.3)
#
# These tests require the category column on flags. ISCP_SCHEMA_VERSION is
# currently frozen at 1 (partial-deployment freeze) so iscp_db_init does NOT
# auto-add the column on fresh DBs. Each test that needs the column must call
# _add_category_column first to apply the migration manually.
# ─────────────────────────────────────────────────────────────────────────────

_add_category_column() {
    "$FLAG" "bootstrap" >/dev/null  # ensure DB exists
    sqlite3 "$ISCP_DB_PATH" "DELETE FROM flags;"
    sqlite3 "$ISCP_DB_PATH" "ALTER TABLE flags ADD COLUMN category TEXT CHECK(category IS NULL OR category IN ('friction', 'idea', 'bug'));"
}

@test "flag --friction stores category" {
    _add_category_column
    run "$FLAG" --friction "test friction"
    assert_success
    local cat
    cat=$(_db_query "SELECT category FROM flags WHERE message='test friction'")
    [[ "$cat" == "friction" ]]
}

@test "flag --idea stores category" {
    _add_category_column
    run "$FLAG" --idea "test idea"
    assert_success
    local cat
    cat=$(_db_query "SELECT category FROM flags WHERE message='test idea'")
    [[ "$cat" == "idea" ]]
}

@test "flag --bug stores category" {
    _add_category_column
    run "$FLAG" --bug "test bug"
    assert_success
    local cat
    cat=$(_db_query "SELECT category FROM flags WHERE message='test bug'")
    [[ "$cat" == "bug" ]]
}

@test "flag with no category stores NULL" {
    _add_category_column
    run "$FLAG" "uncategorized"
    assert_success
    local cat
    cat=$(_db_query "SELECT IFNULL(category, 'NULL') FROM flags WHERE message='uncategorized'")
    [[ "$cat" == "NULL" ]]
}

@test "flag --to combines with --friction" {
    _add_category_column
    run "$FLAG" --to "test-repo/testprincipal/iscp" --friction "friction for iscp"
    assert_success
    local cat to_ag
    cat=$(_db_query "SELECT category FROM flags WHERE message='friction for iscp'")
    to_ag=$(_db_query "SELECT to_agent FROM flags WHERE message='friction for iscp'")
    [[ "$cat" == "friction" ]]
    [[ "$to_ag" == "test-repo/testprincipal/iscp" ]]
}

@test "flag --friction --bug fails (only one category)" {
    run "$FLAG" --friction --bug "ambiguous"
    assert_failure
    assert_output_contains "only one category"
}

@test "flag list --category friction filters" {
    _add_category_column
    "$FLAG" --friction "f1"
    "$FLAG" --idea "i1"
    "$FLAG" --bug "b1"
    "$FLAG" "uncategorized"

    run "$FLAG" list --category friction
    assert_success
    assert_output_contains "f1"
    # Should not contain other categories
    [[ "$output" != *"i1"* ]]
    [[ "$output" != *"b1"* ]]
    [[ "$output" != *"uncategorized"* ]]
}

@test "flag list shows mixed categorized and uncategorized" {
    _add_category_column
    "$FLAG" --friction "f1"
    "$FLAG" "u1"
    "$FLAG" --idea "i1"

    run "$FLAG" list
    assert_success
    assert_output_contains "f1"
    assert_output_contains "u1"
    assert_output_contains "i1"
    assert_output_contains "{friction}"
    assert_output_contains "{idea}"
}

@test "flag list --category with invalid value fails" {
    run "$FLAG" list --category bogus
    assert_failure
    assert_output_contains "unknown category"
}

@test "flag list --category friction in empty queue" {
    _add_category_column
    run "$FLAG" list --category friction
    assert_success
    assert_output_contains "no flags in category 'friction'"
}

@test "flag list --category only marks filtered as read" {
    _add_category_column
    "$FLAG" --friction "f1"
    "$FLAG" --idea "i1"

    "$FLAG" list --category friction >/dev/null
    # friction marked read, idea still unread
    local f_status i_status
    f_status=$(_db_query "SELECT status FROM flags WHERE message='f1'")
    i_status=$(_db_query "SELECT status FROM flags WHERE message='i1'")
    [[ "$f_status" == "read" ]]
    [[ "$i_status" == "unread" ]]
}
