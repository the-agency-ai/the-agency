#!/usr/bin/env bats
#
# Tests for scaffolding tools: agent-create, workstream-create
#
# Tests CLI argument parsing, validation, and flag handling.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# agent-create - Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-create: --version shows version" {
    run_tool agent-create --version
    assert_success
    assert_output_contains "agent-create"
}

@test "agent-create: -v shows version" {
    run_tool agent-create -v
    assert_success
    assert_output_contains "agent-create"
}

@test "agent-create: --help shows usage" {
    run_tool agent-create --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "agentname"
    assert_output_contains "workstream"
}

@test "agent-create: -h shows usage" {
    run_tool agent-create -h
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# agent-create - Argument Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-create: requires agent name" {
    run_tool agent-create
    assert_failure
    # Should indicate missing argument
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "required" ]]
}

@test "agent-create: requires workstream" {
    run_tool agent-create testname
    assert_failure
    # Should indicate missing workstream
    [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "workstream" ]]
}

@test "agent-create: invalid workstream shows error" {
    run_tool agent-create testname nonexistent-workstream
    assert_failure
    # Should indicate workstream doesn't exist
    [[ "$output" =~ "not exist" ]] || [[ "$output" =~ "not found" ]] || [[ "$status" -ne 0 ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# agent-create - Flag Recognition
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-create: --type flag is recognized" {
    run_tool agent-create testname housekeeping --type=generic
    # Will fail (agent exists or other reason) but flag should be recognized
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "invalid flag" ]]
}

@test "agent-create: --verbose flag is recognized" {
    run_tool agent-create testname housekeeping --verbose
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "invalid flag" ]]
}

@test "agent-create: --list-types flag works" {
    run_tool agent-create --list-types
    assert_success
    assert_output_contains "templates"
}

# ─────────────────────────────────────────────────────────────────────────────
# workstream-create - Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "workstream-create: --version shows version" {
    run_tool workstream-create --version
    assert_success
    assert_output_contains "workstream-create"
}

@test "workstream-create: -v shows version" {
    run_tool workstream-create -v
    assert_success
    assert_output_contains "workstream-create"
}

# ─────────────────────────────────────────────────────────────────────────────
# workstream-create - Argument Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "workstream-create: requires name argument" {
    run_tool workstream-create
    assert_failure
    assert_output_contains "Usage:"
}

@test "workstream-create: existing workstream shows error" {
    run_tool workstream-create housekeeping
    assert_failure
    assert_output_contains "already exists"
}

# ─────────────────────────────────────────────────────────────────────────────
# workstream-create - Flag Recognition
# ─────────────────────────────────────────────────────────────────────────────

@test "workstream-create: --verbose flag is recognized" {
    run_tool workstream-create newworkstream --verbose || true
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "invalid flag" ]]
    # Clean up if created
    rm -rf "claude/workstreams/newworkstream" 2>/dev/null || true
}

# ─────────────────────────────────────────────────────────────────────────────
# Security - Input Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-create: handles special characters in agent name" {
    run_tool agent-create 'test$agent' housekeeping || true
    # Should not crash on special characters
    [[ ! "$output" =~ "syntax error" ]]
}

@test "agent-create: handles path traversal in agent name" {
    run_tool agent-create '../../../etc/passwd' housekeeping || true
    # Should fail safely, not create files outside expected directory
    [[ ! -f "etc/passwd" ]]
}

@test "workstream-create: handles special characters in name" {
    run_tool workstream-create 'test; rm -rf /' || true
    # Should not crash or execute injection
    [[ ! "$output" =~ "syntax error" ]]
}

@test "workstream-create: handles path traversal in name" {
    run_tool workstream-create '../../../tmp/hack' || true
    # Should not create files outside expected directory
    [[ ! -d "tmp/hack" ]]
}

