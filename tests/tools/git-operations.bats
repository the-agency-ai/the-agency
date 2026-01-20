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

@test "commit: requires work item OR --adhoc flag" {
    run_tool commit "Test message"
    assert_failure
    assert_output_contains "Work item required" || assert_output_contains "--adhoc"
}

@test "commit: --adhoc flag accepted as escape hatch" {
    run_tool commit "Test message" --adhoc
    # Will fail (no git context) but flag should be recognized
    [[ ! "$output" =~ "unknown" ]] && [[ ! "$output" =~ "Work item required" ]]
}

@test "commit: validates work item format - accepts REQUEST" {
    run_tool commit "Test" --work-item REQUEST-jordan-0001 --stage impl
    [[ ! "$output" =~ "Invalid work item" ]]
}

@test "commit: validates work item format - accepts BUG" {
    run_tool commit "Test" --work-item BUG-housekeeping-00001 --stage impl
    [[ ! "$output" =~ "Invalid work item" ]]
}

@test "commit: validates work item format - accepts TASK" {
    run_tool commit "Test" --work-item TASK-auth-refactor --stage impl
    [[ ! "$output" =~ "Invalid work item" ]]
}

@test "commit: validates work item format - rejects invalid" {
    run_tool commit "Test" --work-item INVALID-test --stage impl
    assert_failure
    assert_output_contains "Invalid work item"
}

@test "commit: validates work item format - rejects empty" {
    run_tool commit "Test" --work-item "" --stage impl
    assert_failure
}

@test "commit: --work-item requires value" {
    run_tool commit "Test" --work-item --stage impl
    assert_failure
    assert_output_contains "requires a value"
}

@test "commit: --stage requires value" {
    run_tool commit "Test" --work-item REQUEST-test-0001 --stage
    assert_failure
    assert_output_contains "requires a value"
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

@test "tag: --skip-order flag is recognized" {
    run_tool tag REQUEST-test-0001 review --skip-order --skip-tests
    [[ ! "$output" =~ "unknown flag" ]]
}

@test "tag: --force flag is recognized" {
    run_tool tag REQUEST-test-0001 impl --force --skip-tests
    [[ ! "$output" =~ "unknown flag" ]]
}

@test "tag: --message requires value" {
    # Flags must come before positional args
    run_tool tag --message
    assert_failure
    assert_output_contains "requires a value"
}

@test "tag: stage order enforcement - review requires impl" {
    local repo_dir
    repo_dir=$(create_mock_git_repo)
    cd "$repo_dir"

    # Try to tag review without impl - should fail
    run "${TOOLS_DIR}/tag" REQUEST-test-0001 review --skip-tests
    assert_failure
    assert_output_contains "stage order" || assert_output_contains "impl"
}

@test "tag: stage order enforcement - impl has no prerequisite" {
    local repo_dir
    repo_dir=$(create_mock_git_repo)
    cd "$repo_dir"

    # Tag impl should work without prerequisites
    run "${TOOLS_DIR}/tag" REQUEST-test-0001 impl --skip-tests
    assert_success
}

@test "tag: --skip-order bypasses stage order check" {
    local repo_dir
    repo_dir=$(create_mock_git_repo)
    cd "$repo_dir"

    # Tag review without impl - should work with --skip-order
    run "${TOOLS_DIR}/tag" --skip-order --skip-tests REQUEST-test-0001 review
    assert_success
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
# Workflow-check Tool Tests
# ─────────────────────────────────────────────────────────────────────────────

@test "workflow-check: --version shows version" {
    run_tool workflow-check --version
    assert_success
    assert_output_contains "workflow-check"
}

@test "workflow-check: --help shows usage" {
    run_tool workflow-check --help
    assert_success
    assert_output_contains "Usage:"
}

@test "workflow-check: -h shows usage" {
    run_tool workflow-check -h
    assert_success
    assert_output_contains "Usage:"
}

@test "workflow-check: requires work item argument" {
    run_tool workflow-check
    assert_failure
    assert_output_contains "Usage:" || assert_output_contains "work-item"
}

@test "workflow-check: --quiet flag is recognized" {
    local repo_dir
    repo_dir=$(create_mock_git_repo)
    cd "$repo_dir"

    run "${TOOLS_DIR}/workflow-check" --quiet REQUEST-test-0001
    assert_success
    # Should output just the stage name
    [[ "$output" =~ "impl" ]]
}

@test "workflow-check: shows workflow status" {
    local repo_dir
    repo_dir=$(create_mock_git_repo)
    cd "$repo_dir"

    run "${TOOLS_DIR}/workflow-check" REQUEST-test-0001
    assert_success
    # Should show all stages
    assert_output_contains "impl"
    assert_output_contains "review"
    assert_output_contains "tests"
    assert_output_contains "complete"
}

@test "workflow-check: identifies next stage correctly" {
    local repo_dir
    repo_dir=$(create_mock_git_repo)
    cd "$repo_dir"

    # Tag impl
    git tag -a REQUEST-test-0001-impl -m "impl"

    run "${TOOLS_DIR}/workflow-check" REQUEST-test-0001
    assert_success
    # Should show review as next
    assert_output_contains "review" && assert_output_contains "next"
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
