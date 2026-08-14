#!/usr/bin/env bats
#
# Tests for tools/opportunities
#
# Run with: bats tests/tools/opportunities.bats
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────
# CLI argument tests
# ─────────────────────────────────────────────────────────────

@test "opportunities: --version shows version" {
    run "${REPO_ROOT}/src/tools-developer/opportunities" --version
    assert_success
    assert_output_contains "opportunities"
    assert_output_contains "1.0.0"
}

@test "opportunities: --help shows usage" {
    run "${REPO_ROOT}/src/tools-developer/opportunities" --help
    assert_success
    assert_output_contains "Usage"
}

@test "opportunities: accepts --since parameter" {
    # Should not error even if service unavailable
    run "${REPO_ROOT}/src/tools-developer/opportunities" --since 7d 2>&1 || true
    # Just verify it doesn't fail on argument parsing
    [[ ! "$output" =~ "Unknown option" ]]
}

@test "opportunities: accepts --patterns flag" {
    run "${REPO_ROOT}/src/tools-developer/opportunities" --patterns 2>&1 || true
    [[ ! "$output" =~ "Unknown option" ]]
}

@test "opportunities: accepts --output flag" {
    run "${REPO_ROOT}/src/tools-developer/opportunities" --output 2>&1 || true
    [[ ! "$output" =~ "Unknown option" ]]
}

@test "opportunities: accepts --input flag" {
    run "${REPO_ROOT}/src/tools-developer/opportunities" --input 2>&1 || true
    [[ ! "$output" =~ "Unknown option" ]]
}

@test "opportunities: accepts --failures flag" {
    run "${REPO_ROOT}/src/tools-developer/opportunities" --failures 2>&1 || true
    [[ ! "$output" =~ "Unknown option" ]]
}

@test "opportunities: accepts --all flag" {
    run "${REPO_ROOT}/src/tools-developer/opportunities" --all 2>&1 || true
    [[ ! "$output" =~ "Unknown option" ]]
}

@test "opportunities: rejects unknown options" {
    run "${REPO_ROOT}/src/tools-developer/opportunities" --unknown-flag
    assert_failure
    assert_output_contains "Unknown option"
}
