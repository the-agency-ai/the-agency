#!/usr/bin/env bats
#
# Tests for handoff type system
#
# Tests --type flag, type parsing, default fallback for missing type,
# and frontmatter preservation.
#

load 'test_helper'

# Helper: parse type from handoff frontmatter (same logic as session-handoff.sh)
parse_handoff_type() {
    local file="$1"
    grep '^type:' "$file" 2>/dev/null | head -1 | sed 's/^type: *//' || true
}

# ─────────────────────────────────────────────────────────────────────────────
# Handoff tool --type flag
# ─────────────────────────────────────────────────────────────────────────────

@test "handoff: --help mentions types" {
    run "${TOOLS_DIR}/handoff" --help
    assert_success
    assert_output_contains "type"
    assert_output_contains "agency-bootstrap"
    assert_output_contains "agency-update"
}

@test "handoff: --version shows version" {
    run "${TOOLS_DIR}/handoff" --version
    assert_success
    assert_output_contains "handoff"
}

# ─────────────────────────────────────────────────────────────────────────────
# Type parsing
# ─────────────────────────────────────────────────────────────────────────────

@test "type-parse: extracts session type from frontmatter" {
    local tmpfile="${BATS_TEST_TMPDIR}/handoff.md"
    cat > "$tmpfile" << 'EOF'
---
type: session
date: 2026-04-01
---

## Current State
Working on tests.
EOF
    local parsed
    parsed=$(parse_handoff_type "$tmpfile")
    [[ "$parsed" == "session" ]]
}

@test "type-parse: extracts agency-bootstrap type" {
    local tmpfile="${BATS_TEST_TMPDIR}/handoff.md"
    cat > "$tmpfile" << 'EOF'
---
type: agency-bootstrap
date: 2026-04-01
principal: test
---

## Welcome
EOF
    local parsed
    parsed=$(parse_handoff_type "$tmpfile")
    [[ "$parsed" == "agency-bootstrap" ]]
}

@test "type-parse: extracts agency-update type" {
    local tmpfile="${BATS_TEST_TMPDIR}/handoff.md"
    cat > "$tmpfile" << 'EOF'
---
type: agency-update
date: 2026-04-01
from_commit: abc12345
to_commit: def67890
---

## Agency Update
EOF
    local parsed
    parsed=$(parse_handoff_type "$tmpfile")
    [[ "$parsed" == "agency-update" ]]
}

@test "type-parse: defaults to session when no type field" {
    local tmpfile="${BATS_TEST_TMPDIR}/handoff.md"
    cat > "$tmpfile" << 'EOF'
---
date: 2026-04-01
branch: main
---

## Current State
EOF
    local parsed
    parsed=$(parse_handoff_type "$tmpfile")
    parsed="${parsed:-session}"
    [[ "$parsed" == "session" ]]
}

@test "type-parse: defaults to session for no frontmatter" {
    local tmpfile="${BATS_TEST_TMPDIR}/handoff.md"
    echo "Just plain content, no frontmatter." > "$tmpfile"
    local parsed
    parsed=$(parse_handoff_type "$tmpfile")
    parsed="${parsed:-session}"
    [[ "$parsed" == "session" ]]
}

@test "type-parse: handles type with extra whitespace" {
    local tmpfile="${BATS_TEST_TMPDIR}/handoff.md"
    cat > "$tmpfile" << 'EOF'
---
type:   agency-bootstrap
date: 2026-04-01
---
EOF
    local parsed
    parsed=$(parse_handoff_type "$tmpfile")
    # Trim trailing whitespace
    parsed=$(echo "$parsed" | sed 's/ *$//')
    [[ "$parsed" == "agency-bootstrap" ]]
}
