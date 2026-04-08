#!/usr/bin/env bats
#
# Tests for claude/tools/agency-version
#
# Covers the three verbs (print / --statusline / --json), help, unknown args,
# and the missing-manifest / missing-field error paths. No network.
#

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup
    cd "${REPO_ROOT}"
}

teardown() {
    test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Help
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-version: --help shows usage" {
    run_tool agency-version --help
    assert_success
    assert_output_contains "agency-version"
    assert_output_contains "statusline"
}

@test "agency-version: -h shows usage" {
    run_tool agency-version -h
    assert_success
    assert_output_contains "agency-version"
}

# ─────────────────────────────────────────────────────────────────────────────
# Default print
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-version: default prints version from manifest" {
    run_tool agency-version
    assert_success
    # Version format: N.N (day.release)
    [[ "$output" =~ ^[0-9]+\.[0-9]+$ ]]
}

@test "agency-version: print verb prints version" {
    run_tool agency-version print
    assert_success
    [[ "$output" =~ ^[0-9]+\.[0-9]+$ ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# --statusline mode
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-version: --statusline prints bare version" {
    run_tool agency-version --statusline
    assert_success
    [[ "$output" =~ ^[0-9]+\.[0-9]+$ ]]
}

@test "agency-version: --statusline is silent when manifest missing" {
    # Point tool at a fake project root with no manifest
    fake_root="${BATS_TEST_TMPDIR}/fake"
    mkdir -p "${fake_root}/claude/tools" "${fake_root}/claude/config"
    cp "${REPO_ROOT}/claude/tools/agency-version" "${fake_root}/claude/tools/"
    run bash "${fake_root}/claude/tools/agency-version" --statusline
    assert_success
    [[ -z "$output" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# --json mode
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-version: --json prints JSON object" {
    run_tool agency-version --json
    assert_success
    assert_output_contains '"agency_version"'
}

@test "agency-version: --json fails when field missing" {
    fake_root="${BATS_TEST_TMPDIR}/fake"
    mkdir -p "${fake_root}/claude/tools" "${fake_root}/claude/config"
    cp "${REPO_ROOT}/claude/tools/agency-version" "${fake_root}/claude/tools/"
    echo '{"schema_version":"1.0"}' > "${fake_root}/claude/config/manifest.json"
    run bash "${fake_root}/claude/tools/agency-version" --json
    [[ "$status" -ne 0 ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Error paths
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-version: unknown arg exits non-zero" {
    run_tool agency-version --bogus
    [[ "$status" -ne 0 ]]
}

@test "agency-version: default fails when manifest missing" {
    fake_root="${BATS_TEST_TMPDIR}/fake"
    mkdir -p "${fake_root}/claude/tools" "${fake_root}/claude/config"
    cp "${REPO_ROOT}/claude/tools/agency-version" "${fake_root}/claude/tools/"
    run bash "${fake_root}/claude/tools/agency-version"
    [[ "$status" -ne 0 ]]
}

@test "agency-version: default fails when field missing" {
    fake_root="${BATS_TEST_TMPDIR}/fake"
    mkdir -p "${fake_root}/claude/tools" "${fake_root}/claude/config"
    cp "${REPO_ROOT}/claude/tools/agency-version" "${fake_root}/claude/tools/"
    echo '{"schema_version":"1.0"}' > "${fake_root}/claude/config/manifest.json"
    run bash "${fake_root}/claude/tools/agency-version"
    [[ "$status" -ne 0 ]]
}
