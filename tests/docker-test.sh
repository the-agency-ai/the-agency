#!/bin/bash
#
# What Problem: Running BATS tests directly on the host leaks into the live
# environment (DB, git config). We need a one-command way to run all ISCP
# tests in complete isolation.
#
# How & Why: Builds a Docker image with bats/sqlite/git/jq, mounts the repo
# read-only, and runs tests inside the container. The container's filesystem
# is completely separate — no HOME, .git/config, or DB leakage possible.
# The repo is mounted read-only so tests can't even accidentally modify it.
#
# Usage:
#   ./tests/docker-test.sh                    # run all ISCP tests
#   ./tests/docker-test.sh tests/tools/flag.bats  # run specific test file
#
# Written: 2026-04-06 — Docker test isolation (dispatches #16, #17)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

IMAGE_NAME="the-agency-tests"
IMAGE_TAG="iscp"

# Build the test image (cached after first build)
echo "Building test image..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" "$SCRIPT_DIR" --quiet

# Determine which tests to run
if [[ $# -gt 0 ]]; then
    TEST_ARGS=("$@")
else
    # Default: all ISCP test files
    TEST_ARGS=(
        tests/tools/iscp-db.bats
        tests/tools/agent-identity.bats
        tests/tools/dispatch-create.bats
        tests/tools/dispatch.bats
        tests/tools/flag.bats
        tests/tools/iscp-check.bats
        tests/tools/iscp-migrate.bats
    )
fi

echo "Running tests in Docker container..."
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
echo "Tests complete. Container destroyed. Zero host contamination."
