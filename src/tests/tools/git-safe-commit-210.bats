#!/usr/bin/env bats
#
# Tests for git-safe-commit #210 guard — commit-notify cascade prevention.
#
# What Problem: Every commit via git-safe-commit fires a "committed" dispatch
# to captain that writes a notify file at
# `usr/{principal}/{agent}/dispatches/commit-to-captain-committed-*.md`.
# That file is in a tracked directory, so the NEXT commit includes it, which
# fires ANOTHER dispatch, which writes ANOTHER notify file — infinite
# cascade. Observed on mdpal-cli 2026-04-20 as a 3-deep "carry-over commit
# cascade" in the branch history.
#
# How & Why: The guard (git-safe-commit lines 541-553) runs `git diff-tree
# --name-only -r HEAD` after the commit and classifies files. If EVERY file
# in the commit matches the notify-file pattern, skip dispatch-create. Any
# non-notify file in the commit → dispatch fires normally.
#
# Tests cover:
#   1. Commit of ONE notify-only file → guard fires, no dispatch
#   2. Commit of MIXED notify + non-notify files → guard does NOT fire
#   3. Commit of TWO notify files from different agents → guard still fires
#   4. Verbose log message "[#210 guard]" appears (#210)
#
# Written: 2026-04-21 during Bucket 0b of A-B-C-D-E-F-G stabilization push
# (the-agency#210 fix).
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

    # Install git-safe + git-safe-commit + lib deps
    mkdir -p agency/tools/lib
    for t in git-safe git-safe-commit; do
        cp "${REPO_ROOT}/agency/tools/$t" "agency/tools/$t"
        chmod +x "agency/tools/$t"
    done
    for lib in _log-helper _colors; do
        cp "${REPO_ROOT}/agency/tools/lib/$lib" "agency/tools/lib/$lib" 2>/dev/null || true
    done

    # Disable pre-commit hook and skip-validation paths (speed + self-contained).
    git config core.hooksPath /dev/null 2>/dev/null || true

    # Baseline commit so HEAD exists. Include the copied tool files so
    # they are NOT untracked during tests (would otherwise get swept in
    # by `git add .` and pollute the commit file-list).
    echo "base" > README.md
    git add README.md agency/tools/
    git commit -m "base" --quiet --no-verify

    if [[ "$(git branch --show-current)" == "master" ]]; then
        git branch -m master main
    fi

    # Switch to a feature branch (the dispatch path only runs off main/master).
    git checkout -b feature/test-210 --quiet

    # Ignore test-isolation's fakehome bytecode cache + agency logs — these
    # get written during git-safe-commit's telemetry and shouldn't pollute
    # the test's commit-file-list.
    cat > .gitignore <<EOF
fakehome/
.claude/logs/
EOF
    git add .gitignore
    git commit -m "ignore test-runtime dirs" --quiet --no-verify
}

teardown() {
    test_isolation_teardown
    [[ -d "${BATS_TEST_TMPDIR}" ]] && rm -rf "${BATS_TEST_TMPDIR}"
}

# Helper: create a fake notify-file payload at the standard path.
_make_notify_file() {
    local principal="${1:-jordan}"
    local agent="${2:-testagent}"
    local shortsha="${3:-abc1234}"
    mkdir -p "usr/${principal}/${agent}/dispatches"
    local path="usr/${principal}/${agent}/dispatches/commit-to-captain-committed-${shortsha}-on-feature-test-210-test-commit-20260421-1200.md"
    cat >"$path" <<EOF
# Commit: ${shortsha}
This is a fake notify file for #210 regression testing.
EOF
    echo "$path"
}

@test "#210 guard: commit with ONLY notify files fires the skip log" {
    cd "${BATS_TEST_TMPDIR}"
    _make_notify_file jordan testagent abc1234 >/dev/null

    git add .
    run ./agency/tools/git-safe-commit --staged "carry-over notify only" --no-work-item
    [ "$status" -eq 0 ]
    [[ "$output" == *"[#210 guard]"* ]] || {
        echo "Expected skip log not found in output:"
        echo "$output"
        return 1
    }
}

@test "#210 guard: commit with MIXED notify + non-notify files does NOT skip" {
    cd "${BATS_TEST_TMPDIR}"
    _make_notify_file jordan testagent def5678 >/dev/null
    echo "real work" > src.txt

    git add .
    run ./agency/tools/git-safe-commit --staged "mixed scope" --no-work-item
    [ "$status" -eq 0 ]
    # Guard should NOT have fired the skip path — non-notify file present.
    [[ "$output" != *"[#210 guard]"* ]]
}

@test "#210 guard: commit with TWO notify files (different agents) still skips" {
    cd "${BATS_TEST_TMPDIR}"
    _make_notify_file jordan alpha aaaa111 >/dev/null
    _make_notify_file jordan beta bbbb222 >/dev/null

    git add .
    run ./agency/tools/git-safe-commit --staged "two notify files" --no-work-item
    [ "$status" -eq 0 ]
    [[ "$output" == *"[#210 guard]"* ]]
}

@test "#210 guard: commit with notify file in non-standard principal path still skips" {
    cd "${BATS_TEST_TMPDIR}"
    # Pattern: usr/{anything}/{anything}/dispatches/commit-to-captain-committed-*.md
    _make_notify_file andrew somebody cccc333 >/dev/null

    git add .
    run ./agency/tools/git-safe-commit --staged "other-principal notify" --no-work-item
    [ "$status" -eq 0 ]
    [[ "$output" == *"[#210 guard]"* ]]
}

@test "#210 guard: commit of regular handoff file does NOT trigger skip (handoff is NOT a notify file)" {
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p usr/jordan/captain
    echo "handoff content" > usr/jordan/captain/captain-handoff.md

    git add .
    run ./agency/tools/git-safe-commit --staged "handoff update" --no-work-item
    [ "$status" -eq 0 ]
    # Handoff is NOT a notify file; guard must NOT fire.
    [[ "$output" != *"[#210 guard]"* ]]
}
