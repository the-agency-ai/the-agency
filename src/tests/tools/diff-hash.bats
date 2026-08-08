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
# Receipt-churn fix (2026-08-08): handoffs must not enter the hash, or the
# receipt /pr-prep just signed is invalidated when /pr-submit or /handoff
# commits a handoff artifact. Exclude active + archived handoffs.
# ─────────────────────────────────────────────────────────────────────────────

@test "diff-hash: active handoff does not change the code hash (isolated)" {
    cd "$TEST_REPO"
    local hash_before hash_after
    hash_before=$(bash "$DIFF_HASH" --base main)
    mkdir -p usr/jordan/captain
    echo "session notes" > usr/jordan/captain/captain-handoff.md
    git add usr/jordan/captain/captain-handoff.md
    git commit -m "handoff" --quiet --no-verify
    hash_after=$(bash "$DIFF_HASH" --base main)
    [ "$hash_before" = "$hash_after" ]
}

@test "diff-hash: archived handoff does not change the code hash (isolated)" {
    cd "$TEST_REPO"
    local hash_before hash_after
    hash_before=$(bash "$DIFF_HASH" --base main)
    mkdir -p usr/jordan/captain/history
    echo "old session" > usr/jordan/captain/history/handoff-20260808-010101.md
    git add usr/jordan/captain/history/handoff-20260808-010101.md
    git commit -m "archive handoff" --quiet --no-verify
    hash_after=$(bash "$DIFF_HASH" --base main)
    [ "$hash_before" = "$hash_after" ]
}

@test "diff-hash: a handoff-only diff is treated as no diff (isolated)" {
    cd "$TEST_REPO"
    git checkout main --quiet
    git checkout -b handoff-only --quiet
    mkdir -p usr/jordan/captain
    echo "just a handoff" > usr/jordan/captain/captain-handoff.md
    git add usr/jordan/captain/captain-handoff.md
    git commit -m "handoff only" --quiet --no-verify
    run bash "$DIFF_HASH" --base main
    [ "$status" -ne 0 ]
}

@test "diff-hash: --json file_count excludes handoffs too (FILE_COUNT path) (isolated)" {
    cd "$TEST_REPO"
    # The exclusion is applied twice — once for the hash (DIFF_OUTPUT) and again,
    # independently, for file_count. The other tests only observe the hash; this
    # one pins the file_count path so the two invocations can't silently diverge.
    # feature already changed 1 code file (file.txt); add a handoff alongside it.
    mkdir -p usr/jordan/captain
    echo "session notes" > usr/jordan/captain/captain-handoff.md
    git add usr/jordan/captain/captain-handoff.md
    git commit -m "handoff alongside code" --quiet --no-verify
    run bash "$DIFF_HASH" --base main --json
    [ "$status" -eq 0 ]
    echo "$output" | grep -q '"file_count":1'
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
