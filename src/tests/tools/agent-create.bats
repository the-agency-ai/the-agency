#!/usr/bin/env bats
#
# Tests for agent-create — workspace scaffolding, registration, bootstrap handoffs
#
# Phase 5.1: Tests from Agent Workspace & Bootstrap Quality plan
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Fixture setup — create a valid project structure for agent-create
# ─────────────────────────────────────────────────────────────────────────────

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    # Create a mock git repo with agency structure
    cd "${BATS_TEST_TMPDIR}"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Minimal agency structure
    mkdir -p agency/tools/lib
    mkdir -p agency/agents/templates/generic
    mkdir -p agency/workstreams/testws
    mkdir -p claude/config
    mkdir -p .claude/agents
    mkdir -p usr/testuser

    # Copy tools we need
    cp "${REPO_ROOT}/agency/tools/agent-create" agency/tools/agent-create
    chmod +x agency/tools/agent-create
    cp "${REPO_ROOT}/agency/tools/lib/_log-helper" agency/tools/lib/_log-helper 2>/dev/null || true
    cp "${REPO_ROOT}/agency/tools/lib/_path-resolve" agency/tools/lib/_path-resolve 2>/dev/null || true

    # Copy now tool if it exists
    if [[ -f "${REPO_ROOT}/agency/tools/now" ]]; then
        cp "${REPO_ROOT}/agency/tools/now" agency/tools/now
        chmod +x agency/tools/now
    fi

    # Copy agent template
    cp -r "${REPO_ROOT}/agency/agents/templates/generic/." agency/agents/templates/generic/

    # Minimal agency.yaml
    cat > agency/config/agency.yaml << 'YAML'
principals:
  testuser:
    name: testuser
YAML

    # Initial commit
    git add -A
    git commit -m "Initial fixture" --quiet

    export USER=testuser
}

teardown() {
    test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Workspace scaffolding (Plan 5.1)
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-create: scaffolds tools/ in principal sandbox" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/agent-create testagent testws
    assert_success
    [[ -d "usr/testuser/testagent/tools" ]]
}

@test "agent-create: scaffolds tmp/ with .gitignore" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/agent-create testagent testws
    assert_success
    [[ -d "usr/testuser/testagent/tmp" ]]
    [[ -f "usr/testuser/testagent/tmp/.gitignore" ]]
    grep -q '^\*$' "usr/testuser/testagent/tmp/.gitignore"
    grep -q '!\.gitignore' "usr/testuser/testagent/tmp/.gitignore"
}

@test "agent-create: writes bootstrap handoff with TODO placeholders" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/agent-create testagent testws
    assert_success
    [[ -f "usr/testuser/testagent/testagent-handoff.md" ]]
    grep -q "TODO:" "usr/testuser/testagent/testagent-handoff.md"
}

@test "agent-create: bootstrap handoff has required frontmatter" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/agent-create testagent testws
    assert_success
    local handoff="usr/testuser/testagent/testagent-handoff.md"
    grep -q "type: agency-bootstrap" "$handoff"
    grep -q "principal:" "$handoff"
    grep -q "agent:" "$handoff"
    grep -q "workstream: testws" "$handoff"
}

# ─────────────────────────────────────────────────────────────────────────────
# Registration template (Plan 5.1)
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-create: registration at principal-scoped path — D42-R3" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/agent-create testagent testws
    assert_success
    local reg=".claude/agents/testuser/testagent.md"
    [[ -f "$reg" ]]
    grep -q "On startup, immediately do" "$reg"
    grep -q "handoff" "$reg"
    grep -q "dispatch list" "$reg"
}

@test "agent-create: registration uses @import pattern — D42-R3" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/agent-create testagent testws
    assert_success
    local reg=".claude/agents/testuser/testagent.md"
    # Structural @import for class doc and workstream CLAUDE
    grep -q "@agency/agents/" "$reg"
    grep -q "@agency/workstreams/testws/" "$reg"
    grep -q "@usr/testuser/" "$reg"
}

@test "agent-create: registration contains TODO guard" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/agent-create testagent testws
    assert_success
    grep -q "TODO:" ".claude/agents/testuser/testagent.md"
    grep -q "Bootstrap handoff incomplete" ".claude/agents/testuser/testagent.md"
}

@test "agent-create: registration contains act-on-startup directive" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/agent-create testagent testws
    assert_success
    grep -q "Do not wait for a prompt" ".claude/agents/testuser/testagent.md"
}

# ─────────────────────────────────────────────────────────────────────────────
# Name validation (Plan 5.1, MAR T1)
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-create: rejects name over 32 characters" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/agent-create abcdefghijklmnopqrstuvwxyz1234567 testws
    assert_failure
}

@test "agent-create: rejects uppercase name" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/agent-create TestAgent testws
    assert_failure
}

@test "agent-create: rejects path traversal name" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/agent-create '../evil' testws
    assert_failure
    [[ ! -d "../evil" ]]
}

@test "agent-create: rejects name with special characters" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/agent-create 'test$agent' testws
    assert_failure
}

# ─────────────────────────────────────────────────────────────────────────────
# No stale paths (Plan 5.1)
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-create: no claude/principals/ references in tool" {
    ! grep -q 'claude/principals' "${REPO_ROOT}/agency/tools/agent-create"
}

@test "agent-create: no myclaude references in tool" {
    ! grep -q 'myclaude' "${REPO_ROOT}/agency/tools/agent-create"
}
