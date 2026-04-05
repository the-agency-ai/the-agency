#!/usr/bin/env bats
#
# What Problem: agent-identity is the unified "who am I" for all ISCP tools.
# If identity resolution breaks, every tool creates dispatches/flags with
# wrong sender addresses. These tests verify resolution, caching, and output.
#
# How & Why: BATS tests with isolated HOME and mock git repo. Tests cover:
# branch-based detection (captain on main, agent on named branch), env var
# override, cache behavior (write, read, branch-scoped), output modes
# (full, --agent, --principal, --json), and error handling.
#
# Written: 2026-04-05 during ISCP Iteration 1.3

load 'test_helper'

# Override test_helper's setup for isolated ISCP testing
setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    export HOME="$BATS_TEST_TMPDIR/fakehome"
    mkdir -p "$HOME"

    # Create a mock git repo with agency.yaml
    export MOCK_REPO="$BATS_TEST_TMPDIR/mock-repo"
    mkdir -p "$MOCK_REPO/claude/tools/lib"
    mkdir -p "$MOCK_REPO/claude/config"

    # Copy the real tools and libs into mock repo
    cp "$REPO_ROOT/claude/tools/agent-identity" "$MOCK_REPO/claude/tools/"
    chmod +x "$MOCK_REPO/claude/tools/agent-identity"
    cp "$REPO_ROOT/claude/tools/lib/_address-parse" "$MOCK_REPO/claude/tools/lib/"
    cp "$REPO_ROOT/claude/tools/lib/_path-resolve" "$MOCK_REPO/claude/tools/lib/"
    cp "$REPO_ROOT/claude/tools/lib/_log-helper" "$MOCK_REPO/claude/tools/lib/"

    cd "$MOCK_REPO"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"

    # agency.yaml with principal mapping
    cat > "$MOCK_REPO/claude/config/agency.yaml" <<'YAML'
principals:
  testuser: testprincipal
  jdm: jordan
YAML

    git add -A
    git commit -m "init" --quiet

    # Set git remote for repo name resolution
    git remote add origin https://github.com/test-org/test-repo.git 2>/dev/null || true

    # Environment — let _path-resolve discover AGENCY_PROJECT_ROOT naturally
    # from SCRIPT_DIR walking up to find agency.yaml. Setting it here would
    # cause _address-parse to skip sourcing _path-resolve entirely.
    export CLAUDE_PROJECT_DIR="$MOCK_REPO"
    unset AGENCY_PROJECT_ROOT
    unset AGENCY_PRINCIPAL
    export USER="testuser"
    # Clear any inherited agent name
    unset CLAUDE_AGENT_NAME
}

teardown() {
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Basic resolution
# ─────────────────────────────────────────────────────────────────────────────

@test "resolves captain on main branch" {
    cd "$MOCK_REPO"
    run "$MOCK_REPO/claude/tools/agent-identity"
    assert_success
    assert_output_contains "test-repo/testprincipal/captain"
}

@test "resolves agent name from branch" {
    cd "$MOCK_REPO"
    git checkout -b iscp --quiet
    run "$MOCK_REPO/claude/tools/agent-identity"
    assert_success
    assert_output_contains "test-repo/testprincipal/iscp"
}

@test "strips worktree- prefix from branch name" {
    cd "$MOCK_REPO"
    git checkout -b worktree-mdpal --quiet
    run "$MOCK_REPO/claude/tools/agent-identity"
    assert_success
    assert_output_contains "test-repo/testprincipal/mdpal"
}

@test "CLAUDE_AGENT_NAME overrides branch detection" {
    cd "$MOCK_REPO"
    export CLAUDE_AGENT_NAME="custom-agent"
    run "$MOCK_REPO/claude/tools/agent-identity"
    assert_success
    assert_output_contains "test-repo/testprincipal/custom-agent"
}

@test "resolves with different principal mapping" {
    cd "$MOCK_REPO"
    export USER="jdm"
    run "$MOCK_REPO/claude/tools/agent-identity"
    assert_success
    assert_output_contains "test-repo/jordan/captain"
}

# ─────────────────────────────────────────────────────────────────────────────
# Output modes
# ─────────────────────────────────────────────────────────────────────────────

@test "--agent outputs bare agent name" {
    cd "$MOCK_REPO"
    run "$MOCK_REPO/claude/tools/agent-identity" --agent
    assert_success
    [[ "$output" == "captain" ]]
}

@test "--principal outputs bare principal name" {
    cd "$MOCK_REPO"
    run "$MOCK_REPO/claude/tools/agent-identity" --principal
    assert_success
    [[ "$output" == "testprincipal" ]]
}

@test "--repo outputs bare repo name" {
    cd "$MOCK_REPO"
    run "$MOCK_REPO/claude/tools/agent-identity" --repo
    assert_success
    [[ "$output" == "test-repo" ]]
}

@test "--json outputs valid JSON" {
    cd "$MOCK_REPO"
    run "$MOCK_REPO/claude/tools/agent-identity" --json
    assert_success
    # Validate JSON structure
    echo "$output" | jq -e '.repo' > /dev/null
    echo "$output" | jq -e '.principal' > /dev/null
    echo "$output" | jq -e '.agent' > /dev/null
    [[ "$(echo "$output" | jq -r '.agent')" == "captain" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Cache behavior
# ─────────────────────────────────────────────────────────────────────────────

@test "creates cache file on first run" {
    cd "$MOCK_REPO"
    run "$MOCK_REPO/claude/tools/agent-identity"
    assert_success
    # Cache should exist under ~/.agency/test-repo/
    local cache_dir="$HOME/.agency/test-repo"
    [[ -d "$cache_dir" ]]
    local cache_files
    cache_files=$(ls "$cache_dir"/.agent-identity-* 2>/dev/null | wc -l)
    [[ "$cache_files" -gt 0 ]]
}

@test "cache is branch-scoped (different branches get different caches)" {
    cd "$MOCK_REPO"
    # Run on main
    "$MOCK_REPO/claude/tools/agent-identity" > /dev/null
    local main_caches
    main_caches=$(ls "$HOME/.agency/test-repo/"/.agent-identity-* 2>/dev/null)

    # Switch branch and run again
    git checkout -b iscp --quiet
    "$MOCK_REPO/claude/tools/agent-identity" > /dev/null
    local all_caches
    all_caches=$(ls "$HOME/.agency/test-repo/"/.agent-identity-* 2>/dev/null | wc -l)

    # Should have 2 cache files (one per branch)
    [[ "$all_caches" -eq 2 ]]
}

@test "second run uses cache (produces same output)" {
    cd "$MOCK_REPO"
    run "$MOCK_REPO/claude/tools/agent-identity"
    assert_success
    local first_output="$output"

    run "$MOCK_REPO/claude/tools/agent-identity"
    assert_success
    [[ "$output" == "$first_output" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Help and version
# ─────────────────────────────────────────────────────────────────────────────

@test "--help shows usage" {
    run "$MOCK_REPO/claude/tools/agent-identity" --help
    assert_success
    assert_output_contains "Usage"
}

@test "--version shows version" {
    run "$MOCK_REPO/claude/tools/agent-identity" --version
    assert_success
    assert_output_contains "agent-identity"
}

@test "unknown option fails" {
    run "$MOCK_REPO/claude/tools/agent-identity" --bad-flag
    assert_failure
    assert_output_contains "unknown option"
}
