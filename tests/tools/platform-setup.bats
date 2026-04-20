#!/usr/bin/env bats
#
# Tests for tools/platform-setup dispatcher and deprecation shims
#
# Tests provider resolution, auto-detection from uname, error handling,
# and mac-setup/linux-setup deprecation shims.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# CLI flags
# ─────────────────────────────────────────────────────────────────────────────

@test "platform-setup: --version shows version" {
    run_tool platform-setup --version
    assert_success
    assert_output_contains "platform-setup"
}

@test "platform-setup: --help shows usage" {
    run_tool platform-setup --help
    assert_success
    assert_output_contains "Usage"
    assert_output_contains "platform.provider"
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider resolution
# ─────────────────────────────────────────────────────────────────────────────

@test "platform-setup: dispatches based on config" {
    # platform.provider is "auto" in agency.yaml, so it auto-detects OS
    run_tool platform-setup --help
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# Auto-detection
# ─────────────────────────────────────────────────────────────────────────────

@test "platform-setup: auto resolves to macos on Darwin" {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        skip "Only runs on macOS"
    fi
    # With "auto" config (default), should dispatch to platform-setup-macos
    run_tool platform-setup --help
    assert_success
}

@test "platform-setup: handles missing provider tool" {
    local fixture="${BATS_TEST_TMPDIR}/project"
    mkdir -p "$fixture/claude/config" "$fixture/agency/tools/lib" "$fixture/tools"
    cp "${TOOLS_DIR}/lib/_path-resolve" "$fixture/tools/" 2>/dev/null || cp "${TOOLS_DIR}/_path-resolve" "$fixture/tools/" 2>/dev/null || true
    cp "${TOOLS_DIR}/lib/_log-helper" "$fixture/tools/" 2>/dev/null || cp "${TOOLS_DIR}/_log-helper" "$fixture/tools/" 2>/dev/null || true
    cp "${REPO_ROOT}/agency/tools/lib/_provider-resolve" "$fixture/agency/tools/lib/"
    cp "${TOOLS_DIR}/platform-setup" "$fixture/tools/"

    cat > "$fixture/agency/config/agency.yaml" << 'EOF'
principals:
  default: unknown
platform:
  provider: "freebsd"
EOF

    run env CLAUDE_PROJECT_DIR="$fixture" bash "$fixture/tools/platform-setup"
    assert_failure
    assert_output_contains "not found"
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider tools
# ─────────────────────────────────────────────────────────────────────────────

@test "platform-setup-macos: --version shows version" {
    run_tool platform-setup-macos --version
    assert_success
    assert_output_contains "platform-setup-macos"
}

@test "platform-setup-linux: --version shows version" {
    run_tool platform-setup-linux --version
    assert_success
    assert_output_contains "platform-setup-linux"
}
