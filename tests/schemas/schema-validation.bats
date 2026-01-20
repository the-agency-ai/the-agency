#!/usr/bin/env bats
#
# Schema validation tests for findings schemas
#
# Tests that example files validate against their schemas
# and that invalid files are properly rejected.
#
# Requires: pip3 install jsonschema
#

# Test helper location relative to this file
load '../tools/test_helper'

# Schemas directory
SCHEMAS_DIR="${REPO_ROOT}/claude/schemas"
EXAMPLES_DIR="${REPO_ROOT}/claude/logs/reviews/REQUEST-jordan-0072"
VALIDATOR="${REPO_ROOT}/tests/schemas/validate-schema.py"

# Skip tests if jsonschema not installed
setup() {
    if ! python3 -c "import jsonschema" 2>/dev/null; then
        skip "jsonschema not installed (pip3 install jsonschema)"
    fi
    # Create temp directory for test artifacts
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    cd "${REPO_ROOT}"
}

teardown() {
    if [[ -d "${BATS_TEST_TMPDIR:-}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ============================================================================
# VALID EXAMPLE FILES
# ============================================================================

@test "finding.schema.json: validates code-review-1.json example" {
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${EXAMPLES_DIR}/code-review-1.json"
    assert_success
}

@test "finding.schema.json: validates security-review-1.json example" {
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${EXAMPLES_DIR}/security-review-1.json"
    assert_success
}

@test "consolidated-findings.schema.json: validates consolidated.json example" {
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/consolidated-findings.schema.json" \
        "${EXAMPLES_DIR}/consolidated.json"
    assert_success
}

# ============================================================================
# REQUIRED FIELDS
# ============================================================================

@test "finding.schema.json: rejects missing schema_version" {
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "work_item": "REQUEST-jordan-0001",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "abc123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${BATS_TEST_TMPDIR}/invalid.json"
    assert_failure
    [[ "$output" =~ "schema_version" ]]
}

@test "finding.schema.json: rejects missing work_item" {
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "1.0",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "abc123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${BATS_TEST_TMPDIR}/invalid.json"
    assert_failure
    [[ "$output" =~ "work_item" ]]
}

@test "consolidated-findings.schema.json: rejects missing stats" {
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0001",
  "stage": "impl",
  "consolidated_by": "captain",
  "timestamp": "2026-01-20T10:00:00Z",
  "source_reviews": [],
  "findings": []
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/consolidated-findings.schema.json" \
        "${BATS_TEST_TMPDIR}/invalid.json"
    assert_failure
    [[ "$output" =~ "stats" ]]
}

# ============================================================================
# ENUM VALIDATION
# ============================================================================

@test "finding.schema.json: rejects invalid review_type enum" {
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0001",
  "stage": "impl",
  "review_type": "performance",
  "reviewer": { "subagent_id": "abc123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${BATS_TEST_TMPDIR}/invalid.json"
    assert_failure
}

@test "finding.schema.json: rejects invalid severity enum" {
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0001",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "abc123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": [
    {
      "id": "F001",
      "severity": "urgent",
      "category": "quality",
      "issue": "Test issue",
      "recommendation": "Test fix"
    }
  ]
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${BATS_TEST_TMPDIR}/invalid.json"
    assert_failure
}

@test "consolidated-findings.schema.json: rejects invalid status enum" {
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0001",
  "stage": "impl",
  "consolidated_by": "captain",
  "timestamp": "2026-01-20T10:00:00Z",
  "source_reviews": ["code-review-1.json"],
  "findings": [
    {
      "id": "C001",
      "source_ids": ["F001"],
      "status": "deferred",
      "severity": "medium",
      "issue": "Test issue"
    }
  ],
  "stats": { "total_findings": 1, "valid": 1, "invalid": 0, "duplicate": 0 }
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/consolidated-findings.schema.json" \
        "${BATS_TEST_TMPDIR}/invalid.json"
    assert_failure
}

# ============================================================================
# PATTERN VALIDATION
# ============================================================================

@test "finding.schema.json: accepts valid work_item pattern (REQUEST)" {
    cat > "${BATS_TEST_TMPDIR}/valid.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0066",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "abc123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${BATS_TEST_TMPDIR}/valid.json"
    assert_success
}

@test "finding.schema.json: accepts valid work_item pattern (SPRINT)" {
    cat > "${BATS_TEST_TMPDIR}/valid.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "SPRINT-web-2026w03",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "abc123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${BATS_TEST_TMPDIR}/valid.json"
    assert_success
}

@test "finding.schema.json: rejects invalid work_item pattern" {
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "request-jordan-0066",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "abc123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${BATS_TEST_TMPDIR}/invalid.json"
    assert_failure
}

@test "finding.schema.json: rejects invalid finding ID pattern" {
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0001",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "abc123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": [
    {
      "id": "C001",
      "severity": "medium",
      "category": "quality",
      "issue": "Test issue",
      "recommendation": "Test fix"
    }
  ]
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${BATS_TEST_TMPDIR}/invalid.json"
    assert_failure
}

@test "finding.schema.json: rejects invalid CWE pattern" {
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0001",
  "stage": "impl",
  "review_type": "security",
  "reviewer": { "subagent_id": "abc123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": [
    {
      "id": "F001",
      "severity": "high",
      "category": "security",
      "issue": "Test vulnerability",
      "recommendation": "Fix it",
      "cwe": "cwe-78"
    }
  ]
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${BATS_TEST_TMPDIR}/invalid.json"
    assert_failure
}

# ============================================================================
# SCHEMA VERSION VALIDATION
# ============================================================================

@test "finding.schema.json: rejects wrong schema_version" {
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "2.0",
  "work_item": "REQUEST-jordan-0001",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "abc123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${BATS_TEST_TMPDIR}/invalid.json"
    assert_failure
}

# ============================================================================
# EMPTY FINDINGS ARRAY (VALID)
# ============================================================================

@test "finding.schema.json: accepts empty findings array" {
    cat > "${BATS_TEST_TMPDIR}/valid.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0001",
  "stage": "impl",
  "review_type": "code",
  "reviewer": { "subagent_id": "abc123" },
  "timestamp": "2026-01-20T10:00:00Z",
  "findings": []
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/finding.schema.json" \
        "${BATS_TEST_TMPDIR}/valid.json"
    assert_success
}

# ============================================================================
# MINITEMS CONSTRAINT (source_ids)
# ============================================================================

@test "consolidated-findings.schema.json: rejects empty source_ids" {
    cat > "${BATS_TEST_TMPDIR}/invalid.json" << 'EOF'
{
  "schema_version": "1.0",
  "work_item": "REQUEST-jordan-0001",
  "stage": "impl",
  "consolidated_by": "captain",
  "timestamp": "2026-01-20T10:00:00Z",
  "source_reviews": ["code-review-1.json"],
  "findings": [
    {
      "id": "C001",
      "source_ids": [],
      "status": "valid",
      "severity": "medium",
      "issue": "Test issue"
    }
  ],
  "stats": { "total_findings": 1, "valid": 1, "invalid": 0, "duplicate": 0 }
}
EOF
    run python3 "$VALIDATOR" \
        "${SCHEMAS_DIR}/consolidated-findings.schema.json" \
        "${BATS_TEST_TMPDIR}/invalid.json"
    assert_failure
    [[ "$output" =~ "source_ids" ]] || [[ "$output" =~ "minItems" ]]
}
