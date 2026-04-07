#!/usr/bin/env bats
# Tests for claude/tools/commit-precheck — pre-commit quality gate
#
# What Problem: commit-precheck needs to correctly classify staged files and
# scope tests. These tests verify the classification logic, fast paths, timeout
# behavior, and dry-run output.
#
# Written: 2026-04-07 during devex Phase 1.4

load test_helper

setup() {
    test_isolation_setup

    # Create a test repo with git initialized
    export TEST_REPO="${BATS_TEST_TMPDIR}/test-repo"
    mkdir -p "$TEST_REPO/claude/tools/lib"
    mkdir -p "$TEST_REPO/tests/tools"
    mkdir -p "$TEST_REPO/usr/jordan/devex"

    cd "$TEST_REPO"
    git init --quiet
    git config user.email "test@test.com"
    git config user.name "Test"

    # Create initial commit so we have a HEAD
    echo "init" > README.md
    git add README.md
    git commit -m "init" --quiet --no-verify

    # Copy commit-precheck and test-scoper
    cp "$REPO_ROOT/claude/tools/commit-precheck" "$TEST_REPO/claude/tools/commit-precheck"
    cp "$REPO_ROOT/claude/tools/test-scoper" "$TEST_REPO/claude/tools/test-scoper"
    chmod +x "$TEST_REPO/claude/tools/commit-precheck"
    chmod +x "$TEST_REPO/claude/tools/test-scoper"

    # Copy log helper if it exists (for telemetry stubs)
    if [[ -f "$REPO_ROOT/claude/tools/lib/_log-helper" ]]; then
        cp "$REPO_ROOT/claude/tools/lib/_log-helper" "$TEST_REPO/claude/tools/lib/_log-helper"
    fi
}

teardown() {
    test_isolation_teardown
}

# ─────────────────────────────────────────────────────────────────────────────
# No staged changes
# ─────────────────────────────────────────────────────────────────────────────

@test "no staged changes exits cleanly" {
    cd "$TEST_REPO"
    run ./claude/tools/commit-precheck
    [ "$status" -eq 0 ]
    [[ "$output" == *"No staged changes"* ]]
    [[ "$output" == *"✓"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Classification: docs-only fast path
# ─────────────────────────────────────────────────────────────────────────────

@test "docs-only: markdown files take fast path" {
    cd "$TEST_REPO"
    echo "# Hello" > doc.md
    git add doc.md
    run ./claude/tools/commit-precheck --verbose
    [ "$status" -eq 0 ]
    [[ "$output" == *"docs-only"* ]]
    [[ "$output" == *"✓"* ]]
}

@test "docs-only: yaml config takes fast path" {
    cd "$TEST_REPO"
    echo "key: value" > config.yaml
    git add config.yaml
    run ./claude/tools/commit-precheck --verbose
    [ "$status" -eq 0 ]
    [[ "$output" == *"docs-only"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Classification: tool-code
# ─────────────────────────────────────────────────────────────────────────────

@test "tool-code: files in claude/tools/ classified correctly" {
    cd "$TEST_REPO"
    echo '#!/bin/bash' > claude/tools/my-tool
    git add claude/tools/my-tool
    run ./claude/tools/commit-precheck --dry-run --verbose
    [ "$status" -eq 0 ]
    [[ "$output" == *"tool-code"* ]]
}

@test "tool-code: test files classified as tool-code" {
    cd "$TEST_REPO"
    echo '@test "x" { true; }' > tests/tools/my.bats
    git add tests/tools/my.bats
    run ./claude/tools/commit-precheck --dry-run --verbose
    [ "$status" -eq 0 ]
    [[ "$output" == *"tool-code"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Classification: app-code
# ─────────────────────────────────────────────────────────────────────────────

@test "app-code: TypeScript files classified correctly" {
    cd "$TEST_REPO"
    echo "const x = 1;" > app.ts
    git add app.ts
    run ./claude/tools/commit-precheck --dry-run --verbose
    [ "$status" -eq 0 ]
    [[ "$output" == *"app-code"* ]]
}

@test "app-code: Python files classified correctly" {
    cd "$TEST_REPO"
    echo "x = 1" > app.py
    git add app.py
    run ./claude/tools/commit-precheck --dry-run --verbose
    [ "$status" -eq 0 ]
    [[ "$output" == *"app-code"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Dry-run mode
# ─────────────────────────────────────────────────────────────────────────────

@test "dry-run: shows classification without executing" {
    cd "$TEST_REPO"
    echo '#!/bin/bash' > claude/tools/my-tool
    git add claude/tools/my-tool
    run ./claude/tools/commit-precheck --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    [[ "$output" == *"✓"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Version and help
# ─────────────────────────────────────────────────────────────────────────────

@test "version flag works" {
    run ./claude/tools/commit-precheck --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"commit-precheck"* ]]
    [[ "$output" == *"3.0.0"* ]]
}

@test "help flag works" {
    run ./claude/tools/commit-precheck --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Mixed staged files
# ─────────────────────────────────────────────────────────────────────────────

@test "mixed: tool + markdown classified as tool-code" {
    cd "$TEST_REPO"
    echo '#!/bin/bash' > claude/tools/my-tool
    echo "# doc" > doc.md
    git add claude/tools/my-tool doc.md
    run ./claude/tools/commit-precheck --dry-run --verbose
    [ "$status" -eq 0 ]
    [[ "$output" == *"tool-code"* ]]
}

@test "mixed: app-code + tool classified as app-code" {
    cd "$TEST_REPO"
    echo "const x = 1;" > app.ts
    echo '#!/bin/bash' > claude/tools/my-tool
    git add app.ts claude/tools/my-tool
    run ./claude/tools/commit-precheck --dry-run --verbose
    [ "$status" -eq 0 ]
    [[ "$output" == *"app-code"* ]]
}
