#!/usr/bin/env bash
#
# What Problem: BATS tests need hermetic isolation from the live environment.
# Without it, tests leak flags into the live ISCP DB, corrupt .git/config,
# and leave debris in the working tree. This was the root cause of 62 ghost
# flags and bare=true corruption (dispatches #16, #17) and the recurring
# Test User attribution bug (dispatches #109, #171).
#
# How & Why: Thin wrapper around the framework lib at
# claude/tools/lib/_test-isolation. The actual isolation helpers live there
# so `agency update` propagates them to every consuming project (monofolk,
# etc.) — they no longer live only in the-agency's tests/ directory. This
# file only computes REPO_ROOT (the-agency-specific) and sources the lib.
#
# Adopter projects: create your own tests/test_helper.bash that sources
# the same lib — see claude/templates/tests/test_helper.bash.
#
# Written: 2026-04-07 during DevEx Phase 1.1 (Universal Test Isolation)
# Refactored: 2026-04-09 — extract helpers to claude/tools/lib/_test-isolation
#             for adopter propagation via agency update
# Evolved from: ISCP test isolation helpers (2026-04-06, dispatches #16, #17)
#

# Get the repo root. Tests are at src/tests/tools/*.bats; BATS_TEST_DIRNAME
# resolves to src/tests/tools, so ../../.. is the repo root.
export REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"

# Source the framework lib — all isolation helpers (test_isolation_setup,
# test_isolation_teardown, SKIP_ISOLATION handling, iscp_* backward-compat
# aliases) live there. The lib also sets TOOLS_DIR, LOG_SERVICE_URL="",
# and adds $TOOLS_DIR to PATH.
source "${REPO_ROOT}/agency/tools/lib/_test-isolation"

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

# Helper: Install git-safe + git-safe-commit suite into the current BATS
# test dir (PWD) for hermetic BATS of those tools. Covers D-6: previously
# duplicated between git-safe-commit-merge.bats and git-safe-commit-210.bats.
#
# Caller precondition: PWD is the test repo, git init has run, user/email
# configured, an initial commit exists (or is about to be made).
#
# Effects:
#   - Installs agency/tools/{git-safe,git-safe-commit} + lib deps
#   - Installs stub agency/tools/{dispatch,agent-identity} when
#     INSTALL_DISPATCH_STUBS=yes (writes invocation marker to
#     $BATS_TEST_TMPDIR/dispatch-stub-invocations/calls.log)
#   - Disables repo-local core.hooksPath so the real pre-commit hook
#     doesn't fire during tests (T8: uses empty-string, more portable)
#
# Usage:
#   install_git_safe_commit_suite
#   install_git_safe_commit_suite --with-dispatch-stubs
install_git_safe_commit_suite() {
    local with_stubs="no"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --with-dispatch-stubs) with_stubs="yes"; shift ;;
            *) echo "install_git_safe_commit_suite: unknown arg: $1" >&2; return 2 ;;
        esac
    done

    mkdir -p agency/tools/lib
    for t in git-safe git-safe-commit; do
        cp "${REPO_ROOT}/agency/tools/$t" "agency/tools/$t"
        chmod +x "agency/tools/$t"
    done
    for lib in _log-helper _colors; do
        cp "${REPO_ROOT}/agency/tools/lib/$lib" "agency/tools/lib/$lib" 2>/dev/null || true
    done

    if [[ "$with_stubs" == "yes" ]]; then
        # Dispatch stub: record each invocation to a marker file so tests
        # can assert "dispatch ran" vs "guard fired and skipped dispatch".
        cat > agency/tools/dispatch <<'STUB'
#!/usr/bin/env bash
marker_dir="${BATS_TEST_TMPDIR}/dispatch-stub-invocations"
mkdir -p "$marker_dir"
printf '%s\n' "$*" >> "$marker_dir/calls.log"
echo "stub dispatch invoked: $*" >&2
exit 0
STUB
        chmod +x agency/tools/dispatch

        cat > agency/tools/agent-identity <<'STUB'
#!/usr/bin/env bash
echo "the-agency/jordan/testagent"
STUB
        chmod +x agency/tools/agent-identity
    fi

    # T8: disable pre-commit hook via empty-string (portable across git versions).
    git config --local core.hooksPath "" 2>/dev/null || true
}
