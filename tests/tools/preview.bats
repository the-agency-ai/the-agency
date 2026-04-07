#!/usr/bin/env bats
#
# Tests for ./claude/tools/preview — SPEC-PROVIDER wrapper
#
# Tests provider resolution from agency.yaml, default fallback, exec dispatch
# to provider tool, and the missing-provider error path.
#
# Mirrors the structure of tests/tools/secret.bats but tests don't depend on
# any preview-* provider tool existing — we mock one in BATS_TEST_TMPDIR.
#
# Written: 2026-04-07 — Day 33 — Item 1 from captain's Day 33 work queue

load test_helper

setup() {
    test_isolation_setup

    # Build a fixture project with the wrapper installed and a mock provider.
    export TEST_REPO="${BATS_TEST_TMPDIR}/test-project"
    mkdir -p "$TEST_REPO/claude/tools" "$TEST_REPO/claude/config"
    cd "$TEST_REPO"
    git init --quiet

    # Copy the wrapper under test
    cp "${REPO_ROOT}/claude/tools/preview" "$TEST_REPO/claude/tools/"
    chmod +x "$TEST_REPO/claude/tools/preview"
}

teardown() {
    test_isolation_teardown
}

# Helper: write an agency.yaml with a specific provider
_write_yaml() {
    local provider="$1"
    cat > "$TEST_REPO/claude/config/agency.yaml" <<YAML
preview:
  provider: "${provider}"
YAML
}

# Helper: install a mock provider tool that just echoes its name and args
_install_mock_provider() {
    local name="$1"
    cat > "$TEST_REPO/claude/tools/preview-$name" <<'PROVIDER'
#!/bin/bash
echo "mock-preview-$(basename "$0" | sed 's/preview-//') invoked with: $*"
exit 0
PROVIDER
    chmod +x "$TEST_REPO/claude/tools/preview-$name"
}

# ─────────────────────────────────────────────────────────────────────────────
# Default provider when no agency.yaml
# ─────────────────────────────────────────────────────────────────────────────

@test "preview: defaults to docker-compose when no agency.yaml" {
    cd "$TEST_REPO"
    rm -f claude/config/agency.yaml
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"docker-compose"* ]]
}

@test "preview: defaults to docker-compose when agency.yaml has no preview section" {
    cd "$TEST_REPO"
    cat > claude/config/agency.yaml <<'YAML'
project:
  name: "test"
YAML
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"docker-compose"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider resolution from agency.yaml
# ─────────────────────────────────────────────────────────────────────────────

@test "preview: reads provider from agency.yaml (quoted)" {
    cd "$TEST_REPO"
    _write_yaml "fly"
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"preview-fly"* ]]
}

@test "preview: reads provider from agency.yaml (unquoted)" {
    cd "$TEST_REPO"
    cat > claude/config/agency.yaml <<'YAML'
preview:
  provider: vercel
YAML
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"preview-vercel"* ]]
}

@test "preview: reads provider with inline comment" {
    cd "$TEST_REPO"
    cat > claude/config/agency.yaml <<'YAML'
preview:
  provider: "cloudflare"  # Default. Alternatives: fly, vercel
YAML
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"preview-cloudflare"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Dispatch to mock provider
# ─────────────────────────────────────────────────────────────────────────────

@test "preview: dispatches to provider tool with no args" {
    cd "$TEST_REPO"
    _write_yaml "test"
    _install_mock_provider "test"
    run ./claude/tools/preview
    [ "$status" -eq 0 ]
    [[ "$output" == *"mock-preview-test invoked with:"* ]]
}

@test "preview: forwards args to provider tool" {
    cd "$TEST_REPO"
    _write_yaml "test"
    _install_mock_provider "test"
    run ./claude/tools/preview start --port 8080
    [ "$status" -eq 0 ]
    [[ "$output" == *"start --port 8080"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Missing provider error
# ─────────────────────────────────────────────────────────────────────────────

@test "preview: missing provider tool returns error with available providers" {
    cd "$TEST_REPO"
    _write_yaml "missing"
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error"* ]]
    [[ "$output" == *"missing"* ]]
}

@test "preview: missing provider lists available alternatives" {
    cd "$TEST_REPO"
    _write_yaml "missing"
    _install_mock_provider "alpha"
    _install_mock_provider "beta"
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"beta"* ]]
}

@test "preview: missing provider points at agency.yaml" {
    cd "$TEST_REPO"
    _write_yaml "missing"
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"agency.yaml"* ]]
    [[ "$output" == *"preview.provider"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Exit code
# ─────────────────────────────────────────────────────────────────────────────

@test "preview: exit 0 on successful dispatch" {
    cd "$TEST_REPO"
    _write_yaml "test"
    _install_mock_provider "test"
    run ./claude/tools/preview
    [ "$status" -eq 0 ]
}

@test "preview: exit 1 on missing provider" {
    cd "$TEST_REPO"
    _write_yaml "missing"
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Security: provider name validation (Cluster A)
# ─────────────────────────────────────────────────────────────────────────────

@test "preview: rejects provider name with path traversal (../)" {
    cd "$TEST_REPO"
    _write_yaml "../../../tmp/evil"
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid provider"* ]] || [[ "$output" == *"invalid"* ]]
}

@test "preview: rejects provider name with slash" {
    cd "$TEST_REPO"
    _write_yaml "foo/bar"
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid provider"* ]] || [[ "$output" == *"invalid"* ]]
}

@test "preview: rejects provider name with shell metacharacters" {
    cd "$TEST_REPO"
    _write_yaml 'foo;rm'
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid provider"* ]] || [[ "$output" == *"invalid"* ]]
}

@test "preview: accepts valid hyphenated provider name" {
    cd "$TEST_REPO"
    _write_yaml "docker-compose"
    _install_mock_provider "docker-compose"
    run ./claude/tools/preview
    [ "$status" -eq 0 ]
    [[ "$output" == *"mock-preview-docker-compose"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Coverage: missing test cases from reviewer-test
# ─────────────────────────────────────────────────────────────────────────────

@test "preview: provider tool exists but not executable → error" {
    cd "$TEST_REPO"
    _write_yaml "broken"
    # Create a file matching the provider name but not executable
    echo '#!/bin/bash' > claude/tools/preview-broken
    # Intentionally NO chmod +x
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"broken"* ]]
}

@test "preview: forwards exit code from provider tool (exec semantics)" {
    cd "$TEST_REPO"
    _write_yaml "test"
    cat > claude/tools/preview-test <<'PROVIDER'
#!/bin/bash
exit 42
PROVIDER
    chmod +x claude/tools/preview-test
    run ./claude/tools/preview
    [ "$status" -eq 42 ]
}

@test "preview: empty provider value falls back to default" {
    cd "$TEST_REPO"
    cat > claude/config/agency.yaml <<'YAML'
preview:
  provider: ""
YAML
    run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"docker-compose"* ]]
}

@test "preview: uses CLAUDE_PROJECT_DIR over git rev-parse" {
    cd "$TEST_REPO"
    # Create an isolated project root with a different config
    local alt="$BATS_TEST_TMPDIR/alt-root"
    mkdir -p "$alt/claude/config"
    cat > "$alt/claude/config/agency.yaml" <<'YAML'
preview:
  provider: "alt-provider"
YAML
    CLAUDE_PROJECT_DIR="$alt" run ./claude/tools/preview
    [ "$status" -eq 1 ]
    [[ "$output" == *"alt-provider"* ]]
}
