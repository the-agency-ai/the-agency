#!/usr/bin/env bats
#
# Tests for git-safe-commit MERGE_HEAD auto-route (D41-R7).
#
# When a merge is in progress, git-safe-commit should detect MERGE_HEAD and
# route to `git commit --no-edit` instead of running the normal message/
# work-item flow. This replaces the git-captain merge-continue workaround for
# agents who finish a merge after resolving conflicts via git-safe.
#

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    cd "${BATS_TEST_TMPDIR}"
    git init --quiet --initial-branch=main 2>/dev/null || git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    git config commit.gpgsign false
    git config init.defaultBranch main

    # Install git-safe and git-safe-commit (+ pre-commit hook deps minimal)
    mkdir -p agency/tools/lib
    for t in git-safe git-safe-commit; do
        cp "${REPO_ROOT}/agency/tools/$t" "agency/tools/$t"
        chmod +x "agency/tools/$t"
    done
    for lib in _log-helper _colors; do
        cp "${REPO_ROOT}/agency/tools/lib/$lib" "agency/tools/lib/$lib" 2>/dev/null || true
    done

    # Disable the real pre-commit hook to keep tests fast and self-contained.
    git config core.hooksPath /dev/null 2>/dev/null || true

    echo "base" > shared.txt
    git add shared.txt
    git commit -m "base" --quiet --no-verify

    if [[ "$(git branch --show-current)" == "master" ]]; then
        git branch -m master main
    fi

    git checkout -b incoming --quiet
    echo "theirs" > shared.txt
    git add shared.txt
    git commit -m "theirs" --quiet --no-verify

    git checkout main --quiet
    echo "ours" > shared.txt
    git add shared.txt
    git commit -m "ours" --quiet --no-verify

    # Trigger the merge conflict (non-zero exit expected)
    git merge incoming --no-edit >/dev/null 2>&1 || true
}

teardown() {
    test_isolation_teardown
    [[ -d "${BATS_TEST_TMPDIR}" ]] && rm -rf "${BATS_TEST_TMPDIR}"
}

@test "git-safe-commit detects MERGE_HEAD and blocks with unresolved conflicts" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/git-safe-commit --no-verify
    # QG fix: pin to the specific message — earlier "Merge" substring was too
    # broad and could match unrelated output.
    [ "$status" -ne 0 ]
    [[ "$output" == *"unresolved conflicts"* ]]
}

@test "git-safe-commit finalizes merge after resolve-conflict --ours" {
    cd "${BATS_TEST_TMPDIR}"
    ./agency/tools/git-safe resolve-conflict shared.txt --ours >/dev/null
    run ./agency/tools/git-safe-commit --no-verify
    # QG fix: assert the specific success banner from the merge-route, not a
    # generic "Merge" substring which matched everything.
    [ "$status" -eq 0 ]
    [[ "$output" == *"Merge committed"* ]]
    # No MERGE_HEAD should remain
    [ ! -f .git/MERGE_HEAD ]
    # Last commit should be a merge (two parents)
    run git log -1 --format="%P" HEAD
    [[ "$output" == *" "* ]]  # two parents separated by space
}

@test "git-safe-commit finalizes merge after resolve-conflict --theirs" {
    cd "${BATS_TEST_TMPDIR}"
    ./agency/tools/git-safe resolve-conflict shared.txt --theirs >/dev/null
    run ./agency/tools/git-safe-commit --no-verify
    [ "$status" -eq 0 ]
    [ ! -f .git/MERGE_HEAD ]
}

@test "git-safe-commit merge-route does NOT require --no-work-item" {
    cd "${BATS_TEST_TMPDIR}"
    ./agency/tools/git-safe resolve-conflict shared.txt --ours >/dev/null
    # Plain git-safe-commit (no message, no work-item) should succeed mid-merge
    run ./agency/tools/git-safe-commit --no-verify
    [ "$status" -eq 0 ]
}
