#!/usr/bin/env bats
#
# Tests for tools/_log-helper
#
# Run with: bats tests/tools/log-helper.bats
#

load 'test_helper'

setup() {
    # Source the log helper
    source "${TOOLS_DIR}/_log-helper"

    # Disable actual logging
    export LOG_SERVICE_URL=""
}

# ─────────────────────────────────────────────────────────────
# _json_escape tests
# ─────────────────────────────────────────────────────────────

@test "_json_escape: escapes double quotes" {
    result=$(_json_escape 'hello "world"')
    [[ "$result" == 'hello \"world\"' ]]
}

@test "_json_escape: escapes backslashes" {
    result=$(_json_escape 'path\to\file')
    [[ "$result" == 'path\\to\\file' ]]
}

@test "_json_escape: escapes newlines" {
    result=$(_json_escape $'line1\nline2')
    [[ "$result" == 'line1\nline2' ]]
}

@test "_json_escape: escapes tabs" {
    result=$(_json_escape $'col1\tcol2')
    [[ "$result" == 'col1\tcol2' ]]
}

@test "_json_escape: handles empty string" {
    result=$(_json_escape '')
    [[ "$result" == '' ]]
}

@test "_json_escape: handles special characters together" {
    result=$(_json_escape $'say "hello"\npath\\to\\file')
    [[ "$result" == 'say \"hello\"\npath\\to\\file' ]]
}

# ─────────────────────────────────────────────────────────────
# _log_enabled tests
# ─────────────────────────────────────────────────────────────

@test "_log_enabled: returns false when LOG_SERVICE_URL is empty" {
    export LOG_SERVICE_URL=""
    run _log_enabled
    assert_failure
}

@test "_log_enabled: returns true when LOG_SERVICE_URL is set" {
    export LOG_SERVICE_URL="http://localhost:3141"
    run _log_enabled
    assert_success
}

# ─────────────────────────────────────────────────────────────
# log_start tests (with logging disabled)
# ─────────────────────────────────────────────────────────────

@test "log_start: returns empty when logging disabled" {
    export LOG_SERVICE_URL=""
    result=$(log_start "test-tool" "agency-tool" "arg1" "arg2")
    [[ -z "$result" ]]
}

@test "log_start: accepts tool name and type" {
    export LOG_SERVICE_URL=""
    # Should not error even with args
    run log_start "my-tool" "bash" "arg1" "arg2" "arg3"
    assert_success
}

# ─────────────────────────────────────────────────────────────
# log_end tests (with logging disabled)
# ─────────────────────────────────────────────────────────────

@test "log_end: handles empty run_id gracefully" {
    export LOG_SERVICE_URL=""
    run log_end "" "success" "0" "100" "summary"
    assert_success
}

@test "log_end: accepts all parameters" {
    export LOG_SERVICE_URL=""
    run log_end "abc123" "success" "0" "100" "summary" "output content"
    assert_success
}

@test "log_end: normalizes invalid status to failure" {
    export LOG_SERVICE_URL=""
    # Should handle invalid status without error
    run log_end "abc123" "invalid" "0" "0" ""
    assert_success
}

# ─────────────────────────────────────────────────────────────
# log_wrap tests
# ─────────────────────────────────────────────────────────────

@test "log_wrap: runs command and returns exit code" {
    export LOG_SERVICE_URL=""
    run log_wrap "test" "bash" true
    assert_success
}

@test "log_wrap: propagates failure exit code" {
    export LOG_SERVICE_URL=""
    run log_wrap "test" "bash" false
    assert_failure
}

@test "log_wrap: passes arguments to command" {
    export LOG_SERVICE_URL=""
    run log_wrap "test" "bash" echo "hello world"
    assert_success
    assert_output_contains "hello world"
}
