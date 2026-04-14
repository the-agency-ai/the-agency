#!/usr/bin/env bats
# Tests for claude/tools/lib/_commit-prefix
#
# What Problem: validate_commit_prefix reads commits.require_day_prefix from
# agency.yaml and validates a commit message. These tests cover all valid
# prefix forms, invalid forms, and the disabled (default) state.
#
# Written: 2026-04-07 during devex Phase 122

load test_helper

setup() {
    test_isolation_setup

    export TEST_REPO="${BATS_TEST_TMPDIR}/test-repo"
    mkdir -p "$TEST_REPO/claude/tools/lib"
    mkdir -p "$TEST_REPO/claude/config"
    cd "$TEST_REPO"
    git init --quiet --no-verify 2>/dev/null || git init --quiet
    git config user.email "test@test.invalid"
    git config user.name "Test"

    # Copy validator and config tool
    cp "$REPO_ROOT/claude/tools/lib/_commit-prefix" "$TEST_REPO/claude/tools/lib/"
    cp "$REPO_ROOT/claude/tools/config" "$TEST_REPO/claude/tools/"
    chmod +x "$TEST_REPO/claude/tools/config"
    if [[ -f "$REPO_ROOT/claude/tools/lib/_log-helper" ]]; then
        cp "$REPO_ROOT/claude/tools/lib/_log-helper" "$TEST_REPO/claude/tools/lib/"
    fi

    # Default config: flag disabled
    cat > claude/config/agency.yaml <<'YAML'
project:
  name: "test"
commits:
  require_day_prefix: false
YAML
}

teardown() {
    test_isolation_teardown
}

# Helper to enable the flag
enable_flag() {
    cat > "$TEST_REPO/claude/config/agency.yaml" <<'YAML'
project:
  name: "test"
commits:
  require_day_prefix: true
YAML
}

# ─────────────────────────────────────────────────────────────────────────────
# Disabled (default)
# ─────────────────────────────────────────────────────────────────────────────

@test "disabled: any prefix passes" {
    cd "$TEST_REPO"
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix "anything goes here"'
    [ "$status" -eq 0 ]
}

@test "disabled: empty message passes" {
    cd "$TEST_REPO"
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix ""'
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Enabled — valid prefixes
# ─────────────────────────────────────────────────────────────────────────────

@test "enabled: Day N: passes" {
    cd "$TEST_REPO"
    enable_flag
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix "Day 32: fix bug"'
    [ "$status" -eq 0 ]
}

@test "enabled: Phase X.Y: passes" {
    cd "$TEST_REPO"
    enable_flag
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix "Phase 1.3: rewrite commit-precheck"'
    [ "$status" -eq 0 ]
}

@test "enabled: Phase X.MN: passes" {
    cd "$TEST_REPO"
    enable_flag
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix "Phase 2.M1: docker T3 milestone"'
    [ "$status" -eq 0 ]
}

@test "enabled: Phase X (no .Y): passes" {
    cd "$TEST_REPO"
    enable_flag
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix "Phase 3: enforcement tooling"'
    [ "$status" -eq 0 ]
}

@test "enabled: Merge commit passes" {
    cd "$TEST_REPO"
    enable_flag
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix "Merge branch foo into main"'
    [ "$status" -eq 0 ]
}

@test "enabled: Revert commit passes" {
    cd "$TEST_REPO"
    enable_flag
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix "Revert \"Day 32: bad change\""'
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Enabled — invalid prefixes
# ─────────────────────────────────────────────────────────────────────────────

@test "enabled: bare 'fix bug' fails" {
    cd "$TEST_REPO"
    enable_flag
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix "fix bug"'
    [ "$status" -eq 1 ]
}

@test "enabled: workstream/agent prefix fails" {
    cd "$TEST_REPO"
    enable_flag
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix "devex/devex: fix bug"'
    [ "$status" -eq 1 ]
}

@test "enabled: lowercase day fails" {
    cd "$TEST_REPO"
    enable_flag
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix "day 32: fix bug"'
    [ "$status" -eq 1 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Multi-line messages — only first line checked
# ─────────────────────────────────────────────────────────────────────────────

@test "enabled: multi-line with valid first line passes" {
    cd "$TEST_REPO"
    enable_flag
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix "Day 32: fix bug

This is the body
with multiple lines"'
    [ "$status" -eq 0 ]
}

@test "enabled: multi-line with invalid first line fails" {
    cd "$TEST_REPO"
    enable_flag
    run bash -c 'source claude/tools/lib/_commit-prefix && validate_commit_prefix "fix bug

Day 32: this is in the body, not the first line"'
    [ "$status" -eq 1 ]
}
