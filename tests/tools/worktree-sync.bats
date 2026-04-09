#!/usr/bin/env bats
#
# Tests for claude/tools/worktree-sync
#
# Focus: issue #57 — the "resolve manually" message after a successful
# conflict-abort is misleading. After a conflict, worktree-sync internally
# aborts the merge and pops the stash; the error message should reflect that
# the merge was automatically aborted, not that the user needs to resolve
# anything by hand.
#
# Strategy: create a throwaway git repo with master + a feature branch that
# has a delete-vs-modify conflict with master, register the feature branch as
# a worktree, run worktree-sync from inside the worktree, and assert on
# exit code + message content.
#

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    # Build a throwaway git repo with a conflict between master and feature.
    # delete-vs-modify is the exact pattern from dispatch #171.
    export MOCK_ROOT="${BATS_TEST_TMPDIR}/mock-main"
    mkdir -p "${MOCK_ROOT}"
    cd "${MOCK_ROOT}"

    git init --quiet --initial-branch=master
    git config user.email "tester@example.invalid"
    git config user.name "Tester"

    echo "root file" > README.md
    echo "shared content" > shared.txt
    git add README.md shared.txt
    git commit --quiet -m "initial"

    # Feature branch modifies shared.txt
    git checkout --quiet -b feature
    echo "feature change" > shared.txt
    git add shared.txt
    git commit --quiet -m "feature: modify shared"

    # Master deletes shared.txt (delete-vs-modify scenario)
    git checkout --quiet master
    git rm --quiet shared.txt
    git commit --quiet -m "master: delete shared"

    # Register feature as worktree
    export WORKTREE_PATH="${BATS_TEST_TMPDIR}/mock-worktree"
    git worktree add --quiet "${WORKTREE_PATH}" feature
}

teardown() {
    # Clean up the worktree registration before wiping tmpdir
    if [[ -d "${MOCK_ROOT}" ]]; then
        (cd "${MOCK_ROOT}" && git worktree remove --force "${WORKTREE_PATH}" 2>/dev/null || true)
    fi
    test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #57 — conflict recovery message
# ─────────────────────────────────────────────────────────────────────────────

@test "worktree-sync: conflict-abort exits non-zero" {
    cd "${WORKTREE_PATH}"
    run bash "${REPO_ROOT}/claude/tools/worktree-sync" --auto
    [[ "$status" -ne 0 ]]
}

@test "worktree-sync: conflict-abort message does NOT say bare 'Resolve manually'" {
    # Regression guard for #57 — the old message was:
    #   'merge conflict with master. Resolve manually.'
    # which is misleading because the merge was already aborted internally.
    cd "${WORKTREE_PATH}"
    run bash "${REPO_ROOT}/claude/tools/worktree-sync" --auto
    [[ "$status" -ne 0 ]]
    # Must NOT contain the bare misleading phrase
    if echo "$output" | grep -qE 'Resolve manually\.?$'; then
        echo "Output still contains the misleading 'Resolve manually' message:" >&2
        echo "$output" >&2
        return 1
    fi
}

@test "worktree-sync: conflict-abort message explains that merge was aborted" {
    cd "${WORKTREE_PATH}"
    run bash "${REPO_ROOT}/claude/tools/worktree-sync" --auto
    [[ "$status" -ne 0 ]]
    # Must contain a word indicating the merge was aborted / reverted
    if ! echo "$output" | grep -qiE 'abort|reverted|restored'; then
        echo "Output does not tell the user the merge was aborted:" >&2
        echo "$output" >&2
        return 1
    fi
}

@test "worktree-sync: repo state is clean after conflict-abort (no MERGE_HEAD)" {
    cd "${WORKTREE_PATH}"
    run bash "${REPO_ROOT}/claude/tools/worktree-sync" --auto
    # MERGE_HEAD must not exist — proves the tool aborted its own merge
    [[ ! -f "${WORKTREE_PATH}/.git/MERGE_HEAD" ]] && [[ ! -f "${MOCK_ROOT}/.git/worktrees/mock-worktree/MERGE_HEAD" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #65 — main-branch repos (not just master)
# ─────────────────────────────────────────────────────────────────────────────
#
# The tool originally hardcoded 'master' throughout, which meant it silently
# broke in any repo using 'main' as the default branch (including the-agency
# itself). The fix detects MAIN_BRANCH from the main checkout's actual HEAD.
# These tests exercise the main-branch path with a successful merge (no
# conflict) to confirm the tool reads MAIN_BRANCH dynamically.

setup_main_branch_repo() {
    # Alternate setup: mock repo uses 'main' as default, feature branch is
    # behind main by one non-conflicting commit.
    export MAIN_MOCK_ROOT="${BATS_TEST_TMPDIR}/mock-main-branch"
    mkdir -p "${MAIN_MOCK_ROOT}"
    cd "${MAIN_MOCK_ROOT}"

    git init --quiet --initial-branch=main
    git config user.email "tester@example.invalid"
    git config user.name "Tester"

    echo "root" > README.md
    git add README.md
    git commit --quiet -m "initial"

    # Feature branch at the root commit
    git checkout --quiet -b devfeature

    # Main advances with a non-conflicting new file
    git checkout --quiet main
    echo "new on main" > newfile.txt
    git add newfile.txt
    git commit --quiet -m "main: add newfile"

    # Register devfeature as a worktree
    export MAIN_WORKTREE_PATH="${BATS_TEST_TMPDIR}/mock-main-worktree"
    git worktree add --quiet "${MAIN_WORKTREE_PATH}" devfeature
}

teardown_main_branch_repo() {
    if [[ -d "${MAIN_MOCK_ROOT:-}" ]]; then
        (cd "${MAIN_MOCK_ROOT}" && git worktree remove --force "${MAIN_WORKTREE_PATH}" 2>/dev/null || true)
    fi
}

@test "worktree-sync: successfully merges 'main' branch (not just 'master')" {
    # Skip the master-based setup for this test
    if [[ -d "${MOCK_ROOT}" ]]; then
        (cd "${MOCK_ROOT}" && git worktree remove --force "${WORKTREE_PATH}" 2>/dev/null || true)
    fi
    setup_main_branch_repo
    cd "${MAIN_WORKTREE_PATH}"
    run bash "${REPO_ROOT}/claude/tools/worktree-sync" --auto
    teardown_main_branch_repo
    assert_success
    # Output should reference 'main', not 'master'
    if echo "$output" | grep -qi 'master'; then
        echo "Output references 'master' instead of 'main' — #65 regression:" >&2
        echo "$output" >&2
        return 1
    fi
    # Output should confirm a merge happened
    if ! echo "$output" | grep -qi 'merged\|up to date\|main'; then
        echo "Output does not confirm main-branch merge:" >&2
        echo "$output" >&2
        return 1
    fi
}

@test "worktree-sync: detects MAIN_BRANCH dynamically from main checkout" {
    # Same setup, different assertion — verify the tool's error path references
    # the actual branch name, not a hardcoded 'master'.
    if [[ -d "${MOCK_ROOT}" ]]; then
        (cd "${MOCK_ROOT}" && git worktree remove --force "${WORKTREE_PATH}" 2>/dev/null || true)
    fi
    setup_main_branch_repo
    # Invoke from the main checkout itself (should soft-skip in auto mode with 'main' in the message)
    cd "${MAIN_MOCK_ROOT}"
    run bash "${REPO_ROOT}/claude/tools/worktree-sync" --auto
    teardown_main_branch_repo
    assert_success
    # The soft-skip message should mention 'main', not 'master'
    if ! echo "$output" | grep -q 'main'; then
        echo "Soft-skip message does not reference 'main':" >&2
        echo "$output" >&2
        return 1
    fi
}
