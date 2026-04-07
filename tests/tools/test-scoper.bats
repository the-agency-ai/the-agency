#!/usr/bin/env bats
# Tests for claude/tools/test-scoper — file-to-test mapping
#
# What Problem: test-scoper maps changed files to relevant BATS test files.
# These tests verify all four mapping strategies work: manifest, convention,
# dependency, and direct test file detection.
#
# Written: 2026-04-07 during devex Phase 1.4

load test_helper

setup() {
    test_isolation_setup

    # Create a mini repo structure in temp dir for testing
    export TEST_REPO="${BATS_TEST_TMPDIR}/test-repo"
    mkdir -p "$TEST_REPO/claude/tools/lib"
    mkdir -p "$TEST_REPO/tests/tools"
    mkdir -p "$TEST_REPO/.git"

    # Initialize a git repo so git rev-parse works
    git -C "$TEST_REPO" init --quiet 2>/dev/null

    # Create fake tools
    echo '#!/bin/bash' > "$TEST_REPO/claude/tools/flag"
    echo '#!/bin/bash' > "$TEST_REPO/claude/tools/dispatch"
    echo '#!/bin/bash' > "$TEST_REPO/claude/tools/lib/_iscp-db"

    # Create a tool with manifest header
    cat > "$TEST_REPO/claude/tools/special-tool" <<'TOOL'
#!/bin/bash
# What Problem: A special tool
# Test: tests/tools/custom-test.bats
echo "hello"
TOOL

    # Create fake test files
    echo '@test "flag test" { true; }' > "$TEST_REPO/tests/tools/flag.bats"
    echo '@test "dispatch test" { true; }' > "$TEST_REPO/tests/tools/dispatch.bats"
    echo '@test "dispatch-create test" { true; }' > "$TEST_REPO/tests/tools/dispatch-create.bats"
    cat > "$TEST_REPO/tests/tools/iscp-db.bats" <<'TEST'
# source lib/_iscp-db
@test "iscp-db test" { true; }
TEST
    cat > "$TEST_REPO/tests/tools/other.bats" <<'TEST'
# source lib/_iscp-db
@test "other test that uses iscp-db" { true; }
TEST
    echo '@test "custom test" { true; }' > "$TEST_REPO/tests/tools/custom-test.bats"
    echo '@test "standalone" { true; }' > "$TEST_REPO/tests/tools/standalone.bats"

    # Copy test-scoper to the test repo
    cp "$REPO_ROOT/claude/tools/test-scoper" "$TEST_REPO/claude/tools/test-scoper"
    chmod +x "$TEST_REPO/claude/tools/test-scoper"
}

teardown() {
    test_isolation_teardown
}

# ─────────────────────────────────────────────────────────────────────────────
# Convention mapping
# ─────────────────────────────────────────────────────────────────────────────

@test "convention: tool maps to matching test file" {
    cd "$TEST_REPO"
    run bash -c 'echo "claude/tools/flag" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
    [[ "$output" == *"flag.bats"* ]]
}

@test "convention: tool with prefix matches gets all related tests" {
    cd "$TEST_REPO"
    run bash -c 'echo "claude/tools/dispatch" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
    [[ "$output" == *"dispatch.bats"* ]]
    [[ "$output" == *"dispatch-create.bats"* ]]
}

@test "convention: tool without test file produces no output" {
    cd "$TEST_REPO"
    echo '#!/bin/bash' > "$TEST_REPO/claude/tools/no-tests-for-me"
    run bash -c 'echo "claude/tools/no-tests-for-me" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Dependency mapping (lib files)
# ─────────────────────────────────────────────────────────────────────────────

@test "dependency: lib file maps to direct-named test and dependents" {
    cd "$TEST_REPO"
    run bash -c 'echo "claude/tools/lib/_iscp-db" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
    [[ "$output" == *"iscp-db.bats"* ]]
}

@test "dependency: lib file finds test files that source it" {
    cd "$TEST_REPO"
    run bash -c 'echo "claude/tools/lib/_iscp-db" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
    [[ "$output" == *"other.bats"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Direct test file
# ─────────────────────────────────────────────────────────────────────────────

@test "direct: .bats file maps to itself" {
    cd "$TEST_REPO"
    run bash -c 'echo "tests/tools/standalone.bats" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
    [[ "$output" == *"standalone.bats"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Manifest override
# ─────────────────────────────────────────────────────────────────────────────

@test "manifest: # Test: header overrides convention" {
    cd "$TEST_REPO"
    run bash -c 'echo "claude/tools/special-tool" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
    [[ "$output" == *"custom-test.bats"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# No mapping (docs, config, etc.)
# ─────────────────────────────────────────────────────────────────────────────

@test "no-mapping: markdown file produces no output" {
    cd "$TEST_REPO"
    run bash -c 'echo "usr/jordan/devex/devex-handoff.md" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "no-mapping: yaml config produces no output" {
    cd "$TEST_REPO"
    run bash -c 'echo "claude/config/agency.yaml" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Multiple files (deduplication)
# ─────────────────────────────────────────────────────────────────────────────

@test "multi: multiple files deduplicates output" {
    cd "$TEST_REPO"
    run bash -c 'printf "claude/tools/flag\ntests/tools/flag.bats\n" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
    # flag.bats should appear exactly once despite two inputs mapping to it
    local count
    count=$(echo "$output" | grep -c "flag.bats" || true)
    [ "$count" -eq 1 ]
}

@test "multi: mixed files with some having no mapping" {
    cd "$TEST_REPO"
    run bash -c 'printf "claude/tools/flag\nusr/jordan/devex/handoff.md\nclaude/tools/dispatch\n" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
    [[ "$output" == *"flag.bats"* ]]
    [[ "$output" == *"dispatch.bats"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Edge cases
# ─────────────────────────────────────────────────────────────────────────────

@test "empty input produces no output" {
    cd "$TEST_REPO"
    run bash -c 'echo "" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "exit code is always 0" {
    cd "$TEST_REPO"
    run bash -c 'echo "nonexistent/path/file.xyz" | ./claude/tools/test-scoper'
    [ "$status" -eq 0 ]
}
