#!/usr/bin/env bats
#
# collaboration tool — path-traversal validation (D41-R5 monofolk QG fix).
# Tests the new _validate_dispatch_filename helper directly.
#

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
COLLAB="${REPO_ROOT}/claude/tools/collaboration"

setup() {
    BATS_TEST_TMPDIR="$(mktemp -d)"
    export BATS_TEST_TMPDIR
    INBOUND="$BATS_TEST_TMPDIR/dispatches/inbound"
    mkdir -p "$INBOUND"
    set +u
    source "$COLLAB" >/dev/null 2>&1 || true
    set -u
}

teardown() {
    rm -rf "$BATS_TEST_TMPDIR"
}

@test "path-traversal: accepts a normal filename" {
    run _validate_dispatch_filename "$INBOUND" "dispatch-foo-20260415.md"
    [ "$status" -eq 0 ]
    [[ "$output" == */dispatches/inbound/dispatch-foo-20260415.md ]]
}

@test "path-traversal: rejects ../ traversal" {
    run _validate_dispatch_filename "$INBOUND" "../etc/passwd"
    [ "$status" -ne 0 ]
    [[ "$output" == *"path separators"* || "$output" == *"traversal"* ]]
}

@test "path-traversal: rejects absolute path" {
    run _validate_dispatch_filename "$INBOUND" "/etc/passwd"
    [ "$status" -ne 0 ]
    [[ "$output" == *"path separators"* ]]
}

@test "path-traversal: rejects backslash" {
    run _validate_dispatch_filename "$INBOUND" 'foo\bar'
    [ "$status" -ne 0 ]
    [[ "$output" == *"path separators"* ]]
}

@test "path-traversal: rejects parent dir literal" {
    run _validate_dispatch_filename "$INBOUND" ".."
    [ "$status" -ne 0 ]
}

@test "path-traversal: rejects current dir literal" {
    run _validate_dispatch_filename "$INBOUND" "."
    [ "$status" -ne 0 ]
}

@test "path-traversal: rejects hidden file" {
    run _validate_dispatch_filename "$INBOUND" ".envrc"
    [ "$status" -ne 0 ]
}

@test "path-traversal: rejects shell metacharacters" {
    run _validate_dispatch_filename "$INBOUND" 'foo;rm.md'
    [ "$status" -ne 0 ]
    [[ "$output" == *"disallowed"* ]]
}

@test "path-traversal: rejects spaces" {
    run _validate_dispatch_filename "$INBOUND" 'foo bar.md'
    [ "$status" -ne 0 ]
    [[ "$output" == *"disallowed"* ]]
}

@test "path-traversal: rejects empty filename" {
    run _validate_dispatch_filename "$INBOUND" ""
    [ "$status" -ne 0 ]
    [[ "$output" == *"empty"* ]]
}

@test "path-traversal: rejects when inbound directory missing" {
    run _validate_dispatch_filename "$BATS_TEST_TMPDIR/nonexistent" "foo.md"
    [ "$status" -ne 0 ]
}

@test "path-traversal: contains traversal sequence inside name" {
    run _validate_dispatch_filename "$INBOUND" "foo..bar"
    [ "$status" -ne 0 ]
    [[ "$output" == *"traversal"* ]]
}
