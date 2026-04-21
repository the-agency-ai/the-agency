#!/usr/bin/env bats
#
# Tests for agency/tools/run-in
#
# Focus: subshell isolation, exit code propagation, argv boundaries, error
# surfaces for missing dir and missing separator.
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
# Help / version
# ─────────────────────────────────────────────────────────────────────────────

@test "run-in: --version prints version" {
    run_tool run-in --version
    assert_success
    assert_output_contains "run-in"
    assert_output_contains "1.0.0"
}

@test "run-in: --help shows usage" {
    run_tool run-in --help
    assert_success
    assert_output_contains "run-in"
    assert_output_contains "target-dir"
}

@test "run-in: no args shows help and exits non-zero" {
    run_tool run-in
    [[ "$status" -ne 0 ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Happy path — subshell isolation
# ─────────────────────────────────────────────────────────────────────────────

@test "run-in: runs command in target dir" {
    mkdir -p "${BATS_TEST_TMPDIR}/target"
    run_tool run-in "${BATS_TEST_TMPDIR}/target" -- pwd
    assert_success
    assert_output_contains "target"
}

@test "run-in: parent shell CWD is unchanged after invocation" {
    mkdir -p "${BATS_TEST_TMPDIR}/target"
    local before_cwd
    before_cwd="$(pwd)"
    run_tool run-in "${BATS_TEST_TMPDIR}/target" -- pwd
    assert_success
    [[ "$(pwd)" == "$before_cwd" ]]
}

@test "run-in: argv boundaries preserved for command with args" {
    mkdir -p "${BATS_TEST_TMPDIR}/target"
    run_tool run-in "${BATS_TEST_TMPDIR}/target" -- echo "hello world" "arg two"
    assert_success
    assert_output_contains "hello world"
    assert_output_contains "arg two"
}

# ─────────────────────────────────────────────────────────────────────────────
# Exit code propagation
# ─────────────────────────────────────────────────────────────────────────────

@test "run-in: propagates non-zero exit code from command" {
    mkdir -p "${BATS_TEST_TMPDIR}/target"
    run_tool run-in "${BATS_TEST_TMPDIR}/target" -- bash -c "exit 42"
    [[ "$status" -eq 42 ]]
}

@test "run-in: propagates zero exit code from successful command" {
    mkdir -p "${BATS_TEST_TMPDIR}/target"
    run_tool run-in "${BATS_TEST_TMPDIR}/target" -- true
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# Error surfaces
# ─────────────────────────────────────────────────────────────────────────────

@test "run-in: missing target dir fails with clear error" {
    run_tool run-in "${BATS_TEST_TMPDIR}/does-not-exist" -- pwd
    [[ "$status" -ne 0 ]]
    assert_output_contains "does not exist"
}

@test "run-in: missing -- separator fails with usage" {
    mkdir -p "${BATS_TEST_TMPDIR}/target"
    run_tool run-in "${BATS_TEST_TMPDIR}/target" pwd
    [[ "$status" -ne 0 ]]
    assert_output_contains "separator"
}

@test "run-in: no command after -- fails with usage" {
    mkdir -p "${BATS_TEST_TMPDIR}/target"
    run_tool run-in "${BATS_TEST_TMPDIR}/target" --
    [[ "$status" -ne 0 ]]
    assert_output_contains "no command"
}
