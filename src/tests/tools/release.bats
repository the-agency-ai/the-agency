#!/usr/bin/env bats
#
# Tests for ./tools/release
#
# Tests CLI argument parsing, validation, and flag handling.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "release: --version shows version" {
    run_tool release --version
    assert_success
    assert_output_contains "release"
}

@test "release: -v shows version" {
    run_tool release -v
    assert_success
    assert_output_contains "release"
}

@test "release: --help shows usage" {
    run_tool release --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "release"
}

@test "release: -h shows usage" {
    run_tool release -h
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# Argument Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "release: requires version argument" {
    run_tool release
    assert_failure
    assert_output_contains "Version required"
}

# ─────────────────────────────────────────────────────────────────────────────
# Flag Recognition
# ─────────────────────────────────────────────────────────────────────────────

@test "release: --dry-run flag is recognized" {
    # Feed 'y' to answer uncommitted changes prompt
    run bash -c "echo y | \"${TOOLS_DIR}/release\" 99.99.99 --dry-run 2>&1"
    # Should complete (success or abort)
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "invalid flag" ]]
}

@test "release: --push flag is recognized" {
    run_tool release 99.99.99 --push --dry-run
    [[ ! "$output" =~ "unknown option" ]]
}

@test "release: --github flag is recognized" {
    run_tool release 99.99.99 --github --dry-run
    [[ ! "$output" =~ "unknown option" ]]
}

@test "release: --changelog flag generates changelog only" {
    run_tool release 99.99.99 --changelog
    # Will fail since tag exists already, but validates flag works
    [[ ! "$output" =~ "unknown option" ]]
    assert_output_contains "Changes"
}

@test "release: --request flag is recognized" {
    run_tool release 99.99.99 --request REQUEST-test --dry-run
    [[ ! "$output" =~ "unknown option" ]]
}

@test "release: --verbose flag is recognized" {
    run_tool release 99.99.99 --verbose --dry-run
    [[ ! "$output" =~ "unknown option" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Version Types
# ─────────────────────────────────────────────────────────────────────────────

@test "release: accepts 'patch' as version" {
    run bash -c "echo y | \"${TOOLS_DIR}/release\" patch --dry-run 2>&1"
    [[ ! "$output" =~ "invalid" ]] && [[ ! "$output" =~ "unknown" ]]
}

@test "release: accepts 'minor' as version" {
    run bash -c "echo y | \"${TOOLS_DIR}/release\" minor --dry-run 2>&1"
    [[ ! "$output" =~ "invalid" ]] && [[ ! "$output" =~ "unknown" ]]
}

@test "release: accepts 'major' as version" {
    run bash -c "echo y | \"${TOOLS_DIR}/release\" major --dry-run 2>&1"
    [[ ! "$output" =~ "invalid" ]] && [[ ! "$output" =~ "unknown" ]]
}

@test "release: accepts semver version" {
    run bash -c "echo y | \"${TOOLS_DIR}/release\" 99.2.3 --dry-run 2>&1"
    assert_output_contains "v99.2.3"
}

@test "release: accepts release candidate version" {
    run bash -c "echo y | \"${TOOLS_DIR}/release\" 99.0.0-rc1 --dry-run 2>&1"
    assert_output_contains "v99.0.0-rc1"
}

# ─────────────────────────────────────────────────────────────────────────────
# Security - Input Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "release: handles special characters in version" {
    # Should not crash on special characters
    run_tool release 'version$test' --dry-run || true
    [[ ! "$output" =~ "syntax error" ]]
}

@test "release: handles spaces in version" {
    run_tool release 'bad version' --dry-run || true
    # Should handle gracefully (fail or accept)
    [[ ! "$output" =~ "syntax error" ]]
}

