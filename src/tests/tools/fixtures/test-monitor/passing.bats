#!/usr/bin/env bats
# Fixture: all tests pass. Used by test-monitor Iter 1 integration tests.

@test "passing case 1" {
    true
}

@test "passing case 2" {
    [ 1 -eq 1 ]
}

@test "passing case 3 — with description" {
    [ "hello" = "hello" ]
}
