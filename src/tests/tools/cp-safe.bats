#!/usr/bin/env bats
#
# cp-safe tests — worktree boundary validation
#
# 2026-04-21: test file rewritten to match the-agency's QG findings
# C-1/C-2/S-1/S-2 fix on cp-safe:
#
# - Fake `.git` file fixtures (touch "$DIR/.git") replaced with real
#   `git init`. The rewritten cp-safe uses `git rev-parse --show-toplevel`
#   and `--git-common-dir` instead of a `[[ -e .git ]]` string check, so
#   fake-.git fixtures no longer represent valid git trees.
#
# - New coverage:
#     * --cross-repo flag (happy path + without-flag-blocked)
#     * sibling-to-sibling worktree blocked (C-1 regression test)
#     * main-to-sibling worktree blocked
#     * `--` end-of-options sentinel (S-1)
#     * --cross-repo cannot bypass same-repo cross-worktree discipline
#

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
CP_SAFE="${REPO_ROOT}/agency/tools/cp-safe"

# Initialize a proper git repo at $1. Silent, with bats-safe config.
init_repo() {
    local dir="$1"
    git -C "$dir" init -q
    git -C "$dir" config user.email "cp-safe-test@agency.local"
    git -C "$dir" config user.name "cp-safe-test"
    git -C "$dir" config commit.gpgsign false
    # Make at least one commit so worktrees are possible
    touch "$dir/.bats-anchor"
    git -C "$dir" add .bats-anchor
    git -C "$dir" commit -q -m "test anchor"
}

# Create a shared-repo layout with two sibling worktrees under
# $1/.claude/worktrees/. Used for C-1 sibling-to-sibling coverage.
init_repo_with_siblings() {
    local main="$1"
    init_repo "$main"
    mkdir -p "$main/.claude/worktrees"
    git -C "$main" worktree add -q "$main/.claude/worktrees/A" -b sib-a 2>/dev/null
    git -C "$main" worktree add -q "$main/.claude/worktrees/B" -b sib-b 2>/dev/null
}

setup() {
    REPO_A=$(mktemp -d)
    REPO_B=$(mktemp -d)
    init_repo "$REPO_A"
    init_repo "$REPO_B"
    echo "test content" > "$REPO_A/file.txt"
    mkdir -p "$REPO_A/subdir"
    echo "nested content" > "$REPO_A/subdir/nested.txt"
    MAIN_REPO=""
}

teardown() {
    rm -rf "$REPO_A" "$REPO_B"
    if [[ -n "${MAIN_REPO:-}" ]]; then
        rm -rf "$MAIN_REPO"
    fi
    return 0
}

# ---- basic copy operations ----

@test "cp-safe: same-repo copy succeeds" {
    run bash "$CP_SAFE" "$REPO_A/file.txt" "$REPO_A/copy.txt"
    [ "$status" -eq 0 ]
    [ -f "$REPO_A/copy.txt" ]
}

@test "cp-safe: recursive flag works" {
    run bash "$CP_SAFE" -r "$REPO_A/subdir" "$REPO_A/subdir-copy"
    [ "$status" -eq 0 ]
    [ -d "$REPO_A/subdir-copy" ]
    [ -f "$REPO_A/subdir-copy/nested.txt" ]
}

# ---- argument validation ----

@test "cp-safe: no args shows usage" {
    run bash "$CP_SAFE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage"* ]]
}

@test "cp-safe: one arg shows error" {
    run bash "$CP_SAFE" "$REPO_A/file.txt"
    [ "$status" -eq 1 ]
}

@test "cp-safe: multi-source rejected" {
    run bash "$CP_SAFE" "$REPO_A/file.txt" "$REPO_A/subdir/nested.txt" "$REPO_A/dest/"
    [ "$status" -eq 1 ]
    [[ "$output" == *"exactly one source"* ]]
}

# ---- git-boundary enforcement ----

@test "cp-safe: dest outside git blocked" {
    local tmp_dest
    tmp_dest=$(mktemp -d)
    run bash "$CP_SAFE" "$REPO_A/file.txt" "$tmp_dest/copy.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"BLOCKED"* ]]
    rm -rf "$tmp_dest"
}

@test "cp-safe: source outside git blocked" {
    local tmp_src
    tmp_src=$(mktemp -d)
    echo "outside" > "$tmp_src/file.txt"
    run bash "$CP_SAFE" "$tmp_src/file.txt" "$REPO_A/copy.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"BLOCKED"* ]]
    rm -rf "$tmp_src"
}

# ---- cross-repo flag (--cross-repo) ----

@test "cp-safe: --cross-repo allows cross-repo copy" {
    run bash "$CP_SAFE" --cross-repo "$REPO_A/file.txt" "$REPO_B/copy.txt"
    [ "$status" -eq 0 ]
    [ -f "$REPO_B/copy.txt" ]
    [[ "$output" == *"Cross-repo copy"* ]]
}

@test "cp-safe: cross-repo without --cross-repo flag blocked" {
    run bash "$CP_SAFE" "$REPO_A/file.txt" "$REPO_B/copy.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"BLOCKED"* ]]
    [[ "$output" == *"Cross-repo"* ]]
    [[ "$output" == *"--cross-repo"* ]]
    [ ! -f "$REPO_B/copy.txt" ]
}

@test "cp-safe: --cross-repo with recursive flag works (flag ordering)" {
    run bash "$CP_SAFE" --cross-repo -r "$REPO_A/subdir" "$REPO_B/subdir-port"
    [ "$status" -eq 0 ]
    [ -d "$REPO_B/subdir-port" ]
    [ -f "$REPO_B/subdir-port/nested.txt" ]
}

@test "cp-safe: -r before --cross-repo works (flag ordering)" {
    run bash "$CP_SAFE" -r --cross-repo "$REPO_A/subdir" "$REPO_B/subdir-port"
    [ "$status" -eq 0 ]
    [ -d "$REPO_B/subdir-port" ]
}

# ---- worktree discipline: main <-> sibling <-> sibling ----

@test "cp-safe: main-to-sibling worktree blocked" {
    MAIN_REPO=$(mktemp -d)
    init_repo_with_siblings "$MAIN_REPO"
    echo "main content" > "$MAIN_REPO/main-file.txt"
    run bash "$CP_SAFE" "$MAIN_REPO/main-file.txt" "$MAIN_REPO/.claude/worktrees/A/copy.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cross-worktree"* ]]
    [ ! -f "$MAIN_REPO/.claude/worktrees/A/copy.txt" ]
}

@test "cp-safe: sibling-to-sibling worktree blocked (C-1 regression)" {
    # C-1: pre-fix cp-safe's string-prefix check only caught main<->sibling;
    # a sibling A to sibling B copy fell through to the cross-repo branch
    # and could be bypassed with --cross-repo. git-native detection via
    # --git-common-dir should catch this correctly.
    MAIN_REPO=$(mktemp -d)
    init_repo_with_siblings "$MAIN_REPO"
    echo "sibling A content" > "$MAIN_REPO/.claude/worktrees/A/file.txt"

    # Without --cross-repo — blocked as cross-worktree
    run bash "$CP_SAFE" \
        "$MAIN_REPO/.claude/worktrees/A/file.txt" \
        "$MAIN_REPO/.claude/worktrees/B/copy.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cross-worktree"* ]]
    [ ! -f "$MAIN_REPO/.claude/worktrees/B/copy.txt" ]
}

@test "cp-safe: --cross-repo cannot bypass sibling-to-sibling block" {
    # Principal defense-in-depth: even if a user passes --cross-repo
    # (intending a peer-repo workflow), same-repo worktrees must still
    # block. This is the direct C-1 exploit prevention.
    MAIN_REPO=$(mktemp -d)
    init_repo_with_siblings "$MAIN_REPO"
    echo "sibling A content" > "$MAIN_REPO/.claude/worktrees/A/file.txt"

    run bash "$CP_SAFE" --cross-repo \
        "$MAIN_REPO/.claude/worktrees/A/file.txt" \
        "$MAIN_REPO/.claude/worktrees/B/copy.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cross-worktree"* ]]
    [ ! -f "$MAIN_REPO/.claude/worktrees/B/copy.txt" ]
}

@test "cp-safe: main-to-sibling with --cross-repo still blocked (same-repo)" {
    MAIN_REPO=$(mktemp -d)
    init_repo_with_siblings "$MAIN_REPO"
    echo "content" > "$MAIN_REPO/main-file.txt"

    run bash "$CP_SAFE" --cross-repo \
        "$MAIN_REPO/main-file.txt" \
        "$MAIN_REPO/.claude/worktrees/A/copy.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cross-worktree"* ]]
}

# ---- `--` end-of-options sentinel (S-1) ----

@test "cp-safe: -- sentinel allows positional after flag-looking arg" {
    # Create a file literally named "-f" (exact cp flag) in repo A,
    # then reference it by bare name (no path prefix) from within $REPO_A.
    # Without the `--` sentinel, the bare "-f" would be captured into
    # CP_FLAGS by the `-*)` arm and promoted to a cp flag (S-1).
    # With `--`, it's treated as positional.
    ( cd "$REPO_A" && touch -- "-f" )
    run bash -c "cd '$REPO_A' && '$CP_SAFE' -- -f dash-copy"
    [ "$status" -eq 0 ]
    [ -f "$REPO_A/dash-copy" ]
}

# ---- path canonicalization (C-2) ----

@test "cp-safe: relative-traversal source resolves correctly" {
    # With C-2 fix, relative paths including `..` canonicalize properly
    # so cross-worktree detection works even when paths aren't tidy.
    MAIN_REPO=$(mktemp -d)
    init_repo_with_siblings "$MAIN_REPO"
    echo "sibling A content" > "$MAIN_REPO/.claude/worktrees/A/file.txt"

    # From sibling A, point at sibling B via `../B/...` relative path
    run bash -c "cd '$MAIN_REPO/.claude/worktrees/A' && '$CP_SAFE' file.txt ../B/copy.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cross-worktree"* ]]
}
