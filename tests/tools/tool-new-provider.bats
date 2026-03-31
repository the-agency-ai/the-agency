#!/usr/bin/env bats
#
# Tests for tools/tool-create --provider flag
#
# Tests provider pattern scaffolding: name remapping, template substitution,
# collision detection, and invalid pattern rejection.
#

load 'test_helper'

# Save and restore build number to avoid side effects
setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    cd "${REPO_ROOT}"
    export BUILD_FILE="${REPO_ROOT}/claude/data/tool-build-number"
    if [[ -f "$BUILD_FILE" ]]; then
        cp "$BUILD_FILE" "${BATS_TEST_TMPDIR}/build-number-backup"
    fi
}

teardown() {
    # Restore build number
    if [[ -f "${BATS_TEST_TMPDIR}/build-number-backup" ]]; then
        cp "${BATS_TEST_TMPDIR}/build-number-backup" "$BUILD_FILE"
    fi
    # Clean up any tools we created
    for pattern in secret-test- terminal-setup-test- platform-setup-test- design-test-; do
        rm -f "${TOOLS_DIR}/${pattern}"* 2>/dev/null || true
    done
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider pattern: secrets
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-create --provider=secrets: creates secret-{name}" {
    run_tool tool-create --provider=secrets test-s1 "Test secrets provider"
    assert_success
    assert_file_exists "${TOOLS_DIR}/secret-test-s1"
    rm -f "${TOOLS_DIR}/secret-test-s1"
}

@test "tool-create --provider=secrets: template has correct tool name" {
    run_tool tool-create --provider=secrets test-s2 "Test secrets provider"
    assert_success
    assert_file_contains "${TOOLS_DIR}/secret-test-s2" "secret-test-s2"
    rm -f "${TOOLS_DIR}/secret-test-s2"
}

@test "tool-create --provider=secrets: template has correct dispatcher" {
    run_tool tool-create --provider=secrets test-s3 "Test secrets provider"
    assert_success
    assert_file_contains "${TOOLS_DIR}/secret-test-s3" "Dispatched via: ./claude/tools/secret"
    rm -f "${TOOLS_DIR}/secret-test-s3"
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider pattern: terminal
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-create --provider=terminal: creates terminal-setup-{name}" {
    run_tool tool-create --provider=terminal test-t1 "Test terminal provider"
    assert_success
    assert_file_exists "${TOOLS_DIR}/terminal-setup-test-t1"
    rm -f "${TOOLS_DIR}/terminal-setup-test-t1"
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider pattern: platform
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-create --provider=platform: creates platform-setup-{name}" {
    run_tool tool-create --provider=platform test-p1 "Test platform provider"
    assert_success
    assert_file_exists "${TOOLS_DIR}/platform-setup-test-p1"
    rm -f "${TOOLS_DIR}/platform-setup-test-p1"
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider pattern: design
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-create --provider=design: creates design-{name}" {
    run_tool tool-create --provider=design test-d1 "Test design provider"
    assert_success
    assert_file_exists "${TOOLS_DIR}/design-test-d1"
    rm -f "${TOOLS_DIR}/design-test-d1"
}

# ─────────────────────────────────────────────────────────────────────────────
# Template content
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-create --provider: created tool is executable" {
    run_tool tool-create --provider=secrets test-exec "Test"
    assert_success
    [[ -x "${TOOLS_DIR}/secret-test-exec" ]]
    rm -f "${TOOLS_DIR}/secret-test-exec"
}

@test "tool-create --provider: created tool has provider pattern in content" {
    run_tool tool-create --provider=secrets test-content "Test"
    assert_success
    assert_file_contains "${TOOLS_DIR}/secret-test-content" "secrets"
    rm -f "${TOOLS_DIR}/secret-test-content"
}

@test "tool-create --provider: created tool has set -euo pipefail" {
    run_tool tool-create --provider=secrets test-strict "Test"
    assert_success
    assert_file_contains "${TOOLS_DIR}/secret-test-strict" "set -euo pipefail"
    rm -f "${TOOLS_DIR}/secret-test-strict"
}

@test "tool-create --provider: created tool --help works" {
    run_tool tool-create --provider=secrets test-help "Test help provider"
    assert_success
    run "${TOOLS_DIR}/secret-test-help" --help
    assert_success
    assert_output_contains "secret-test-help"
    rm -f "${TOOLS_DIR}/secret-test-help"
}

# ─────────────────────────────────────────────────────────────────────────────
# Error handling
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-create --provider=invalid: rejects unknown pattern" {
    run_tool tool-create --provider=invalid test-bad "Test"
    assert_failure
    assert_output_contains "Unknown provider pattern"
}

@test "tool-create --provider: rejects if remapped tool already exists" {
    # secret-vault already exists
    run_tool tool-create --provider=secrets vault "Test"
    assert_failure
    assert_output_contains "already exists"
}
