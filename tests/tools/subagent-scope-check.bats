#!/usr/bin/env bats
#
# BATS: subagent-scope-check (v46.0 reset — Phase 0b)
# Required min-test-count: 6 (per Plan v4 §3 Phase 0b)
# Actual tests: 7

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/agency/tools/subagent-scope-check"

    TMP_REPO="$(mktemp -d -t sasc.XXXXXX)"
    cd "$TMP_REPO"
    git init -q -b main .
    git config user.email "test@test"
    git config user.name "test"
    mkdir -p agency/tools agency/hooks
    echo "x" > agency/tools/a
    echo "y" > agency/hooks/h
    git add .; git commit -q -m "seed"
    BASE="$(git rev-parse HEAD)"
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

make_manifest() {
    cat > manifest.yaml <<EOF
subagent: A
files:
  - agency/tools/*
$1
EOF
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "requires --manifest" {
    run "$TOOL" --branch foo
    [ "$status" -eq 2 ]
}

@test "requires --branch" {
    make_manifest ""
    run "$TOOL" --manifest manifest.yaml
    [ "$status" -eq 2 ]
}

@test "in-scope changes pass" {
    make_manifest ""
    git checkout -q -b work
    echo "zz" >> agency/tools/a
    git commit -q -am "in-scope"
    run "$TOOL" --manifest manifest.yaml --branch work --base "$BASE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"OK"* ]]
}

@test "out-of-scope change rejects" {
    make_manifest ""
    git checkout -q -b work
    echo "zz" >> agency/hooks/h
    git commit -q -am "out"
    run "$TOOL" --manifest manifest.yaml --branch work --base "$BASE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"OUT-OF-SCOPE"* ]]
}

@test "non-empty assertion: zero changes without expected_changes: 0 fails" {
    make_manifest ""
    git checkout -q -b work
    run "$TOOL" --manifest manifest.yaml --branch work --base HEAD
    [ "$status" -eq 1 ]
}

@test "expected_changes: 0 permits zero changes" {
    make_manifest "expected_changes: 0"
    git checkout -q -b work
    run "$TOOL" --manifest manifest.yaml --branch work --base HEAD
    [ "$status" -eq 0 ]
}
