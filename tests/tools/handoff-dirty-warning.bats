#!/usr/bin/env bats
# Tests for handoff tool's dirty-impl-files warning
#
# What Problem: Handoff tool must detect uncommitted impl files and warn the
# agent so they don't claim 'complete' for uncommitted work (the P7 friction).
#
# Written: 2026-04-07 during devex Phase 118.2

load test_helper

setup() {
    test_isolation_setup

    export TEST_REPO="${BATS_TEST_TMPDIR}/test-repo"
    mkdir -p "$TEST_REPO/claude/tools/lib"
    mkdir -p "$TEST_REPO/usr/jordan/devex"
    cd "$TEST_REPO"
    git init --quiet --no-verify 2>/dev/null || git init --quiet
    git config user.email "test@test.invalid"
    git config user.name "Test"
    echo "init" > README.md
    git add README.md
    git commit --quiet --no-verify -m "init"

    # Copy the handoff tool
    cp "$REPO_ROOT/claude/tools/handoff" "$TEST_REPO/claude/tools/"
    chmod +x "$TEST_REPO/claude/tools/handoff"
    if [[ -f "$REPO_ROOT/claude/tools/lib/_log-helper" ]]; then
        cp "$REPO_ROOT/claude/tools/lib/_log-helper" "$TEST_REPO/claude/tools/lib/"
    fi
    if [[ -f "$REPO_ROOT/claude/tools/lib/_address-parse" ]]; then
        cp "$REPO_ROOT/claude/tools/lib/_address-parse" "$TEST_REPO/claude/tools/lib/"
    fi

    # Create an existing handoff so the tool has something to archive
    echo "old handoff content" > usr/jordan/devex/devex-handoff.md
    git add usr/jordan/devex/devex-handoff.md
    git commit --quiet --no-verify -m "add handoff"
}

teardown() {
    test_isolation_teardown
}

# ─────────────────────────────────────────────────────────────────────────────
# Clean state
# ─────────────────────────────────────────────────────────────────────────────

@test "clean: no warning when no impl files dirty" {
    cd "$TEST_REPO"
    run bash -c './claude/tools/handoff write --trigger test 2>&1'
    [ "$status" -eq 0 ]
    [[ "$output" != *"WARNING"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Dirty impl files trigger warning
# ─────────────────────────────────────────────────────────────────────────────

@test "dirty: .py file triggers warning" {
    cd "$TEST_REPO"
    echo "x = 1" > foo.py
    git add foo.py
    run bash -c './claude/tools/handoff write --trigger test 2>&1'
    [ "$status" -eq 0 ]
    [[ "$output" == *"WARNING"* ]]
    [[ "$output" == *"foo.py"* ]]
}

@test "dirty: .bats file triggers warning" {
    cd "$TEST_REPO"
    mkdir -p tests/tools
    echo '@test "x" { true; }' > tests/tools/foo.bats
    git add tests/tools/foo.bats
    run bash -c './claude/tools/handoff write --trigger test 2>&1'
    [ "$status" -eq 0 ]
    [[ "$output" == *"WARNING"* ]]
    [[ "$output" == *"foo.bats"* ]]
}

@test "dirty: claude/tools/ bash script triggers warning" {
    cd "$TEST_REPO"
    mkdir -p claude/tools
    echo '#!/bin/bash' > claude/tools/my-tool
    git add claude/tools/my-tool
    run bash -c './claude/tools/handoff write --trigger test 2>&1'
    [ "$status" -eq 0 ]
    [[ "$output" == *"WARNING"* ]]
    [[ "$output" == *"my-tool"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Doc/handoff files don't trigger warning
# ─────────────────────────────────────────────────────────────────────────────

@test "clean: markdown changes don't trigger warning" {
    cd "$TEST_REPO"
    echo "# new doc" > doc.md
    git add doc.md
    run bash -c './claude/tools/handoff write --trigger test 2>&1'
    [ "$status" -eq 0 ]
    [[ "$output" != *"WARNING"* ]]
}

@test "clean: yaml config changes don't trigger warning" {
    cd "$TEST_REPO"
    echo "k: v" > config.yaml
    git add config.yaml
    run bash -c './claude/tools/handoff write --trigger test 2>&1'
    [ "$status" -eq 0 ]
    [[ "$output" != *"WARNING"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Multiple files
# ─────────────────────────────────────────────────────────────────────────────

@test "dirty: counts multiple impl files" {
    cd "$TEST_REPO"
    echo "x" > a.py
    echo "x" > b.py
    echo "x" > c.py
    git add a.py b.py c.py
    run bash -c './claude/tools/handoff write --trigger test 2>&1'
    [ "$status" -eq 0 ]
    [[ "$output" == *"3 uncommitted"* ]]
}
