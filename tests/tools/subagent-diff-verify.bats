#!/usr/bin/env bats
#
# BATS: subagent-diff-verify (v46.0 reset — Phase 0b)
# Required min-test-count: 10 (per Plan v4 §3 Phase 0b)
# Actual tests: 11

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/claude/tools/subagent-diff-verify"

    TMP_REPO="$(mktemp -d -t sdv.XXXXXX)"
    cd "$TMP_REPO"
    git init -q -b main .
    git config user.email "test@test"
    git config user.name "test"

    cat > manifest.yaml <<'EOF'
subagent: A
allowed_substitutions:
  - pattern: "claude/tools/"
    replacement: "agency/tools/"
  - pattern: "claude/hooks/"
    replacement: "agency/hooks/"
EOF
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

commit_base() {
    echo "$1" > "$2"
    git add "$2"; git commit -q -m seed
    BASE="$(git rev-parse HEAD)"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "--version prints version" {
    run "$TOOL" --version
    [ "$status" -eq 0 ]
}

@test "requires --manifest and --branch" {
    run "$TOOL"
    [ "$status" -eq 2 ]
}

@test "manifest-authorized single substitution passes" {
    commit_base "claude/tools/foo" a.md
    git checkout -q -b work
    echo "agency/tools/foo" > a.md
    git commit -q -am "sub"
    run "$TOOL" --manifest manifest.yaml --branch work --base "$BASE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"OK"* ]]
}

@test "multi-substitution on same line passes" {
    commit_base "claude/tools/a claude/hooks/b" a.md
    git checkout -q -b work
    echo "agency/tools/a agency/hooks/b" > a.md
    git commit -q -am "sub"
    run "$TOOL" --manifest manifest.yaml --branch work --base "$BASE"
    [ "$status" -eq 0 ]
}

@test "same-length non-sub corruption rejects" {
    commit_base "claude/tools/foo" a.md
    git checkout -q -b work
    # Change the path to something same-length but not a manifest substitution
    echo "xxxxxx/tools/foo" > a.md
    git commit -q -am "corrupt"
    run "$TOOL" --manifest manifest.yaml --branch work --base "$BASE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"REJECT"* ]]
}

@test "whitespace-only drift rejects" {
    commit_base "claude/tools/foo" a.md
    git checkout -q -b work
    printf 'claude/tools/foo  \n' > a.md  # trailing spaces
    git commit -q -am "ws-drift"
    run "$TOOL" --manifest manifest.yaml --branch work --base "$BASE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"whitespace-only"* ]]
}

@test "non-substitution free-text rejects" {
    commit_base "hello world" a.md
    git checkout -q -b work
    echo "goodbye world" > a.md
    git commit -q -am "free-text"
    run "$TOOL" --manifest manifest.yaml --branch work --base "$BASE"
    [ "$status" -eq 1 ]
}

@test "binary-file change rejects" {
    printf '\x00\x01claude/tools/\x02' > bin.dat
    git add bin.dat; git commit -q -m "seed"
    BASE="$(git rev-parse HEAD)"
    git checkout -q -b work
    printf '\x00\x01agency/tools/\x02' > bin.dat
    git commit -q -am "binary sub"
    run "$TOOL" --manifest manifest.yaml --branch work --base "$BASE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"binary"* ]]
}

@test "test fixture path is exempt (ignored)" {
    mkdir -p test/test-agency-project
    echo "claude/tools/x" > test/test-agency-project/file.md
    git add .; git commit -q -m "seed"
    BASE="$(git rev-parse HEAD)"
    git checkout -q -b work
    echo "LITERALLY-DIFFERENT" > test/test-agency-project/file.md
    git commit -q -am "fixture edit"
    run "$TOOL" --manifest manifest.yaml --branch work --base "$BASE"
    # Fixture files are ignored — pass even for non-sub content
    [ "$status" -eq 0 ]
}

@test "empty diff (no changes) passes" {
    commit_base "stuff" a.md
    git checkout -q -b work
    run "$TOOL" --manifest manifest.yaml --branch work --base HEAD
    [ "$status" -eq 0 ]
}
