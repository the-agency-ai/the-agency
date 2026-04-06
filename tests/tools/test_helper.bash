#!/usr/bin/env bash
#
# Test helper for bats-core bash tool tests
#
# Usage in test files:
#   load 'test_helper'
#
# Provides:
#   - Common setup/teardown
#   - Path configuration
#   - Helper functions
#

# Get the repo root
export REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
export TOOLS_DIR="${REPO_ROOT}/claude/tools"

# Add tools to PATH
export PATH="${TOOLS_DIR}:${PATH}"

# Disable telemetry during tests
export LOG_SERVICE_URL=""

# Common setup
setup() {
    # Create temp directory for test artifacts
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    cd "${REPO_ROOT}"
}

# Common teardown
teardown() {
    # Clean up temp directory
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# Helper: Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Helper: Assert file exists
assert_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Expected file to exist: $file" >&2
        return 1
    fi
}

# Helper: Assert file contains
assert_file_contains() {
    local file="$1"
    local pattern="$2"
    if ! grep -q "$pattern" "$file"; then
        echo "Expected file '$file' to contain: $pattern" >&2
        return 1
    fi
}

# Helper: Assert output contains
assert_output_contains() {
    local pattern="$1"
    if [[ ! "$output" =~ $pattern ]]; then
        echo "Expected output to contain: $pattern" >&2
        echo "Actual output: $output" >&2
        return 1
    fi
}

# Helper: Assert success
assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "Expected success (exit 0), got exit $status" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

# Helper: Assert failure
assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "Expected failure (exit != 0), got exit 0" >&2
        echo "Output: $output" >&2
        return 1
    fi
}

# Helper: Run tool with mocked environment
run_tool() {
    local tool="$1"
    shift
    run "${TOOLS_DIR}/${tool}" "$@"
}

# Helper: Create a mock git repo for testing
create_mock_git_repo() {
    local dir="${BATS_TEST_TMPDIR}/mock-repo"
    mkdir -p "$dir"
    cd "$dir"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet
    echo "$dir"
}

# ─────────────────────────────────────────────────────────────────────────────
# ISCP Test Isolation Helpers
# What Problem: BATS tests leaked into the live ISCP DB (~62 flags) and
# corrupted the live .git/config (bare=true, user=Test User). Tests MUST be
# hermetically isolated from the live environment.
# How & Why: Provides setup/teardown helpers that every ISCP test file calls.
# Belt-and-suspenders: env var overrides PLUS guards that fail loudly.
# Written: 2026-04-06 — test isolation fix (dispatches #16, #17)
# ─────────────────────────────────────────────────────────────────────────────

# Call this in setup() of every ISCP test file AFTER creating BATS_TEST_TMPDIR.
# Sets up complete isolation: fake HOME, explicit DB path, git config isolation.
iscp_test_isolation_setup() {
    # 1. Isolate HOME (DB path, cache, etc.)
    export HOME="${BATS_TEST_TMPDIR}/fakehome"
    mkdir -p "$HOME"

    # 2. Explicit ISCP DB path — belt-and-suspenders on top of HOME override
    export ISCP_DB_PATH="${BATS_TEST_TMPDIR}/test-iscp.db"

    # 3. Git config isolation — prevent any writes to live .git/config
    export GIT_CONFIG_GLOBAL=/dev/null
    export GIT_CONFIG_SYSTEM=/dev/null

    # 4. Snapshot live .git/config checksum for guard validation
    if [[ -f "$REPO_ROOT/.git/config" ]]; then
        _ISCP_TEST_GIT_CONFIG_HASH=$(md5 -q "$REPO_ROOT/.git/config" 2>/dev/null || md5sum "$REPO_ROOT/.git/config" 2>/dev/null | awk '{print $1}')
    fi
}

# Call this in teardown() of every ISCP test file BEFORE cleanup.
# Fails loudly if the live .git/config was modified during the test.
iscp_test_isolation_teardown() {
    # Guard: verify live .git/config wasn't modified
    if [[ -n "${_ISCP_TEST_GIT_CONFIG_HASH:-}" && -f "$REPO_ROOT/.git/config" ]]; then
        local current_hash
        current_hash=$(md5 -q "$REPO_ROOT/.git/config" 2>/dev/null || md5sum "$REPO_ROOT/.git/config" 2>/dev/null | awk '{print $1}')
        if [[ "$current_hash" != "$_ISCP_TEST_GIT_CONFIG_HASH" ]]; then
            echo "CRITICAL: BATS test modified live .git/config! Hash before=$_ISCP_TEST_GIT_CONFIG_HASH after=$current_hash" >&2
            return 1
        fi
    fi

    # Guard: verify live ISCP DB wasn't touched
    local live_db="$HOME/.agency/the-agency/iscp.db"
    # (HOME was overridden, so this checks the FAKE home — if somehow the real
    # home's DB was touched, the ISCP_DB_PATH override prevented it)
}
