#!/usr/bin/env bats
#
# diff-hash tests
#

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
DIFF_HASH="${REPO_ROOT}/claude/tools/diff-hash"

@test "diff-hash: produces 7-char hash" {
    run bash "$DIFF_HASH"
    [ "$status" -eq 0 ]
    [[ "${#output}" -eq 7 ]]
    [[ "$output" =~ ^[a-f0-9]{7}$ ]]
}

@test "diff-hash: --json produces valid JSON" {
    run bash "$DIFF_HASH" --json
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '"hash"'
    echo "$output" | grep -q '"full_hash"'
    echo "$output" | grep -q '"mode":"diff"'
}

@test "diff-hash: --file hashes a single file" {
    local tmp
    tmp=$(mktemp)
    echo "test content" > "$tmp"
    run bash "$DIFF_HASH" --file "$tmp"
    [ "$status" -eq 0 ]
    [[ "${#output}" -eq 7 ]]
    rm "$tmp"
}

@test "diff-hash: --file on missing file fails" {
    run bash "$DIFF_HASH" --file /nonexistent/path
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "diff-hash: --file --json produces file mode" {
    local tmp
    tmp=$(mktemp)
    echo "test" > "$tmp"
    run bash "$DIFF_HASH" --file "$tmp" --json
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '"mode":"file"'
    rm "$tmp"
}

@test "diff-hash: same input produces same hash" {
    local hash1 hash2
    hash1=$(bash "$DIFF_HASH")
    hash2=$(bash "$DIFF_HASH")
    [ "$hash1" = "$hash2" ]
}

@test "diff-hash: --help shows usage" {
    run bash "$DIFF_HASH" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}
