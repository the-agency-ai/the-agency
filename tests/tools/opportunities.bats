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
    run_tool opportunities --version
    assert_success
    assert_output_contains "opportunities"
    assert_output_contains "1.0.0"
}

@test "opportunities: --help shows usage" {
    run_tool opportunities --help
    assert_success
    assert_output_contains "Usage"
}

@test "opportunities: accepts --since parameter" {
    # Should not error even if service unavailable
    run_tool opportunities --since 7d 2>&1 || true
    # Just verify it doesn't fail on argument parsing
    [[ ! "$output" =~ "Unknown option" ]]
}

@test "opportunities: accepts --patterns flag" {
    run_tool opportunities --patterns 2>&1 || true
    [[ ! "$output" =~ "Unknown option" ]]
}

@test "opportunities: accepts --output flag" {
    run_tool opportunities --output 2>&1 || true
    [[ ! "$output" =~ "Unknown option" ]]
}

@test "opportunities: accepts --input flag" {
    run_tool opportunities --input 2>&1 || true
    [[ ! "$output" =~ "Unknown option" ]]
}

@test "opportunities: accepts --failures flag" {
    run_tool opportunities --failures 2>&1 || true
    [[ ! "$output" =~ "Unknown option" ]]
}

@test "opportunities: accepts --all flag" {
    run_tool opportunities --all 2>&1 || true
    [[ ! "$output" =~ "Unknown option" ]]
}

@test "opportunities: rejects unknown options" {
    run_tool opportunities --unknown-flag
    assert_failure
    assert_output_contains "Unknown option"
}
