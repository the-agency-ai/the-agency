#!/usr/bin/env bats
#
# Verifies that required reference documents exist in claude/docs/.
#
# These are core Agency documentation files that tools, agents,
# and commands depend on. Missing files indicate incomplete setup
# or accidental deletion.
#

load '../tools/test_helper'

DOCS_DIR="${REPO_ROOT}/claude/docs"

# ─────────────────────────────────────────────────────────────────────────────
# Core Reference Documents
# ─────────────────────────────────────────────────────────────────────────────

@test "docs: QUALITY-GATE.md exists" {
    assert_file_exists "${DOCS_DIR}/QUALITY-GATE.md"
}

@test "docs: DEVELOPMENT-METHODOLOGY.md exists" {
    assert_file_exists "${DOCS_DIR}/DEVELOPMENT-METHODOLOGY.md"
}

@test "docs: CODE-REVIEW-LIFECYCLE.md exists" {
    assert_file_exists "${DOCS_DIR}/CODE-REVIEW-LIFECYCLE.md"
}

@test "docs: FEEDBACK-FORMAT.md exists" {
    assert_file_exists "${DOCS_DIR}/FEEDBACK-FORMAT.md"
}

@test "docs: PR-LIFECYCLE.md exists" {
    assert_file_exists "${DOCS_DIR}/PR-LIFECYCLE.md"
}

@test "docs: TELEMETRY.md exists" {
    assert_file_exists "${DOCS_DIR}/TELEMETRY.md"
}

# ─────────────────────────────────────────────────────────────────────────────
# Additional Expected Documents
# ─────────────────────────────────────────────────────────────────────────────

@test "docs: QUICK-START.md exists" {
    assert_file_exists "${DOCS_DIR}/QUICK-START.md"
}

@test "docs: PRINCIPALS.md exists" {
    assert_file_exists "${DOCS_DIR}/PRINCIPALS.md"
}

@test "docs: SECRETS.md exists" {
    assert_file_exists "${DOCS_DIR}/SECRETS.md"
}

@test "docs: TESTING.md exists" {
    assert_file_exists "${DOCS_DIR}/TESTING.md"
}

# ─────────────────────────────────────────────────────────────────────────────
# Non-Empty Checks
# ─────────────────────────────────────────────────────────────────────────────

@test "docs: QUALITY-GATE.md is not empty" {
    [[ -s "${DOCS_DIR}/QUALITY-GATE.md" ]]
}

@test "docs: DEVELOPMENT-METHODOLOGY.md is not empty" {
    [[ -s "${DOCS_DIR}/DEVELOPMENT-METHODOLOGY.md" ]]
}

@test "docs: CODE-REVIEW-LIFECYCLE.md is not empty" {
    [[ -s "${DOCS_DIR}/CODE-REVIEW-LIFECYCLE.md" ]]
}

@test "docs: FEEDBACK-FORMAT.md is not empty" {
    [[ -s "${DOCS_DIR}/FEEDBACK-FORMAT.md" ]]
}

@test "docs: PR-LIFECYCLE.md is not empty" {
    [[ -s "${DOCS_DIR}/PR-LIFECYCLE.md" ]]
}

@test "docs: TELEMETRY.md is not empty" {
    [[ -s "${DOCS_DIR}/TELEMETRY.md" ]]
}
