#!/usr/bin/env bash
# Test helper for Agency-managed projects
# Sources the framework test isolation library for BATS tests
#
# What Problem: BATS tests can pollute git config, HOME, and ISCP state
# unless they run in an isolated environment. Every adopter needs the same
# isolation boilerplate.
#
# How & Why: Thin shim that sources the framework _test-isolation library
# (test_isolation_setup / test_isolation_teardown). Installed by agency init;
# safe to customise — init will not overwrite an existing copy.
#
# Written: 2026-04-14 during devex task #16

# Find the repo root
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"

# Source the framework test isolation library
if [[ -f "$REPO_ROOT/claude/tools/lib/_test-isolation" ]]; then
    source "$REPO_ROOT/claude/tools/lib/_test-isolation"
else
    echo "WARNING: _test-isolation not found at $REPO_ROOT/claude/tools/lib/_test-isolation" >&2
    echo "Run 'agency update' to install framework test infrastructure" >&2
fi

# Source bats-support and bats-assert if available
if [[ -d "$REPO_ROOT/tests/test_helper" ]]; then
    load "$REPO_ROOT/tests/test_helper/bats-support/load"
    load "$REPO_ROOT/tests/test_helper/bats-assert/load"
fi
