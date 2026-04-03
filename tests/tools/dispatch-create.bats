#!/usr/bin/env bats
#
# Tests for tools/dispatch-create
#
# Tests dispatch creation with fully qualified addresses,
# frontmatter format, validation, and slug generation.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Help and basic invocation
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch-create: --help shows usage" {
    run "${TOOLS_DIR}/dispatch-create" --help
    assert_success
    assert_output_contains "--to"
    assert_output_contains "--subject"
}

@test "dispatch-create: fails without --to" {
    run "${TOOLS_DIR}/dispatch-create" --subject "test"
    assert_failure
    assert_output_contains "--to"
}

@test "dispatch-create: fails without --subject" {
    run "${TOOLS_DIR}/dispatch-create" --to "jordan/captain"
    assert_failure
    assert_output_contains "--subject"
}

# ─────────────────────────────────────────────────────────────────────────────
# Dispatch creation
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch-create: creates file with correct frontmatter" {
    run "${TOOLS_DIR}/dispatch-create" --to "monofolk/jordan/captain" --subject "Test dispatch"
    assert_success
    assert_output_contains "Created:"
    assert_output_contains "dispatch-test-dispatch-"

    # Extract filepath from output
    local filepath
    filepath=$(echo "$output" | grep "Created:" | sed 's/Created: //')

    # Check frontmatter fields
    assert_file_contains "$filepath" "status: created"
    assert_file_contains "$filepath" "created_by:"
    assert_file_contains "$filepath" "to: monofolk/jordan/captain"
    assert_file_contains "$filepath" "priority: normal"
    assert_file_contains "$filepath" 'subject: "Test dispatch"'
    assert_file_contains "$filepath" "in_reply_to: null"

    # Clean up
    rm -f "$filepath"
}

@test "dispatch-create: created_by is fully qualified" {
    run "${TOOLS_DIR}/dispatch-create" --to "jordan/captain" --subject "FQ test"
    assert_success

    local filepath
    filepath=$(echo "$output" | grep "Created:" | sed 's/Created: //')

    # created_by should have repo/principal/agent format (3 segments with /)
    local created_by
    created_by=$(grep "created_by:" "$filepath" | sed 's/created_by: //')
    local slash_count
    slash_count=$(echo "$created_by" | tr -cd '/' | wc -c | tr -d ' ')
    [[ "$slash_count" -eq 2 ]]

    rm -f "$filepath"
}

@test "dispatch-create: --priority high sets priority" {
    run "${TOOLS_DIR}/dispatch-create" --to "jordan/captain" --subject "Urgent" --priority high
    assert_success

    local filepath
    filepath=$(echo "$output" | grep "Created:" | sed 's/Created: //')
    assert_file_contains "$filepath" "priority: high"

    rm -f "$filepath"
}

@test "dispatch-create: --reply-to sets in_reply_to" {
    run "${TOOLS_DIR}/dispatch-create" --to "jordan/captain" --subject "Reply" --reply-to "dispatch-original-20260401-1200.md"
    assert_success

    local filepath
    filepath=$(echo "$output" | grep "Created:" | sed 's/Created: //')
    assert_file_contains "$filepath" "in_reply_to: dispatch-original-20260401-1200.md"

    rm -f "$filepath"
}

@test "dispatch-create: slug generated from subject" {
    run "${TOOLS_DIR}/dispatch-create" --to "jordan/captain" --subject "Code Review Findings for Phase 2"
    assert_success
    assert_output_contains "dispatch-code-review-findings-for-phase-2-"

    local filepath
    filepath=$(echo "$output" | grep "Created:" | sed 's/Created: //')
    rm -f "$filepath"
}

# ─────────────────────────────────────────────────────────────────────────────
# Address validation
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch-create: rejects invalid --to address" {
    run "${TOOLS_DIR}/dispatch-create" --to "" --subject "Bad"
    assert_failure
}

@test "dispatch-create: rejects invalid --priority" {
    run "${TOOLS_DIR}/dispatch-create" --to "jordan/captain" --subject "Bad" --priority critical
    assert_failure
    assert_output_contains "normal, high, or low"
}

@test "dispatch-create: output shows From and To" {
    run "${TOOLS_DIR}/dispatch-create" --to "monofolk/peter/devex" --subject "Cross-repo"
    assert_success
    assert_output_contains "From:"
    assert_output_contains "To:"
    assert_output_contains "monofolk/peter/devex"

    local filepath
    filepath=$(echo "$output" | grep "Created:" | sed 's/Created: //')
    rm -f "$filepath"
}
