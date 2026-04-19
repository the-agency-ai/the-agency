#!/usr/bin/env bats
#
# What Problem: `_detect-main-branch` is the shared MAIN_BRANCH resolver
# for framework tools. All four resolution paths (origin/HEAD, local main,
# local master, safety-guard refusal) must be mechanically verified,
# because every one of these is the hinge of a "data loss" class bug
# somewhere in the framework's history. If the resolver drifts silently,
# we reintroduce the Day 42 designex incident.
#
# How & Why: per-path fixture setup + assertion. Each test builds a
# minimal git repo in a temp dir, configures the specific state we want
# (origin/HEAD set, local branches present/absent, ref pointing at
# non-main/master), and asserts the helper returns the expected branch
# name and exit code.
#
# Written: 2026-04-19 during D45-R3 — helper extraction. Regression tests
# for all four resolution paths + explicit safety-guard coverage.

load 'test_helper'

# Helper: set up a minimal git repo with main-branch initialized to $1
# (either "main" or "master"). Returns tmp dir path.
setup_repo_main_branch() {
    local branch="$1"
    local root="${BATS_TEST_TMPDIR}/repo-${branch}"
    mkdir -p "$root"
    git init --quiet --initial-branch="$branch" "$root"
    ( cd "$root" && echo "hello" > README.md && git add README.md && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify )
    echo "$root"
}

# Helper: set up repo with BOTH main and master branches (mid-rename scenario)
setup_repo_both_branches() {
    local root="${BATS_TEST_TMPDIR}/repo-both"
    mkdir -p "$root"
    git init --quiet --initial-branch=master "$root"
    ( cd "$root" && echo "hello" > README.md && git add README.md && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify && \
        git branch main )
    echo "$root"
}

# Helper: attach a fake remote origin with origin/HEAD pointing at $2
# $1 = repo path, $2 = branch that origin/HEAD should point to
set_origin_head() {
    local repo="$1" branch="$2"
    local fake_remote="${BATS_TEST_TMPDIR}/remote-$(basename "$repo")"
    mkdir -p "$fake_remote"
    git init --bare --quiet --initial-branch="$branch" "$fake_remote"
    ( cd "$repo" && git remote add origin "$fake_remote" && \
        git push --quiet origin "$branch" && \
        git remote set-head origin "$branch" )
}

# Source the helper in a clean bash environment for each test.
# The helper defines a function; the subshell pattern isolates it.
detect() {
    local repo="$1"
    bash -c "source \"${REPO_ROOT:-$(pwd)}/claude/tools/lib/_detect-main-branch\" && detect_main_branch \"$repo\""
}

@test "detect_main_branch: fails loudly when called with no argument" {
    run detect ""
    [ "$status" -ne 0 ]
    [[ "$output" == *"required argument"* ]]
}

@test "detect_main_branch: fails loudly on non-git directory" {
    mkdir -p "${BATS_TEST_TMPDIR}/not-a-repo"
    run detect "${BATS_TEST_TMPDIR}/not-a-repo"
    [ "$status" -ne 0 ]
    [[ "$output" == *"not a git repository"* ]]
}

@test "detect_main_branch: resolves via origin/HEAD symbolic-ref (main)" {
    local repo
    repo=$(setup_repo_main_branch main)
    set_origin_head "$repo" main
    run detect "$repo"
    [ "$status" -eq 0 ]
    [ "$output" = "main" ]
}

@test "detect_main_branch: resolves via origin/HEAD symbolic-ref (master)" {
    local repo
    repo=$(setup_repo_main_branch master)
    set_origin_head "$repo" master
    run detect "$repo"
    [ "$status" -eq 0 ]
    [ "$output" = "master" ]
}

@test "detect_main_branch: falls back to local main when no origin/HEAD" {
    local repo
    repo=$(setup_repo_main_branch main)
    run detect "$repo"
    [ "$status" -eq 0 ]
    [ "$output" = "main" ]
}

@test "detect_main_branch: falls back to local master when no main and no origin/HEAD" {
    local repo
    repo=$(setup_repo_main_branch master)
    run detect "$repo"
    [ "$status" -eq 0 ]
    [ "$output" = "master" ]
}

@test "detect_main_branch: prefers main over master when both exist (mid-rename scenario)" {
    local repo
    repo=$(setup_repo_both_branches)
    # No origin/HEAD — fallback order matters
    run detect "$repo"
    [ "$status" -eq 0 ]
    [ "$output" = "main" ]
}

@test "detect_main_branch: safety guard refuses when origin/HEAD points to non-main/master (e.g., trunk)" {
    local repo
    repo=$(setup_repo_main_branch trunk)
    set_origin_head "$repo" trunk
    run detect "$repo"
    [ "$status" -ne 0 ]
    [[ "$output" == *"not main or master"* ]]
    [[ "$output" == *"escalate"* ]]
}

@test "detect_main_branch: fails loudly when no branches and no origin/HEAD" {
    # Git init but never commit — no branches exist
    local repo="${BATS_TEST_TMPDIR}/repo-empty"
    mkdir -p "$repo"
    git init --quiet "$repo"
    run detect "$repo"
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot determine main branch"* ]]
    [[ "$output" == *"git remote set-head"* ]]
}

@test "detect_main_branch: ignores origin/HEAD pointing to branch with no local ref, falls through to local" {
    # Origin says main, but local only has master (fresh clone edge case)
    local repo
    repo=$(setup_repo_main_branch master)
    # Set origin/HEAD to main WITHOUT creating local main
    local fake_remote="${BATS_TEST_TMPDIR}/remote-fresh"
    mkdir -p "$fake_remote"
    git init --bare --quiet --initial-branch=main "$fake_remote"
    ( cd "$repo" && git remote add origin "$fake_remote" && \
        git push --quiet origin master:main && \
        git remote set-head origin main )
    # Local main doesn't exist; origin/HEAD → main
    run detect "$repo"
    # Helper should fall through to local master rather than return empty or fail
    [ "$status" -eq 0 ]
    [ "$output" = "master" ]
}

@test "detect_main_branch: handles repo path with spaces (quoting correctness)" {
    # Regression for QGR reviewer-test M1 — the helper uses `git -C "$path"`
    # throughout and must resolve cleanly even when the repo lives under a
    # path with spaces. macOS default user dirs ("~/Library/Application
    # Support", "~/My Drive/…") routinely contain spaces; this case must
    # never silently regress to the empty-path failure mode.
    local root="${BATS_TEST_TMPDIR}/repo with spaces"
    mkdir -p "$root"
    git init --quiet --initial-branch=main "$root"
    ( cd "$root" && echo "hello" > README.md && git add README.md && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify )
    run detect "$root"
    [ "$status" -eq 0 ]
    [ "$output" = "main" ]
}
