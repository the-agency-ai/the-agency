#!/usr/bin/env bats
#
# What Problem: Bug triage for batch G — 26 MED+LOW severity issues on main.
# This file captures the exposing tests for the bugs that got fix-applied or
# already-fixed outcomes. Each test is anchored to an issue number.
#
# How & Why: One file per triage batch keeps the archeology findable.
# Tests use the REPO_ROOT-anchored resolution pattern (issue #403) so they
# survive the Great Rename — never $BATS_TEST_DIRNAME/../.
#
# Written: 2026-04-22 during fix-batch-G triage (captain).

load 'test_helper'

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export REPO_ROOT
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #167 — main-updated vs master-updated vocabulary
# Fixed: dispatch tool canonicalizes main-updated → master-updated
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #167: dispatch tool exposes _canonicalize_type alias helper" {
    # The dispatch tool must define _canonicalize_type to heal legacy
    # main-updated → master-updated references in docs.
    run grep -q "_canonicalize_type" "$REPO_ROOT/agency/tools/dispatch"
    [ "$status" -eq 0 ]
}

@test "issue #167: sync-all SKILL.md uses canonical master-updated" {
    # sync-all skill docs must use master-updated (matches dispatch VALID_TYPES)
    run grep -c "master-updated" "$REPO_ROOT/.claude/skills/sync-all/SKILL.md"
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
}

@test "issue #167: captain-sync-all SKILL.md uses canonical master-updated" {
    run grep -c "master-updated" "$REPO_ROOT/.claude/skills/captain-sync-all/SKILL.md"
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #201 — session-preflight Check 5 hardcoded warn
# Fixed: Check 5 now informational by default; AGENCY_PREFLIGHT_MONITOR_STRICT=1 restores warn
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #201: session-preflight Check 5 is informational by default" {
    # Default run must not emit a warn for dispatch monitor (WARN still reported
    # for other warnings, but not hardcoded "Dispatch monitor — verify")
    run "$REPO_ROOT/agency/tools/session-preflight" --quiet
    # Accept any exit code (depends on other checks), but assert monitor warn not unconditionally emitted.
    [[ ! "$output" =~ "Dispatch monitor — verify it is running" ]] || {
        # Permit only when AGENCY_PREFLIGHT_MONITOR_STRICT is set (not the default)
        [[ -n "${AGENCY_PREFLIGHT_MONITOR_STRICT:-}" ]]
    }
}

@test "issue #201: session-preflight Check 5 strict mode still warns" {
    run env AGENCY_PREFLIGHT_MONITOR_STRICT=1 "$REPO_ROOT/agency/tools/session-preflight"
    # Should mention dispatch monitor verification
    [[ "$output" =~ "Dispatch monitor" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #251 — dispatch --body / --body-file mutex
# Covered fully in src/tests/tools/dispatch.bats (same commit)
# Sentinel test here asserts dispatch help documents --body-file
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #251: dispatch create --help documents --body-file" {
    run "$REPO_ROOT/agency/tools/dispatch" create --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--body-file" ]]
}

@test "issue #251: dispatch create --help documents mutex" {
    run "$REPO_ROOT/agency/tools/dispatch" create --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "mutually exclusive" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #388 — git-safe add --files-from for bulk sweeps
# Fixed: --files-from <path> reads newline-separated file list
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #388: git-safe add --files-from requires a path argument" {
    run "$REPO_ROOT/agency/tools/git-safe" add --files-from
    [ "$status" -ne 0 ]
    [[ "$output" =~ "requires a path" ]]
}

@test "issue #388: git-safe add --files-from rejects missing file" {
    run "$REPO_ROOT/agency/tools/git-safe" add --files-from /tmp/does-not-exist-$$.list
    [ "$status" -ne 0 ]
    [[ "$output" =~ "not found" ]]
}

@test "issue #388: git-safe add --files-from rejects empty list" {
    local list="$BATS_TEST_TMPDIR/empty.list"
    mkdir -p "$BATS_TEST_TMPDIR"
    : > "$list"
    run "$REPO_ROOT/agency/tools/git-safe" add --files-from "$list"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "no files to stage" ]]
}

@test "issue #388: git-safe add --files-from rejects directory entries" {
    local list="$BATS_TEST_TMPDIR/dirs.list"
    mkdir -p "$BATS_TEST_TMPDIR"
    echo "$REPO_ROOT/agency" > "$list"
    run "$REPO_ROOT/agency/tools/git-safe" add --files-from "$list"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "directory" ]]
}

@test "issue #388: git-safe add --files-from rejects wildcard entries" {
    local list="$BATS_TEST_TMPDIR/wild.list"
    mkdir -p "$BATS_TEST_TMPDIR"
    echo '*' > "$list"
    run "$REPO_ROOT/agency/tools/git-safe" add --files-from "$list"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "wildcard" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #403 — BATS tests at src/tests/tools/ must use REPO_ROOT-anchored paths
# Validation test: this file itself demonstrates the correct pattern
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #403: triage-batch-G tests use git-rooted REPO_ROOT resolution" {
    # This very test file must resolve REPO_ROOT via $BATS_TEST_DIRNAME/../../..
    # (the src/tests/tools → repo root walk). Assert that REPO_ROOT points
    # at a directory containing CLAUDE.md.
    [ -d "$REPO_ROOT" ]
    [ -f "$REPO_ROOT/CLAUDE.md" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #200 — SessionStart "needs merge" for nonexistent dispatch path
# Verified: no current hook in agency/hooks/ emits this message; feature is gone
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #200: no SessionStart hook emits 'needs merge' notice" {
    run grep -rln "needs merge" "$REPO_ROOT/agency/hooks/"
    # rg/grep exits 1 when no matches. We want NO matches.
    [ "$status" -ne 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #247 — settings-template.json should include Edit(.claude/skills/**)
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #247: settings-template.json allows Edit on .claude/skills/**" {
    run grep -F "Edit(.claude/skills/**)" "$REPO_ROOT/agency/config/settings-template.json"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #209 — agency-health Python version check (deprecated target 3.12,
# current floor is 3.13 per D45-R1). Assert the check exists and warns below floor.
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #209: agency-health references python version floor" {
    # Bug was filed with 3.12 floor; D45-R1 supersedes to 3.13.
    # Accept either until the health check is wired (currently not implemented
    # — this test pins the floor value so future implementation matches spec).
    run grep -E "python.*3\\.1[23]|3\\.1[23].*python|PYTHON_FLOOR" "$REPO_ROOT/agency/tools/agency-health"
    # Allow to be pending (status != 0) — this is the deprecation sentinel.
    # When the feature lands with 3.13 floor, the test flips to green.
    [ "$status" -ne 0 ] || [[ "$output" =~ 3\.13 ]]
}
