#!/usr/bin/env bats
#
# Tests for claude/tools/worktree-create
#
# Focus: the --workstream/--agent collapse rule (dispatch #166, resolved in
# #169). These tests use --compute-only mode so no real worktrees are created.
#
# The full end-to-end worktree creation path (git worktree add, dependency
# install, branch management) is not tested here — those operations are
# integration-tested by actually using the tool during real worktree-create
# workflows. This file verifies the NAMING CONTRACT only.
#
# Written: 2026-04-09 — dispatch #166/#169, task #9

load test_helper

setup() {
    test_isolation_setup
    export TOOL="${REPO_ROOT}/claude/tools/worktree-create"
}

teardown() {
    test_isolation_teardown
}

# ─────────────────────────────────────────────────────────────────────────────
# Collapse rule — canonical cases from dispatch #169
# ─────────────────────────────────────────────────────────────────────────────

@test "collapse: devex + devex → devex (exact match)" {
    run "$TOOL" --compute-only --workstream devex --agent devex
    [ "$status" -eq 0 ]
    [ "$output" = "devex" ]
}

@test "collapse: iscp + iscp → iscp (exact match)" {
    run "$TOOL" --compute-only --workstream iscp --agent iscp
    [ "$status" -eq 0 ]
    [ "$output" = "iscp" ]
}

@test "collapse: mdpal + mdpal-app → mdpal-app (prefix match)" {
    run "$TOOL" --compute-only --workstream mdpal --agent mdpal-app
    [ "$status" -eq 0 ]
    [ "$output" = "mdpal-app" ]
}

@test "collapse: mdpal + mdpal-cli → mdpal-cli (prefix match)" {
    run "$TOOL" --compute-only --workstream mdpal --agent mdpal-cli
    [ "$status" -eq 0 ]
    [ "$output" = "mdpal-cli" ]
}

@test "no collapse: agency + captain → agency-captain" {
    run "$TOOL" --compute-only --workstream agency --agent captain
    [ "$status" -eq 0 ]
    [ "$output" = "agency-captain" ]
}

@test "no collapse: fleet + captain → fleet-captain" {
    run "$TOOL" --compute-only --workstream fleet --agent captain
    [ "$status" -eq 0 ]
    [ "$output" = "fleet-captain" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Edge cases
# ─────────────────────────────────────────────────────────────────────────────

@test "edge: agent that contains workstream but doesn't start with it → no collapse" {
    # e.g., workstream=api, agent=rest-api → 'rest-api' does NOT start with 'api-'
    run "$TOOL" --compute-only --workstream api --agent rest-api
    [ "$status" -eq 0 ]
    [ "$output" = "api-rest-api" ]
}

@test "edge: hyphenated workstream, matching agent → collapse" {
    # e.g., workstream=mock-and-mark, agent=mock-and-mark → exact match
    run "$TOOL" --compute-only --workstream mock-and-mark --agent mock-and-mark
    [ "$status" -eq 0 ]
    [ "$output" = "mock-and-mark" ]
}

@test "edge: hyphenated workstream with prefixed agent → collapse" {
    # e.g., workstream=mock-and-mark, agent=mock-and-mark-ios → prefix match
    run "$TOOL" --compute-only --workstream mock-and-mark --agent mock-and-mark-ios
    [ "$status" -eq 0 ]
    [ "$output" = "mock-and-mark-ios" ]
}

@test "edge: agent named like workstream but without hyphen → no collapse" {
    # e.g., workstream=test, agent=tester → 'tester' does NOT start with 'test-'
    # (it starts with 'test' but the rule requires 'test-' specifically)
    run "$TOOL" --compute-only --workstream test --agent tester
    [ "$status" -eq 0 ]
    [ "$output" = "test-tester" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Missing / invalid input
# ─────────────────────────────────────────────────────────────────────────────

@test "invalid: --workstream without --agent fails" {
    run "$TOOL" --compute-only --workstream devex
    [ "$status" -ne 0 ]
}

@test "invalid: --agent without --workstream fails" {
    run "$TOOL" --compute-only --agent devex
    [ "$status" -ne 0 ]
}

@test "invalid: empty workstream fails" {
    run "$TOOL" --compute-only --workstream "" --agent devex
    [ "$status" -ne 0 ]
}

@test "invalid: empty agent fails" {
    run "$TOOL" --compute-only --workstream devex --agent ""
    [ "$status" -ne 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Backward compat: positional name still works
# ─────────────────────────────────────────────────────────────────────────────

@test "positional mode: shows error when no name given" {
    run "$TOOL"
    [ "$status" -ne 0 ]
    [[ "$output" == *"name is required"* ]]
}

@test "positional mode: --help still works" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--workstream"* ]]
    [[ "$output" == *"--agent"* ]]
}

@test "positional mode: --version shows new version" {
    run "$TOOL" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"2.1"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Help text includes the naming rule
# ─────────────────────────────────────────────────────────────────────────────

@test "help: includes collapse rule description" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"collapse"* ]] || [[ "$output" == *"Naming rule"* ]]
}

@test "help: includes example with --workstream" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--workstream"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Mixing modes is an error
# ─────────────────────────────────────────────────────────────────────────────

@test "invalid: positional + --workstream + --agent is ambiguous" {
    run "$TOOL" someName --workstream devex --agent devex
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot mix"* ]] || [[ "$output" == *"ambiguous"* ]]
}
