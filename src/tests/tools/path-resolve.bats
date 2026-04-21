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
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'"
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# Exported Variables
# ─────────────────────────────────────────────────────────────────────────────

@test "_path-resolve: exports AGENCY_PRINCIPAL" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve' && echo \"\$AGENCY_PRINCIPAL\""
    assert_success
    [[ -n "$output" ]]
}

@test "_path-resolve: exports AGENCY_PRINCIPAL_DIR" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve' && echo \"\$AGENCY_PRINCIPAL_DIR\""
    assert_success
    [[ -n "$output" ]]
}

@test "_path-resolve: exports AGENCY_REFS_DIR" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve' && echo \"\$AGENCY_REFS_DIR\""
    assert_success
    [[ -n "$output" ]]
}

@test "_path-resolve: exports AGENCY_PROJECT_ROOT" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve' && echo \"\$AGENCY_PROJECT_ROOT\""
    assert_success
    [[ -n "$output" ]]
}

@test "_path-resolve: AGENCY_PRINCIPAL_DIR is under usr/" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve' && echo \"\$AGENCY_PRINCIPAL_DIR\""
    assert_success
    assert_output_contains "/usr/"
}

@test "_path-resolve: AGENCY_REFS_DIR ends with claude/refs" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve' && echo \"\$AGENCY_REFS_DIR\""
    assert_success
    assert_output_contains "claude/refs"
}

# ─────────────────────────────────────────────────────────────────────────────
# YAML Principal Mapping
# ─────────────────────────────────────────────────────────────────────────────

@test "_path-resolve: maps jdm user to jordan principal" {
    run env USER=jdm AGENCY_PRINCIPAL= bash -c "source '${TOOLS_DIR}/lib/_path-resolve' && echo \"\$AGENCY_PRINCIPAL\""
    assert_success
    assert_output_contains "jordan"
}

@test "_path-resolve: falls back to default mapping for unknown user" {
    run env USER=nonexistentuser99 AGENCY_PRINCIPAL= bash -c "source '${TOOLS_DIR}/lib/_path-resolve' && echo \"\$AGENCY_PRINCIPAL\""
    assert_success
    # Should fall back to "default" mapping which yields "unknown"
    assert_output_contains "unknown"
}

@test "_path-resolve: AGENCY_PRINCIPAL env var is deprecated and ignored" {
    # AGENCY_PRINCIPAL is intentionally never trusted because it leaks from
    # test suites, shell profiles, and old add-principal runs. The lib resolves
    # from agency.yaml via $USER and only WRITES to AGENCY_PRINCIPAL.
    run env AGENCY_PRINCIPAL=override USER=jdm bash -c "source '${TOOLS_DIR}/lib/_path-resolve' && echo \"\$AGENCY_PRINCIPAL\""
    assert_success
    # Should NOT be "override" — the env var is ignored
    [[ "$output" != "override" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Missing agency.yaml
# ─────────────────────────────────────────────────────────────────────────────

@test "_path-resolve: handles missing agency.yaml gracefully" {
    run env AGENCY_PRINCIPAL= CLAUDE_PROJECT_DIR="${BATS_TEST_TMPDIR}" SCRIPT_DIR="${BATS_TEST_TMPDIR}" bash -c "cd '${BATS_TEST_TMPDIR}' && source '${TOOLS_DIR}/lib/_path-resolve' && echo \"\$AGENCY_PRINCIPAL\""
    assert_success
    # Should fall back to $USER or "unknown"
    [[ -n "$output" ]]
}

@test "_path-resolve: does not crash when agency.yaml is missing" {
    run env AGENCY_PRINCIPAL= CLAUDE_PROJECT_DIR="${BATS_TEST_TMPDIR}" SCRIPT_DIR="${BATS_TEST_TMPDIR}" bash -c "cd '${BATS_TEST_TMPDIR}' && source '${TOOLS_DIR}/lib/_path-resolve'"
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# _validate_name
# ─────────────────────────────────────────────────────────────────────────────

@test "_validate_name: accepts valid principal name" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_name 'jordan' principal"
    assert_success
}

@test "_validate_name: accepts leading digit" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_name '3d-renderer' repo"
    assert_success
}

@test "_validate_name: accepts underscores and hyphens" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_name 'my_cool-agent' agent"
    assert_success
}

@test "_validate_name: rejects empty" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_name '' principal"
    assert_failure
    assert_output_contains "empty"
}

@test "_validate_name: rejects path traversal (..)" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_name '../etc' principal"
    assert_failure
    assert_output_contains "traversal"
}

@test "_validate_name: rejects slash" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_name 'a/b' principal"
    assert_failure
    assert_output_contains "traversal"
}

@test "_validate_name: rejects uppercase" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_name 'UPPER' principal"
    assert_failure
}

@test "_validate_name: rejects name over 32 chars" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_name 'abcdefghijklmnopqrstuvwxyz1234567' principal"
    assert_failure
    assert_output_contains "32"
}

@test "_validate_name: rejects reserved 'system' for principal" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_name 'system' principal"
    assert_failure
    assert_output_contains "reserved"
}

@test "_validate_name: rejects reserved 'default' for agent" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_name 'default' agent"
    assert_failure
    assert_output_contains "reserved"
}

@test "_validate_name: allows reserved 'system' for repo level" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_name 'system' repo"
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# _validate_timezone
# ─────────────────────────────────────────────────────────────────────────────

@test "_validate_timezone: accepts standard timezone" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_timezone 'America/New_York'"
    assert_success
}

@test "_validate_timezone: accepts UTC" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_timezone 'UTC'"
    assert_success
}

@test "_validate_timezone: accepts offset format" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_timezone 'Etc/GMT+5'"
    assert_success
}

@test "_validate_timezone: rejects empty" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_timezone ''"
    assert_failure
}

@test "_validate_timezone: rejects spaces" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_timezone 'New York'"
    assert_failure
}

@test "_validate_timezone: rejects over 64 chars" {
    run bash -c "source '${TOOLS_DIR}/lib/_path-resolve'; _validate_timezone 'AAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFFFFFF012345'"
    assert_failure
}
