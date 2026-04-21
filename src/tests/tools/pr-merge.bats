#!/usr/bin/env bats
#
# pr-merge tests — discipline enforcement for safe PR merging
#
# These tests verify the safety guarantees of pr-merge WITHOUT actually
# calling GitHub. We assert on input validation, flag rejection, and help
# output. End-to-end PR creation/merge is NOT covered here (would require
# live GitHub state); covered by acceptance via use on the D41-R13 PR
# itself ("dog-food" per principal directive).
#

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
TOOL="${REPO_ROOT}/agency/tools/pr-merge"

@test "pr-merge: --help works" {
    run bash "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"pr-merge — Safe merge"* ]]
    [[ "$output" == *"--principal-approved"* ]]
    [[ "$output" == *"Never --squash"* ]]
}

@test "pr-merge: --version prints version" {
    run bash "$TOOL" --version
    [ "$status" -eq 0 ]
    [[ "$output" == pr-merge\ * ]]
}

@test "pr-merge: rejects --squash explicitly" {
    run bash "$TOOL" 42 --squash
    [ "$status" -ne 0 ]
    [[ "$output" == *"BANNED"* ]]
    [[ "$output" == *"squash"* ]]
}

@test "pr-merge: rejects --rebase explicitly" {
    run bash "$TOOL" 42 --rebase
    [ "$status" -ne 0 ]
    [[ "$output" == *"BANNED"* ]]
    [[ "$output" == *"rebase"* ]]
}

@test "pr-merge: rejects raw --admin (must use --principal-approved)" {
    run bash "$TOOL" 42 --admin
    [ "$status" -ne 0 ]
    [[ "$output" == *"--admin is not allowed directly"* ]]
    [[ "$output" == *"--principal-approved"* ]]
}

@test "pr-merge: rejects unknown flag" {
    run bash "$TOOL" 42 --not-a-flag
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown flag"* ]]
}

@test "pr-merge: missing pr-number errors" {
    run bash "$TOOL"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Missing"* ]]
}

@test "pr-merge: non-integer pr-number rejected" {
    run bash "$TOOL" not-a-number
    [ "$status" -ne 0 ]
    [[ "$output" == *"integer"* ]]
}

@test "pr-merge: rejects multiple positional args" {
    run bash "$TOOL" 42 99
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unexpected positional arg"* ]]
}

# C#372 Fix A — post-merge advisory + auto-flag emission.
# Live gh behavior can't be tested here, so we assert on presence + shape of
# the advisory code path. If someone removes the advisory, this fails.

@test "pr-merge: C#372 Fix A advisory block present in tool source" {
    # The advisory block identifies itself via the comment marker.
    run grep -q "C#372 FIX A — POST-MERGE ADVISORY" "$TOOL"
    [ "$status" -eq 0 ]
}

@test "pr-merge: C#372 Fix A queries baseRefName (needed to gate advisory)" {
    # baseRefName must be in the --json list or the advisory can't fire
    # correctly (would fire on every merge, including to non-main branches).
    run grep -q "baseRefName" "$TOOL"
    [ "$status" -eq 0 ]
}

@test "pr-merge: C#372 Fix A gates advisory on main/master base ref" {
    # The advisory block must guard on main/master base ref.
    run grep -q 'PR_BASE_REF" == "main" || "$PR_BASE_REF" == "master"' "$TOOL"
    [ "$status" -eq 0 ]
}

@test "pr-merge: --help mentions C#372 post-merge advisory" {
    run bash "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"C#372"* ]] || [[ "$output" == *"/pr-captain-post-merge"* ]]
}

@test "pr-merge: --version bumped for Fix A (1.1.0+)" {
    run bash "$TOOL" --version
    [ "$status" -eq 0 ]
    # Version string like "pr-merge 1.1.0-20260421-c372-fix-a"
    [[ "$output" == *"1.1.0"* ]] || [[ "$output" == *"c372"* ]]
}
