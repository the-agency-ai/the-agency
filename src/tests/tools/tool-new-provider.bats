#!/usr/bin/env bats
#
# Tests for tools/tool-create --provider flag
#
# Tests provider pattern scaffolding: name remapping, template substitution,
# collision detection, and invalid pattern rejection.
#

load 'test_helper'

# tool-create is a DEVELOPER tool (src/tools-developer/, not agency/tools/).
# It was moved there in v46.1-cleanup and its claude/ paths were migrated to
# agency/ in the-agency#256. These tests run it HERMETICALLY: TOOL_CREATE_TOOLS_DIR
# and TOOL_CREATE_BUILD_FILE redirect all writes into the per-test BATS sandbox,
# so nothing lands in the live agency/tools + agency/data trees.
setup() {
    test_isolation_setup
    cd "${REPO_ROOT}"
    TOOL_CREATE="${REPO_ROOT}/src/tools-developer/tool-create"
    SANDBOX_TOOLS="${BATS_TEST_TMPDIR}/tools"
    mkdir -p "$SANDBOX_TOOLS"
    export TOOL_CREATE_TOOLS_DIR="$SANDBOX_TOOLS"
    export TOOL_CREATE_BUILD_FILE="${BATS_TEST_TMPDIR}/tool-build-number"
}

teardown() {
    test_isolation_teardown
    # BATS auto-removes BATS_TEST_TMPDIR (the sandbox); nothing else to clean.
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider pattern: secrets
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-create --provider=secrets: creates secret-{name}" {
    run "$TOOL_CREATE" --provider=secrets test-s1 "Test secrets provider"
    assert_success
    assert_file_exists "${SANDBOX_TOOLS}/secret-test-s1"
    rm -f "${SANDBOX_TOOLS}/secret-test-s1"
}

@test "tool-create --provider=secrets: template has correct tool name" {
    run "$TOOL_CREATE" --provider=secrets test-s2 "Test secrets provider"
    assert_success
    assert_file_contains "${SANDBOX_TOOLS}/secret-test-s2" "secret-test-s2"
    rm -f "${SANDBOX_TOOLS}/secret-test-s2"
}

@test "tool-create --provider=secrets: template has correct dispatcher" {
    run "$TOOL_CREATE" --provider=secrets test-s3 "Test secrets provider"
    assert_success
    assert_file_contains "${SANDBOX_TOOLS}/secret-test-s3" "Dispatched via: ./agency/tools/secret"
    rm -f "${SANDBOX_TOOLS}/secret-test-s3"
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider pattern: terminal
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-create --provider=terminal: creates terminal-setup-{name}" {
    run "$TOOL_CREATE" --provider=terminal test-t1 "Test terminal provider"
    assert_success
    assert_file_exists "${SANDBOX_TOOLS}/terminal-setup-test-t1"
    rm -f "${SANDBOX_TOOLS}/terminal-setup-test-t1"
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider pattern: platform
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-create --provider=platform: creates platform-setup-{name}" {
    run "$TOOL_CREATE" --provider=platform test-p1 "Test platform provider"
    assert_success
    assert_file_exists "${SANDBOX_TOOLS}/platform-setup-test-p1"
    rm -f "${SANDBOX_TOOLS}/platform-setup-test-p1"
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider pattern: design
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-create --provider=design: creates design-{name}" {
    run "$TOOL_CREATE" --provider=design test-d1 "Test design provider"
    assert_success
    assert_file_exists "${SANDBOX_TOOLS}/design-test-d1"
    rm -f "${SANDBOX_TOOLS}/design-test-d1"
}

# ─────────────────────────────────────────────────────────────────────────────
# Template content
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-create --provider: created tool is executable" {
    run "$TOOL_CREATE" --provider=secrets test-exec "Test"
    assert_success
    [[ -x "${SANDBOX_TOOLS}/secret-test-exec" ]]
    rm -f "${SANDBOX_TOOLS}/secret-test-exec"
}

@test "tool-create --provider: created tool has provider pattern in content" {
    run "$TOOL_CREATE" --provider=secrets test-content "Test"
    assert_success
    assert_file_contains "${SANDBOX_TOOLS}/secret-test-content" "secrets"
    rm -f "${SANDBOX_TOOLS}/secret-test-content"
}

@test "tool-create --provider: created tool has set -euo pipefail" {
    run "$TOOL_CREATE" --provider=secrets test-strict "Test"
    assert_success
    assert_file_contains "${SANDBOX_TOOLS}/secret-test-strict" "set -euo pipefail"
    rm -f "${SANDBOX_TOOLS}/secret-test-strict"
}

@test "tool-create --provider: created tool --help works" {
    run "$TOOL_CREATE" --provider=secrets test-help "Test help provider"
    assert_success
    run "${SANDBOX_TOOLS}/secret-test-help" --help
    assert_success
    assert_output_contains "secret-test-help"
    rm -f "${SANDBOX_TOOLS}/secret-test-help"
}

# ─────────────────────────────────────────────────────────────────────────────
# Error handling
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-create --provider=invalid: rejects unknown pattern" {
    run "$TOOL_CREATE" --provider=invalid test-bad "Test"
    assert_failure
    assert_output_contains "Unknown provider pattern"
}

@test "tool-create --provider: rejects if remapped tool already exists" {
    # Pre-create the remapped target (secrets:vault -> secret-vault) in the
    # sandbox so the collision check has something to collide with.
    touch "${SANDBOX_TOOLS}/secret-vault"
    run "$TOOL_CREATE" --provider=secrets vault "Test"
    assert_failure
    assert_output_contains "already exists"
}
