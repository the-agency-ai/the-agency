#!/usr/bin/env bats
#
# Tests for tools/_path-resolve sourced helper
#
# Tests principal path resolution: sourcing, exports, YAML mapping,
# fallback behavior, and graceful handling of missing config.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Sourcing
# ─────────────────────────────────────────────────────────────────────────────

@test "_path-resolve: sources without error" {
    run bash -c "source '${TOOLS_DIR}/_path-resolve'"
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# Exported Variables
# ─────────────────────────────────────────────────────────────────────────────

@test "_path-resolve: exports AGENCY_PRINCIPAL" {
    run bash -c "source '${TOOLS_DIR}/_path-resolve' && echo \"\$AGENCY_PRINCIPAL\""
    assert_success
    [[ -n "$output" ]]
}

@test "_path-resolve: exports AGENCY_PRINCIPAL_DIR" {
    run bash -c "source '${TOOLS_DIR}/_path-resolve' && echo \"\$AGENCY_PRINCIPAL_DIR\""
    assert_success
    [[ -n "$output" ]]
}

@test "_path-resolve: exports AGENCY_REFS_DIR" {
    run bash -c "source '${TOOLS_DIR}/_path-resolve' && echo \"\$AGENCY_REFS_DIR\""
    assert_success
    [[ -n "$output" ]]
}

@test "_path-resolve: exports AGENCY_PROJECT_ROOT" {
    run bash -c "source '${TOOLS_DIR}/_path-resolve' && echo \"\$AGENCY_PROJECT_ROOT\""
    assert_success
    [[ -n "$output" ]]
}

@test "_path-resolve: AGENCY_PRINCIPAL_DIR is under usr/" {
    run bash -c "source '${TOOLS_DIR}/_path-resolve' && echo \"\$AGENCY_PRINCIPAL_DIR\""
    assert_success
    assert_output_contains "/usr/"
}

@test "_path-resolve: AGENCY_REFS_DIR ends with claude/refs" {
    run bash -c "source '${TOOLS_DIR}/_path-resolve' && echo \"\$AGENCY_REFS_DIR\""
    assert_success
    assert_output_contains "claude/refs"
}

# ─────────────────────────────────────────────────────────────────────────────
# YAML Principal Mapping
# ─────────────────────────────────────────────────────────────────────────────

@test "_path-resolve: maps jdm user to jordan principal" {
    run env USER=jdm AGENCY_PRINCIPAL= bash -c "source '${TOOLS_DIR}/_path-resolve' && echo \"\$AGENCY_PRINCIPAL\""
    assert_success
    assert_output_contains "jordan"
}

@test "_path-resolve: falls back to default mapping for unknown user" {
    run env USER=nonexistentuser99 AGENCY_PRINCIPAL= bash -c "source '${TOOLS_DIR}/_path-resolve' && echo \"\$AGENCY_PRINCIPAL\""
    assert_success
    # Should fall back to "default" mapping which yields "unknown"
    assert_output_contains "unknown"
}

@test "_path-resolve: AGENCY_PRINCIPAL env var takes precedence" {
    run env AGENCY_PRINCIPAL=override bash -c "source '${TOOLS_DIR}/_path-resolve' && echo \"\$AGENCY_PRINCIPAL\""
    assert_success
    assert_output_contains "override"
}

# ─────────────────────────────────────────────────────────────────────────────
# Missing agency.yaml
# ─────────────────────────────────────────────────────────────────────────────

@test "_path-resolve: handles missing agency.yaml gracefully" {
    run env AGENCY_PRINCIPAL= CLAUDE_PROJECT_DIR="${BATS_TEST_TMPDIR}" SCRIPT_DIR="${BATS_TEST_TMPDIR}" bash -c "cd '${BATS_TEST_TMPDIR}' && source '${TOOLS_DIR}/_path-resolve' && echo \"\$AGENCY_PRINCIPAL\""
    assert_success
    # Should fall back to $USER or "unknown"
    [[ -n "$output" ]]
}

@test "_path-resolve: does not crash when agency.yaml is missing" {
    run env AGENCY_PRINCIPAL= CLAUDE_PROJECT_DIR="${BATS_TEST_TMPDIR}" SCRIPT_DIR="${BATS_TEST_TMPDIR}" bash -c "cd '${BATS_TEST_TMPDIR}' && source '${TOOLS_DIR}/_path-resolve'"
    assert_success
}
