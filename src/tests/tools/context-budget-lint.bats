#!/usr/bin/env bats
# Tests for agency/tools/context-budget-lint
#
# What Problem: context-budget-lint resolves @-import chains and estimates token
# cost. These tests verify import resolution, token estimation, budget checking,
# and circular import handling.
#
# Written: 2026-04-07 during devex Phase 3.4

load test_helper

setup() {
    test_isolation_setup

    export TEST_REPO="${BATS_TEST_TMPDIR}/test-repo"
    mkdir -p "$TEST_REPO/agency/tools/lib"
    mkdir -p "$TEST_REPO/.claude/skills/simple/SKILL.md"
    mkdir -p "$TEST_REPO/.git"

    cd "$TEST_REPO"
    git init --quiet --no-verify 2>/dev/null || git init --quiet

    # Copy the linter
    cp "$REPO_ROOT/agency/tools/context-budget-lint" "$TEST_REPO/agency/tools/"
    chmod +x "$TEST_REPO/agency/tools/context-budget-lint"

    # Copy log helper
    if [[ -f "$REPO_ROOT/agency/tools/lib/_log-helper" ]]; then
        cp "$REPO_ROOT/agency/tools/lib/_log-helper" "$TEST_REPO/agency/tools/lib/"
    fi
}

teardown() {
    test_isolation_teardown
}

# Helper: create a skill file with known word count
create_skill() {
    local name="$1"
    local content="$2"
    mkdir -p "$TEST_REPO/.claude/skills/$name"
    # Remove the directory if SKILL.md was created as a directory by mkdir -p
    rm -rf "$TEST_REPO/.claude/skills/$name/SKILL.md"
    echo "$content" > "$TEST_REPO/.claude/skills/$name/SKILL.md"
}

# ─────────────────────────────────────────────────────────────────────────────
# Simple skill (no imports)
# ─────────────────────────────────────────────────────────────────────────────

@test "simple: small skill within budget" {
    cd "$TEST_REPO"
    create_skill "tiny" "This is a small skill with just a few words"
    run ./agency/tools/context-budget-lint --skill tiny
    [ "$status" -eq 0 ]
    [[ "$output" == *"✓ tiny"* ]]
    [[ "$output" == *"within budget"* ]]
}

@test "simple: over-budget skill detected" {
    cd "$TEST_REPO"
    # Create a skill with lots of words
    local big_content=""
    for i in $(seq 1 600); do
        big_content="$big_content word$i is here now "
    done
    create_skill "big" "$big_content"
    # Use a tiny budget to force failure
    run ./agency/tools/context-budget-lint --skill big --budget 100
    [ "$status" -eq 1 ]
    [[ "$output" == *"✗ big"* ]]
    [[ "$output" == *"OVER"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Import chains
# ─────────────────────────────────────────────────────────────────────────────

@test "import: resolves @-import chain" {
    cd "$TEST_REPO"
    mkdir -p "$TEST_REPO/claude/docs"
    echo "some imported content with several words in it here" > "$TEST_REPO/claude/docs/imported.md"
    create_skill "importer" "@agency/docs/imported.md
This skill imports another file"
    run ./agency/tools/context-budget-lint --skill importer --verbose
    [ "$status" -eq 0 ]
    [[ "$output" == *"claude/docs/imported.md"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Circular imports
# ─────────────────────────────────────────────────────────────────────────────

@test "circular: detects and skips circular imports" {
    cd "$TEST_REPO"
    mkdir -p "$TEST_REPO/claude/docs"
    echo "@agency/docs/b.md
Content of a" > "$TEST_REPO/claude/docs/a.md"
    echo "@agency/docs/a.md
Content of b" > "$TEST_REPO/claude/docs/b.md"
    create_skill "circular" "@agency/docs/a.md
Skill that starts a circular chain"
    run ./agency/tools/context-budget-lint --skill circular --verbose
    [ "$status" -eq 0 ]
    [[ "$output" == *"CIRCULAR"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Budget override
# ─────────────────────────────────────────────────────────────────────────────

@test "budget: custom budget respected" {
    cd "$TEST_REPO"
    create_skill "medium" "one two three four five six seven eight nine ten eleven twelve"
    run ./agency/tools/context-budget-lint --skill medium --budget 1
    [ "$status" -eq 1 ]
    [[ "$output" == *"OVER"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Edge cases
# ─────────────────────────────────────────────────────────────────────────────

@test "no skills directory: exits cleanly" {
    cd "$TEST_REPO"
    rm -rf .claude/skills
    run ./agency/tools/context-budget-lint
    [ "$status" -eq 0 ]
    [[ "$output" == *"No skills directory"* ]]
}

@test "version flag works" {
    run ./agency/tools/context-budget-lint --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"context-budget-lint"* ]]
}
