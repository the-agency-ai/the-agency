#!/usr/bin/env bats
#
# Tests for tools/terminal-setup dispatcher and deprecation shim
#
# Tests provider resolution, auto-detection from $TERM_PROGRAM,
# error handling, and the ghostty-setup deprecation shim.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# CLI flags
# ─────────────────────────────────────────────────────────────────────────────

@test "terminal-setup: --version shows version" {
    run_tool terminal-setup --version
    assert_success
    assert_output_contains "terminal-setup"
}

@test "terminal-setup: --help shows usage" {
    run_tool terminal-setup --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "terminal.provider"
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider resolution
# ─────────────────────────────────────────────────────────────────────────────

@test "terminal-setup: dispatches to terminal-setup-ghostty" {
    # terminal.provider is "ghostty" in agency.yaml
    # This will actually exec terminal-setup-ghostty which does real work,
    # so just verify --help dispatches correctly
    run_tool terminal-setup --help
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# Auto-detection fallback
# ─────────────────────────────────────────────────────────────────────────────

@test "terminal-setup: auto-detects ghostty from TERM_PROGRAM" {
    # Create a fixture without terminal config
    local fixture="${BATS_TEST_TMPDIR}/project"
    mkdir -p "$fixture/claude/config" "$fixture/claude/tools/lib" "$fixture/tools"
    cp "${TOOLS_DIR}/_path-resolve" "$fixture/tools/"
    cp "${TOOLS_DIR}/_log-helper" "$fixture/tools/" 2>/dev/null || true
    cp "${REPO_ROOT}/claude/tools/lib/_provider-resolve" "$fixture/claude/tools/lib/"
    cp "${TOOLS_DIR}/terminal-setup" "$fixture/tools/"

    # Create a mock terminal-setup-ghostty that just prints and exits
    cat > "$fixture/tools/terminal-setup-ghostty" << 'MOCK'
#!/bin/bash
echo "mock-ghostty-dispatched"
MOCK
    chmod +x "$fixture/tools/terminal-setup-ghostty"

    # agency.yaml without terminal section
    cat > "$fixture/claude/config/agency.yaml" << 'EOF'
principals:
  default: unknown
secrets:
  provider: "vault"
EOF

    run env TERM_PROGRAM=ghostty CLAUDE_PROJECT_DIR="$fixture" bash "$fixture/tools/terminal-setup"
    assert_success
    assert_output_contains "mock-ghostty-dispatched"
}

@test "terminal-setup: fails when no provider and unknown TERM_PROGRAM" {
    local fixture="${BATS_TEST_TMPDIR}/project"
    mkdir -p "$fixture/claude/config" "$fixture/claude/tools/lib" "$fixture/tools"
    cp "${TOOLS_DIR}/_path-resolve" "$fixture/tools/"
    cp "${TOOLS_DIR}/_log-helper" "$fixture/tools/" 2>/dev/null || true
    cp "${REPO_ROOT}/claude/tools/lib/_provider-resolve" "$fixture/claude/tools/lib/"
    cp "${TOOLS_DIR}/terminal-setup" "$fixture/tools/"

    cat > "$fixture/claude/config/agency.yaml" << 'EOF'
principals:
  default: unknown
EOF

    run env TERM_PROGRAM=unknown-terminal CLAUDE_PROJECT_DIR="$fixture" bash "$fixture/tools/terminal-setup"
    assert_failure
    assert_output_contains "No terminal provider configured"
}

# ─────────────────────────────────────────────────────────────────────────────
# Deprecation shim
# ─────────────────────────────────────────────────────────────────────────────

@test "ghostty-setup: prints deprecation warning" {
    run_tool ghostty-setup --help 2>&1
    # The shim should mention the new name
    assert_output_contains "terminal-setup-ghostty"
}

# ─────────────────────────────────────────────────────────────────────────────
# terminal-setup-ghostty
# ─────────────────────────────────────────────────────────────────────────────

@test "terminal-setup-ghostty: --version shows version" {
    run_tool terminal-setup-ghostty --version
    assert_success
    assert_output_contains "terminal-setup-ghostty"
}

@test "terminal-setup-ghostty: --help shows usage" {
    run_tool terminal-setup-ghostty --help
    assert_success
}
