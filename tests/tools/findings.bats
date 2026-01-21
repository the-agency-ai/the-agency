#!/usr/bin/env bats
#
# Tests for findings capture tools
#
# Tests ./tools/findings-save and ./tools/findings-consolidate
#

load 'test_helper'

# ============================================================================
# FINDINGS-SAVE TESTS
# ============================================================================

@test "findings-save: shows help with --help" {
    run_tool findings-save --help
    assert_success
    [[ "$output" =~ "Usage:" ]]
}

@test "findings-save: fails without arguments" {
    run "${TOOLS_DIR}/findings-save"
    assert_failure
    [[ "$output" =~ "Usage" ]]
}

@test "findings-save: fails with invalid stage" {
    run bash -c "echo '{}' | '${TOOLS_DIR}/findings-save' TEST-test-0001 deploy code"
    assert_failure
    [[ "$output" =~ "Invalid stage" ]]
}

@test "findings-save: fails with invalid review type" {
    run bash -c "echo '{}' | '${TOOLS_DIR}/findings-save' TEST-test-0001 impl performance"
    assert_failure
    [[ "$output" =~ "Invalid review type" ]]
}

@test "findings-save: fails with invalid JSON" {
    run bash -c "echo 'not json' | '${TOOLS_DIR}/findings-save' TEST-test-0001 impl code"
    assert_failure
    [[ "$output" =~ "Invalid JSON" ]]
}

@test "findings-save: fails with empty stdin" {
    run bash -c "echo -n '' | '${TOOLS_DIR}/findings-save' TEST-test-0001 impl code"
    assert_failure
    [[ "$output" =~ "Empty input" ]]
}

@test "findings-save: rejects path traversal in work item" {
    run bash -c "echo '{}' | '${TOOLS_DIR}/findings-save' '../etc/passwd' impl code"
    assert_failure
    [[ "$output" =~ "Invalid work item" ]]
}

@test "findings-save: rejects invalid work item format" {
    run bash -c "echo '{}' | '${TOOLS_DIR}/findings-save' 'invalid' impl code"
    assert_failure
    [[ "$output" =~ "Invalid work item format" ]]
}

@test "findings-save: dry-run shows output path" {
    cat > "${BATS_TEST_TMPDIR}/finding.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "TEST-test-0001",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "test123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF
    run bash -c "cat '${BATS_TEST_TMPDIR}/finding.json' | '${TOOLS_DIR}/findings-save' TEST-test-0001 impl code --dry-run"
    assert_success
    [[ "$output" =~ "Would save to:" ]]
    [[ "$output" =~ "code-review-1.json" ]]
}

@test "findings-save: validates against schema" {
    # Missing required field
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "1.0",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "test123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF
    run bash -c "cat '${BATS_TEST_TMPDIR}/invalid.json' | '${TOOLS_DIR}/findings-save' TEST-test-0001 impl code"
    assert_failure
    [[ "$output" =~ "validation" ]] || [[ "$output" =~ "required" ]] || [[ "$output" =~ "work_item" ]]
}

@test "findings-save: --no-validate skips schema validation" {
    # Missing required field but skip validation
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "1.0",
  "stage": "impl"
}
EOF
    run bash -c "cat '${BATS_TEST_TMPDIR}/invalid.json' | '${TOOLS_DIR}/findings-save' TEST-test-0001 impl code --dry-run --no-validate"
    assert_success
    [[ "$output" =~ "dry-run" ]]
}

@test "findings-save: creates output directory" {
    cat > "${BATS_TEST_TMPDIR}/finding.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "TEST-new-0001",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "test123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF

    # Create temp reviews directory
    TEST_REVIEWS="${BATS_TEST_TMPDIR}/reviews"
    mkdir -p "$TEST_REVIEWS"

    # Override REVIEWS_DIR for this test but keep SCHEMAS_DIR pointing to original
    TOOL_SCRIPT="${BATS_TEST_TMPDIR}/findings-save-test"
    sed -e "s|REVIEWS_DIR=.*|REVIEWS_DIR=\"$TEST_REVIEWS\"|" \
        -e "s|SCHEMAS_DIR=.*|SCHEMAS_DIR=\"${REPO_ROOT}/claude/schemas\"|" \
        "${TOOLS_DIR}/findings-save" > "$TOOL_SCRIPT"
    chmod +x "$TOOL_SCRIPT"

    run bash -c "cat '${BATS_TEST_TMPDIR}/finding.json' | '$TOOL_SCRIPT' TEST-new-0001 impl code"
    assert_success
    [[ -f "$TEST_REVIEWS/TEST-new-0001/code-review-1.json" ]]
}

@test "findings-save: auto-increments file number" {
    TEST_REVIEWS="${BATS_TEST_TMPDIR}/reviews"
    mkdir -p "$TEST_REVIEWS/TEST-incr-0001"
    echo '{}' > "$TEST_REVIEWS/TEST-incr-0001/code-review-1.json"

    cat > "${BATS_TEST_TMPDIR}/finding.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "TEST-incr-0001",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "test123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF

    TOOL_SCRIPT="${BATS_TEST_TMPDIR}/findings-save-test"
    sed -e "s|REVIEWS_DIR=.*|REVIEWS_DIR=\"$TEST_REVIEWS\"|" \
        -e "s|SCHEMAS_DIR=.*|SCHEMAS_DIR=\"${REPO_ROOT}/claude/schemas\"|" \
        "${TOOLS_DIR}/findings-save" > "$TOOL_SCRIPT"
    chmod +x "$TOOL_SCRIPT"

    run bash -c "cat '${BATS_TEST_TMPDIR}/finding.json' | '$TOOL_SCRIPT' TEST-incr-0001 impl code --dry-run"
    assert_success
    [[ "$output" =~ "code-review-2.json" ]]
}

# ============================================================================
# FINDINGS-CONSOLIDATE TESTS
# ============================================================================

@test "findings-consolidate: shows help with --help" {
    run_tool findings-consolidate --help
    assert_success
    [[ "$output" =~ "Usage:" ]]
}

@test "findings-consolidate: fails without arguments" {
    run "${TOOLS_DIR}/findings-consolidate"
    assert_failure
    [[ "$output" =~ "Usage" ]]
}

@test "findings-consolidate: fails with invalid stage" {
    run_tool findings-consolidate TEST-test-0001 deploy
    assert_failure
    [[ "$output" =~ "Invalid stage" ]]
}

@test "findings-consolidate: rejects path traversal in work item" {
    run_tool findings-consolidate '../etc/passwd' impl --list
    assert_failure
    [[ "$output" =~ "Invalid work item" ]]
}

@test "findings-consolidate: rejects invalid work item format" {
    run_tool findings-consolidate 'invalid' impl --list
    assert_failure
    [[ "$output" =~ "Invalid work item format" ]]
}

@test "findings-consolidate: --list shows review files" {
    run_tool findings-consolidate REQUEST-jordan-0072 impl --list
    assert_success
    [[ "$output" =~ "code-review-1.json" ]]
    [[ "$output" =~ "security-review-1.json" ]]
}

@test "findings-consolidate: fails when no reviews directory" {
    run_tool findings-consolidate NONEXISTENT-test-0001 impl --list
    assert_failure
    [[ "$output" =~ "No reviews found" ]]
}

@test "findings-consolidate: requires stdin input (no --list)" {
    # Run with /dev/null as stdin to simulate no input
    run bash -c "'${TOOLS_DIR}/findings-consolidate' REQUEST-jordan-0072 impl < /dev/null"
    assert_failure
    [[ "$output" =~ "No input" ]] || [[ "$output" =~ "stdin" ]] || [[ "$output" =~ "Invalid JSON" ]]
}

@test "findings-consolidate: validates against schema" {
    # Missing required stats field
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0072",
  "stage": "impl",
  "consolidated_by": "captain",
  "timestamp": "2026-01-20T10:00:00Z",
  "source_reviews": ["code-review-1.json"],
  "findings": []
}
EOF
    run bash -c "cat '${BATS_TEST_TMPDIR}/invalid.json' | '${TOOLS_DIR}/findings-consolidate' REQUEST-jordan-0072 impl"
    assert_failure
    [[ "$output" =~ "validation" ]] || [[ "$output" =~ "stats" ]] || [[ "$output" =~ "required" ]]
}

@test "findings-consolidate: dry-run shows output path" {
    cat > "${BATS_TEST_TMPDIR}/consolidated.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0072",
  "stage": "impl",
  "consolidated_by": "captain",
  "timestamp": "2026-01-20T10:00:00Z",
  "source_reviews": ["code-review-1.json"],
  "findings": [],
  "stats": { "total_findings": 0, "valid": 0, "invalid": 0, "duplicate": 0 }
}
EOF
    run bash -c "cat '${BATS_TEST_TMPDIR}/consolidated.json' | '${TOOLS_DIR}/findings-consolidate' REQUEST-jordan-0072 impl --dry-run"
    assert_success
    [[ "$output" =~ "Would save to:" ]]
    [[ "$output" =~ "consolidated.json" ]]
}

# ============================================================================
# INTEGRATION TESTS (added from test review)
# ============================================================================

@test "findings-save: writes file and preserves content" {
    # Create test finding with actual content
    cat > "${BATS_TEST_TMPDIR}/finding.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "TEST-integration-0001",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "test-reviewer-abc" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": [
    {
      "id": "F001",
      "severity": "medium",
      "category": "quality",
      "file": "src/test.ts",
      "line_start": 42,
      "line_end": 45,
      "issue": "Missing error handling",
      "recommendation": "Add try-catch block"
    }
  ]
}
EOF

    # Create temp reviews directory with overridden paths
    TEST_REVIEWS="${BATS_TEST_TMPDIR}/reviews"
    mkdir -p "$TEST_REVIEWS"

    TOOL_SCRIPT="${BATS_TEST_TMPDIR}/findings-save-test"
    sed -e "s|REVIEWS_DIR=.*|REVIEWS_DIR=\"$TEST_REVIEWS\"|" \
        -e "s|SCHEMAS_DIR=.*|SCHEMAS_DIR=\"${REPO_ROOT}/claude/schemas\"|" \
        "${TOOLS_DIR}/findings-save" > "$TOOL_SCRIPT"
    chmod +x "$TOOL_SCRIPT"

    # Run the tool to actually write
    run bash -c "cat '${BATS_TEST_TMPDIR}/finding.json' | '$TOOL_SCRIPT' TEST-integration-0001 impl code"
    assert_success

    # Verify file exists
    OUTPUT_FILE="$TEST_REVIEWS/TEST-integration-0001/code-review-1.json"
    [[ -f "$OUTPUT_FILE" ]]

    # Verify content is preserved (check for key data)
    [[ "$(cat "$OUTPUT_FILE")" =~ "test-reviewer-abc" ]]
    [[ "$(cat "$OUTPUT_FILE")" =~ "Missing error handling" ]]
    [[ "$(cat "$OUTPUT_FILE")" =~ "line_start" ]]
}

@test "findings-save: creates separate files for different review types" {
    TEST_REVIEWS="${BATS_TEST_TMPDIR}/reviews"
    mkdir -p "$TEST_REVIEWS"

    TOOL_SCRIPT="${BATS_TEST_TMPDIR}/findings-save-test"
    sed -e "s|REVIEWS_DIR=.*|REVIEWS_DIR=\"$TEST_REVIEWS\"|" \
        -e "s|SCHEMAS_DIR=.*|SCHEMAS_DIR=\"${REPO_ROOT}/claude/schemas\"|" \
        "${TOOLS_DIR}/findings-save" > "$TOOL_SCRIPT"
    chmod +x "$TOOL_SCRIPT"

    # Save a code review
    cat > "${BATS_TEST_TMPDIR}/code.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "TEST-multi-0001",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "code-reviewer" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF
    run bash -c "cat '${BATS_TEST_TMPDIR}/code.json' | '$TOOL_SCRIPT' TEST-multi-0001 impl code"
    assert_success

    # Save a security review
    cat > "${BATS_TEST_TMPDIR}/security.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "TEST-multi-0001",
  "stage": "impl",
  "review_type": "security",
  "reviewer": { "subagent_id": "security-reviewer" },
  "timestamp": "2026-01-20T11:00:00Z",
  "findings": []
}
EOF
    run bash -c "cat '${BATS_TEST_TMPDIR}/security.json' | '$TOOL_SCRIPT' TEST-multi-0001 impl security"
    assert_success

    # Verify both files exist
    [[ -f "$TEST_REVIEWS/TEST-multi-0001/code-review-1.json" ]]
    [[ -f "$TEST_REVIEWS/TEST-multi-0001/security-review-1.json" ]]
}
