#!/usr/bin/env bats
#
# Tests for ./tools/myclaude
#
# Tests CLI argument parsing, validation, and flag handling.
# Does NOT actually launch Claude (interactive session).
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "myclaude: --version shows version" {
    run_tool myclaude --version
    assert_success
    assert_output_contains "myclaude"
}

@test "myclaude: -v shows version" {
    run_tool myclaude -v
    assert_success
    assert_output_contains "myclaude"
}

@test "myclaude: no arguments shows usage and error" {
    run_tool myclaude
    assert_failure
    assert_output_contains "Usage:"
    assert_output_contains "WORKSTREAM"
}

@test "myclaude: one argument shows usage and error" {
    run_tool myclaude housekeeping
    assert_failure
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# Agent Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "myclaude: non-existent agent shows error" {
    run_tool myclaude housekeeping nonexistent-agent-xyz
    assert_failure
    assert_output_contains "Agent not found"
}

@test "myclaude: shows available agents on error" {
    run_tool myclaude
    assert_failure
    assert_output_contains "Available agents:"
}

# ─────────────────────────────────────────────────────────────────────────────
# Flag Recognition
# ─────────────────────────────────────────────────────────────────────────────

@test "myclaude: --verbose flag is recognized" {
    # Will still fail (no claude binary in test env) but validates flag parsing
    run_tool myclaude --verbose housekeeping nonexistent
    # Should not complain about unknown flag
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "invalid flag" ]]
}

@test "myclaude: --debug flag is recognized" {
    run_tool myclaude --debug housekeeping nonexistent
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "invalid flag" ]]
}

@test "myclaude: --update flag is recognized" {
    # Will fail (npm install) but validates flag parsing
    run_tool myclaude --update 2>&1 || true
    # Should attempt npm install, not show usage error
    [[ ! "$output" =~ "Usage:" ]] || [[ "$output" =~ "npm" ]] || [[ "$output" =~ "Claude" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Security - Input Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "myclaude: handles special characters in workstream" {
    run_tool myclaude "test; echo pwned" captain
    # Should fail gracefully (either agent not found or workstream validation)
    # Should NOT execute injected command
    [[ ! "$output" =~ "pwned" ]]
}

@test "myclaude: handles special characters in agent name" {
    run_tool myclaude housekeeping "captain; rm -rf /"
    assert_failure
    # Should show agent not found, not execute command
    [[ "$output" =~ "Agent not found" ]] || [[ "$output" =~ "Error" ]]
}

@test "myclaude: handles path traversal in agent name" {
    run_tool myclaude housekeeping "../../../etc/passwd"
    assert_failure
    assert_output_contains "Agent not found"
}

@test "myclaude: handles quotes in prompt" {
    # Test that quotes in prompt don't break argument parsing
    run_tool myclaude housekeeping nonexistent "test \"quoted\" prompt"
    assert_failure
    # Should fail on agent not found, not shell syntax error
    [[ "$output" =~ "Agent not found" ]] || [[ "$output" =~ "not found" ]]
}

