#!/usr/bin/env bats
#
# Tests for ./tools/starter-release
#
# Tests CLI argument parsing, validation, and flag handling.
# Note: Many tests use --dry-run to avoid actual file system changes.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "starter-release: --version shows version" {
    run_tool starter-release --version
    assert_success
    assert_output_contains "starter-release"
}

@test "starter-release: -v shows version" {
    run_tool starter-release -v
    assert_success
    assert_output_contains "starter-release"
}

@test "starter-release: --help shows usage" {
    run_tool starter-release --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "starter-release"
    assert_output_contains "--push"
    assert_output_contains "--github"
}

@test "starter-release: -h shows usage" {
    run_tool starter-release -h
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# Flag Recognition
# ─────────────────────────────────────────────────────────────────────────────

@test "starter-release: --dry-run flag is recognized" {
    run_tool starter-release patch --dry-run
    # Should succeed or fail gracefully (might fail if starter dir missing)
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "invalid flag" ]]
}

@test "starter-release: -n flag is alias for --dry-run" {
    run_tool starter-release patch -n
    [[ ! "$output" =~ "unknown option" ]]
}

@test "starter-release: --sync-only flag is recognized" {
    run_tool starter-release --sync-only --dry-run
    [[ ! "$output" =~ "unknown option" ]]
}

@test "starter-release: -s flag is alias for --sync-only" {
    run_tool starter-release -s --dry-run
    [[ ! "$output" =~ "unknown option" ]]
}

@test "starter-release: --push flag is recognized" {
    run_tool starter-release patch --push --dry-run --verbose
    [[ ! "$output" =~ "unknown option" ]]
    assert_output_contains "Would push"
}

@test "starter-release: --github flag is recognized" {
    run_tool starter-release patch --github --dry-run --verbose
    [[ ! "$output" =~ "unknown option" ]]
    assert_output_contains "Would create GitHub release"
}

@test "starter-release: --build-bench flag is recognized" {
    run_tool starter-release patch --build-bench --dry-run --verbose
    [[ ! "$output" =~ "unknown option" ]]
    assert_output_contains "Would build AgencyBench"
}

@test "starter-release: --verbose flag is recognized" {
    run_tool starter-release patch --verbose --dry-run
    [[ ! "$output" =~ "unknown option" ]]
}

@test "starter-release: combined flags work together" {
    run_tool starter-release patch --push --github --verbose --dry-run
    [[ ! "$output" =~ "unknown option" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Version Arguments
# ─────────────────────────────────────────────────────────────────────────────

@test "starter-release: accepts 'patch' as version" {
    run_tool starter-release patch --dry-run --verbose
    [[ "$output" =~ "New version:" ]]
}

@test "starter-release: accepts 'minor' as version" {
    run_tool starter-release minor --dry-run --verbose
    [[ "$output" =~ "New version:" ]]
}

@test "starter-release: accepts 'major' as version" {
    run_tool starter-release major --dry-run --verbose
    [[ "$output" =~ "New version:" ]]
}

@test "starter-release: accepts explicit semver version" {
    run_tool starter-release 99.99.99 --dry-run --verbose
    assert_output_contains "New version: 99.99.99"
}

@test "starter-release: rejects invalid version format" {
    run_tool starter-release invalid --dry-run
    assert_failure
    assert_output_contains "Invalid version format"
}

@test "starter-release: rejects partial version (1.0)" {
    run_tool starter-release 1.0 --dry-run
    assert_failure
    assert_output_contains "Invalid version format"
}

@test "starter-release: rejects version with letters (1.0.a)" {
    run_tool starter-release 1.0.a --dry-run
    assert_failure
    assert_output_contains "Invalid version format"
}

# ─────────────────────────────────────────────────────────────────────────────
# Error Handling
# ─────────────────────────────────────────────────────────────────────────────

# Note: Testing "starter directory not found" is difficult because the tool
# first checks for a sibling repo before using THE_AGENCY_STARTER_DIR env var.
# This would require filesystem mocking to properly test.

# ─────────────────────────────────────────────────────────────────────────────
# Dry Run Mode
# ─────────────────────────────────────────────────────────────────────────────

@test "starter-release: dry-run shows what would happen" {
    run_tool starter-release patch --dry-run --verbose
    # Should show planned actions
    assert_output_contains "DRY RUN"
    assert_output_contains "Would sync files"
    assert_output_contains "Would clean cruft"
    assert_output_contains "Would verify build"
    assert_output_contains "Would commit and tag"
}

@test "starter-release: dry-run with push shows push would happen" {
    run_tool starter-release patch --dry-run --push --verbose
    assert_output_contains "Would push to origin"
}

@test "starter-release: dry-run with github shows release would happen" {
    run_tool starter-release patch --dry-run --github --verbose
    assert_output_contains "Would create GitHub release"
}
