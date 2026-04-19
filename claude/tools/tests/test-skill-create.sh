#!/bin/bash
#
# test-skill-create.sh — Tests for claude/tools/skill-create (v2-compliant
# skill bundle scaffolder + v1→v2 upgrade retrofitter).
#
# Purpose: pin regressions for bugs identified in the retroactive MAR run
# at the-agency#314/#315/#320 cluster (commits c69ea338..HEAD on monofolk
# master). Each test maps to a specific scorer-ranked finding.
#
# Run: bash claude/tools/tests/test-skill-create.sh
#
# Uses tempdirs to isolate from the real repo. Creates minimal skill and
# registry fixtures; exercises --upgrade and create paths.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOL="$TOOLS_DIR/skill-create"
UPGRADE_TOOL="$TOOLS_DIR/skill-upgrade"

PASS=0
FAIL=0
ERRORS=""
TMPBASE=""

# --- Test harness ---
assert_eq() {
    local test_name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        PASS=$((PASS + 1))
        printf "  ✓ %s\n" "$test_name"
    else
        FAIL=$((FAIL + 1))
        ERRORS="${ERRORS}\n  FAIL: ${test_name}\n    expected: ${expected}\n    actual:   ${actual}"
        printf "  ✗ %s\n" "$test_name"
    fi
}

assert_contains() {
    local test_name="$1" expected="$2" actual="$3"
    if echo "$actual" | grep -qF "$expected"; then
        PASS=$((PASS + 1))
        printf "  ✓ %s\n" "$test_name"
    else
        FAIL=$((FAIL + 1))
        ERRORS="${ERRORS}\n  FAIL: ${test_name}\n    expected to contain: ${expected}\n    actual: ${actual}"
        printf "  ✗ %s\n" "$test_name"
    fi
}

assert_file_exists() {
    local test_name="$1" path="$2"
    if [ -f "$path" ]; then
        PASS=$((PASS + 1))
        printf "  ✓ %s\n" "$test_name"
    else
        FAIL=$((FAIL + 1))
        ERRORS="${ERRORS}\n  FAIL: ${test_name}\n    expected file to exist: ${path}"
        printf "  ✗ %s\n" "$test_name"
    fi
}

assert_path_exists() {
    local test_name="$1" path="$2"
    if [ -e "$path" ]; then
        PASS=$((PASS + 1))
        printf "  ✓ %s\n" "$test_name"
    else
        FAIL=$((FAIL + 1))
        ERRORS="${ERRORS}\n  FAIL: ${test_name}\n    expected path to exist: ${path}"
        printf "  ✗ %s\n" "$test_name"
    fi
}

assert_exit_code() {
    local test_name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        PASS=$((PASS + 1))
        printf "  ✓ %s\n" "$test_name"
    else
        FAIL=$((FAIL + 1))
        ERRORS="${ERRORS}\n  FAIL: ${test_name}\n    expected exit code: ${expected}\n    actual: ${actual}"
        printf "  ✗ %s\n" "$test_name"
    fi
}

# --- Fixtures ---
setup_repo() {
    TMPBASE=$(mktemp -d)
    local repo="$TMPBASE/repo"
    mkdir -p "$repo/.claude/skills" "$repo/claude" "$repo/.git"
    # Minimal registry fixture with the anchor heading the tool expects
    cat > "$repo/claude/REFERENCE-SKILLS-INDEX.md" <<'EOF'
# REFERENCE-SKILLS-INDEX

Registry of skills.

| Name | Description | V | Scope | Status | Required Reading |
|------|-------------|---|-------|--------|------------------|

## Retrofit priorities

EOF
    # Spoof a .git so git rev-parse works
    (cd "$repo" && git init -q 2>/dev/null)
    echo "$repo"
}

make_v1_skill() {
    local repo="$1" name="$2"
    local sk_dir="$repo/.claude/skills/$name"
    mkdir -p "$sk_dir"
    cat > "$sk_dir/SKILL.md" <<EOF
---
name: $name
description: A v1 skill for testing
---

# $name

Some body content.
EOF
    # Add a matching registry row
    # Use printf so we don't run into echo's backslash handling
    printf '| %s | A v1 skill for testing | 1 | agent | active | SKILL-AUTHORING |\n' "$name" >> "$repo/claude/REFERENCE-SKILLS-INDEX.md"
}

make_v2_skill() {
    local repo="$1" name="$2"
    local sk_dir="$repo/.claude/skills/$name"
    mkdir -p "$sk_dir/scripts" "$sk_dir/assets"
    cat > "$sk_dir/SKILL.md" <<EOF
---
name: $name
description: A v2 skill for testing
agency-skill-version: 2
when_to_use: during testing
argument-hint: "<arg>"
paths:
  - .claude/worktrees/**
required_reading:
  - claude/REFERENCE-SKILL-AUTHORING.md
---

# $name

## Why this exists
## Required reading
## Usage
## Preconditions
## Flow / Steps
## Failure modes
## What this does NOT do
## Status
## Related
EOF
    printf "TODO\n" > "$sk_dir/reference.md"
    printf "TODO\n" > "$sk_dir/examples.md"
    printf "TODO\n" > "$sk_dir/scripts/README.md"
    printf "TODO\n" > "$sk_dir/assets/README.md"
    printf '| %s | A v2 skill for testing | 2 | agent | active | SKILL-AUTHORING |\n' "$name" >> "$repo/claude/REFERENCE-SKILLS-INDEX.md"
}

cleanup() {
    if [ -n "$TMPBASE" ] && [ -d "$TMPBASE" ]; then
        rm -rf "$TMPBASE"
    fi
}
trap cleanup EXIT

# --- Tests ---

echo ""
echo "Running skill-create tests..."
echo ""

# ============================================================================
# Test 1: EXIT trap does NOT delete existing skill on --upgrade (regression
# guard for the bug discovered during this session — _cleanup_all was
# rm -rf'ing the skill dir when SUCCESS_MARK was not set on the upgrade path).
# Maps to scorer finding #5 (T1+code-1 dedup).
# ============================================================================

echo "Test 1: --upgrade preserves existing skill dir across exit"
repo=$(setup_repo)
make_v1_skill "$repo" "test-skill-1"
# Marker file proves the directory survived
echo "MARKER" > "$repo/.claude/skills/test-skill-1/MARKER"
CLAUDE_PROJECT_DIR="$repo" "$UPGRADE_TOOL" test-skill-1 >/dev/null 2>&1 || true
assert_file_exists "t1.1 SKILL.md survives --upgrade" "$repo/.claude/skills/test-skill-1/SKILL.md"
assert_file_exists "t1.2 MARKER file survives --upgrade" "$repo/.claude/skills/test-skill-1/MARKER"
cleanup

# ============================================================================
# Test 2: --upgrade creates the 4 missing bundle files (reference.md,
# examples.md, scripts/README.md, assets/README.md).
# Maps to normal happy-path validation of --upgrade.
# ============================================================================

echo ""
echo "Test 2: --upgrade scaffolds missing bundle files"
repo=$(setup_repo)
make_v1_skill "$repo" "test-skill-2"
CLAUDE_PROJECT_DIR="$repo" "$UPGRADE_TOOL" test-skill-2 >/dev/null 2>&1 || true
assert_file_exists "t2.1 reference.md created" "$repo/.claude/skills/test-skill-2/reference.md"
assert_file_exists "t2.2 examples.md created" "$repo/.claude/skills/test-skill-2/examples.md"
assert_file_exists "t2.3 scripts/README.md created" "$repo/.claude/skills/test-skill-2/scripts/README.md"
assert_file_exists "t2.4 assets/README.md created" "$repo/.claude/skills/test-skill-2/assets/README.md"
cleanup

# ============================================================================
# Test 3: --upgrade adds v2 frontmatter fields with TODO placeholders
# preserving existing name + description.
# ============================================================================

echo ""
echo "Test 3: --upgrade adds missing v2 frontmatter fields"
repo=$(setup_repo)
make_v1_skill "$repo" "test-skill-3"
CLAUDE_PROJECT_DIR="$repo" "$UPGRADE_TOOL" test-skill-3 >/dev/null 2>&1 || true
fm=$(cat "$repo/.claude/skills/test-skill-3/SKILL.md")
assert_contains "t3.1 name preserved" "name: test-skill-3" "$fm"
assert_contains "t3.2 description preserved" "A v1 skill for testing" "$fm"
assert_contains "t3.3 agency-skill-version: 2 added" "agency-skill-version: 2" "$fm"
assert_contains "t3.4 when_to_use added (TODO placeholder ok)" "when_to_use:" "$fm"
assert_contains "t3.5 required_reading added" "required_reading:" "$fm"
cleanup

# ============================================================================
# Test 4: --upgrade is idempotent on already-v2 skill (finding T5 / #24).
# Re-running --upgrade must not change a v2 SKILL.md byte-content beyond
# benign whitespace. Key gate: the EXISTING_VERSION check must detect v2
# (finding #2 / code-2 — _existing must not return empty for int scalar).
# ============================================================================

echo ""
echo "Test 4: --upgrade on v2 skill is idempotent (detects existing v2)"
repo=$(setup_repo)
make_v2_skill "$repo" "test-skill-4"
before_sha=$(shasum "$repo/.claude/skills/test-skill-4/SKILL.md" | awk '{print $1}')
out=$(CLAUDE_PROJECT_DIR="$repo" "$UPGRADE_TOOL" test-skill-4 2>&1 || true)
after_sha=$(shasum "$repo/.claude/skills/test-skill-4/SKILL.md" | awk '{print $1}')
assert_contains "t4.1 announces no frontmatter changes needed" "already agency-skill-version 2" "$out"
# Must detect v2 and NOT touch the file (pre-fix: _existing returned "" for int, silent re-write)
assert_eq "t4.2 SKILL.md byte-identical after --upgrade on v2" "$before_sha" "$after_sha"
cleanup

# ============================================================================
# Test 5: --upgrade on missing skill exits 3 (not 0 or some other code).
# Finding T6 / #30 — exit-code matrix.
# ============================================================================

echo ""
echo "Test 5: --upgrade on missing skill exits 3"
repo=$(setup_repo)
set +e
CLAUDE_PROJECT_DIR="$repo" "$UPGRADE_TOOL" nonexistent-skill >/dev/null 2>&1
ec=$?
set -e
assert_exit_code "t5.1 exit code 3 on missing skill" "3" "$ec"
cleanup

# ============================================================================
# Test 6: --upgrade on skill with dir but no SKILL.md exits 3.
# ============================================================================

echo ""
echo "Test 6: --upgrade on skill with no SKILL.md exits 3"
repo=$(setup_repo)
mkdir -p "$repo/.claude/skills/empty-skill"
set +e
CLAUDE_PROJECT_DIR="$repo" "$UPGRADE_TOOL" empty-skill >/dev/null 2>&1
ec=$?
set -e
assert_exit_code "t6.1 exit code 3 on missing SKILL.md" "3" "$ec"
# And critically: the empty dir still exists (not rm -rf'd by trap — same
# guard as test 1 but with an even more aggressive reproduction).
assert_path_exists "t6.2 empty skill dir preserved across exit" "$repo/.claude/skills/empty-skill"
cleanup

# ============================================================================
# Test 7: --upgrade on SKILL.md with broken frontmatter exits 4 (not 0, not
# silent pass). Finding #1 / code-1 — set -e + UPGRADE_FM_EXIT capture.
# ============================================================================

echo ""
echo "Test 7: --upgrade on broken frontmatter exits 4"
repo=$(setup_repo)
mkdir -p "$repo/.claude/skills/broken-skill"
# No leading "---" → python exits 4
cat > "$repo/.claude/skills/broken-skill/SKILL.md" <<EOF
just a body, no frontmatter
EOF
printf '| broken-skill | no frontmatter | 1 | agent | active | SKILL-AUTHORING |\n' >> "$repo/claude/REFERENCE-SKILLS-INDEX.md"
set +e
CLAUDE_PROJECT_DIR="$repo" "$UPGRADE_TOOL" broken-skill >/dev/null 2>&1
ec=$?
set -e
# Pre-fix: set -e kills the script before UPGRADE_FM_EXIT=$? captures, so exit
# code would be whatever python emitted (but script terminates early; real
# exit code is 4 from set -e semantics — verify).
assert_exit_code "t7.1 exit code 4 on broken frontmatter" "4" "$ec"
cleanup

# ============================================================================
# Test 8: create mode — kebab-case name validation rejects bad names.
# Finding T3 / #17 — NAME regex rejection.
# ============================================================================

echo ""
echo "Test 8: create mode rejects bad skill names"

repo=$(setup_repo)
set +e
CLAUDE_PROJECT_DIR="$repo" "$TOOL" "../etc/passwd" --description "x" >/dev/null 2>&1
ec_traversal=$?
CLAUDE_PROJECT_DIR="$repo" "$TOOL" "BadName" --description "x" >/dev/null 2>&1
ec_upper=$?
CLAUDE_PROJECT_DIR="$repo" "$TOOL" "9leading" --description "x" >/dev/null 2>&1
ec_digit=$?
CLAUDE_PROJECT_DIR="$repo" "$TOOL" "a/b" --description "x" >/dev/null 2>&1
ec_slash=$?
set -e
assert_exit_code "t8.1 path traversal rejected" "2" "$ec_traversal"
assert_exit_code "t8.2 uppercase rejected" "2" "$ec_upper"
assert_exit_code "t8.3 leading digit rejected" "2" "$ec_digit"
assert_exit_code "t8.4 slash rejected" "2" "$ec_slash"
cleanup

# ============================================================================
# Test 9: create mode rejects descriptions with newlines or pipe chars.
# Finding T2 / #16 — description validation.
# ============================================================================

echo ""
echo "Test 9: create mode rejects unsafe descriptions"
repo=$(setup_repo)
set +e
CLAUDE_PROJECT_DIR="$repo" "$TOOL" "valid-name-1" --description "multi
line" >/dev/null 2>&1
ec_nl=$?
CLAUDE_PROJECT_DIR="$repo" "$TOOL" "valid-name-2" --description "has | pipe" >/dev/null 2>&1
ec_pipe=$?
set -e
assert_exit_code "t9.1 newline in description rejected" "2" "$ec_nl"
assert_exit_code "t9.2 pipe in description rejected" "2" "$ec_pipe"
cleanup

# ============================================================================
# Test 10: skill-create --upgrade now redirects to skill-upgrade
# (backwards-compat shim with deprecation warning).
# Maps to the-agency#320 D5 finding — mode-flag → subcommand split.
# ============================================================================

echo ""
echo "Test 10: skill-create --upgrade redirects to skill-upgrade with deprecation warning"
repo=$(setup_repo)
make_v1_skill "$repo" "redirect-test"
out=$(CLAUDE_PROJECT_DIR="$repo" "$TOOL" --upgrade redirect-test 2>&1 || true)
assert_contains "t10.1 deprecation warning shown" "DEPRECATED" "$out"
assert_contains "t10.2 redirect happens" "Redirecting to skill-upgrade" "$out"
assert_file_exists "t10.3 upgrade still worked via redirect" "$repo/.claude/skills/redirect-test/reference.md"
cleanup

# ============================================================================
# Test 11: skill-upgrade rejects bad names (same validation as skill-create).
# ============================================================================

echo ""
echo "Test 11: skill-upgrade rejects invalid names"
repo=$(setup_repo)
set +e
CLAUDE_PROJECT_DIR="$repo" "$UPGRADE_TOOL" "../etc/passwd" >/dev/null 2>&1
ec_traversal=$?
CLAUDE_PROJECT_DIR="$repo" "$UPGRADE_TOOL" "UPPER" >/dev/null 2>&1
ec_upper=$?
set -e
assert_exit_code "t11.1 traversal rejected" "2" "$ec_traversal"
assert_exit_code "t11.2 uppercase rejected" "2" "$ec_upper"
cleanup

# ============================================================================
# Test 12: skill-upgrade --help shows independent help (not skill-create's).
# ============================================================================

echo ""
echo "Test 12: skill-upgrade has its own --help and --version"
out=$("$UPGRADE_TOOL" --help 2>&1)
assert_contains "t12.1 help mentions v1→v2 retrofit" "v1 skill to v2" "$out"
ver=$("$UPGRADE_TOOL" --version 2>&1)
assert_contains "t12.2 version reported" "skill-upgrade" "$ver"

# --- Report ---
echo ""
echo "────────────────────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    echo -e "$ERRORS"
    exit 1
fi
exit 0
