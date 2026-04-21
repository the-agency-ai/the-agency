#!/usr/bin/env bats
#
# diff-hash tests — ISOLATED (D42 test-isolation fix, dispatch #476)
#
# All diff-mode tests run in an isolated temp git repo with a known diff
# against a local 'main' branch. No dependency on origin/main in the live repo.
#

load 'test_helper'

DIFF_HASH="${REPO_ROOT}/agency/tools/diff-hash"

setup() {
    test_isolation_setup

    # Build an isolated git repo with a known diff for diff-mode tests.
    export TEST_REPO="${BATS_TEST_TMPDIR}/diff-hash-repo"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init --quiet --initial-branch=main 2>/dev/null || git init --quiet
    git config user.email "test@test.com"
    git config user.name "Test"
    git config commit.gpgsign false

    # Initial commit on main — the "base" state.
    echo "base content" > file.txt
    git add file.txt
    git commit -m "initial" --quiet --no-verify

    # Create a feature branch with a known change — this is the diff we hash.
    git checkout -b feature --quiet
    echo "changed content" > file.txt
    git add file.txt
    git commit -m "change" --quiet --no-verify
}

teardown() {
    test_isolation_teardown
}

# ─────────────────────────────────────────────────────────────────────────────
# Diff mode (isolated repo)
# ─────────────────────────────────────────────────────────────────────────────

@test "diff-hash: produces 7-char hash (isolated)" {
    cd "$TEST_REPO"
    run bash "$DIFF_HASH" --base main
    [ "$status" -eq 0 ]
    [[ "${#output}" -eq 7 ]]
    [[ "$output" =~ ^[a-f0-9]{7}$ ]]
}

@test "diff-hash: --json produces valid JSON (isolated)" {
    cd "$TEST_REPO"
    run bash "$DIFF_HASH" --base main --json
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '"hash"'
    echo "$output" | grep -q '"full_hash"'
    echo "$output" | grep -q '"mode":"diff"'
}

@test "diff-hash: same input produces same hash (isolated)" {
    cd "$TEST_REPO"
    local hash1 hash2
    hash1=$(bash "$DIFF_HASH" --base main)
    hash2=$(bash "$DIFF_HASH" --base main)
    [ "$hash1" = "$hash2" ]
}

@test "diff-hash: different content produces different hash (isolated)" {
    cd "$TEST_REPO"
    local hash1
    hash1=$(bash "$DIFF_HASH" --base main)
    echo "more changes" >> file.txt
    git add file.txt
    git commit -m "more" --quiet --no-verify
    local hash2
    hash2=$(bash "$DIFF_HASH" --base main)
    [ "$hash1" != "$hash2" ]
}

@test "diff-hash: no diff returns error (isolated)" {
    cd "$TEST_REPO"
    # On main, diffing against itself should produce no diff
    git checkout main --quiet
    run bash "$DIFF_HASH" --base main
    [ "$status" -ne 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# File mode (already isolated — uses tmpfiles)
# ─────────────────────────────────────────────────────────────────────────────

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

@test "diff-hash: --help shows usage" {
    run bash "$DIFF_HASH" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}
