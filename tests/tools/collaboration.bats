#!/usr/bin/env bats
#
# Tests for collaboration tools: collaborate, collaboration-respond
#
# Tests CLI argument parsing, validation, and error handling.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# collaborate - Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "collaborate: --version shows version" {
    run_tool collaborate --version
    assert_success
    assert_output_contains "collaborate"
}

@test "collaborate: -v shows version" {
    run_tool collaborate -v
    assert_success
    assert_output_contains "collaborate"
}

@test "collaborate: --help shows usage" {
    run_tool collaborate --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "target-agent"
    assert_output_contains "subject"
}

@test "collaborate: -h shows usage" {
    run_tool collaborate -h
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# collaborate - Argument Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "collaborate: requires 3 arguments" {
    run_tool collaborate
    assert_failure
    assert_output_contains "Usage:"
}

@test "collaborate: with 1 argument shows usage" {
    run_tool collaborate "target-agent"
    assert_failure
    assert_output_contains "Usage:"
}

@test "collaborate: with 2 arguments shows usage" {
    run_tool collaborate "target-agent" "subject"
    assert_failure
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# collaborate - Flag Recognition
# ─────────────────────────────────────────────────────────────────────────────

@test "collaborate: --verbose flag is recognized" {
    run_tool collaborate --verbose "agent" "subject" "description"
    # Will fail (git operations) but should not complain about unknown flag
    [[ ! "$output" =~ "unknown flag" ]] && [[ ! "$output" =~ "invalid option" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# collaboration-respond - Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "collaboration-respond: --version shows version" {
    run_tool collaboration-respond --version
    assert_success
    assert_output_contains "collaboration-respond"
}

@test "collaboration-respond: -v shows version" {
    run_tool collaboration-respond -v
    assert_success
    assert_output_contains "collaboration-respond"
}

@test "collaboration-respond: --help shows usage" {
    run_tool collaboration-respond --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "collaboration-file"
}

@test "collaboration-respond: -h shows usage" {
    run_tool collaboration-respond -h
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# collaboration-respond - Argument Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "collaboration-respond: requires 2 arguments" {
    run_tool collaboration-respond
    assert_failure
    assert_output_contains "Usage:"
}

@test "collaboration-respond: with 1 argument shows usage" {
    run_tool collaboration-respond "path/to/file.md"
    assert_failure
    assert_output_contains "Usage:"
}

@test "collaboration-respond: non-existent file shows error" {
    run_tool collaboration-respond "/nonexistent/file.md" "response"
    assert_failure
    assert_output_contains "File not found"
}

# ─────────────────────────────────────────────────────────────────────────────
# collaboration-respond - Flag Recognition
# ─────────────────────────────────────────────────────────────────────────────

@test "collaboration-respond: --verbose flag is recognized" {
    run_tool collaboration-respond --verbose "/nonexistent.md" "response"
    # Will fail (file not found) but should not complain about unknown flag
    [[ ! "$output" =~ "unknown flag" ]] && [[ ! "$output" =~ "invalid option" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Security - Input Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "collaborate: handles special characters in target-agent" {
    # Test that shell metacharacters don't cause syntax errors or crashes
    run_tool collaborate 'agent$test' "subject" "description" || true
    # Tool should run (may fail on git ops) but not crash on special chars
    [[ ! "$output" =~ "syntax error" ]]
}

@test "collaborate: handles special characters in subject" {
    run_tool collaborate "target" "subject\$(echo pwned)" "description"
    [[ ! "$output" =~ "pwned" ]]
}

@test "collaboration-respond: handles path traversal in file path" {
    run_tool collaboration-respond "../../etc/passwd" "response"
    assert_failure
    # Should fail safely
    [[ "$output" =~ "not found" ]] || [[ "$output" =~ "Error" ]] || [[ "$status" -ne 0 ]]
}

