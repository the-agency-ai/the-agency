#!/usr/bin/env bats
#
# BATS: agency-update-migrate-back (v46.0 reset — Phase 0b)
# Required min-test-count: 8 (per Plan v4 §3 Phase 0b)
# Actual tests: 8

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/agency/tools/agency-update-migrate-back"
    TMP_REPO="$(mktemp -d -t amb.XXXXXX)"
    cd "$TMP_REPO"
    git init -q .
    git config user.email "t@t"
    git config user.name "t"
    echo seed > README
    git add .; git commit -q -m s
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "refuses when tag is missing (exit 11)" {
    run "$TOOL"
    [ "$status" -eq 11 ]
    [[ "$output" == *"tag not found"* ]]
}

@test "refuses on dirty tree without --force (exit 10)" {
    git tag v45.3-pre-reset-local
    echo "dirty" > dirty.md
    run "$TOOL"
    [ "$status" -eq 10 ]
}

@test "--force proceeds on dirty tree" {
    git tag v45.3-pre-reset-local
    echo "dirty" > dirty.md
    run "$TOOL" --force
    [ "$status" -eq 0 ]
}

@test "clean tree rollback succeeds" {
    git tag v45.3-pre-reset-local
    run "$TOOL"
    [ "$status" -eq 0 ]
}

@test "rollback clears prep marker" {
    git tag v45.3-pre-reset-local
    mkdir -p .agency
    touch .agency/migrate-prep-v46.ok
    # Marker is tracked — need to add+commit+stash it so clean tree
    git add .agency; git commit -q -m marker
    git tag v45.3-pre-reset-local -f
    run "$TOOL"
    [ "$status" -eq 0 ]
    [ ! -f .agency/migrate-prep-v46.ok ]
}

@test "rescue log is created" {
    git tag v45.3-pre-reset-local
    mkdir -p agency/workstreams/w
    echo "dispatch" > agency/workstreams/w/dispatch-test.md
    git add agency; git commit -q -m ds
    git tag v45.3-pre-reset-local -f HEAD~0
    run "$TOOL" --force
    [ "$status" -eq 0 ]
    [ -f .agency/migrate-back-rescue-v46.log ]
}

@test "--json emits structured output" {
    git tag v45.3-pre-reset-local
    run "$TOOL" --json
    [ "$status" -eq 0 ]
    [[ "$output" == *'"severity":"OK"'* ]]
}
