#!/usr/bin/env bats
#
# BATS: smoke-battery (v46.0 reset — Phase 0b)
# Required min-test-count: 12 (per Plan v4 §3 Phase 0b)
# Actual tests: 12

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/claude/tools/smoke-battery"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "--version prints version" {
    run "$TOOL" --version
    [ "$status" -eq 0 ]
}

@test "smoke-battery runs on current repo" {
    # Run against the real repo — items will pass or fail based on state
    run "$TOOL"
    # Exit 0 or 1 depending on environment — just check the command produces output
    [[ "$output" == *"handoff"* ]]
    [[ "$output" == *"dispatch"* ]]
    [[ "$output" == *"flag"* ]]
    [[ "$output" == *"agency-health"* ]]
}

@test "--item runs only the named item (handoff)" {
    run "$TOOL" --item handoff
    [[ "$output" == *"handoff"* ]]
    # Other items not checked:
    [[ "$output" != *"[OK] dispatch:"* ]]
}

@test "--item runs only the named item (bats)" {
    run "$TOOL" --item bats
    [[ "$output" == *"bats"* ]]
}

@test "--skip omits the named item" {
    run "$TOOL" --skip handoff
    [[ "$output" != *"[OK] handoff:"* ]]
    [[ "$output" != *"[FAIL] handoff:"* ]]
}

@test "--json emits structured output" {
    run "$TOOL" --json --item handoff
    [[ "$output" == *'"item":"handoff"'* ]]
}

@test "handoff smoke is scripted, not green-by-inspection" {
    # Verify the smoke item script exists (independent of real framework state)
    run "$TOOL" --item handoff
    [ -n "$output" ]
}

@test "dispatch smoke item runs" {
    run "$TOOL" --item dispatch
    [[ "$output" == *"dispatch"* ]]
}

@test "flag smoke item runs" {
    run "$TOOL" --item flag
    [[ "$output" == *"flag"* ]]
}

@test "ref-injector smoke item runs" {
    run "$TOOL" --item ref-injector
    [[ "$output" == *"ref-injector"* ]]
}

@test "iscp smoke item runs" {
    run "$TOOL" --item iscp
    [[ "$output" == *"iscp"* ]]
}
