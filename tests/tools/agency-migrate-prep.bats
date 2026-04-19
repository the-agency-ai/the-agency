#!/usr/bin/env bats
#
# BATS: agency-migrate-prep (v46.0 reset — Phase 0b)
# Required min-test-count: 10 (per Plan v4 §3 Phase 0b)
# Actual tests: 10

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/claude/tools/agency-migrate-prep"

    TMP_REPO="$(mktemp -d -t amp.XXXXXX)"
    cd "$TMP_REPO"
    git init -q .
    git config user.email "test@test"
    git config user.name "test"
    echo "seed" > README
    git add .; git commit -q -m "seed"
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "--version prints version" {
    run "$TOOL" --version
    [ "$status" -eq 0 ]
}

@test "dry-run is default; no marker written" {
    run "$TOOL"
    [ "$status" -eq 0 ]
    [ ! -f .agency/migrate-prep-v46.ok ]
}

@test "dry-run creates backup tag" {
    run "$TOOL"
    [ "$status" -eq 0 ]
    git rev-parse v45.3-pre-reset-local
}

@test "--apply --yes creates prep marker" {
    run "$TOOL" --apply --yes
    [ "$status" -eq 0 ]
    [ -f .agency/migrate-prep-v46.ok ]
}

@test "idempotent: re-run with marker present returns exit 10" {
    "$TOOL" --apply --yes >/dev/null
    run "$TOOL" --apply --yes
    [ "$status" -eq 10 ]
    [[ "$output" == *"already present"* ]]
}

@test "--apply without --yes in non-TTY refuses" {
    run "$TOOL" --apply
    [ "$status" -eq 2 ]
    [[ "$output" == *"refusing"* ]]
}

@test "backup tag persists even after prep" {
    "$TOOL" --apply --yes >/dev/null
    git rev-parse v45.3-pre-reset-local
}

@test "--json emits structured output" {
    run "$TOOL" --json
    [ "$status" -eq 0 ]
    [[ "$output" == *'"severity":"OK"'* ]]
}

@test "marker content includes timestamp" {
    "$TOOL" --apply --yes >/dev/null
    grep -q "ts=" .agency/migrate-prep-v46.ok
}
