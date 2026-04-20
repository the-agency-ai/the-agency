#!/usr/bin/env bats
#
# Tests for ./agency/tools/deploy — SPEC-PROVIDER wrapper
#
# Tests provider resolution from agency.yaml, default fallback, exec dispatch
# to provider tool, and the missing-provider error path.
#
# Mirrors the structure of tests/tools/preview.bats and tests/tools/secret.bats
# but tests don't depend on any deploy-* provider tool existing — we mock one
# in BATS_TEST_TMPDIR.
#
# Written: 2026-04-07 — Day 33 — Item 1 from captain's Day 33 work queue

load test_helper

setup() {
    test_isolation_setup

    export TEST_REPO="${BATS_TEST_TMPDIR}/test-project"
    mkdir -p "$TEST_REPO/claude/tools" "$TEST_REPO/claude/config"
    cd "$TEST_REPO"
    git init --quiet

    cp "${REPO_ROOT}/agency/tools/deploy" "$TEST_REPO/agency/tools/"
    chmod +x "$TEST_REPO/agency/tools/deploy"
}

teardown() {
    test_isolation_teardown
}

_write_yaml() {
    local provider="$1"
    cat > "$TEST_REPO/agency/config/agency.yaml" <<YAML
deploy:
  provider: "${provider}"
YAML
}

_install_mock_provider() {
    local name="$1"
    cat > "$TEST_REPO/agency/tools/deploy-$name" <<'PROVIDER'
#!/bin/bash
echo "mock-deploy-$(basename "$0" | sed 's/deploy-//') invoked with: $*"
exit 0
PROVIDER
    chmod +x "$TEST_REPO/agency/tools/deploy-$name"
}

# ─────────────────────────────────────────────────────────────────────────────
# Default provider when no agency.yaml
# ─────────────────────────────────────────────────────────────────────────────

@test "deploy: defaults to fly when no agency.yaml" {
    cd "$TEST_REPO"
    rm -f agency/config/agency.yaml
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"fly"* ]]
}

@test "deploy: defaults to fly when agency.yaml has no deploy section" {
    cd "$TEST_REPO"
    cat > agency/config/agency.yaml <<'YAML'
project:
  name: "test"
YAML
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"fly"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Provider resolution from agency.yaml
# ─────────────────────────────────────────────────────────────────────────────

@test "deploy: reads provider from agency.yaml (quoted)" {
    cd "$TEST_REPO"
    _write_yaml "vercel"
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"deploy-vercel"* ]]
}

@test "deploy: reads provider from agency.yaml (unquoted)" {
    cd "$TEST_REPO"
    cat > agency/config/agency.yaml <<'YAML'
deploy:
  provider: aws
YAML
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"deploy-aws"* ]]
}

@test "deploy: reads provider with inline comment" {
    cd "$TEST_REPO"
    cat > agency/config/agency.yaml <<'YAML'
deploy:
  provider: "railway"  # Default. Alternatives: fly, vercel, aws
YAML
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"deploy-railway"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Dispatch to mock provider
# ─────────────────────────────────────────────────────────────────────────────

@test "deploy: dispatches to provider tool with no args" {
    cd "$TEST_REPO"
    _write_yaml "test"
    _install_mock_provider "test"
    run ./agency/tools/deploy
    [ "$status" -eq 0 ]
    [[ "$output" == *"mock-deploy-test invoked with:"* ]]
}

@test "deploy: forwards args to provider tool" {
    cd "$TEST_REPO"
    _write_yaml "test"
    _install_mock_provider "test"
    run ./agency/tools/deploy deploy --env staging
    [ "$status" -eq 0 ]
    [[ "$output" == *"deploy --env staging"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Missing provider error
# ─────────────────────────────────────────────────────────────────────────────

@test "deploy: missing provider tool returns error" {
    cd "$TEST_REPO"
    _write_yaml "missing"
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error"* ]]
    [[ "$output" == *"missing"* ]]
}

@test "deploy: missing provider lists available alternatives" {
    cd "$TEST_REPO"
    _write_yaml "missing"
    _install_mock_provider "alpha"
    _install_mock_provider "beta"
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"beta"* ]]
}

@test "deploy: missing provider points at agency.yaml" {
    cd "$TEST_REPO"
    _write_yaml "missing"
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"agency.yaml"* ]]
    [[ "$output" == *"deploy.provider"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Exit code
# ─────────────────────────────────────────────────────────────────────────────

@test "deploy: exit 0 on successful dispatch" {
    cd "$TEST_REPO"
    _write_yaml "test"
    _install_mock_provider "test"
    run ./agency/tools/deploy
    [ "$status" -eq 0 ]
}

@test "deploy: exit 1 on missing provider" {
    cd "$TEST_REPO"
    _write_yaml "missing"
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Security: provider name validation (Cluster A)
# ─────────────────────────────────────────────────────────────────────────────

@test "deploy: rejects provider name with path traversal (../)" {
    cd "$TEST_REPO"
    _write_yaml "../../../tmp/evil"
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid provider"* ]] || [[ "$output" == *"invalid"* ]]
}

@test "deploy: rejects provider name with slash" {
    cd "$TEST_REPO"
    _write_yaml "foo/bar"
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid provider"* ]] || [[ "$output" == *"invalid"* ]]
}

@test "deploy: rejects provider name with shell metacharacters" {
    cd "$TEST_REPO"
    _write_yaml 'foo;rm'
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid provider"* ]] || [[ "$output" == *"invalid"* ]]
}

@test "deploy: accepts valid hyphenated provider name" {
    cd "$TEST_REPO"
    _write_yaml "fly-io"
    _install_mock_provider "fly-io"
    run ./agency/tools/deploy
    [ "$status" -eq 0 ]
    [[ "$output" == *"mock-deploy-fly-io"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Coverage: missing test cases from reviewer-test
# ─────────────────────────────────────────────────────────────────────────────

@test "deploy: provider tool exists but not executable → error" {
    cd "$TEST_REPO"
    _write_yaml "broken"
    echo '#!/bin/bash' > agency/tools/deploy-broken
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"broken"* ]]
}

@test "deploy: forwards exit code from provider tool (exec semantics)" {
    cd "$TEST_REPO"
    _write_yaml "test"
    cat > agency/tools/deploy-test <<'PROVIDER'
#!/bin/bash
exit 42
PROVIDER
    chmod +x agency/tools/deploy-test
    run ./agency/tools/deploy
    [ "$status" -eq 42 ]
}

@test "deploy: empty provider value falls back to default" {
    cd "$TEST_REPO"
    cat > agency/config/agency.yaml <<'YAML'
deploy:
  provider: ""
YAML
    run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"fly"* ]]
}

@test "deploy: uses CLAUDE_PROJECT_DIR over git rev-parse" {
    cd "$TEST_REPO"
    local alt="$BATS_TEST_TMPDIR/alt-root"
    mkdir -p "$alt/claude/config"
    cat > "$alt/agency/config/agency.yaml" <<'YAML'
deploy:
  provider: "alt-provider"
YAML
    CLAUDE_PROJECT_DIR="$alt" run ./agency/tools/deploy
    [ "$status" -eq 1 ]
    [[ "$output" == *"alt-provider"* ]]
}
