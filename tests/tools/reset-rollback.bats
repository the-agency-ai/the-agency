#!/usr/bin/env bats
#
# BATS: reset-rollback (v46.0 reset — Phase 0b)
# Required min-test-count: 6 (per Plan v4 §3 Phase 0b)
# Actual tests: 6

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/claude/tools/reset-rollback"

    TMP_REPO="$(mktemp -d -t rr.XXXXXX)"
    cd "$TMP_REPO"
    git init -q -b main .
    git config user.email "t@t"
    git config user.name "t"
    echo seed > README
    git add .; git commit -q -m s
    BASE="$(git rev-parse HEAD)"
    # Seed untracked shim file (simulates Principle 12 captain-private shim)
    mkdir -p usr/jordan/captain/reset-baseline-20260419
    echo "shim content" > usr/jordan/captain/reset-baseline-20260419/reset-shim.sh
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "requires a mode" {
    run "$TOOL"
    [ "$status" -eq 2 ]
}

@test "--pre-commit resets HEAD-staging without touching untracked shim" {
    echo "dirty" > README
    git add README
    # Shim remains
    [ -f usr/jordan/captain/reset-baseline-20260419/reset-shim.sh ]
    run "$TOOL" --pre-commit
    [ "$status" -eq 0 ]
    [ -f usr/jordan/captain/reset-baseline-20260419/reset-shim.sh ]
    # README is reset to HEAD state
    grep -q "seed" README
}

@test "--full-reset-to-tag resets to tag (shim preserved)" {
    # Commit ONLY tracked content (shim stays untracked — Principle 12)
    echo "new commit" > NEW.md
    git add NEW.md; git commit -q -m new
    git tag my-anchor "$BASE"
    run "$TOOL" --full-reset-to-tag my-anchor
    [ "$status" -eq 0 ]
    [ ! -f NEW.md ]
    # Untracked shim remains untouched by git reset --hard
    [ -f usr/jordan/captain/reset-baseline-20260419/reset-shim.sh ]
}

@test "--full-reset-to-tag fails on missing tag" {
    run "$TOOL" --full-reset-to-tag does-not-exist
    [ "$status" -eq 1 ]
}

@test "baseline dir preserved after reset" {
    [ -d usr/jordan/captain/reset-baseline-20260419 ]
    run "$TOOL" --pre-commit
    [ "$status" -eq 0 ]
    [ -d usr/jordan/captain/reset-baseline-20260419 ]
}
