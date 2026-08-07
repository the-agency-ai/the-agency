#!/usr/bin/env bats
# Fixture: mixed pass/fail. Used by test-monitor Iter 1 integration tests.

@test "case 1 passes" {
    true
}

@test "case 2 fails — with assertion message" {
    [ 1 -eq 2 ]
}

@test "case 3 passes" {
    [ "ok" = "ok" ]
}
