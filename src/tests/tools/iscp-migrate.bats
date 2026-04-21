#!/usr/bin/env bats
#
# What Problem: iscp-migrate must correctly import legacy ISCP data (JSONL
# flags and markdown dispatches) into the SQLite DB. If migration fails
# silently, loses data, or produces invalid DB records, the v2 tools won't
# see historical dispatches and flags — breaking continuity.
#
# How & Why: Isolated tests with HOME override. Create synthetic legacy
# data (JSONL for flags, markdown with YAML frontmatter and without for
# dispatches) and verify DB records after migration. Tests cover: flag
# import, flag idempotency (.migrated rename), dispatch import with
# frontmatter, dispatch import without frontmatter (markdown header
# fallback), type mapping, status mapping, idempotent re-run, and
# code-reviews/ directory scanning.
#
# Written: 2026-04-05 during ISCP Iteration 2.2

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    iscp_test_isolation_setup

    export MOCK_REPO="$BATS_TEST_TMPDIR/mock-repo"
    mkdir -p "$MOCK_REPO/agency/tools/lib" "$MOCK_REPO/claude/config"

    for tool in iscp-migrate agent-identity dispatch flag; do
        cp "$REPO_ROOT/agency/tools/$tool" "$MOCK_REPO/agency/tools/"
        chmod +x "$MOCK_REPO/agency/tools/$tool"
    done
    cp "$REPO_ROOT/agency/tools/dispatch-create" "$MOCK_REPO/agency/tools/"
    chmod +x "$MOCK_REPO/agency/tools/dispatch-create"

    for lib in _iscp-db _address-parse _path-resolve _log-helper; do
        cp "$REPO_ROOT/agency/tools/lib/$lib" "$MOCK_REPO/agency/tools/lib/"
    done

    cd "$MOCK_REPO"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"

    cat > "$MOCK_REPO/agency/config/agency.yaml" <<'YAML'
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

    MIGRATE="$MOCK_REPO/agency/tools/iscp-migrate"
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
# Flag migration
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-migrate flags: imports JSONL flags" {
    mkdir -p "$MOCK_REPO/usr/jordan"
    cat > "$MOCK_REPO/usr/jordan/flag-queue.jsonl" <<'JSONL'
{"ts":"2026-04-03T18:54:30Z","message":"Test observation one","principal":"jordan","branch":"main","session":"test-session"}
{"ts":"2026-04-03T19:00:00Z","message":"Test observation two","principal":"jordan","branch":"iscp","session":"test-session-2"}
JSONL

    run "$MIGRATE" flags
    assert_success
    assert_output_contains "2 flags imported"

    local count
    count=$(_db_query "SELECT count(*) FROM flags")
    [[ "$count" -eq 2 ]]

    # All should be 'read' (pre-DB era)
    local read_count
    read_count=$(_db_query "SELECT count(*) FROM flags WHERE status='read'")
    [[ "$read_count" -eq 2 ]]
}

@test "iscp-migrate flags: preserves timestamp and branch" {
    mkdir -p "$MOCK_REPO/usr/jordan"
    cat > "$MOCK_REPO/usr/jordan/flag-queue.jsonl" <<'JSONL'
{"ts":"2026-04-03T18:54:30Z","message":"With metadata","principal":"jordan","branch":"iscp","session":"sess-1"}
JSONL

    run "$MIGRATE" flags
    assert_success

    local ts branch session
    ts=$(_db_query "SELECT created_at FROM flags WHERE id=1")
    branch=$(_db_query "SELECT branch FROM flags WHERE id=1")
    session=$(_db_query "SELECT session_id FROM flags WHERE id=1")

    [[ "$ts" == "2026-04-03T18:54:30Z" ]]
    [[ "$branch" == "iscp" ]]
    [[ "$session" == "sess-1" ]]
}

@test "iscp-migrate flags: renames to .migrated" {
    mkdir -p "$MOCK_REPO/usr/jordan"
    echo '{"ts":"2026-04-03T00:00:00Z","message":"migrate me","principal":"jordan","branch":"main","session":""}' \
        > "$MOCK_REPO/usr/jordan/flag-queue.jsonl"

    run "$MIGRATE" flags
    assert_success

    # Original should be gone
    [[ ! -f "$MOCK_REPO/usr/jordan/flag-queue.jsonl" ]]
    # .migrated should exist
    [[ -f "$MOCK_REPO/usr/jordan/flag-queue.jsonl.migrated" ]]
}

@test "iscp-migrate flags: skips when no JSONL exists" {
    run "$MIGRATE" flags
    assert_success
    assert_output_contains "skipping"
}

@test "iscp-migrate flags: handles .from field" {
    mkdir -p "$MOCK_REPO/usr/jordan"
    cat > "$MOCK_REPO/usr/jordan/flag-queue.jsonl" <<'JSONL'
{"ts":"2026-04-05T00:15:00Z","from":"the-agency/jordan/captain","text":"With from field","tags":["test"]}
JSONL

    run "$MIGRATE" flags
    assert_success

    local from_ag msg
    from_ag=$(_db_query "SELECT from_agent FROM flags WHERE id=1")
    msg=$(_db_query "SELECT message FROM flags WHERE id=1")

    [[ "$from_ag" == "the-agency/jordan/captain" ]]
    [[ "$msg" == "With from field" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Dispatch migration — YAML frontmatter
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-migrate dispatches: imports dispatch with YAML frontmatter" {
    mkdir -p "$MOCK_REPO/usr/jordan/captain/dispatches"
    cat > "$MOCK_REPO/usr/jordan/captain/dispatches/directive-test-20260405.md" <<'MD'
---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-05 10:38
status: pending
priority: high
subject: "Test directive"
---

# Test directive

Do the thing.
MD

    run "$MIGRATE" dispatches
    assert_success

    local count
    count=$(_db_query "SELECT count(*) FROM dispatches")
    [[ "$count" -eq 1 ]]

    local dtype from_ag to_ag priority subject status
    dtype=$(_db_query "SELECT type FROM dispatches WHERE id=1")
    from_ag=$(_db_query "SELECT from_agent FROM dispatches WHERE id=1")
    to_ag=$(_db_query "SELECT to_agent FROM dispatches WHERE id=1")
    priority=$(_db_query "SELECT priority FROM dispatches WHERE id=1")
    subject=$(_db_query "SELECT subject FROM dispatches WHERE id=1")
    status=$(_db_query "SELECT status FROM dispatches WHERE id=1")

    [[ "$dtype" == "directive" ]]
    [[ "$from_ag" == "the-agency/jordan/captain" ]]
    [[ "$to_ag" == "the-agency/jordan/iscp" ]]
    [[ "$priority" == "high" ]]
    [[ "$subject" == "Test directive" ]]
    [[ "$status" == "unread" ]]  # "pending" maps to "unread"
}

# ─────────────────────────────────────────────────────────────────────────────
# Dispatch migration — markdown header fallback
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-migrate dispatches: imports dispatch with markdown headers (no frontmatter)" {
    mkdir -p "$MOCK_REPO/usr/jordan/captain/dispatches"
    cat > "$MOCK_REPO/usr/jordan/captain/dispatches/dispatch-old-style-20260330.md" <<'MD'
# Dispatch: Old Style Communication

**Date:** 2026-03-30
**From:** Captain (the-agency)
**To:** Agent (the-agency)
**Priority:** High — this is important

---

## Context

This uses the old dispatch format without YAML frontmatter.
MD

    run "$MIGRATE" dispatches
    assert_success

    local count
    count=$(_db_query "SELECT count(*) FROM dispatches")
    [[ "$count" -eq 1 ]]

    local dtype subject priority
    dtype=$(_db_query "SELECT type FROM dispatches WHERE id=1")
    subject=$(_db_query "SELECT subject FROM dispatches WHERE id=1")
    priority=$(_db_query "SELECT priority FROM dispatches WHERE id=1")

    [[ "$dtype" == "dispatch" ]]  # Default type for old format
    [[ "$subject" == "Dispatch: Old Style Communication" ]]
    [[ "$priority" == "high" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Type and status mapping
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-migrate dispatches: maps unknown type to dispatch" {
    mkdir -p "$MOCK_REPO/usr/jordan/captain/dispatches"
    cat > "$MOCK_REPO/usr/jordan/captain/dispatches/dispatch-unknown-type.md" <<'MD'
---
type: weird-unknown-type
from: a/b/c
to: d/e/f
date: 2026-01-01
subject: "Unknown type"
---

# Unknown type test
MD

    run "$MIGRATE" dispatches
    assert_success

    local dtype
    dtype=$(_db_query "SELECT type FROM dispatches WHERE id=1")
    [[ "$dtype" == "dispatch" ]]
}

@test "iscp-migrate dispatches: maps statuses correctly" {
    mkdir -p "$MOCK_REPO/usr/jordan/captain/dispatches"

    # created → unread
    cat > "$MOCK_REPO/usr/jordan/captain/dispatches/dispatch-created.md" <<'MD'
---
type: dispatch
from: a/b/c
to: d/e/f
date: 2026-01-01
status: created
subject: "Status created"
---
# Test
MD

    # in-progress → read
    cat > "$MOCK_REPO/usr/jordan/captain/dispatches/dispatch-inprogress.md" <<'MD'
---
type: dispatch
from: a/b/c
to: d/e/f
date: 2026-01-02
status: in-progress
subject: "Status in-progress"
---
# Test
MD

    # resolved → resolved
    cat > "$MOCK_REPO/usr/jordan/captain/dispatches/dispatch-resolved.md" <<'MD'
---
type: dispatch
from: a/b/c
to: d/e/f
date: 2026-01-03
status: resolved
subject: "Status resolved"
---
# Test
MD

    run "$MIGRATE" dispatches
    assert_success

    local s1 s2 s3
    s1=$(_db_query "SELECT status FROM dispatches WHERE subject='Status created'")
    s2=$(_db_query "SELECT status FROM dispatches WHERE subject='Status in-progress'")
    s3=$(_db_query "SELECT status FROM dispatches WHERE subject='Status resolved'")

    [[ "$s1" == "unread" ]]
    [[ "$s2" == "read" ]]
    [[ "$s3" == "resolved" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Idempotency
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-migrate dispatches: idempotent — no duplicates on re-run" {
    mkdir -p "$MOCK_REPO/usr/jordan/captain/dispatches"
    cat > "$MOCK_REPO/usr/jordan/captain/dispatches/dispatch-idem.md" <<'MD'
---
type: dispatch
from: a/b/c
to: d/e/f
date: 2026-01-01
subject: "Idempotent test"
---
# Test
MD

    "$MIGRATE" dispatches > /dev/null 2>&1
    "$MIGRATE" dispatches > /dev/null 2>&1

    local count
    count=$(_db_query "SELECT count(*) FROM dispatches")
    [[ "$count" -eq 1 ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# code-reviews/ scanning (MAR F-1)
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-migrate dispatches: scans code-reviews/ directory" {
    mkdir -p "$MOCK_REPO/usr/jordan/captain/code-reviews"
    cat > "$MOCK_REPO/usr/jordan/captain/code-reviews/review-findings-20260401.md" <<'MD'
---
type: review
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-01
subject: "Code review findings"
---
# Review findings
MD

    run "$MIGRATE" dispatches
    assert_success

    local count
    count=$(_db_query "SELECT count(*) FROM dispatches")
    [[ "$count" -eq 1 ]]

    local dtype
    dtype=$(_db_query "SELECT type FROM dispatches WHERE id=1")
    [[ "$dtype" == "review" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Full migration
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-migrate: full migration runs both flags and dispatches" {
    mkdir -p "$MOCK_REPO/usr/jordan"
    echo '{"ts":"2026-04-03T00:00:00Z","message":"a flag","principal":"jordan","branch":"main","session":""}' \
        > "$MOCK_REPO/usr/jordan/flag-queue.jsonl"

    mkdir -p "$MOCK_REPO/usr/jordan/captain/dispatches"
    cat > "$MOCK_REPO/usr/jordan/captain/dispatches/dispatch-full.md" <<'MD'
---
type: dispatch
from: a/b/c
to: d/e/f
date: 2026-01-01
subject: "Full migration"
---
# Test
MD

    run "$MIGRATE"
    assert_success
    assert_output_contains "1 flags imported"
    assert_output_contains "1 imported"
    assert_output_contains "Migration complete"
}

# ─────────────────────────────────────────────────────────────────────────────
# Help and version
# ─────────────────────────────────────────────────────────────────────────────

@test "iscp-migrate: --help shows usage" {
    run "$MIGRATE" --help
    assert_success
    assert_output_contains "iscp-migrate"
    assert_output_contains "flags"
    assert_output_contains "dispatches"
}

@test "iscp-migrate: --version shows version" {
    run "$MIGRATE" --version
    assert_success
    assert_output_contains "1.0.0"
}
