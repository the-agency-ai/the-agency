#!/usr/bin/env bats
#
# cp-safe tests — worktree boundary validation
#

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
CP_SAFE="${REPO_ROOT}/agency/tools/cp-safe"

setup() {
    # Create two fake worktrees with .git markers
    WORKTREE_A=$(mktemp -d)
    WORKTREE_B=$(mktemp -d)
    touch "$WORKTREE_A/.git"
    touch "$WORKTREE_B/.git"
    mkdir -p "$WORKTREE_A/subdir"
    echo "test content" > "$WORKTREE_A/file.txt"
    echo "test content" > "$WORKTREE_A/subdir/nested.txt"
}

teardown() {
    rm -rf "$WORKTREE_A" "$WORKTREE_B"
}

@test "cp-safe: same worktree copy succeeds" {
    run bash "$CP_SAFE" "$WORKTREE_A/file.txt" "$WORKTREE_A/copy.txt"
    [ "$status" -eq 0 ]
    [ -f "$WORKTREE_A/copy.txt" ]
}

@test "cp-safe: cross-worktree copy blocked" {
    run bash "$CP_SAFE" "$WORKTREE_A/file.txt" "$WORKTREE_B/copy.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"BLOCKED"* ]]
    [[ "$output" == *"Cross-worktree"* ]]
    [ ! -f "$WORKTREE_B/copy.txt" ]
}

@test "cp-safe: no args shows usage" {
    run bash "$CP_SAFE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage"* ]]
}

@test "cp-safe: one arg shows error" {
    run bash "$CP_SAFE" "$WORKTREE_A/file.txt"
    [ "$status" -eq 1 ]
}

@test "cp-safe: multi-source rejected" {
    run bash "$CP_SAFE" "$WORKTREE_A/file.txt" "$WORKTREE_A/subdir/nested.txt" "$WORKTREE_A/dest/"
    [ "$status" -eq 1 ]
    [[ "$output" == *"exactly one source"* ]]
}

@test "cp-safe: recursive flag works" {
    run bash "$CP_SAFE" -r "$WORKTREE_A/subdir" "$WORKTREE_A/subdir-copy"
    [ "$status" -eq 0 ]
    [ -d "$WORKTREE_A/subdir-copy" ]
}

@test "cp-safe: dest outside git blocked" {
    local tmp_dest
    tmp_dest=$(mktemp -d)
    run bash "$CP_SAFE" "$WORKTREE_A/file.txt" "$tmp_dest/copy.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"BLOCKED"* ]]
    rm -rf "$tmp_dest"
}

@test "cp-safe: source outside git blocked" {
    local tmp_src
    tmp_src=$(mktemp -d)
    echo "outside" > "$tmp_src/file.txt"
    run bash "$CP_SAFE" "$tmp_src/file.txt" "$WORKTREE_A/copy.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"BLOCKED"* ]]
    rm -rf "$tmp_src"
}
