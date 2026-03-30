#!/usr/bin/env bats
#
# Tests for tools/agency-verify
#
# Tests provider configuration validation, directory checks,
# pass/fail/warn counting, and exit codes.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# CLI flags
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-verify: --version shows version" {
    run_tool agency-verify --version
    assert_success
    assert_output_contains "agency-verify"
}

@test "agency-verify: --help shows usage" {
    run_tool agency-verify --help
    assert_success
    assert_output_contains "Usage"
}

# ─────────────────────────────────────────────────────────────────────────────
# Against real project
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-verify: passes on the-agency repo" {
    run_tool agency-verify
    assert_success
    assert_output_contains "checks passed"
    assert_output_contains "✓"
}

@test "agency-verify: verbose shows individual checks" {
    run_tool agency-verify --verbose
    assert_success
    assert_output_contains "agency.yaml exists"
    assert_output_contains "_provider-resolve loaded"
}

@test "agency-verify: reports secrets provider" {
    run_tool agency-verify --verbose
    assert_success
    assert_output_contains "secrets: secret-vault"
}

@test "agency-verify: reports terminal provider" {
    run_tool agency-verify --verbose
    assert_success
    assert_output_contains "terminal: terminal-setup-ghostty"
}

@test "agency-verify: reports platform provider (auto-detected)" {
    run_tool agency-verify --verbose
    assert_success
    assert_output_contains "platform: platform-setup-"
}

@test "agency-verify: reports design providers as deferred warnings" {
    run_tool agency-verify --verbose
    assert_success
    assert_output_contains "design.diff"
    assert_output_contains "deferred"
}

@test "agency-verify: checks required directories" {
    run_tool agency-verify --verbose
    assert_success
    assert_output_contains "directory: claude/config/"
    assert_output_contains "directory: claude/agents/"
    assert_output_contains "directory: claude/docs/"
    assert_output_contains "directory: claude/hooks/"
}
