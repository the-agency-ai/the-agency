#!/usr/bin/env bash
#
# What Problem: BATS tests need hermetic isolation from the live environment.
# Without it, tests leak flags into the live ISCP DB, corrupt .git/config,
# and leave debris in the working tree. This was the root cause of 62 ghost
# flags and bare=true corruption (dispatches #16, #17).
#
# How & Why: Universal isolation as the default for ALL test files — not just
# ISCP tests. Every setup() gets fake HOME, isolated git config, explicit
# ISCP DB path. Every teardown() checks for .git/config corruption and
# working-tree debris. Opt-out via SKIP_ISOLATION=1 for the rare test that
# needs real environment access. Belt-and-suspenders: env var overrides PLUS
# guards that fail loudly.
#
# Written: 2026-04-07 during DevEx Phase 1.1 (Universal Test Isolation)
# Evolved from: ISCP test isolation helpers (2026-04-06, dispatches #16, #17)
#

# Get the repo root
export REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
export TOOLS_DIR="${REPO_ROOT}/claude/tools"

# Add tools to PATH
export PATH="${TOOLS_DIR}:${PATH}"

# Disable telemetry during tests
export LOG_SERVICE_URL=""

# ─────────────────────────────────────────────────────────────────────────────
# Universal Test Isolation
# ─────────────────────────────────────────────────────────────────────────────

# Call this in setup() — sets up complete isolation: fake HOME, explicit DB
# path, git config isolation. Called automatically by the default setup().
# Files with custom setup() MUST call this explicitly.
test_isolation_setup() {
    # Opt-out escape hatch
    if [[ "${SKIP_ISOLATION:-0}" == "1" ]]; then
        return 0
    fi

    # 0. Clean leaked git env vars (CRITICAL when running inside a pre-commit hook).
    # Without this, BATS tests inherit GIT_DIR/GIT_INDEX_FILE/GIT_WORK_TREE from
    # the parent commit operation. Calls to `git config user.email/name` then
    # write to the OUTER repo's local config, polluting it with [user] section
    # and corrupting commit attribution. This bug authored every commit in the
    # devex session as "Test User <test@test.com>" before the fix.
    unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE
    unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_AUTHOR_DATE
    unset GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_COMMITTER_DATE

    # 1. Isolate HOME (DB path, cache, dotfiles, etc.)
    export ORIGINAL_HOME="${HOME}"
    export HOME="${BATS_TEST_TMPDIR}/fakehome"
    mkdir -p "$HOME"

    # 2. Explicit ISCP DB path — belt-and-suspenders on top of HOME override
    export ISCP_DB_PATH="${BATS_TEST_TMPDIR}/test-iscp.db"

    # 3. Git config isolation — prevent any writes to live .git/config
    export GIT_CONFIG_GLOBAL=/dev/null
    export GIT_CONFIG_SYSTEM=/dev/null

    # 4. Snapshot live .git/config checksum for guard validation
    if [[ -f "$REPO_ROOT/.git/config" ]]; then
        _TEST_GIT_CONFIG_HASH=$(md5 -q "$REPO_ROOT/.git/config" 2>/dev/null || md5sum "$REPO_ROOT/.git/config" 2>/dev/null | awk '{print $1}')
    fi

    # 5. Snapshot key directories for debris detection
    if [[ -d "$REPO_ROOT/claude/agents" ]]; then
        _TEST_AGENTS_SNAPSHOT=$(ls "$REPO_ROOT/claude/agents/" 2>/dev/null | sort)
    fi
    if [[ -d "$REPO_ROOT/.claude/agents" ]]; then
        _TEST_DOT_AGENTS_SNAPSHOT=$(ls "$REPO_ROOT/.claude/agents/" 2>/dev/null | sort)
    fi
}

# Call this in teardown() — fails loudly if live environment was modified.
# Called automatically by the default teardown(). Files with custom
# teardown() MUST call this explicitly.
test_isolation_teardown() {
    # Opt-out escape hatch
    if [[ "${SKIP_ISOLATION:-0}" == "1" ]]; then
        return 0
    fi

    # Guard 1: verify live .git/config wasn't modified
    if [[ -n "${_TEST_GIT_CONFIG_HASH:-}" && -f "$REPO_ROOT/.git/config" ]]; then
        local current_hash
        current_hash=$(md5 -q "$REPO_ROOT/.git/config" 2>/dev/null || md5sum "$REPO_ROOT/.git/config" 2>/dev/null | awk '{print $1}')
        if [[ "$current_hash" != "$_TEST_GIT_CONFIG_HASH" ]]; then
            echo "CRITICAL: BATS test modified live .git/config! Hash before=$_TEST_GIT_CONFIG_HASH after=$current_hash" >&2
            # Specific check: did a [user] section get added? This is the most common
            # pollution vector — tests calling 'git config user.email/name' inside a
            # pre-commit hook context where GIT_DIR points to the outer repo.
            if grep -q "^\[user\]" "$REPO_ROOT/.git/config" 2>/dev/null; then
                echo "  → [user] section found in live .git/config — test polluted commit attribution" >&2
            fi
            return 1
        fi
    fi

    # Guard 2: verify no debris in key directories
    if [[ -n "${_TEST_AGENTS_SNAPSHOT:-}" && -d "$REPO_ROOT/claude/agents" ]]; then
        local current_agents
        current_agents=$(ls "$REPO_ROOT/claude/agents/" 2>/dev/null | sort)
        if [[ "$current_agents" != "$_TEST_AGENTS_SNAPSHOT" ]]; then
            echo "CRITICAL: BATS test left debris in claude/agents/! Before: $_TEST_AGENTS_SNAPSHOT After: $current_agents" >&2
            return 1
        fi
    fi
    if [[ -n "${_TEST_DOT_AGENTS_SNAPSHOT:-}" && -d "$REPO_ROOT/.claude/agents" ]]; then
        local current_dot_agents
        current_dot_agents=$(ls "$REPO_ROOT/.claude/agents/" 2>/dev/null | sort)
        if [[ "$current_dot_agents" != "$_TEST_DOT_AGENTS_SNAPSHOT" ]]; then
            echo "CRITICAL: BATS test left debris in .claude/agents/! Before: $_TEST_DOT_AGENTS_SNAPSHOT After: $current_dot_agents" >&2
            return 1
        fi
    fi

    # Guard 3: verify live ISCP DB wasn't touched
    # (HOME was overridden, so the real home's DB should be untouched.
    # ISCP_DB_PATH override provides belt-and-suspenders protection.)
}

# Backward-compatible aliases for ISCP test files
iscp_test_isolation_setup() { test_isolation_setup; }
iscp_test_isolation_teardown() { test_isolation_teardown; }

# ─────────────────────────────────────────────────────────────────────────────
# Default setup/teardown — calls isolation automatically
# ─────────────────────────────────────────────────────────────────────────────

# Common setup — files with custom setup() override this entirely,
# so they MUST call test_isolation_setup themselves.
setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup
    cd "${REPO_ROOT}"
}

# Common teardown — files with custom teardown() override this entirely,
# so they MUST call test_isolation_teardown themselves.
teardown() {
    test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Helper functions
# ─────────────────────────────────────────────────────────────────────────────

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
