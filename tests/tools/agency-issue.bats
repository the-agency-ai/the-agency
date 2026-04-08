#!/usr/bin/env bats
#
# Tests for claude/tools/agency-issue
#
# Covers --version, --help, and the error paths that do not require
# network access. The verbs that actually hit GitHub (file/list/view/
# comment/close) are not tested against a live repo — those paths
# are covered by smoke tests during development.
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
# Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-issue: --version shows version" {
    run_tool agency-issue --version
    assert_success
    assert_output_contains "agency-issue"
    assert_output_contains "1.0.0"
}

@test "agency-issue: --help shows usage" {
    run_tool agency-issue --help
    assert_success
    assert_output_contains "agency-issue"
    assert_output_contains "file"
    assert_output_contains "list"
    assert_output_contains "view"
    assert_output_contains "comment"
    assert_output_contains "close"
}

@test "agency-issue: -h shows usage" {
    run_tool agency-issue -h
    assert_success
    assert_output_contains "Usage:"
}

@test "agency-issue: no args shows help" {
    run_tool agency-issue
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# Unknown verb handling
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-issue: unknown verb fails with error" {
    run_tool agency-issue bogus
    assert_failure
    assert_output_contains "Unknown verb"
}

# ─────────────────────────────────────────────────────────────────────────────
# file verb: required-flag validation
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-issue: file without --type fails" {
    # Use GH_TOKEN override to skip gh auth check, or rely on early arg validation
    # Arg validation happens before gh check, so this should fail on missing --type
    run_tool agency-issue file --title "test" --body "body"
    assert_failure
    assert_output_contains "--type"
}

@test "agency-issue: file without --title fails" {
    run_tool agency-issue file --type bug --body "body"
    assert_failure
    assert_output_contains "--title"
}

@test "agency-issue: file without --body or --body-file fails" {
    run_tool agency-issue file --type bug --title "test"
    assert_failure
    assert_output_contains "--body"
}

@test "agency-issue: file rejects invalid --type" {
    run_tool agency-issue file --type bogus --title "t" --body "b"
    assert_failure
    assert_output_contains "invalid --type"
}

@test "agency-issue: file accepts type=bug" {
    # This will fail at the gh stage, not at validation, so the error
    # should NOT be about invalid --type
    run_tool agency-issue file --type bug --title "t" --body "b"
    # We don't assert success because gh may not be available in CI
    # We do assert the error is not about type validation
    [[ "$output" != *"invalid --type"* ]]
}

@test "agency-issue: file accepts type=feature" {
    run_tool agency-issue file --type feature --title "t" --body "b"
    [[ "$output" != *"invalid --type"* ]]
}

@test "agency-issue: file accepts type=friction" {
    run_tool agency-issue file --type friction --title "t" --body "b"
    [[ "$output" != *"invalid --type"* ]]
}

@test "agency-issue: file accepts type=question" {
    run_tool agency-issue file --type question --title "t" --body "b"
    [[ "$output" != *"invalid --type"* ]]
}

@test "agency-issue: file accepts type=docs" {
    run_tool agency-issue file --type docs --title "t" --body "b"
    [[ "$output" != *"invalid --type"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# list verb: state validation
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-issue: list rejects invalid state" {
    run_tool agency-issue list --state bogus
    assert_failure
    assert_output_contains "invalid --state"
}

# ─────────────────────────────────────────────────────────────────────────────
# view / comment / close: required id validation
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-issue: view without id fails" {
    run_tool agency-issue view
    assert_failure
    assert_output_contains "issue id required"
}

@test "agency-issue: comment without id fails" {
    run_tool agency-issue comment
    assert_failure
    assert_output_contains "issue id required"
}

@test "agency-issue: comment without body fails" {
    run_tool agency-issue comment 123
    assert_failure
    assert_output_contains "--body"
}

@test "agency-issue: close without id fails" {
    run_tool agency-issue close
    assert_failure
    assert_output_contains "issue id required"
}
