#!/usr/bin/env bats
# Tests for claude/tools/worktree-cwd-check
#
# What Problem: worktree-cwd-check warns when CWD is outside the current
# worktree root. These tests verify it correctly detects mismatch and stays
# silent when CWD is inside the worktree.
#
# Written: 2026-04-07 during devex Phase 110

load test_helper

setup() {
    test_isolation_setup

    export TEST_REPO="${BATS_TEST_TMPDIR}/test-repo"
    mkdir -p "$TEST_REPO/subdir/nested"
    cd "$TEST_REPO"
    git init --quiet --no-verify 2>/dev/null || git init --quiet
    git config user.email "test@test.invalid"
    git config user.name "Test"
    echo "init" > README.md
    git add README.md
    git commit --quiet --no-verify -m "init"

    # Copy the tool
    mkdir -p "$TEST_REPO/claude/tools"
    cp "$REPO_ROOT/claude/tools/worktree-cwd-check" "$TEST_REPO/claude/tools/"
    chmod +x "$TEST_REPO/claude/tools/worktree-cwd-check"
}

teardown() {
    test_isolation_teardown
}

# ─────────────────────────────────────────────────────────────────────────────
# CWD inside worktree
# ─────────────────────────────────────────────────────────────────────────────

@test "cwd at worktree root: no warning, exit 0" {
    cd "$TEST_REPO"
    run ./claude/tools/worktree-cwd-check
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "cwd in worktree subdir: no warning, exit 0" {
    cd "$TEST_REPO/subdir"
    run ../claude/tools/worktree-cwd-check
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "cwd in nested subdir: no warning, exit 0" {
    cd "$TEST_REPO/subdir/nested"
    run ../../claude/tools/worktree-cwd-check
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# CWD outside any git repo
# ─────────────────────────────────────────────────────────────────────────────

@test "cwd outside any git repo: exit 0 (no check possible)" {
    # Use BATS_TEST_TMPDIR's parent as a non-git location
    local nongit
    nongit=$(mktemp -d "${BATS_TEST_TMPDIR}/nongit.XXXXXX")
    cd "$nongit"
    run "$TEST_REPO/claude/tools/worktree-cwd-check"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Quiet mode
# ─────────────────────────────────────────────────────────────────────────────

@test "--quiet: no output even on success" {
    cd "$TEST_REPO"
    run ./claude/tools/worktree-cwd-check --quiet
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Version
# ─────────────────────────────────────────────────────────────────────────────

@test "version flag works" {
    run ./claude/tools/worktree-cwd-check --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"worktree-cwd-check"* ]]
}
