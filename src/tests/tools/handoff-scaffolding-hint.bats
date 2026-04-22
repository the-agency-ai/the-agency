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

@test "handoff read: shows scaffolding hint when no handoff exists" {
    # Move HOME to ensure no handoff file exists
    HOME="${BATS_TEST_TMPDIR}/fake-home" run "${TOOLS_DIR}/handoff" read
    # Expected: non-zero exit and stderr contains a hint
    [ "$status" -ne 0 ]
    # Combined output (stdout+stderr) should mention `write` as the remedy
    [[ "$output" == *"write"* ]]
}

@test "handoff read: hint includes the path" {
    HOME="${BATS_TEST_TMPDIR}/fake-home" run "${TOOLS_DIR}/handoff" read
    [ "$status" -ne 0 ]
    [[ "$output" == *"Path:"* ]] || [[ "$output" == *"path"* ]] || [[ "$output" == *"handoff"* ]]
}
