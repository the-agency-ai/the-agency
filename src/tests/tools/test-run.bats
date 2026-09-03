#!/usr/bin/env bats
#
# Tests for agency/tools/test-run — focused on the --isolated / --working-tree
# wire-in (#42 step 3). The actual in-container execution needs a container
# backend (absent in the isolated test env), so these cover arg-parsing, the
# help/list surface, and structural guards on the container-test-run integration.

load 'test_helper'

TR="${REPO_ROOT}/agency/tools/test-run"
CTR="${REPO_ROOT}/agency/tools/container-test-run"

@test "test-run: --help documents --isolated and --working-tree" {
    run bash "$TR" --help
    assert_success
    assert_output_contains "--isolated"
    assert_output_contains "--working-tree"
}

@test "test-run: --isolated is a recognized flag (not 'unknown option')" {
    run bash "$TR" --isolated --list
    assert_success
    [[ "$output" != *"unknown option"* ]]
    assert_output_contains "Configured test suites"
}

@test "test-run: --working-tree is recognized (implies --isolated)" {
    run bash "$TR" --working-tree --list
    assert_success
    [[ "$output" != *"unknown option"* ]]
}

@test "test-run: a genuinely unknown flag is still rejected" {
    run bash "$TR" --totally-bogus
    assert_failure
    assert_output_contains "unknown option"
}

@test "test-run: --list still works normally (no isolation)" {
    run bash "$TR" --list
    assert_success
    assert_output_contains "tools"
    assert_output_contains "hookify"
}

# ── Structural guards on the container-test-run integration ──────────────────

@test "test-run: --isolated routes bats suites through container-test-run" {
    run grep -qE 'container-test-run' "$TR"
    assert_success
}

@test "container-test-run: supports a --working-tree mode" {
    run grep -qE '\-\-working-tree' "$CTR"
    assert_success
}

@test "container-test-run: working-tree overlay replays the uncommitted delta" {
    # The overlay must copy modified+untracked (gitignore-respected) and remove
    # working-tree-deleted files — the mechanism that lets it test uncommitted work.
    run grep -qE 'ls-files .*--modified --others --exclude-standard' "$CTR"
    assert_success
    run grep -qE 'ls-files .*--deleted' "$CTR"
    assert_success
}

@test "container-test-run: routes through the container_run abstraction" {
    run grep -qE 'container_run' "$CTR"
    assert_success
}
