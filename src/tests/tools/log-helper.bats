#!/usr/bin/env bats
#
# Tests for agency/tools/lib/_log-helper (JSONL-based logger)
#
# Run with: bats tests/tools/log-helper.bats
#

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    # Create temp log directory
    export CLAUDE_PROJECT_DIR="${BATS_TEST_TMPDIR}"
    mkdir -p "${BATS_TEST_TMPDIR}/.claude/logs"

    # Source the log helper
    source "${TOOLS_DIR}/lib/_log-helper"
}

# ─────────────────────────────────────────────────────────────
# _uuid7 tests
# ─────────────────────────────────────────────────────────────

@test "_uuid7: generates a UUID" {
    result=$(_uuid7)
    [[ -n "$result" ]]
}

@test "_uuid7: matches UUID format (8-4-4-4-12)" {
    result=$(_uuid7)
    [[ "$result" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]
}

@test "_uuid7: generates unique IDs" {
    id1=$(_uuid7)
    id2=$(_uuid7)
    [[ "$id1" != "$id2" ]]
}

# ─────────────────────────────────────────────────────────────
# log_start tests
# ─────────────────────────────────────────────────────────────

@test "log_start: returns a run ID" {
    result=$(log_start "test-tool" "arg1" "arg2")
    [[ -n "$result" ]]
    [[ "$result" =~ ^[0-9a-f]{8}-[0-9a-f]{4} ]]
}

@test "log_start: writes start event to JSONL" {
    run_id=$(log_start "test-tool" "arg1")
    # Check the log file exists and has a start event
    last_line=$(tail -1 "${BATS_TEST_TMPDIR}/.claude/logs/tool-runs.jsonl")
    echo "$last_line" | jq -e '.event == "start"'
    echo "$last_line" | jq -e '.tool == "test-tool"'
    echo "$last_line" | jq -e ".run == \"$run_id\""
}

@test "log_start: records args" {
    run_id=$(log_start "test-tool" "--verbose" "file.txt")
    last_line=$(tail -1 "${BATS_TEST_TMPDIR}/.claude/logs/tool-runs.jsonl")
    echo "$last_line" | jq -e '.args | test("--verbose")'
}

# ─────────────────────────────────────────────────────────────
# log_end tests
# ─────────────────────────────────────────────────────────────

@test "log_end: writes end event to JSONL" {
    run_id=$(log_start "test-tool")
    log_end "$run_id" "success" "0" "100" "completed ok"
    last_line=$(tail -1 "${BATS_TEST_TMPDIR}/.claude/logs/tool-runs.jsonl")
    echo "$last_line" | jq -e '.event == "end"'
    echo "$last_line" | jq -e '.outcome == "success"'
    echo "$last_line" | jq -e ".run == \"$run_id\""
}

@test "log_end: records exit code and duration" {
    run_id=$(log_start "test-tool")
    log_end "$run_id" "failure" "1" "250" "something failed"
    last_line=$(tail -1 "${BATS_TEST_TMPDIR}/.claude/logs/tool-runs.jsonl")
    echo "$last_line" | jq -e '.exit == 1'
    echo "$last_line" | jq -e '.duration_ms == 250'
}

@test "log_end: handles empty run_id gracefully" {
    run log_end "" "success" "0" "0" "summary"
    assert_success
}

# ─────────────────────────────────────────────────────────────
# log_detail tests
# ─────────────────────────────────────────────────────────────

@test "log_detail: writes detail event to JSONL" {
    run_id=$(log_start "test-tool")
    log_detail "$run_id" "stdout" "hello world output"
    last_line=$(tail -1 "${BATS_TEST_TMPDIR}/.claude/logs/tool-runs.jsonl")
    echo "$last_line" | jq -e '.event == "detail"'
    echo "$last_line" | jq -e '.channel == "stdout"'
    echo "$last_line" | jq -e '.content | test("hello world")'
}

# ─────────────────────────────────────────────────────────────
# tool_output tests
# ─────────────────────────────────────────────────────────────

@test "tool_output: prints standard 3-line format" {
    run tool_output "my-tool" "019d1234-abcd-7000-8000-123456789abc" "done"
    assert_success
    assert_output_contains "my-tool"
    assert_output_contains "done"
    assert_output_contains "✓"
}

@test "tool_output: uses custom icon" {
    run tool_output "my-tool" "019d1234-abcd-7000-8000-123456789abc" "done" "✗"
    assert_success
    assert_output_contains "✗"
}

@test "tool_output: shows short run ID" {
    run tool_output "my-tool" "019d1234-abcd-7000-8000-123456789abc" "done"
    assert_output_contains "019d1234"
}
