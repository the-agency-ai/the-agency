#!/bin/bash
#
# What Problem: Running BATS tests directly on the host risks leaking into the
# live environment (DB, git config, working tree). We need a one-command way to
# run all tests in complete Docker isolation.
#
# How & Why: Builds a Docker image with bats/sqlite/git/jq, mounts the repo
# read-only, and runs tests inside the container. The container's filesystem
# is completely separate — no HOME, .git/config, or DB leakage possible.
# The repo is mounted read-only so tests can't even accidentally modify it.
# Supports --iscp-only for backward compat, --file for single-file runs,
# and defaults to all BATS files for full-suite T3 runs.
#
# Usage:
#   ./src/tests/docker-test.sh                         # run ALL test files (T3)
#   ./src/tests/docker-test.sh --iscp-only             # run only ISCP tests
#   ./src/tests/docker-test.sh --file src/tests/tools/flag.bats  # run specific file
#   ./src/tests/docker-test.sh src/tests/tools/flag.bats   # positional arg (legacy)
#
# Written: 2026-04-06 — Docker test isolation (dispatches #16, #17)
# Updated: 2026-04-07 — Phase 2.1: extend to all BATS files, add --iscp-only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

IMAGE_NAME="the-agency-tests"
IMAGE_TAG="full"

# Heal Docker reachability before any docker command. On macOS, Docker Desktop
# exposes its socket at $HOME/.docker/run/docker.sock rather than the default
# /var/run/docker.sock — without this, the CLI fails with "dial unix ...: no
# such file or directory" even though Docker Desktop is running. See GH #58
# and agency/tools/lib/_docker-heal for the full remediation logic.
#
# docker_heal returns 0 if docker is reachable (either already or after
# setting DOCKER_HOST) and 1 with an actionable error. We check the exit
# explicitly so the error message comes through cleanly.
source "$REPO_ROOT/agency/tools/lib/_docker-heal"
if ! docker_heal; then
    exit 1
fi

# ISCP-only test files (original 7)
ISCP_FILES=(
    src/tests/tools/iscp-db.bats
    src/tests/tools/agent-identity.bats
    src/tests/tools/dispatch-create.bats
    src/tests/tools/dispatch.bats
    src/tests/tools/flag.bats
    src/tests/tools/iscp-check.bats
    src/tests/tools/iscp-migrate.bats
)

# Parse arguments
ISCP_ONLY=false
FILE_ARG=""
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --iscp-only)
            ISCP_ONLY=true
            shift
            ;;
        --file)
            FILE_ARG="$2"
            shift 2
            ;;
        --help|-h)
            sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Determine which tests to run
if [[ -n "$FILE_ARG" ]]; then
    TEST_ARGS=("$FILE_ARG")
elif [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
    TEST_ARGS=("${POSITIONAL_ARGS[@]}")
elif [[ "$ISCP_ONLY" == "true" ]]; then
    TEST_ARGS=("${ISCP_FILES[@]}")
else
    # Default: all BATS test files (T3 full suite)
    TEST_ARGS=()
    while IFS= read -r f; do
        TEST_ARGS+=("$f")
    done < <(find src/tests/tools -name '*.bats' -type f | sort)
fi

TEST_COUNT=${#TEST_ARGS[@]}

# Build the test image (cached after first build)
echo "Building test image..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" "$SCRIPT_DIR" --quiet

echo "Running $TEST_COUNT test file(s) in Docker container..."
echo "──────────────────────────────────────"

# Run tests in container:
# - Mount repo read-only at /repo
# - Set REPO_ROOT so test_helper.bash can find tools
# - Run as testrunner user (non-root)
# - --rm: clean up container after run
docker run --rm \
    -v "${REPO_ROOT}:/repo:ro" \
    -e REPO_ROOT=/repo \
    -w /repo \
    "${IMAGE_NAME}:${IMAGE_TAG}" \
    "${TEST_ARGS[@]}"

echo "──────────────────────────────────────"
echo "Tests complete ($TEST_COUNT files). Container destroyed. Zero host contamination."
