#!/usr/bin/env bats
#
# What Problem: dispatch create (v2) must create both a DB record and a
# git payload file. If either fails, dispatches are invisible or orphaned.
# These tests verify the create subcommand and the backward-compat wrapper.
#
# How & Why: Isolated tests with HOME override for DB safety, mock git repo
# with agency.yaml for identity resolution. Tests cover: required args,
# type validation, priority validation, DB record creation, payload file
# creation, frontmatter content, slug generation, and backward compat.
#
# Written: 2026-04-05 during ISCP Iteration 1.4

load 'test_helper'

# Override test_helper's setup for isolated ISCP testing
setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    iscp_test_isolation_setup

    # Create a mock git repo with agency.yaml and all required tool files
    export MOCK_REPO="$BATS_TEST_TMPDIR/mock-repo"
    mkdir -p "$MOCK_REPO/claude/tools/lib"
    mkdir -p "$MOCK_REPO/claude/config"

    # Copy tools and libs
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

    # agency.yaml with principal mapping
    cat > "$MOCK_REPO/claude/config/agency.yaml" <<'YAML'
principals:
  testuser: testprincipal
YAML

    git add -A
    git commit -m "init" --quiet
    git remote add origin https://github.com/test-org/test-repo.git 2>/dev/null || true

    # Environment
    export CLAUDE_PROJECT_DIR="$MOCK_REPO"
    unset AGENCY_PROJECT_ROOT
    unset AGENCY_PRINCIPAL
    export USER="testuser"
    unset CLAUDE_AGENT_NAME
}

teardown() {
    iscp_test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# Helper: get DB path for assertions
_db_path() {
    echo "$ISCP_DB_PATH"
}

# Helper: query the DB
_db_query() {
    sqlite3 "$(_db_path)" "$1"
}

# ─────────────────────────────────────────────────────────────────────────────
# Help and basic invocation
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch create: --help shows usage" {
    run "$MOCK_REPO/claude/tools/dispatch" create --help
    assert_success
    assert_output_contains "--to"
    assert_output_contains "--subject"
}

@test "dispatch create: fails without --to" {
    run "$MOCK_REPO/claude/tools/dispatch" create --subject "test" --body "content"
    assert_failure
    assert_output_contains "--to"
}

@test "dispatch create: fails without --subject" {
    run "$MOCK_REPO/claude/tools/dispatch" create --to "jordan/captain" --body "content"
    assert_failure
    assert_output_contains "--subject"
}

# ─────────────────────────────────────────────────────────────────────────────
# Successful creation
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch create: creates file and DB record" {
    run "$MOCK_REPO/claude/tools/dispatch" create --to "test-repo/testprincipal/captain" --subject "Test dispatch" --body "Test content"
    assert_success
    assert_output_contains "ID:"
    assert_output_contains "File:"
    assert_output_contains "From:"
    assert_output_contains "To:"

    # DB should have a record
    local count
    count=$(_db_query "SELECT count(*) FROM dispatches")
    [[ "$count" -eq 1 ]]
}

@test "dispatch create: DB record has correct fields" {
    "$MOCK_REPO/claude/tools/dispatch" create --to "test-repo/testprincipal/captain" --subject "Field check" --body "Directive content" --type directive --priority high

    local from_agent to_agent dtype priority subject status
    from_agent=$(_db_query "SELECT from_agent FROM dispatches WHERE id=1")
    to_agent=$(_db_query "SELECT to_agent FROM dispatches WHERE id=1")
    dtype=$(_db_query "SELECT type FROM dispatches WHERE id=1")
    priority=$(_db_query "SELECT priority FROM dispatches WHERE id=1")
    subject=$(_db_query "SELECT subject FROM dispatches WHERE id=1")
    status=$(_db_query "SELECT status FROM dispatches WHERE id=1")

    [[ "$from_agent" == "test-repo/testprincipal/captain" ]]
    [[ "$to_agent" == "test-repo/testprincipal/captain" ]]
    [[ "$dtype" == "directive" ]]
    [[ "$priority" == "high" ]]
    [[ "$subject" == "Field check" ]]
    [[ "$status" == "unread" ]]
}

@test "dispatch create: payload file exists with correct frontmatter" {
    "$MOCK_REPO/claude/tools/dispatch" create --to "test-repo/testprincipal/captain" --subject "Frontmatter test" --body "Frontmatter test content"

    local payload_path
    payload_path=$(_db_query "SELECT payload_path FROM dispatches WHERE id=1")
    local full_path="$MOCK_REPO/$payload_path"

    [[ -f "$full_path" ]]
    grep -q "type: dispatch" "$full_path"
    grep -q "from: test-repo/testprincipal/captain" "$full_path"
    grep -q "to: test-repo/testprincipal/captain" "$full_path"
    grep -q 'subject: "Frontmatter test"' "$full_path"
}

@test "dispatch create: default type is dispatch" {
    "$MOCK_REPO/claude/tools/dispatch" create --to "test-repo/testprincipal/captain" --subject "Default type" --body "Default type content"

    local dtype
    dtype=$(_db_query "SELECT type FROM dispatches WHERE id=1")
    [[ "$dtype" == "dispatch" ]]
}

@test "dispatch create: slug in filename comes from subject" {
    "$MOCK_REPO/claude/tools/dispatch" create --to "test-repo/testprincipal/captain" --subject "Code Review Findings" --body "Review content"

    local payload_path
    payload_path=$(_db_query "SELECT payload_path FROM dispatches WHERE id=1")
    [[ "$payload_path" == *"dispatch-code-review-findings"* ]]
}

@test "dispatch create: type prefix in filename" {
    "$MOCK_REPO/claude/tools/dispatch" create --to "test-repo/testprincipal/captain" --subject "Fix this" --body "Fix content" --type review

    local payload_path
    payload_path=$(_db_query "SELECT payload_path FROM dispatches WHERE id=1")
    [[ "$payload_path" == *"review-fix-this"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Type and priority validation
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch create: validates type against enum" {
    run "$MOCK_REPO/claude/tools/dispatch" create --to "test-repo/testprincipal/captain" --subject "Bad" --body "content" --type invalid
    assert_failure
    assert_output_contains "invalid dispatch type"
}

@test "dispatch create: accepts all valid types" {
    for dtype in directive seed review review-response commit master-updated escalation dispatch; do
        run "$MOCK_REPO/claude/tools/dispatch" create --to "test-repo/testprincipal/captain" --subject "Type $dtype" --body "Content for $dtype" --type "$dtype"
        assert_success
    done

    local count
    count=$(_db_query "SELECT count(*) FROM dispatches")
    [[ "$count" -eq 8 ]]
}

@test "dispatch create: rejects invalid priority" {
    run "$MOCK_REPO/claude/tools/dispatch" create --to "test-repo/testprincipal/captain" --subject "Bad" --body "content" --priority critical
    assert_failure
    assert_output_contains "normal, high, or low"
}

# ─────────────────────────────────────────────────────────────────────────────
# Reply-to
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch create: --reply-to with integer sets in_reply_to FK" {
    # Create original dispatch
    "$MOCK_REPO/claude/tools/dispatch" create --to "test-repo/testprincipal/captain" --subject "Original" --body "Original content"

    # Create reply
    "$MOCK_REPO/claude/tools/dispatch" create --to "test-repo/testprincipal/captain" --subject "Reply" --body "Reply content" --reply-to 1 --type review-response

    local reply_to
    reply_to=$(_db_query "SELECT in_reply_to FROM dispatches WHERE id=2")
    [[ "$reply_to" == "1" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Backward compatibility — dispatch-create wrapper
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch-create wrapper: works as before" {
    run "$MOCK_REPO/claude/tools/dispatch-create" --to "test-repo/testprincipal/captain" --subject "Wrapper test" --body "Wrapper content"
    assert_success
    assert_output_contains "ID:"
    assert_output_contains "File:"

    local count
    count=$(_db_query "SELECT count(*) FROM dispatches")
    [[ "$count" -eq 1 ]]
}

@test "dispatch-create wrapper: --help works" {
    run "$MOCK_REPO/claude/tools/dispatch-create" --help
    assert_success
    assert_output_contains "--to"
}

# ─────────────────────────────────────────────────────────────────────────────
# Edge cases
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch: --help shows all subcommands" {
    run "$MOCK_REPO/claude/tools/dispatch" --help
    assert_success
    assert_output_contains "create"
    assert_output_contains "list"
    assert_output_contains "read"
    assert_output_contains "check"
    assert_output_contains "resolve"
}

@test "dispatch: --version shows version" {
    run "$MOCK_REPO/claude/tools/dispatch" --version
    assert_success
    assert_output_contains "dispatch"
    assert_output_contains "2.0.1"
}
