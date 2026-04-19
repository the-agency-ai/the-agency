#!/usr/bin/env bats
#
# Tests for agency/tools/lib/_provider-resolve sourced helper
#
# Tests provider resolution: sourcing, name mapping, YAML config reading,
# validation, and tool path resolution.
#

load 'test_helper'

PROVIDER_LIB="${REPO_ROOT}/agency/tools/lib/_provider-resolve"

# ─────────────────────────────────────────────────────────────────────────────
# Test fixture: create a minimal agency project with agency.yaml and mock tools
# ─────────────────────────────────────────────────────────────────────────────

setup_provider_fixture() {
    export FIXTURE_DIR="${BATS_TEST_TMPDIR}/project"
    mkdir -p "$FIXTURE_DIR/claude/config"
    mkdir -p "$FIXTURE_DIR/agency/tools/lib"

    # Copy real helpers
    cp "${TOOLS_DIR}/lib/_path-resolve" "$FIXTURE_DIR/agency/tools/lib/"
    cp "${TOOLS_DIR}/lib/_log-helper" "$FIXTURE_DIR/agency/tools/lib/" 2>/dev/null || true
    cp "$PROVIDER_LIB" "$FIXTURE_DIR/agency/tools/lib/"

    # Default agency.yaml
    cat > "$FIXTURE_DIR/agency/config/agency.yaml" << 'EOF'
principals:
  test: test
  default: unknown

secrets:
  provider: "vault"

terminal:
  provider: "ghostty"

platform:
  provider: "auto"

design:
  provider: "figma"
EOF

    # Create mock provider tools
    for tool in secret-vault terminal-setup-ghostty platform-setup-macos platform-setup-linux design-diff-figma; do
        printf '#!/bin/bash\necho "mock %s"\n' "$tool" > "$FIXTURE_DIR/agency/tools/$tool"
        chmod +x "$FIXTURE_DIR/agency/tools/$tool"
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Sourcing
# ─────────────────────────────────────────────────────────────────────────────

@test "_provider-resolve: sources without error" {
    run bash -c "CLAUDE_PROJECT_DIR='${REPO_ROOT}' source '$PROVIDER_LIB'"
    assert_success
}

@test "_provider-resolve: sources _path-resolve automatically" {
    run bash -c "CLAUDE_PROJECT_DIR='${REPO_ROOT}' source '$PROVIDER_LIB' && [[ -n \"\$AGENCY_PROJECT_ROOT\" ]]"
    assert_success
}

@test "_provider-resolve: works with CLAUDE_PROJECT_DIR fallback" {
    # When sourced from a copied location, CLAUDE_PROJECT_DIR fallback kicks in
    setup_provider_fixture
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && [[ -n \"\$AGENCY_PROJECT_ROOT\" ]]"
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# _provider_tool_name mapping
# ─────────────────────────────────────────────────────────────────────────────

@test "_provider_tool_name: secrets -> secret-{provider}" {
    run bash -c "CLAUDE_PROJECT_DIR='${REPO_ROOT}' source '$PROVIDER_LIB' && _provider_tool_name secrets vault"
    assert_success
    [[ "$output" == "secret-vault" ]]
}

@test "_provider_tool_name: terminal -> terminal-setup-{provider}" {
    run bash -c "CLAUDE_PROJECT_DIR='${REPO_ROOT}' source '$PROVIDER_LIB' && _provider_tool_name terminal ghostty"
    assert_success
    [[ "$output" == "terminal-setup-ghostty" ]]
}

@test "_provider_tool_name: platform -> platform-setup-{provider}" {
    run bash -c "CLAUDE_PROJECT_DIR='${REPO_ROOT}' source '$PROVIDER_LIB' && _provider_tool_name platform macos"
    assert_success
    [[ "$output" == "platform-setup-macos" ]]
}

@test "_provider_tool_name: design with verb -> design-{verb}-{provider}" {
    run bash -c "CLAUDE_PROJECT_DIR='${REPO_ROOT}' source '$PROVIDER_LIB' && _provider_tool_name design figma diff"
    assert_success
    [[ "$output" == "design-diff-figma" ]]
}

@test "_provider_tool_name: design without verb fails" {
    run bash -c "CLAUDE_PROJECT_DIR='${REPO_ROOT}' source '$PROVIDER_LIB' && _provider_tool_name design figma 2>&1"
    assert_failure
    assert_output_contains "design section requires a verb"
}

@test "_provider_tool_name: unknown section -> {section}-{provider}" {
    run bash -c "CLAUDE_PROJECT_DIR='${REPO_ROOT}' source '$PROVIDER_LIB' && _provider_tool_name monitoring datadog"
    assert_success
    [[ "$output" == "monitoring-datadog" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# get_provider_name
# ─────────────────────────────────────────────────────────────────────────────

@test "get_provider_name: reads secrets provider from agency.yaml" {
    setup_provider_fixture
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && get_provider_name secrets"
    assert_success
    [[ "$output" == "vault" ]]
}

@test "get_provider_name: reads terminal provider from agency.yaml" {
    setup_provider_fixture
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && get_provider_name terminal"
    assert_success
    [[ "$output" == "ghostty" ]]
}

@test "get_provider_name: reads platform provider from agency.yaml" {
    setup_provider_fixture
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && get_provider_name platform"
    assert_success
    [[ "$output" == "auto" ]]
}

@test "get_provider_name: fails for unconfigured section" {
    setup_provider_fixture
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && get_provider_name nonexistent 2>&1"
    assert_failure
}

@test "get_provider_name: fails when agency.yaml missing" {
    setup_provider_fixture
    rm "$FIXTURE_DIR/agency/config/agency.yaml"
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && get_provider_name secrets 2>&1"
    assert_failure
    assert_output_contains "agency.yaml not found"
}

@test "get_provider_name: strips quotes from provider value" {
    setup_provider_fixture
    # Write a value with extra quotes
    cat > "$FIXTURE_DIR/agency/config/agency.yaml" << 'EOF'
principals:
  default: unknown
secrets:
  provider: "vault"
EOF
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && get_provider_name secrets"
    assert_success
    [[ "$output" == "vault" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider name validation
# ─────────────────────────────────────────────────────────────────────────────

@test "get_provider_name: rejects path traversal attempt" {
    setup_provider_fixture
    cat > "$FIXTURE_DIR/agency/config/agency.yaml" << 'EOF'
principals:
  default: unknown
secrets:
  provider: "../../etc/passwd"
EOF
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && get_provider_name secrets 2>&1"
    assert_failure
    assert_output_contains "invalid provider name"
}

@test "get_provider_name: rejects uppercase provider names" {
    setup_provider_fixture
    cat > "$FIXTURE_DIR/agency/config/agency.yaml" << 'EOF'
principals:
  default: unknown
secrets:
  provider: "VAULT"
EOF
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && get_provider_name secrets 2>&1"
    assert_failure
    assert_output_contains "invalid provider name"
}

@test "get_provider_name: rejects provider with slashes" {
    setup_provider_fixture
    cat > "$FIXTURE_DIR/agency/config/agency.yaml" << 'EOF'
principals:
  default: unknown
secrets:
  provider: "foo/bar"
EOF
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && get_provider_name secrets 2>&1"
    assert_failure
    assert_output_contains "invalid provider name"
}

@test "get_provider_name: accepts valid hyphenated names" {
    setup_provider_fixture
    cat > "$FIXTURE_DIR/agency/config/agency.yaml" << 'EOF'
principals:
  default: unknown
secrets:
  provider: "my-custom-backend"
EOF
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && get_provider_name secrets"
    assert_success
    [[ "$output" == "my-custom-backend" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# resolve_provider
# ─────────────────────────────────────────────────────────────────────────────

@test "resolve_provider: returns full path for secrets" {
    setup_provider_fixture
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && resolve_provider secrets"
    assert_success
    [[ "$output" == "$FIXTURE_DIR/agency/tools/secret-vault" ]]
}

@test "resolve_provider: returns full path for terminal" {
    setup_provider_fixture
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && resolve_provider terminal"
    assert_success
    [[ "$output" == "$FIXTURE_DIR/agency/tools/terminal-setup-ghostty" ]]
}

@test "resolve_provider: returns full path for design with verb" {
    setup_provider_fixture
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && resolve_provider design diff"
    assert_success
    [[ "$output" == "$FIXTURE_DIR/agency/tools/design-diff-figma" ]]
}

@test "resolve_provider: exports AGENCY_PROVIDER" {
    setup_provider_fixture
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && resolve_provider secrets >/dev/null && echo \"\$AGENCY_PROVIDER\""
    assert_success
    [[ "$output" == "vault" ]]
}

@test "resolve_provider: exports AGENCY_PROVIDER_TOOL" {
    setup_provider_fixture
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && resolve_provider secrets >/dev/null && echo \"\$AGENCY_PROVIDER_TOOL\""
    assert_success
    [[ "$output" == "$FIXTURE_DIR/agency/tools/secret-vault" ]]
}

@test "resolve_provider: fails when tool not found" {
    setup_provider_fixture
    rm "$FIXTURE_DIR/agency/tools/secret-vault"
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && resolve_provider secrets 2>&1"
    assert_failure
    assert_output_contains "provider tool not found"
}

@test "resolve_provider: fails when tool not executable" {
    setup_provider_fixture
    chmod -x "$FIXTURE_DIR/agency/tools/secret-vault"
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && resolve_provider secrets 2>&1"
    assert_failure
    assert_output_contains "provider tool not executable"
}

@test "resolve_provider: fails for unconfigured section" {
    setup_provider_fixture
    run bash -c "CLAUDE_PROJECT_DIR='$FIXTURE_DIR' source '$FIXTURE_DIR/claude/tools/lib/_provider-resolve' && resolve_provider nonexistent 2>&1"
    assert_failure
}
