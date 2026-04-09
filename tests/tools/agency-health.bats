#!/usr/bin/env bats
#
# Tests for claude/tools/agency-health
#
# Strategy: smoke-test the tool shape (version, help, exit codes, dimension
# dispatch, JSON mode) against the LIVE repo. The health checkers run on
# real data, so assertions are loose: "it runs and exits with a reasonable
# code" rather than "it produces exactly N warnings." For tight assertions
# on individual checks, we would need a fixture repo — deferred to v2.
#

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup
    cd "${REPO_ROOT}"
}

teardown() {
    test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Version / help / error paths
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-health: --version shows version" {
    run_tool agency-health --version
    assert_success
    assert_output_contains "agency-health"
    assert_output_contains "1.0.0"
}

@test "agency-health: --help shows usage" {
    run_tool agency-health --help
    assert_success
    assert_output_contains "fleet health"
    assert_output_contains "workstream"
    assert_output_contains "agent"
    assert_output_contains "worktree"
    assert_output_contains "EXIT CODES"
}

@test "agency-health: unknown arg exits non-zero with usage" {
    run_tool agency-health --bogus
    [[ "$status" -ne 0 ]]
    assert_output_contains "unknown argument"
}

# ─────────────────────────────────────────────────────────────────────────────
# Dimension dispatch — each runs without error
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-health: worktree runs without crash" {
    run_tool agency-health worktree
    # Exit code is 0, 1, or 2 depending on actual fleet state
    [[ "$status" -ge 0 && "$status" -le 2 ]]
    assert_output_contains "WORKTREES"
}

@test "agency-health: agent runs without crash" {
    run_tool agency-health agent
    [[ "$status" -ge 0 && "$status" -le 2 ]]
    assert_output_contains "AGENTS"
}

@test "agency-health: workstream runs without crash" {
    run_tool agency-health workstream
    [[ "$status" -ge 0 && "$status" -le 2 ]]
    assert_output_contains "WORKSTREAMS"
}

@test "agency-health: all runs without crash and shows three sections" {
    run_tool agency-health
    [[ "$status" -ge 0 && "$status" -le 2 ]]
    assert_output_contains "WORKSTREAMS"
    assert_output_contains "AGENTS"
    assert_output_contains "WORKTREES"
    assert_output_contains "OVERALL:"
}

@test "agency-health: all (explicit) runs the same as bare" {
    run_tool agency-health all
    [[ "$status" -ge 0 && "$status" -le 2 ]]
    assert_output_contains "WORKSTREAMS"
    assert_output_contains "AGENTS"
    assert_output_contains "WORKTREES"
}

# ─────────────────────────────────────────────────────────────────────────────
# Target filter — passing a name only scopes to that item
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-health: workstream <name> scopes to single workstream" {
    # Run against 'agency' which exists in the live repo
    run_tool agency-health workstream agency
    [[ "$status" -ge 0 && "$status" -le 2 ]]
    assert_output_contains "agency"
}

@test "agency-health: worktree <name> nonexistent surfaces critical" {
    run_tool agency-health worktree this-worktree-does-not-exist
    # Expected exit 2 because nonexistent target is critical
    [[ "$status" -eq 2 ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# JSON mode
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-health: --json produces JSON output" {
    run_tool agency-health --json workstream
    [[ "$status" -ge 0 && "$status" -le 2 ]]
    # Output should contain JSON braces and a timestamp field
    assert_output_contains '"timestamp"'
    assert_output_contains '"version"'
    assert_output_contains '"summary"'
}
