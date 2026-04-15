#!/usr/bin/env bats
#
# git-captain sync-main tests — fast-forward local main to origin/main.
#
# Scope: sync-main subcommand only. A broader git-captain.bats covering all
# subcommands is a separate, pre-existing gap (flag #128).
#

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
GIT_CAPTAIN="${REPO_ROOT}/claude/tools/git-captain"

# Create an isolated repo+origin pair for sync-main scenarios.
# Returns: prints path to the worktree clone. Origin is at <clone>/../origin.git.
setup_repo_with_origin() {
    local base="$(mktemp -d)"
    local origin="${base}/origin.git"
    local work="${base}/work"
    git init --bare --initial-branch=main "$origin" >/dev/null 2>&1
    git clone "$origin" "$work" >/dev/null 2>&1
    (
        cd "$work"
        git config user.email "test@example.com"
        git config user.name "Test"
        git commit --allow-empty -m "initial" >/dev/null
        git branch -M main
        git push origin main >/dev/null 2>&1
    )
    echo "$work"
}

# Advance origin/main by one commit (simulates a merged PR).
advance_origin() {
    local work="$1"
    local tmp="$(mktemp -d)"
    git clone "${work}/../origin.git" "$tmp/other" >/dev/null 2>&1
    (
        cd "$tmp/other"
        git config user.email "other@example.com"
        git config user.name "Other"
        git commit --allow-empty -m "remote advance" >/dev/null
        git push origin main >/dev/null 2>&1
    )
    rm -rf "$tmp"
}

@test "sync-main: rejects extra args" {
    run bash "$GIT_CAPTAIN" sync-main foo
    [ "$status" -ne 0 ]
    [[ "$output" == *"takes no arguments"* ]]
}

@test "sync-main: errors when not on main" {
    local work; work="$(setup_repo_with_origin)"
    cd "$work"
    git checkout -b feature >/dev/null 2>&1
    run bash "$GIT_CAPTAIN" sync-main
    [ "$status" -ne 0 ]
    [[ "$output" == *"Must be on main"* ]]
}

@test "sync-main: errors when tree is dirty" {
    local work; work="$(setup_repo_with_origin)"
    cd "$work"
    echo "dirty" > dirty.txt
    git add dirty.txt
    run bash "$GIT_CAPTAIN" sync-main
    [ "$status" -ne 0 ]
    [[ "$output" == *"dirty"* ]]
}

@test "sync-main: errors when HEAD is detached" {
    local work; work="$(setup_repo_with_origin)"
    cd "$work"
    git checkout --detach HEAD >/dev/null 2>&1
    run bash "$GIT_CAPTAIN" sync-main
    [ "$status" -ne 0 ]
    [[ "$output" == *"detached"* ]]
}

@test "sync-main: errors when origin/main ref missing" {
    local dir; dir="$(mktemp -d)"
    cd "$dir"
    git init --initial-branch=main >/dev/null 2>&1
    git config user.email "test@example.com"
    git config user.name "Test"
    git commit --allow-empty -m "initial" >/dev/null
    run bash "$GIT_CAPTAIN" sync-main
    [ "$status" -ne 0 ]
    [[ "$output" == *"origin/main"* ]]
}

@test "sync-main: happy path fast-forwards to origin/main" {
    local work; work="$(setup_repo_with_origin)"
    advance_origin "$work"
    cd "$work"
    git fetch origin >/dev/null 2>&1
    run bash "$GIT_CAPTAIN" sync-main
    [ "$status" -eq 0 ]
    [[ "$output" == *"sync-main complete"* ]]
    # Verify HEAD actually advanced
    [[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]]
}

@test "sync-main: no-op when already at origin/main" {
    local work; work="$(setup_repo_with_origin)"
    cd "$work"
    git fetch origin >/dev/null 2>&1
    run bash "$GIT_CAPTAIN" sync-main
    [ "$status" -eq 0 ]
    [[ "$output" == *"sync-main complete"* ]]
}

@test "sync-main: fails on diverged history" {
    local work; work="$(setup_repo_with_origin)"
    advance_origin "$work"
    cd "$work"
    git fetch origin >/dev/null 2>&1
    # Local main diverges: commit locally without pulling
    git commit --allow-empty -m "local divergence" >/dev/null
    run bash "$GIT_CAPTAIN" sync-main
    [ "$status" -ne 0 ]
    [[ "$output" == *"Fast-forward failed"* ]]
}
