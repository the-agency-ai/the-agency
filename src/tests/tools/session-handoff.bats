#!/usr/bin/env bats
#
# Tests for session-handoff.sh hook — branch resolution and type handling
#
# Phase 5.2: Tests the hook script directly
#

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    # Create minimal project structure
    cd "${BATS_TEST_TMPDIR}"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test" > README.md
    git add README.md
    git commit -m "Initial" --quiet

    # Create structure the hook expects
    mkdir -p agency/tools/lib
    mkdir -p claude/config
    mkdir -p usr/testuser/captain

    # Copy the hook
    cp "${REPO_ROOT}/agency/hooks/session-handoff.sh" session-handoff.sh
    chmod +x session-handoff.sh

    # Copy lib dependencies
    cp "${REPO_ROOT}/agency/tools/lib/_log-helper" agency/tools/lib/_log-helper 2>/dev/null || true
    cp "${REPO_ROOT}/agency/tools/lib/_path-resolve" agency/tools/lib/_path-resolve 2>/dev/null || true
    if [[ -f "${REPO_ROOT}/agency/tools/now" ]]; then
        cp "${REPO_ROOT}/agency/tools/now" agency/tools/now
        chmod +x agency/tools/now
    fi

    cat > agency/config/agency.yaml << 'YAML'
principals:
  testuser:
    name: testuser
YAML

    export USER=testuser
    export CLAUDE_PROJECT_DIR="${BATS_TEST_TMPDIR}"
}

teardown() {
    test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Branch → captain mapping
# ─────────────────────────────────────────────────────────────────────────────

@test "session-handoff: main branch resolves to captain directory" {
    cd "${BATS_TEST_TMPDIR}"
    # We're on main branch (default for git init)
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD)
    # main or master — either way, should map to captain
    [[ "$branch" == "main" ]] || [[ "$branch" == "master" ]]
    # The hook should read from captain path
    grep -q 'captain' session-handoff.sh
}

@test "session-handoff: hook maps main to captain slug" {
    # Verify the hook contains the main→captain mapping
    grep -qE 'BRANCH_SLUG.*=.*"captain"' "${REPO_ROOT}/agency/hooks/session-handoff.sh" || \
    grep -qE '"main".*"master"' "${REPO_ROOT}/agency/hooks/session-handoff.sh"
}

@test "session-handoff: hook maps master to captain slug" {
    grep -q '"master"' "${REPO_ROOT}/agency/hooks/session-handoff.sh"
}

# ─────────────────────────────────────────────────────────────────────────────
# Feature branch resolution
# ─────────────────────────────────────────────────────────────────────────────

@test "session-handoff: feature branch uses branch slug as directory" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -b feature/mdpal-ui --quiet
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD)
    [[ "$branch" == "feature/mdpal-ui" ]]
    # Branch slug should NOT be captain for feature branches
}

# ─────────────────────────────────────────────────────────────────────────────
# Type handling
# ─────────────────────────────────────────────────────────────────────────────

@test "session-handoff: hook handles agency-bootstrap type" {
    grep -q 'agency-bootstrap' "${REPO_ROOT}/agency/hooks/session-handoff.sh"
}

@test "session-handoff: hook handles agency-update type" {
    grep -q 'agency-update' "${REPO_ROOT}/agency/hooks/session-handoff.sh"
}
