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
export TOOLS_DIR="${REPO_ROOT}/tools"

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
