#!/usr/bin/env bats
#
# Tests for ./tools/gh and related wrappers (gh-pr, gh-release, gh-api)
#
# Tests token injection, security, and delegation patterns.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Version and Help - tools/gh
# ─────────────────────────────────────────────────────────────────────────────

@test "gh: --version shows wrapper version" {
    run_tool gh --version
    assert_success
    assert_output_contains "gh .agency wrapper"
}

@test "gh: -v shows wrapper version" {
    run_tool gh -v
    assert_success
    assert_output_contains "gh .agency wrapper"
}

@test "gh: --help shows wrapper help" {
    run_tool gh --help
    assert_success
    assert_output_contains "GitHub CLI wrapper"
    assert_output_contains "token injection"
    assert_output_contains "GH_TOKEN"
}

@test "gh: --help shows security note" {
    run_tool gh --help
    assert_success
    assert_output_contains "Security"
}

# ─────────────────────────────────────────────────────────────────────────────
# Token Security - CRITICAL
# ─────────────────────────────────────────────────────────────────────────────

@test "gh: dry-run does not leak token value" {
    export GH_TOKEN="secret-test-token-12345"
    run_tool gh --dry-run pr list
    assert_success
    # Token value must NOT appear in output
    [[ ! "$output" =~ "secret-test-token-12345" ]]
    # But should indicate token is set
    [[ "$output" =~ "set" ]]
    unset GH_TOKEN
}

@test "gh: dry-run shows token source as environment" {
    export GH_TOKEN="test-token"
    run_tool gh --dry-run pr list
    assert_success
    assert_output_contains "environment"
    unset GH_TOKEN
}

@test "gh: GH_SECRET_NAME environment variable is documented" {
    run_tool gh --help
    assert_success
    assert_output_contains "GH_SECRET_NAME"
}

# ─────────────────────────────────────────────────────────────────────────────
# Dry Run Mode
# ─────────────────────────────────────────────────────────────────────────────

@test "gh: --dry-run shows command without executing" {
    export GH_TOKEN="test"
    run_tool gh --dry-run release list
    assert_success
    assert_output_contains "Would execute: gh release list"
    assert_output_contains "(dry-run)"
    unset GH_TOKEN
}

@test "gh: --dry-run shows run ID" {
    export GH_TOKEN="test"
    run_tool gh --dry-run pr list
    assert_success
    # Check for run ID pattern (bracket is regex metachar, escape it)
    [[ "$output" =~ "run:" ]]
    unset GH_TOKEN
}

# ─────────────────────────────────────────────────────────────────────────────
# Error Handling
# ─────────────────────────────────────────────────────────────────────────────

@test "gh: warning shown when no token available" {
    # Unset token and use non-existent secret
    unset GH_TOKEN
    export GH_SECRET_NAME="nonexistent-secret-name"
    run_tool gh --dry-run pr list
    # Should warn but still complete dry-run
    assert_success
    assert_output_contains "Warning"
    unset GH_SECRET_NAME
}

# ─────────────────────────────────────────────────────────────────────────────
# Version and Help - tools/gh-pr
# ─────────────────────────────────────────────────────────────────────────────

@test "gh-pr: --version shows gh-pr version" {
    run_tool gh-pr --version
    assert_success
    assert_output_contains "gh-pr"
}

@test "gh-pr: --help shows PR commands" {
    run_tool gh-pr --help
    assert_success
    assert_output_contains "list"
    assert_output_contains "create"
    assert_output_contains "merge"
}

@test "gh-pr: no args shows help" {
    run_tool gh-pr
    assert_success
    assert_output_contains "Usage"
}

# ─────────────────────────────────────────────────────────────────────────────
# Version and Help - tools/gh-release
# ─────────────────────────────────────────────────────────────────────────────

@test "gh-release: --version shows gh-release version" {
    run_tool gh-release --version
    assert_success
    assert_output_contains "gh-release"
}

@test "gh-release: --help shows release commands" {
    run_tool gh-release --help
    assert_success
    assert_output_contains "list"
    assert_output_contains "create"
}

@test "gh-release: --help mentions ./tools/release" {
    run_tool gh-release --help
    assert_success
    assert_output_contains "./tools/release"
}

@test "gh-release: no args shows help" {
    run_tool gh-release
    assert_success
    assert_output_contains "Usage"
}

# ─────────────────────────────────────────────────────────────────────────────
# Version and Help - tools/gh-api
# ─────────────────────────────────────────────────────────────────────────────

@test "gh-api: --version shows gh-api version" {
    run_tool gh-api --version
    assert_success
    assert_output_contains "gh-api"
}

@test "gh-api: --help shows API usage" {
    run_tool gh-api --help
    assert_success
    assert_output_contains "REST"
    assert_output_contains "GraphQL"
}

@test "gh-api: no args shows help" {
    run_tool gh-api
    assert_success
    assert_output_contains "Usage"
}

# ─────────────────────────────────────────────────────────────────────────────
# Integration - Delegation Pattern
# ─────────────────────────────────────────────────────────────────────────────

@test "gh-pr: delegates to gh wrapper" {
    # Verify gh-pr uses exec to ./tools/gh
    run grep -q 'exec.*gh.*pr' tools/gh-pr
    assert_success
}

@test "gh-release: delegates to gh wrapper" {
    run grep -q 'exec.*gh.*release' tools/gh-release
    assert_success
}

@test "gh-api: delegates to gh wrapper" {
    run grep -q 'exec.*gh.*api' tools/gh-api
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# Logging Fallback
# ─────────────────────────────────────────────────────────────────────────────

@test "gh: defines log_end fallback when helper missing" {
    # Check that the script defines a no-op log_end fallback
    run grep -q 'log_end.*{.*:.*}' tools/gh
    assert_success
}
