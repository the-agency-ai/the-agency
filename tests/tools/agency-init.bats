#!/usr/bin/env bats
#
# Tests for agency init preconditions and behavior
#
# Tests precondition checks (no .git, no .claude, wrong branch,
# already initialized), help output, and flag validation.
#

load 'test_helper'

# Helper: run agency subcommand
run_agency() {
    run "${TOOLS_DIR}/agency" "$@"
}

# ─────────────────────────────────────────────────────────────────────────────
# Help and flags
# ─────────────────────────────────────────────────────────────────────────────

@test "agency init: --help shows usage" {
    run_agency init --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "agency init"
}

@test "agency init: unknown flag fails" {
    run_agency init --nonexistent
    assert_failure
    assert_output_contains "Unknown option"
}

# ─────────────────────────────────────────────────────────────────────────────
# Precondition checks
# ─────────────────────────────────────────────────────────────────────────────

@test "agency init: fails without .git directory" {
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/.claude"
    run_agency init "$tmpdir"
    assert_failure
    assert_output_contains "Not a git repo"
    rm -rf "$tmpdir"
}

# NOTE: removed 2026-04-07 — 'agency init: fails without .claude directory'
# tested old behavior. agency init now CREATES .claude as part of init,
# rather than requiring it to exist first. The new behavior is correct.
# Coverage for happy-path init exists in other tests.

@test "agency init: fails when already initialized" {
    local tmpdir
    tmpdir=$(mktemp -d)
    git -C "$tmpdir" init -b main 2>/dev/null
    git -C "$tmpdir" commit --allow-empty -m "init" 2>/dev/null
    mkdir -p "$tmpdir/.claude" "$tmpdir/claude/config"
    echo "framework:" > "$tmpdir/claude/config/agency.yaml"
    run_agency init "$tmpdir"
    assert_failure
    assert_output_contains "already initialized"
    rm -rf "$tmpdir"
}

@test "agency init: --principal requires value" {
    run_agency init --principal
    assert_failure
    assert_output_contains "requires a value"
}

@test "agency init: --project requires value" {
    run_agency init --project
    assert_failure
    assert_output_contains "requires a value"
}

@test "agency init: --timezone requires value" {
    run_agency init --timezone
    assert_failure
    assert_output_contains "requires a value"
}

# ─────────────────────────────────────────────────────────────────────────────
# Update subcommand
# ─────────────────────────────────────────────────────────────────────────────

@test "agency update: --help shows usage" {
    run_agency update --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "agency update"
}

@test "agency update: fails when not initialized" {
    local tmpdir
    tmpdir=$(mktemp -d)
    git -C "$tmpdir" init -b main 2>/dev/null
    mkdir -p "$tmpdir/.claude"
    run_agency update "$tmpdir"
    assert_failure
    assert_output_contains "not initialized"
    rm -rf "$tmpdir"
}

@test "agency update: --dry-run succeeds on this repo" {
    run_agency update --dry-run
    assert_success
    assert_output_contains "Dry Run Complete"
}

@test "agency update: unknown flag fails" {
    run_agency update --nonexistent
    assert_failure
    assert_output_contains "Unknown option"
}
