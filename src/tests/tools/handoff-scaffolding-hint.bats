#!/usr/bin/env bats
#
# What Problem: `handoff read` silently printed "No handoff found" with no
# onboarding signal for fresh installs (issue #280). Agents had no hint
# about how to create one.
#
# How & Why: `handoff read` should emit a scaffolding hint on the missing
# handoff path — suggesting the `handoff write` command and showing the
# expected path.
#
# Written: 2026-04-22 — issue #280 fix

load 'test_helper'

# The tool resolves its handoff path from CLAUDE_PROJECT_DIR (or the git root)
# plus the resolved principal sandbox — NOT from HOME. Overriding HOME alone
# (the old approach) left it resolving against the real repo, where
# usr/jordan/captain/captain-handoff.md exists, so `read` exited 0 and the
# no-handoff path was never exercised. Isolate with a mock repo that has a
# principal sandbox directory but no handoff file, and point the tool at it.
setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    export MOCK_REPO="${BATS_TEST_TMPDIR}/mock-repo"
    mkdir -p "${MOCK_REPO}/usr/jordan/captain"
    cd "${MOCK_REPO}"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "readme" > README.md
    git add -A
    git commit -m "init" --quiet

    # The tool honors CLAUDE_PROJECT_DIR for path resolution — point it at the
    # empty mock so the handoff file is genuinely absent.
    export CLAUDE_PROJECT_DIR="${MOCK_REPO}"
}

teardown() {
    test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

@test "handoff read: shows scaffolding hint when no handoff exists" {
    run "${TOOLS_DIR}/handoff" read
    # Expected: non-zero exit and stderr contains a hint
    [ "$status" -ne 0 ]
    # Combined output (stdout+stderr) should mention `write` as the remedy
    [[ "$output" == *"write"* ]]
}

@test "handoff read: hint includes the path" {
    run "${TOOLS_DIR}/handoff" read
    [ "$status" -ne 0 ]
    [[ "$output" == *"Path:"* ]] || [[ "$output" == *"path"* ]] || [[ "$output" == *"handoff"* ]]
}
