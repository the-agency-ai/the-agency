#!/usr/bin/env bats
#
# Tests for git operation tools: commit, tag, sync
#
# Tests CLI argument parsing, validation, and git state handling.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Commit Tool Tests
# ─────────────────────────────────────────────────────────────────────────────

@test "commit: --version shows version" {
    run_tool commit --version
    assert_success
    assert_output_contains "commit"
}

@test "commit: --help shows usage" {
    run_tool commit --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "summary"
}

@test "commit: -h shows usage" {
    run_tool commit -h
    assert_success
    assert_output_contains "Usage:"
}

@test "commit: requires message argument" {
    run_tool commit
    assert_failure
    # Should indicate message is required
    assert_output_contains "message" || assert_output_contains "required"
}

@test "commit: accepts -m flag for message" {
    # Will fail (no git context) but validates flag is recognized
    run_tool commit -m "Test message"
    # Should not complain about unknown flag
    [[ ! "$output" =~ "unknown" ]] && [[ ! "$output" =~ "invalid" ]]
}

@test "commit: accepts --message flag" {
    run_tool commit --message "Test message"
    [[ ! "$output" =~ "unknown" ]] && [[ ! "$output" =~ "invalid" ]]
}

@test "commit: accepts work item with -w flag" {
    run_tool commit -m "Test" -w REQUEST-test-0001
    [[ ! "$output" =~ "invalid flag" ]]
}

@test "commit: accepts --work-item flag" {
    run_tool commit -m "Test" --work-item REQUEST-test-0001
    [[ ! "$output" =~ "invalid flag" ]]
}

@test "commit: accepts stage with -s flag" {
    run_tool commit -m "Test" -s impl
    [[ ! "$output" =~ "invalid flag" ]]
}

@test "commit: accepts --stage flag" {
    run_tool commit -m "Test" --stage impl
    [[ ! "$output" =~ "invalid flag" ]]
}

@test "commit: validates stage values" {
    run_tool commit -m "Test" --stage invalid
    # Invalid stage should be rejected
    [[ "$status" -ne 0 ]] || [[ "$output" =~ "invalid" ]] || [[ "$output" =~ "stage" ]]
}

@test "commit: --dry-run flag is recognized" {
    run_tool commit -m "Test" --dry-run
    [[ ! "$output" =~ "unknown" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Tag Tool Tests
# ─────────────────────────────────────────────────────────────────────────────

@test "tag: --version shows version" {
    run_tool tag --version
    assert_success
    assert_output_contains "tag"
}

@test "tag: --help shows usage" {
    run_tool tag --help
    assert_success
    assert_output_contains "Usage:"
}

@test "tag: requires arguments" {
    run_tool tag
    assert_failure
    # Should show usage or error about missing args
}

@test "tag: accepts work-item and stage" {
    run_tool tag REQUEST-test-0001 impl
    # Will fail (not in git repo with tests) but validates args parsed
    [[ ! "$output" =~ "invalid argument" ]]
}

@test "tag: validates stage format" {
    run_tool tag REQUEST-test-0001 invalidstage
    assert_failure
    assert_output_contains "Invalid stage" || assert_output_contains "impl" || assert_output_contains "review"
}

@test "tag: accepts release type" {
    run_tool tag release 0.1.0
    # Will fail (not in proper context) but validates args
    [[ ! "$output" =~ "invalid" ]]
}

@test "tag: --skip-tests flag is recognized" {
    run_tool tag REQUEST-test-0001 impl --skip-tests
    [[ ! "$output" =~ "unknown flag" ]]
}

@test "tag: --push flag is recognized" {
    run_tool tag REQUEST-test-0001 impl --push
    [[ ! "$output" =~ "unknown flag" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Sync Tool Tests
# ─────────────────────────────────────────────────────────────────────────────

@test "sync: --version shows version" {
    run_tool sync --version
    assert_success
    assert_output_contains "sync"
}

@test "sync: --help shows usage" {
    run_tool sync --help
    assert_success
    assert_output_contains "Usage:"
}

@test "sync: -h shows usage" {
    run_tool sync -h
    assert_success
}

@test "sync: --check flag is recognized" {
    run_tool sync --check
    # Will fail (no git context) but flag should be recognized
    [[ ! "$output" =~ "unknown" ]]
}

@test "sync: --force flag is recognized" {
    run_tool sync --force
    [[ ! "$output" =~ "unknown" ]]
}

@test "sync: --verbose flag is recognized" {
    run_tool sync --verbose
    [[ ! "$output" =~ "unknown" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Integration with Mock Git Repo
# ─────────────────────────────────────────────────────────────────────────────

@test "commit: detects non-git directory" {
    cd "${BATS_TEST_TMPDIR}"
    run "${TOOLS_DIR}/commit" -m "Test"
    assert_failure
    # Should indicate git issue
    [[ "$output" =~ "git" ]] || [[ "$output" =~ "repository" ]] || [[ "$status" -ne 0 ]]
}

@test "tag: works in mock git repo context" {
    local repo_dir
    repo_dir=$(create_mock_git_repo)
    cd "$repo_dir"

    # Try to tag - should fail on tests but parse args correctly
    run "${TOOLS_DIR}/tag" REQUEST-test-0001 impl --skip-tests
    # Either succeeds or fails on something other than arg parsing
    [[ ! "$output" =~ "invalid argument" ]]
}

@test "sync: detects clean vs dirty working tree" {
    local repo_dir
    repo_dir=$(create_mock_git_repo)
    cd "$repo_dir"

    # Clean tree
    run "${TOOLS_DIR}/sync" --check
    # Should not error on working tree
    [[ ! "$output" =~ "uncommitted" ]] || [[ "$status" -eq 0 ]]

    # Make dirty
    echo "change" >> README.md
    run "${TOOLS_DIR}/sync" --check
    # Should detect uncommitted changes
    [[ "$output" =~ "uncommitted" ]] || [[ "$output" =~ "changed" ]] || [[ "$status" -ne 0 ]]
}
