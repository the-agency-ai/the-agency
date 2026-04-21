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
