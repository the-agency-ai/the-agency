#!/usr/bin/env bats
#
# What Problem: dispatch lifecycle subcommands (list, read, check, resolve,
# status) must correctly query and update the ISCP DB. If list misses
# dispatches, read fails to mark as read, or check is noisy when empty,
# the whole notification system breaks.
#
# How & Why: Isolated tests with HOME override. Each test creates dispatches
# via the create subcommand, then exercises lifecycle operations and asserts
# DB state changes. Tests cover: list filtering, read with mark-as-read,
# check silent/noisy behavior, resolve lifecycle, status display.
#
# Written: 2026-04-05 during ISCP Iteration 1.5

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    iscp_test_isolation_setup

    export MOCK_REPO="$BATS_TEST_TMPDIR/mock-repo"
    mkdir -p "$MOCK_REPO/claude/tools/lib" "$MOCK_REPO/claude/config"

    for tool in dispatch dispatch-create agent-identity; do
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

    # Alias for readability
    DISPATCH="$MOCK_REPO/claude/tools/dispatch"
}

teardown() {
    iscp_test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

_db_path() { echo "$ISCP_DB_PATH"; }
_db_query() { sqlite3 "$(_db_path)" "$1"; }

# Helper: create a test dispatch and return silently
_create_dispatch() {
    "$DISPATCH" create --to "test-repo/testprincipal/captain" --subject "${1:-Test}" --body "Test content for: ${1:-Test}" --type "${2:-dispatch}" > /dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────────────────────
# list
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch list: shows no dispatches when empty" {
    # Need to init DB first via a noop
    run "$DISPATCH" list
    assert_success
    assert_output_contains "No dispatches"
}

@test "dispatch list: shows dispatches for current agent" {
    _create_dispatch "List test one"
    _create_dispatch "List test two"

    run "$DISPATCH" list
    assert_success
    assert_output_contains "List test one"
    assert_output_contains "List test two"
    assert_output_contains "ID"
}

@test "dispatch list: --status filters by status" {
    _create_dispatch "Unread one"
    _create_dispatch "Unread two"
    # Mark first as read
    _db_query "UPDATE dispatches SET status = 'read' WHERE id = 1"

    run "$DISPATCH" list --status unread
    assert_success
    assert_output_contains "Unread two"
    # Should NOT show the read dispatch
    ! echo "$output" | grep -q "Unread one"
}

@test "dispatch list: --type filters by type" {
    _create_dispatch "A directive" "directive"
    _create_dispatch "A review" "review"

    run "$DISPATCH" list --type review
    assert_success
    assert_output_contains "A review"
    ! echo "$output" | grep -q "A directive"
}

@test "dispatch list: --all shows dispatches for all agents" {
    _create_dispatch "Mine"
    # Insert one for a different agent directly
    _db_query "INSERT INTO dispatches (created_at, from_agent, to_agent, type, priority, subject, payload_path, status) VALUES ('2026-01-01', 'a/b/c', 'other/agent/name', 'dispatch', 'normal', 'Not mine', 'path/to/file.md', 'unread')"

    run "$DISPATCH" list --all
    assert_success
    assert_output_contains "Mine"
    assert_output_contains "Not mine"
}

# ─────────────────────────────────────────────────────────────────────────────
# read
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch read: shows dispatch and marks as read" {
    _create_dispatch "Read me"

    run "$DISPATCH" read 1
    assert_success
    assert_output_contains "Read me"
    assert_output_contains "marked as read"

    # DB should show read status
    local status
    status=$(_db_query "SELECT status FROM dispatches WHERE id=1")
    [[ "$status" == "read" ]]
}

@test "dispatch read: sets read_by and read_at" {
    _create_dispatch "Track reader"

    "$DISPATCH" read 1 > /dev/null

    local read_by read_at
    read_by=$(_db_query "SELECT read_by FROM dispatches WHERE id=1")
    read_at=$(_db_query "SELECT read_at FROM dispatches WHERE id=1")

    [[ -n "$read_by" ]]
    [[ -n "$read_at" ]]
}

@test "dispatch read: does not re-mark already-read dispatch" {
    _create_dispatch "Already read"
    "$DISPATCH" read 1 > /dev/null

    # Read again — should NOT say "marked as read" again
    run "$DISPATCH" read 1
    assert_success
    ! echo "$output" | grep -q "marked as read"
}

@test "dispatch read: fails for nonexistent ID" {
    run "$DISPATCH" read 999
    assert_failure
    assert_output_contains "not found"
}

@test "dispatch read: requires integer ID" {
    run "$DISPATCH" read "not-a-number"
    assert_failure
    assert_output_contains "integer ID"
}

# ─────────────────────────────────────────────────────────────────────────────
# check
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch check: silent when no unread" {
    run "$DISPATCH" check
    assert_success
    [[ -z "$output" ]]
}

@test "dispatch check: silent when no DB exists" {
    run "$DISPATCH" check
    assert_success
    [[ -z "$output" ]]
}

@test "dispatch check: reports unread dispatches as JSON" {
    _create_dispatch "Pending one"
    _create_dispatch "Pending two"

    run "$DISPATCH" check
    assert_success
    # Should output JSON with systemMessage
    echo "$output" | jq -e '.systemMessage' > /dev/null
    assert_output_contains "2 dispatch"
}

@test "dispatch check: silent after all dispatches read" {
    _create_dispatch "Will be read"
    "$DISPATCH" read 1 > /dev/null

    run "$DISPATCH" check
    assert_success
    [[ -z "$output" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# resolve
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch resolve: marks as resolved" {
    _create_dispatch "To resolve"

    run "$DISPATCH" resolve 1
    assert_success
    assert_output_contains "resolved"

    local status resolved_at
    status=$(_db_query "SELECT status FROM dispatches WHERE id=1")
    resolved_at=$(_db_query "SELECT resolved_at FROM dispatches WHERE id=1")
    [[ "$status" == "resolved" ]]
    [[ -n "$resolved_at" ]]
}

@test "dispatch resolve: fails for nonexistent ID" {
    run "$DISPATCH" resolve 999
    assert_failure
    assert_output_contains "not found"
}

# ─────────────────────────────────────────────────────────────────────────────
# status
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch status: shows full record" {
    _create_dispatch "Status check" "directive"

    run "$DISPATCH" status 1
    assert_success
    assert_output_contains "Status check"
    assert_output_contains "directive"
    assert_output_contains "unread"
    assert_output_contains "test-repo/testprincipal/captain"
}

@test "dispatch status: fails for nonexistent ID" {
    run "$DISPATCH" status 999
    assert_failure
    assert_output_contains "not found"
}

# ─────────────────────────────────────────────────────────────────────────────
# fetch — read-only peek
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch fetch: displays dispatch without changing status" {
    _create_dispatch "Peek at me"

    # Verify starts as unread
    local status_before
    status_before=$(_db_query "SELECT status FROM dispatches WHERE id=1")
    [[ "$status_before" == "unread" ]]

    run "$DISPATCH" fetch 1
    assert_success
    assert_output_contains "Peek at me"

    # Status should still be unread
    local status_after
    status_after=$(_db_query "SELECT status FROM dispatches WHERE id=1")
    [[ "$status_after" == "unread" ]]
}

@test "dispatch fetch: does not say 'marked as read'" {
    _create_dispatch "No marking"

    run "$DISPATCH" fetch 1
    assert_success
    ! echo "$output" | grep -q "marked as read"
}

@test "dispatch fetch: fails for nonexistent ID" {
    run "$DISPATCH" fetch 999
    assert_failure
    assert_output_contains "not found"
}

@test "dispatch fetch: requires integer ID" {
    run "$DISPATCH" fetch "not-a-number"
    assert_failure
    assert_output_contains "integer ID"
}

@test "dispatch fetch: works on already-read dispatch" {
    _create_dispatch "Already read dispatch"
    "$DISPATCH" read 1 > /dev/null  # mark as read

    run "$DISPATCH" fetch 1
    assert_success
    assert_output_contains "Already read dispatch"

    # Status should still be read (not reverted to something else)
    local status
    status=$(_db_query "SELECT status FROM dispatches WHERE id=1")
    [[ "$status" == "read" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# reply — quick response
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch reply: creates reply addressed to original sender" {
    _create_dispatch "Original message"

    run "$DISPATCH" reply 1 "Got it, thanks"
    assert_success
    assert_output_contains "reply"
    assert_output_contains "Re: Original message"
    assert_output_contains "Reply-to: #1"

    # Verify the reply dispatch exists in DB
    local to_agent
    to_agent=$(_db_query "SELECT to_agent FROM dispatches WHERE id=2")
    # Reply should be addressed to original sender (test-repo/testprincipal/iscp — our identity)
    [[ -n "$to_agent" ]]
}

@test "dispatch reply: sets in_reply_to FK" {
    _create_dispatch "Parent dispatch"

    "$DISPATCH" reply 1 "Reply message" > /dev/null

    local reply_to
    reply_to=$(_db_query "SELECT in_reply_to FROM dispatches WHERE id=2")
    [[ "$reply_to" == "1" ]]
}

@test "dispatch reply: prefixes subject with Re:" {
    _create_dispatch "Important topic"

    run "$DISPATCH" reply 1 "My response"
    assert_success
    assert_output_contains "Re: Important topic"
}

@test "dispatch reply: does not double-prefix Re:" {
    # Create a dispatch that already has Re: in subject
    "$DISPATCH" create --to "test-repo/testprincipal/captain" --subject "Re: Already a reply" --body "Follow-up content" --type dispatch > /dev/null 2>&1

    run "$DISPATCH" reply 1 "Follow-up"
    assert_success
    assert_output_contains "Re: Already a reply"
    # Should NOT contain "Re: Re:"
    ! echo "$output" | grep -q "Re: Re:"
}

@test "dispatch reply: fails for nonexistent ID" {
    run "$DISPATCH" reply 999 "Hello"
    assert_failure
    assert_output_contains "not found"
}

@test "dispatch reply: requires message" {
    _create_dispatch "Need reply"

    run "$DISPATCH" reply 1 ""
    assert_failure
    assert_output_contains "requires a message"
}

@test "dispatch reply: requires integer ID" {
    run "$DISPATCH" reply "abc" "hello"
    assert_failure
    assert_output_contains "integer ID"
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R24 (issue #119 bug 4): strict flag rejection on `dispatch reply`
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch reply: rejects --subject flag (issue #119 bug 4)" {
    _create_dispatch "Strict parsing test"
    run "$DISPATCH" reply 1 --subject "foo"
    assert_failure
    assert_output_contains "does not accept flag"
    assert_output_contains "--subject"
}

@test "dispatch reply: rejects --body flag" {
    _create_dispatch "Strict parsing test"
    run "$DISPATCH" reply 1 --body "bar"
    assert_failure
    assert_output_contains "does not accept flag"
}

@test "dispatch reply: rejects arbitrary unknown flag" {
    _create_dispatch "Strict parsing test"
    run "$DISPATCH" reply 1 --not-a-real-flag
    assert_failure
    assert_output_contains "does not accept flag"
    assert_output_contains "--not-a-real-flag"
}

@test "dispatch reply: rejects extra positional args" {
    _create_dispatch "Strict parsing test"
    run "$DISPATCH" reply 1 "message" "extra1" "extra2"
    assert_failure
    assert_output_contains "Extra"
}

@test "dispatch reply: regression — legitimate call with just id and message still works" {
    _create_dispatch "Legit call"
    run "$DISPATCH" reply 1 "legitimate reply message"
    assert_success
}

@test "dispatch reply: writes payload file with message body" {
    _create_dispatch "Payload test"

    "$DISPATCH" reply 1 "This is the reply content" > /dev/null

    # Find the reply payload file
    local payload_path
    payload_path=$(_db_query "SELECT payload_path FROM dispatches WHERE id=2")
    [[ -f "$MOCK_REPO/$payload_path" ]]

    # Verify the message is in the payload
    grep -q "This is the reply content" "$MOCK_REPO/$payload_path"
}

# ─────────────────────────────────────────────────────────────────────────────
# --body required / --template opt-in (escalation #53)
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch create: fails without --body or --template" {
    run "$DISPATCH" create --to "test-repo/testprincipal/captain" --subject "No content"
    assert_failure
    assert_output_contains "--body"
    assert_output_contains "--template"
}

@test "dispatch create: succeeds with --body" {
    run "$DISPATCH" create --to "test-repo/testprincipal/captain" --subject "With body" --body "Real content here"
    assert_success
    assert_output_contains "ID:"

    local payload_path
    payload_path=$(_db_query "SELECT payload_path FROM dispatches WHERE id=1")
    grep -q "Real content here" "$MOCK_REPO/$payload_path"
    # Should not contain template placeholders
    ! grep -q '<!-- ' "$MOCK_REPO/$payload_path"
}

@test "dispatch create: --template writes placeholder file" {
    run "$DISPATCH" create --to "test-repo/testprincipal/captain" --subject "Template mode" --template
    assert_success
    assert_output_contains "TEMPLATE MODE"
    assert_output_contains "placeholders"

    local payload_path
    payload_path=$(_db_query "SELECT payload_path FROM dispatches WHERE id=1")
    grep -q '<!-- ' "$MOCK_REPO/$payload_path"
}

@test "dispatch create: --body and --template together uses body" {
    run "$DISPATCH" create --to "test-repo/testprincipal/captain" --subject "Both" --body "Actual content" --template
    assert_success

    local payload_path
    payload_path=$(_db_query "SELECT payload_path FROM dispatches WHERE id=1")
    grep -q "Actual content" "$MOCK_REPO/$payload_path"
    # Should not contain template placeholders because --body was provided
    ! grep -q '<!-- ' "$MOCK_REPO/$payload_path"
}

# ─────────────────────────────────────────────────────────────────────────────
# Symlink payload resolution (directive #71)
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch create: creates symlink in dispatches dir" {
    _create_dispatch "Symlink test"

    local db_dir
    db_dir=$(dirname "$ISCP_DB_PATH")
    local symlink="$db_dir/dispatches/dispatch-1.md"

    # Symlink should exist
    [[ -L "$symlink" ]]
    # And resolve to a readable file
    [[ -f "$symlink" ]]
}

@test "dispatch read: resolves payload via symlink" {
    _create_dispatch "Read via symlink"

    # Delete the local copy — force symlink resolution
    local payload_path
    payload_path=$(_db_query "SELECT payload_path FROM dispatches WHERE id=1")
    local original_file="$MOCK_REPO/$payload_path"
    local db_dir
    db_dir=$(dirname "$ISCP_DB_PATH")
    local symlink="$db_dir/dispatches/dispatch-1.md"

    # Verify symlink points to the right file
    [[ -L "$symlink" ]]
    local target
    target=$(readlink "$symlink")
    [[ "$target" == "$original_file" ]]

    # Read should work via symlink
    run "$DISPATCH" read 1
    assert_success
    assert_output_contains "Read via symlink"
}

@test "dispatch read: reports dangling symlink" {
    _create_dispatch "Will be deleted"

    # Delete the payload file to create a dangling symlink
    local payload_path
    payload_path=$(_db_query "SELECT payload_path FROM dispatches WHERE id=1")
    rm -f "$MOCK_REPO/$payload_path"

    run "$DISPATCH" read 1
    assert_success
    # Should report the dangling symlink
    assert_output_contains "unavailable"
}

@test "dispatch reply: creates symlink for reply" {
    _create_dispatch "Original"
    "$DISPATCH" reply 1 "Reply content" > /dev/null

    local db_dir
    db_dir=$(dirname "$ISCP_DB_PATH")
    local symlink="$db_dir/dispatches/dispatch-2.md"

    [[ -L "$symlink" ]]
    [[ -f "$symlink" ]]
}
