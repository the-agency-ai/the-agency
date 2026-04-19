#!/usr/bin/env bats
#
# BATS: agency-update-migrate (v46.0 reset — Phase 0b)
# Required min-test-count: 6 (per Plan v4 §3 Phase 0b)
# Actual tests: 6

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/agency/tools/agency-update-migrate"
    TMP_REPO="$(mktemp -d -t aum.XXXXXX)"
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

@test "refuses without --migrate (exit 10)" {
    run "$TOOL"
    [ "$status" -eq 10 ]
    [[ "$output" == *"requires --migrate"* ]]
}

@test "refuses without prep marker (exit 11)" {
    run "$TOOL" --migrate
    [ "$status" -eq 11 ]
    [[ "$output" == *"prep marker missing"* ]]
}

@test "succeeds with --migrate AND marker" {
    mkdir -p .agency agency
    touch .agency/migrate-prep-v46.ok
    run "$TOOL" --migrate
    [ "$status" -eq 0 ]
}

@test "detects inconsistent tree (exit 12)" {
    mkdir -p .agency claude
    touch .agency/migrate-prep-v46.ok
    run "$TOOL" --migrate
    [ "$status" -eq 12 ]
}

@test "--json emits structured output on refuse" {
    run "$TOOL" --json
    [ "$status" -eq 10 ]
    [[ "$output" == *'"severity":"FAIL"'* ]]
}
