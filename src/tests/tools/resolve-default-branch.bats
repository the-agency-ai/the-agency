#!/usr/bin/env bats
#
# resolve-default-branch — the shared default-branch primitive.
#
# Seven copies of this logic had drifted across the tool tree, each with a
# different probe order, a different fallback, and a different failure mode.
# This suite pins the UNION contract the consumers were converged onto:
#
#   - the probe order (local refs → origin/HEAD → origin/{main,master})
#   - the `main` fallback in default mode (NOT `master` — #463 QG finding)
#   - `--strict` exits nonzero and prints NOTHING, so the fail-closed
#     consumers (git-captain, pr-create) keep failing loud
#   - slash-bearing default branch names survive the prefix strip
#
# Each test builds a throwaway repo pair (origin + clone) in BATS_TEST_TMPDIR
# so no probe can reach the real repo.

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
TOOL="${REPO_ROOT}/agency/tools/resolve-default-branch"

# Build an origin repo whose default branch is $1, cloned to $CLONE.
# Leaves: $ORIGIN (bare-ish source repo), $CLONE (the repo under test).
setup_repo_pair() {
    local default_branch="$1"

    ORIGIN="$BATS_TEST_TMPDIR/origin"
    CLONE="$BATS_TEST_TMPDIR/clone"

    git init --quiet --initial-branch="$default_branch" "$ORIGIN"
    git -C "$ORIGIN" config user.email "t@example.com"
    git -C "$ORIGIN" config user.name "t"
    echo seed > "$ORIGIN/seed.txt"
    git -C "$ORIGIN" add seed.txt
    git -C "$ORIGIN" commit --quiet -m seed

    git clone --quiet "$ORIGIN" "$CLONE"
    git -C "$CLONE" config user.email "t@example.com"
    git -C "$CLONE" config user.name "t"
}

# Detach the clone from any local branch and delete every local branch ref,
# so only remote-tracking refs remain. This is what isolates probes 3-5 from
# probes 1-2.
strip_local_branches() {
    local sha
    sha="$(git -C "$CLONE" rev-parse HEAD)"
    git -C "$CLONE" checkout --quiet --detach "$sha"
    local b
    for b in $(git -C "$CLONE" for-each-ref --format='%(refname:short)' refs/heads); do
        git -C "$CLONE" branch --quiet -D "$b"
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Shape
# ─────────────────────────────────────────────────────────────────────────────

@test "resolve-default-branch: exists and is executable" {
    [ -x "$TOOL" ]
}

@test "resolve-default-branch: is syntactically valid bash" {
    bash -n "$TOOL"
}

@test "resolve-default-branch: --help exits 0 and documents --strict" {
    run bash "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--strict"* ]]
}

@test "resolve-default-branch: unknown flag is a usage error (exit 2)" {
    run bash "$TOOL" --nope
    [ "$status" -eq 2 ]
}

@test "resolve-default-branch: outside a git repo exits 1" {
    run bash "$TOOL" -C "$BATS_TEST_TMPDIR"
    [ "$status" -eq 1 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Probe 1/2 — local branch refs win (git-captain's recovery case: origin
# unreachable, local main still present)
# ─────────────────────────────────────────────────────────────────────────────

@test "resolve-default-branch: local refs/heads/main resolves to main" {
    setup_repo_pair main
    run bash "$TOOL" -C "$CLONE"
    [ "$status" -eq 0 ]
    [ "$output" = "main" ]
}

@test "resolve-default-branch: local refs/heads/master resolves to master" {
    setup_repo_pair master
    run bash "$TOOL" -C "$CLONE"
    [ "$status" -eq 0 ]
    [ "$output" = "master" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Probe 3 — origin/HEAD
# ─────────────────────────────────────────────────────────────────────────────

@test "resolve-default-branch: origin/HEAD present (no local branches) resolves via symbolic ref" {
    setup_repo_pair trunk
    git -C "$CLONE" remote set-head origin -a >/dev/null 2>&1
    strip_local_branches
    run bash "$TOOL" -C "$CLONE"
    [ "$status" -eq 0 ]
    [ "$output" = "trunk" ]
}

@test "resolve-default-branch: slash-bearing default branch survives the prefix strip" {
    setup_repo_pair release/stable
    git -C "$CLONE" remote set-head origin -a >/dev/null 2>&1
    strip_local_branches
    run bash "$TOOL" -C "$CLONE"
    [ "$status" -eq 0 ]
    [ "$output" = "release/stable" ]
}

@test "resolve-default-branch: slash-bearing name also resolves in --strict mode" {
    setup_repo_pair release/stable
    git -C "$CLONE" remote set-head origin -a >/dev/null 2>&1
    strip_local_branches
    run bash "$TOOL" -C "$CLONE" --strict
    [ "$status" -eq 0 ]
    [ "$output" = "release/stable" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Probe 4/5 — remote-tracking refs when origin/HEAD is absent
# ─────────────────────────────────────────────────────────────────────────────

@test "resolve-default-branch: origin/HEAD absent + origin/main present → main" {
    setup_repo_pair main
    git -C "$CLONE" symbolic-ref --delete refs/remotes/origin/HEAD 2>/dev/null || true
    strip_local_branches
    run bash "$TOOL" -C "$CLONE"
    [ "$status" -eq 0 ]
    [ "$output" = "main" ]
}

@test "resolve-default-branch: origin/HEAD absent + origin/master present → master" {
    setup_repo_pair master
    git -C "$CLONE" symbolic-ref --delete refs/remotes/origin/HEAD 2>/dev/null || true
    strip_local_branches
    run bash "$TOOL" -C "$CLONE"
    [ "$status" -eq 0 ]
    [ "$output" = "master" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Probe 6 — the fallback, and the --strict policy split
# ─────────────────────────────────────────────────────────────────────────────

@test "resolve-default-branch: nothing resolvable → falls back to main (not master)" {
    setup_repo_pair trunk
    git -C "$CLONE" symbolic-ref --delete refs/remotes/origin/HEAD 2>/dev/null || true
    strip_local_branches
    # Remove every remote-tracking ref too — now no probe can succeed.
    local r
    for r in $(git -C "$CLONE" for-each-ref --format='%(refname)' refs/remotes); do
        git -C "$CLONE" update-ref -d "$r"
    done
    run bash "$TOOL" -C "$CLONE"
    [ "$status" -eq 0 ]
    [ "$output" = "main" ]
}

@test "resolve-default-branch: nothing resolvable + --strict → nonzero and no name on stdout" {
    setup_repo_pair trunk
    git -C "$CLONE" symbolic-ref --delete refs/remotes/origin/HEAD 2>/dev/null || true
    strip_local_branches
    local r
    for r in $(git -C "$CLONE" for-each-ref --format='%(refname)' refs/remotes); do
        git -C "$CLONE" update-ref -d "$r"
    done

    # stdout captured separately: --strict must print NOTHING there, so a
    # caller doing BRANCH=$(resolve-default-branch --strict) cannot end up
    # with a plausible-looking wrong value.
    run bash -c "bash '$TOOL' -C '$CLONE' --strict 2>/dev/null"
    [ "$status" -ne 0 ]
    [ -z "$output" ]
}

@test "resolve-default-branch: --strict failure explains the fix on stderr" {
    setup_repo_pair trunk
    git -C "$CLONE" symbolic-ref --delete refs/remotes/origin/HEAD 2>/dev/null || true
    strip_local_branches
    local r
    for r in $(git -C "$CLONE" for-each-ref --format='%(refname)' refs/remotes); do
        git -C "$CLONE" update-ref -d "$r"
    done
    run bash -c "bash '$TOOL' -C '$CLONE' --strict 2>&1 >/dev/null"
    [ "$status" -ne 0 ]
    [[ "$output" == *"remote set-head"* ]]
}
