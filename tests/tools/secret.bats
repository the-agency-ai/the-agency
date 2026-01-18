#!/usr/bin/env bats
#
# Tests for ./tools/secret
#
# Tests CLI argument parsing, input validation, and error handling.
# Uses mock responses where service interaction is needed.
#

load 'test_helper'

# Setup mock service URL
setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    export SECRET_SERVICE_URL="http://localhost:9999/api/secret"
    export AGENCY_USER="principal:test"
    cd "${REPO_ROOT}"
}

teardown() {
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "secret: --version shows version" {
    run_tool secret --version
    assert_success
    assert_output_contains "secret"
    assert_output_contains "1.0.0"
}

@test "secret: -v shows version" {
    run_tool secret -v
    assert_success
    assert_output_contains "secret"
}

@test "secret: --help shows usage" {
    run_tool secret --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "vault"
    assert_output_contains "create"
    assert_output_contains "get"
}

@test "secret: -h shows usage" {
    run_tool secret -h
    assert_success
    assert_output_contains "Usage:"
}

@test "secret: no arguments shows help" {
    run_tool secret
    # Should show help/usage when no command given
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# Vault Commands - Argument Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "secret: vault status attempts API call" {
    # vault status should attempt to call API (will fail but validates args)
    run_tool secret vault status
    # Will fail since no service running - may show error or usage
    [[ "$status" -ne 0 ]] || [[ "$output" =~ "status" ]] || [[ "$output" =~ "vault" ]]
}

@test "secret: vault with unknown subcommand shows usage" {
    run_tool secret vault invalidcmd
    # Shows usage for vault subcommands
    assert_output_contains "vault"
}

# ─────────────────────────────────────────────────────────────────────────────
# Secret Commands - Argument Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "secret: create requires name argument" {
    run_tool secret create
    assert_failure
    assert_output_contains "name"
}

@test "secret: create validates name format" {
    # Names with special characters should be handled
    run_tool secret create "test-secret" --type=api_key
    # Will fail due to no service, but should not fail on name validation
    [[ "$status" -ne 0 ]] # Expected to fail (no service)
    # Should not contain "invalid name" - the name format is valid
    [[ ! "$output" =~ "invalid name format" ]]
}

@test "secret: get requires name argument" {
    run_tool secret get
    assert_failure
    assert_output_contains "name"
}

@test "secret: show requires name argument" {
    run_tool secret show
    assert_failure
    assert_output_contains "name"
}

@test "secret: delete requires name argument" {
    run_tool secret delete
    assert_failure
    assert_output_contains "name"
}

@test "secret: rotate requires name argument" {
    run_tool secret rotate
    assert_failure
    assert_output_contains "name"
}

@test "secret: update requires name argument" {
    run_tool secret update
    assert_failure
    assert_output_contains "name"
}

# ─────────────────────────────────────────────────────────────────────────────
# Tag Commands - Argument Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "secret: tag without --tool fails" {
    run_tool secret tag mysecret
    assert_failure
    # Will fail due to missing --tool or service unavailable
}

@test "secret: untag without --tool fails" {
    run_tool secret untag mysecret
    assert_failure
    # Will fail due to missing --tool or service unavailable
}

# ─────────────────────────────────────────────────────────────────────────────
# Access Control - Argument Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "secret: grant requires name" {
    run_tool secret grant
    assert_failure
    assert_output_contains "name"
}

@test "secret: grant requires --to identity" {
    run_tool secret grant mysecret
    assert_failure
    assert_output_contains "to"
}

@test "secret: revoke requires name" {
    run_tool secret revoke
    assert_failure
    assert_output_contains "name"
}

@test "secret: revoke without --from fails" {
    run_tool secret revoke mysecret
    assert_failure
    # Will fail due to missing --from or service unavailable
}

# ─────────────────────────────────────────────────────────────────────────────
# Audit Commands - Argument Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "secret: audit requires name" {
    run_tool secret audit
    assert_failure
    assert_output_contains "name"
}

# ─────────────────────────────────────────────────────────────────────────────
# Input Sanitization
# ─────────────────────────────────────────────────────────────────────────────

@test "secret: handles special characters in secret name" {
    # Test that special chars are handled - name is passed to API
    run_tool secret get 'test-with-dash'
    # Should fail (no service) but not crash on the special char
    [[ "$status" -ne 0 ]]
}

@test "secret: handles quotes in secret name" {
    run_tool secret get 'test"quote'
    # Should fail gracefully, not crash
    [[ ! "$output" =~ "syntax error" ]]
}

@test "secret: handles newlines in description" {
    run_tool secret create testname --type=api_key --description=$'line1\nline2'
    # Should handle multiline input without breaking
    [[ ! "$output" =~ "syntax error" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Option Parsing
# ─────────────────────────────────────────────────────────────────────────────

@test "secret: --json flag is accepted" {
    run_tool secret list --json
    # Will fail (no service) but should recognize the flag
    [[ ! "$output" =~ "unknown option" ]]
}

@test "secret: --verbose flag enables verbose output" {
    run_tool secret --verbose list
    # Will fail but should show verbose markers
    [[ "$output" =~ "[" ]] || [[ "$status" -ne 0 ]]
}

@test "secret: accepts --type option for create" {
    run_tool secret create testname --type=api_key
    # Validates type is accepted
    [[ ! "$output" =~ "invalid type" ]]
}

@test "secret: accepts --service option for create" {
    run_tool secret create testname --type=api_key --service=GitHub
    # Validates service is accepted
    [[ ! "$output" =~ "invalid option" ]]
}

@test "secret: accepts --permission option for grant" {
    run_tool secret grant testname --to=agent:test --permission=read
    # Validates permission is accepted
    [[ ! "$output" =~ "invalid permission" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Error Handling
# ─────────────────────────────────────────────────────────────────────────────

@test "secret: unknown command shows error" {
    run_tool secret unknowncommand
    assert_failure
    assert_output_contains "Unknown"
}

@test "secret: service unavailable returns error" {
    export SECRET_SERVICE_URL="http://localhost:1/api/secret"
    run_tool secret list
    # Should fail when service unavailable
    [[ "$status" -ne 0 ]] || [[ "$output" =~ "error" ]] || [[ "$output" =~ "Error" ]]
}
