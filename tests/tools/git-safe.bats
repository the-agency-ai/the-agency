#!/usr/bin/env bats
#
# Tests for git-safe — safe git operations for agents
#
# Covers: read-only subcommand pass-through, guarded `add` (blocks -A/./wildcards),
# `merge-from-master` with main/master auto-detection and dirty-tree guard.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Fixture setup — isolated git repo with git-safe installed
# ─────────────────────────────────────────────────────────────────────────────

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    cd "${BATS_TEST_TMPDIR}"
    git init --quiet --initial-branch=main 2>/dev/null || git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    git config commit.gpgsign false
    git config init.defaultBranch main

    # Install git-safe into the test repo
    mkdir -p claude/tools/lib
    cp "${REPO_ROOT}/claude/tools/git-safe" claude/tools/git-safe
    chmod +x claude/tools/git-safe
    cp "${REPO_ROOT}/claude/tools/lib/_log-helper" claude/tools/lib/_log-helper 2>/dev/null || true
    cp "${REPO_ROOT}/claude/tools/lib/_colors" claude/tools/lib/_colors 2>/dev/null || true

    # Seed an initial commit
    echo "# Test" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet

    # Ensure we're on main (rename if default was master)
    if [[ "$(git branch --show-current)" == "master" ]]; then
        git branch -m master main
    fi

    # Create a feature branch to work on
    git checkout -b feature --quiet
}

teardown() {
    test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Help and version
# ─────────────────────────────────────────────────────────────────────────────

@test "git-safe --help shows usage" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe --help
    assert_success
    assert_output_contains "git-safe"
    assert_output_contains "Usage"
    assert_output_contains "Subcommands"
}

@test "git-safe -h shows usage" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe -h
    assert_success
    assert_output_contains "Usage"
}

@test "git-safe with no args shows usage" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe
    assert_success
    assert_output_contains "Usage"
}

@test "git-safe --version shows version" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe --version
    assert_success
    assert_output_contains "git-safe"
    assert_output_contains "[0-9]+\.[0-9]+\.[0-9]+"
}

@test "git-safe unknown subcommand errors" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe bogus-subcommand
    assert_failure
    assert_output_contains "Unknown subcommand"
}

# ─────────────────────────────────────────────────────────────────────────────
# Read-only pass-through subcommands
# ─────────────────────────────────────────────────────────────────────────────

@test "git-safe status shows working tree status" {
    cd "${BATS_TEST_TMPDIR}"
    echo "dirty" > untracked.txt
    run ./claude/tools/git-safe status
    assert_success
    assert_output_contains "untracked.txt"
}

@test "git-safe status matches git status" {
    cd "${BATS_TEST_TMPDIR}"
    local safe_out
    local git_out
    safe_out=$(./claude/tools/git-safe status --short)
    git_out=$(git status --short)
    [[ "$safe_out" == "$git_out" ]]
}

@test "git-safe log accepts --oneline -5" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe log --oneline -5
    assert_success
    assert_output_contains "Initial commit"
}

@test "git-safe log without args works" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe log
    assert_success
    assert_output_contains "Initial commit"
}

@test "git-safe diff works (empty when clean)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe diff
    assert_success
}

@test "git-safe diff shows changes" {
    cd "${BATS_TEST_TMPDIR}"
    echo "changed content" >> README.md
    run ./claude/tools/git-safe diff
    assert_success
    assert_output_contains "changed content"
}

@test "git-safe branch returns current branch name" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe branch
    assert_success
    assert_output_contains "feature"
}

@test "git-safe show HEAD shows latest commit" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe show HEAD
    assert_success
    assert_output_contains "Initial commit"
}

@test "git-safe blame works on a tracked file" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe blame README.md
    assert_success
    assert_output_contains "Test User"
}

# ─────────────────────────────────────────────────────────────────────────────
# git-safe add — success cases
# ─────────────────────────────────────────────────────────────────────────────

@test "git-safe add stages a single explicit file" {
    cd "${BATS_TEST_TMPDIR}"
    echo "content" > file1.txt
    run ./claude/tools/git-safe add file1.txt
    assert_success
    assert_output_contains "Staged"
    # Verify it is actually staged
    run git diff --cached --name-only
    assert_output_contains "file1.txt"
}

@test "git-safe add stages multiple explicit files" {
    cd "${BATS_TEST_TMPDIR}"
    echo "a" > file1.txt
    echo "b" > file2.txt
    run ./claude/tools/git-safe add file1.txt file2.txt
    assert_success
    run git diff --cached --name-only
    assert_output_contains "file1.txt"
    assert_output_contains "file2.txt"
}

@test "git-safe add with no args errors" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe add
    assert_failure
    assert_output_contains "requires explicit file paths"
}

# ─────────────────────────────────────────────────────────────────────────────
# git-safe add — the guards (blocks)
# ─────────────────────────────────────────────────────────────────────────────

@test "git-safe add -A is BLOCKED" {
    cd "${BATS_TEST_TMPDIR}"
    echo "x" > should-not-stage.txt
    run ./claude/tools/git-safe add -A
    assert_failure
    assert_output_contains "blocks"
    # Verify nothing got staged
    run git diff --cached --name-only
    [[ -z "$output" ]]
}

@test "git-safe add --all is BLOCKED" {
    cd "${BATS_TEST_TMPDIR}"
    echo "x" > should-not-stage.txt
    run ./claude/tools/git-safe add --all
    assert_failure
    assert_output_contains "blocks"
    run git diff --cached --name-only
    [[ -z "$output" ]]
}

@test "git-safe add . is BLOCKED" {
    cd "${BATS_TEST_TMPDIR}"
    echo "x" > should-not-stage.txt
    run ./claude/tools/git-safe add .
    assert_failure
    assert_output_contains "blocks"
    run git diff --cached --name-only
    [[ -z "$output" ]]
}

@test "git-safe add ./ is BLOCKED" {
    cd "${BATS_TEST_TMPDIR}"
    echo "x" > should-not-stage.txt
    run ./claude/tools/git-safe add ./
    assert_failure
    assert_output_contains "blocks"
}

@test "git-safe add .. is BLOCKED" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe add ..
    assert_failure
    assert_output_contains "blocks"
}

@test "git-safe add '*' is BLOCKED" {
    cd "${BATS_TEST_TMPDIR}"
    echo "x" > should-not-stage.txt
    run ./claude/tools/git-safe add '*'
    assert_failure
    assert_output_contains "blocks"
    run git diff --cached --name-only
    [[ -z "$output" ]]
}

@test "git-safe add on a bare directory is BLOCKED" {
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p somedir
    echo "nested" > somedir/nested.txt
    run ./claude/tools/git-safe add somedir
    assert_failure
    assert_output_contains "directory"
    run git diff --cached --name-only
    [[ -z "$output" ]]
}

@test "git-safe add blocks -A even when other files given" {
    cd "${BATS_TEST_TMPDIR}"
    echo "x" > file1.txt
    run ./claude/tools/git-safe add file1.txt -A
    assert_failure
    assert_output_contains "blocks"
}

# ─────────────────────────────────────────────────────────────────────────────
# git-safe merge-from-master — branch detection + guards
# ─────────────────────────────────────────────────────────────────────────────

@test "merge-from-master uses main when main branch exists" {
    cd "${BATS_TEST_TMPDIR}"
    # We are on feature, main exists from setup
    # Make a change on main first
    git checkout main --quiet
    echo "from main" > main-file.txt
    git add main-file.txt
    git commit -m "Add main file" --quiet
    git checkout feature --quiet

    run ./claude/tools/git-safe merge-from-master
    assert_success
    assert_output_contains "main"
    [[ -f main-file.txt ]]
}

@test "merge-from-master uses master when only master branch exists" {
    # Build a separate repo with only master
    local repo="${BATS_TEST_TMPDIR}/master-repo"
    mkdir -p "$repo/claude/tools/lib"
    cd "$repo"
    git init --quiet --initial-branch=master 2>/dev/null || {
        git init --quiet
        git symbolic-ref HEAD refs/heads/master
    }
    git config user.email "test@example.com"
    git config user.name "Test User"
    git config commit.gpgsign false
    cp "${REPO_ROOT}/claude/tools/git-safe" claude/tools/git-safe
    chmod +x claude/tools/git-safe
    cp "${REPO_ROOT}/claude/tools/lib/_log-helper" claude/tools/lib/_log-helper 2>/dev/null || true
    cp "${REPO_ROOT}/claude/tools/lib/_colors" claude/tools/lib/_colors 2>/dev/null || true

    echo "master readme" > README.md
    git add README.md
    git commit -m "Initial on master" --quiet

    # Ensure actually on master (rename if default was main)
    if [[ "$(git branch --show-current)" == "main" ]]; then
        git branch -m main master
    fi

    git checkout -b feature --quiet

    git checkout master --quiet
    echo "master change" > master-file.txt
    git add master-file.txt
    git commit -m "Master change" --quiet
    git checkout feature --quiet

    run ./claude/tools/git-safe merge-from-master
    assert_success
    assert_output_contains "master"
    [[ -f master-file.txt ]]
}

@test "merge-from-master refuses when already on main" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout main --quiet
    run ./claude/tools/git-safe merge-from-master
    assert_failure
    assert_output_contains "Already on main"
}

@test "merge-from-master refuses dirty working tree" {
    cd "${BATS_TEST_TMPDIR}"
    # We're on feature; make it dirty
    echo "dirty change" >> README.md
    run ./claude/tools/git-safe merge-from-master
    assert_failure
    assert_output_contains "dirty"
    assert_output_contains "worktree-sync"
}

@test "merge-from-master refuses staged-but-uncommitted changes" {
    cd "${BATS_TEST_TMPDIR}"
    echo "staged content" > staged.txt
    git add staged.txt
    run ./claude/tools/git-safe merge-from-master
    assert_failure
    assert_output_contains "dirty"
}

# ─────────────────────────────────────────────────────────────────────────────
# rm — guarded delete (D41-R7)
# ─────────────────────────────────────────────────────────────────────────────

@test "rm removes a tracked file" {
    cd "${BATS_TEST_TMPDIR}"
    echo "doomed" > doomed.txt
    git add doomed.txt
    git commit -m "add doomed" --quiet
    run ./claude/tools/git-safe rm doomed.txt
    assert_success
    assert_output_contains "Removed"
    [ ! -f doomed.txt ]
}

@test "rm blocks -r and --recursive" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe rm -r some-dir
    assert_failure
    run ./claude/tools/git-safe rm --recursive some-dir
    assert_failure
}

@test "rm blocks -f" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe rm -f x.txt
    assert_failure
}

@test "rm blocks bare directory" {
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p subdir
    run ./claude/tools/git-safe rm subdir
    assert_failure
    assert_output_contains "directory"
}

@test "rm blocks wildcards and dot paths" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe rm '*'
    assert_failure
    run ./claude/tools/git-safe rm '.'
    assert_failure
}

# ─────────────────────────────────────────────────────────────────────────────
# merge-abort (D41-R7)
# ─────────────────────────────────────────────────────────────────────────────

@test "merge-abort fails when no merge is in progress" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe merge-abort
    assert_failure
    assert_output_contains "No merge in progress"
}

# ─────────────────────────────────────────────────────────────────────────────
# resolve-conflict (D41-R7)
# ─────────────────────────────────────────────────────────────────────────────

# Helper — create a two-branch conflict setup on shared.txt and leave the
# working tree mid-merge with an unresolved conflict. Uses 'conflict-br'
# because the shared setup() already created 'feature'.
_setup_conflict() {
    cd "${BATS_TEST_TMPDIR}"
    # setup() left us on 'feature' with feature branch existing. Move back
    # to main for the conflict setup.
    git checkout main --quiet 2>/dev/null || true
    echo "base" > shared.txt
    git add shared.txt
    git commit -m "base" --quiet
    git checkout -b conflict-br --quiet
    echo "theirs side" > shared.txt
    git add shared.txt
    git commit -m "theirs change" --quiet
    git checkout main --quiet
    echo "ours side" > shared.txt
    git add shared.txt
    git commit -m "ours change" --quiet
    git merge conflict-br --no-edit >/dev/null 2>&1 || true
}

@test "resolve-conflict requires a file argument" {
    _setup_conflict
    run ./claude/tools/git-safe resolve-conflict --ours
    assert_failure
    assert_output_contains "requires a file"
}

@test "resolve-conflict requires --ours or --theirs" {
    _setup_conflict
    run ./claude/tools/git-safe resolve-conflict shared.txt
    assert_failure
    assert_output_contains "ours"
}

@test "resolve-conflict fails when no merge is in progress" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-safe resolve-conflict shared.txt --ours
    assert_failure
    assert_output_contains "No merge in progress"
}

@test "resolve-conflict --ours picks main's version and stages it" {
    _setup_conflict
    run ./claude/tools/git-safe resolve-conflict shared.txt --ours
    assert_success
    assert_output_contains "Resolved"
    run cat shared.txt
    assert_output_contains "ours side"
    # Should be staged (no unmerged entries for this file)
    [[ -z "$(git ls-files -u shared.txt)" ]]
}

@test "resolve-conflict --theirs picks the incoming version and stages it" {
    _setup_conflict
    run ./claude/tools/git-safe resolve-conflict shared.txt --theirs
    assert_success
    run cat shared.txt
    assert_output_contains "theirs side"
}

@test "resolve-conflict rejects unknown flags" {
    _setup_conflict
    run ./claude/tools/git-safe resolve-conflict shared.txt --bogus
    assert_failure
}

@test "resolve-conflict rejects non-conflicted file" {
    _setup_conflict
    # Unrelated, non-conflicted file
    echo "clean" > clean.txt
    run ./claude/tools/git-safe resolve-conflict clean.txt --ours
    assert_failure
    assert_output_contains "not conflicted"
}
