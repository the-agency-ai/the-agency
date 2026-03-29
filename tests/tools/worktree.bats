#!/usr/bin/env bats
#
# Tests for worktree tools:
#   - worktree-create
#   - worktree-list
#   - worktree-delete
#
# Tests CLI argument parsing, validation, and flag handling.
# Actual worktree creation/deletion is skipped — those modify git state.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# worktree-create - Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "worktree-create: --version shows version" {
    run_tool worktree-create --version
    assert_success
    assert_output_contains "worktree-create"
}

@test "worktree-create: -v shows version" {
    run_tool worktree-create -v
    assert_success
    assert_output_contains "worktree-create"
}

@test "worktree-create: --help shows usage" {
    run_tool worktree-create --help
    assert_success
    assert_output_contains "Usage:"
}

@test "worktree-create: -h shows usage" {
    run_tool worktree-create -h
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# worktree-create - Argument Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "worktree-create: no args shows error" {
    run_tool worktree-create
    assert_failure
    assert_output_contains "name is required"
}

@test "worktree-create: invalid name starting with number shows error" {
    run_tool worktree-create "123invalid"
    assert_failure
    assert_output_contains "must start with a letter"
}

@test "worktree-create: invalid name with special chars shows error" {
    run_tool worktree-create "bad name!"
    assert_failure
}

@test "worktree-create: unknown option shows error" {
    run_tool worktree-create --bogus
    assert_failure
    assert_output_contains "Unknown option"
}

# ─────────────────────────────────────────────────────────────────────────────
# worktree-list - Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "worktree-list: --version shows version" {
    run_tool worktree-list --version
    assert_success
    assert_output_contains "worktree-list"
}

@test "worktree-list: -v shows version" {
    run_tool worktree-list -v
    assert_success
    assert_output_contains "worktree-list"
}

@test "worktree-list: --help shows usage" {
    run_tool worktree-list --help
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# worktree-delete - Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "worktree-delete: --version shows version" {
    run_tool worktree-delete --version
    assert_success
    assert_output_contains "worktree-delete"
}

@test "worktree-delete: -v shows version" {
    run_tool worktree-delete -v
    assert_success
    assert_output_contains "worktree-delete"
}

@test "worktree-delete: --help shows usage" {
    run_tool worktree-delete --help
    assert_success
    assert_output_contains "Usage:"
}
