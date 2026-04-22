#!/usr/bin/env bats
#
# What Problem: Triage wave J — 14 low-severity docs + small-fix items
# on main. This file captures probe tests for code changes landed during
# wave J (primarily issue #395 git-safe-commit --coord flag, plus doc
# regression guards against slippage on key reference files).
#
# How & Why: One file per triage wave keeps the archeology findable.
# Tests use the REPO_ROOT-anchored resolution pattern (issue #403) so
# they survive the Great Rename — never $BATS_TEST_DIRNAME/../.
#
# Written: 2026-04-22 during triage-wave-J (captain).

load 'test_helper'

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export REPO_ROOT
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #395 — git-safe-commit: --coord convenience flag
# Fixed: --coord is now a recognized alias for --no-work-item semantics.
# Probe: dry-run a coord commit to assert the flag parses and does not
# fail with "Unknown option: --coord".
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #395: git-safe-commit --coord flag is recognized (parses without error)" {
    # Running with --coord and --dry-run should not fail with "Unknown option".
    # We do not assert commit success — only that the option parser accepts
    # --coord. The rest of the flow may abort for other reasons (no staged
    # changes, no work item derivable, etc.) but NOT with "Unknown option".
    run "$REPO_ROOT/agency/tools/git-safe-commit" "probe: coord flag" --coord --dry-run
    # Look for the exact "Unknown option: --coord" error — its absence is
    # the minimum-viable signal that the flag was parsed.
    [[ ! "$output" =~ "Unknown option: --coord" ]]
}

@test "issue #395: git-safe-commit --help mentions --coord" {
    # Help output should list --coord so agents discover the flag.
    run "$REPO_ROOT/agency/tools/git-safe-commit" --help
    [[ "$output" =~ --coord ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #253 — REFERENCE-RECEIPT-INFRASTRUCTURE.md §6 doc fix
# Fixed: "on disk" clarified to mean "committed state" via diff_base.
# Probe: doc regression guard — verify the clarifying sentence is present.
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #253: REFERENCE-RECEIPT-INFRASTRUCTURE.md §6 clarifies on-disk = committed" {
    # Must contain the committed-state clarification.
    run grep -q "Committed state.*diff_base" "$REPO_ROOT/agency/REFERENCE/REFERENCE-RECEIPT-INFRASTRUCTURE.md"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #354 — Tool-tier carve-out doc
# Fixed: REFERENCE-SAFE-TOOLS.md documents the agent-boundary vs.
# tool-boundary carve-out.
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #354: REFERENCE-SAFE-TOOLS.md documents tool-tier carve-out" {
    run grep -q "Tool-tier Carve-out" "$REPO_ROOT/agency/REFERENCE/REFERENCE-SAFE-TOOLS.md"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #336 — Hooks + hookify location clarification
# Fixed: REFERENCE-SAFE-TOOLS.md documents agency/hooks/ vs agency/hookify/
# vs why .claude/hooks/ does not exist.
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #336: REFERENCE-SAFE-TOOLS.md documents hooks/hookify locations" {
    run grep -q "Hooks and Hookify" "$REPO_ROOT/agency/REFERENCE/REFERENCE-SAFE-TOOLS.md"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #235 — Telemetry-Driven Tool Discovery docs landing
# Fixed: CLAUDE-THEAGENCY.md and README-THEAGENCY.md both contain the
# Telemetry-Driven Tool Discovery section.
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #235: CLAUDE-THEAGENCY.md contains Telemetry-Driven Tool Discovery section" {
    run grep -q "Telemetry-Driven Tool Discovery" "$REPO_ROOT/agency/CLAUDE-THEAGENCY.md"
    [ "$status" -eq 0 ]
}

@test "issue #235: README-THEAGENCY.md contains Telemetry-Driven Tool Discovery section" {
    run grep -q "Telemetry-Driven Tool Discovery" "$REPO_ROOT/agency/README-THEAGENCY.md"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #238 — D-counter principal-PR-days docs
# Fixed: REFERENCE-DEVELOPMENT-METHODOLOGY.md documents the D-counter
# definition (principal-PR-days, not workdays, not calendar days).
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #238: REFERENCE-DEVELOPMENT-METHODOLOGY.md documents D-counter definition" {
    run grep -q "principal-PR-days" "$REPO_ROOT/agency/REFERENCE/REFERENCE-DEVELOPMENT-METHODOLOGY.md"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #357 — Noun-verb naming convention docs
# Fixed: REFERENCE-DEVELOPMENT-METHODOLOGY.md documents the noun-verb
# convention with rationale + known violators list.
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #357: REFERENCE-DEVELOPMENT-METHODOLOGY.md documents noun-verb convention" {
    run grep -q "Noun-Verb" "$REPO_ROOT/agency/REFERENCE/REFERENCE-DEVELOPMENT-METHODOLOGY.md"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #398 — Great Rename v1/v2/v3 retirement rule
# Fixed: REFERENCE-DEVELOPMENT-METHODOLOGY.md documents the Rename
# methodology + v1/v2/v3 retirement rule.
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #398: REFERENCE-DEVELOPMENT-METHODOLOGY.md documents Great Rename methodology" {
    run grep -q "Great Rename" "$REPO_ROOT/agency/REFERENCE/REFERENCE-DEVELOPMENT-METHODOLOGY.md"
    [ "$status" -eq 0 ]
    run grep -q "v1/v2/v3" "$REPO_ROOT/agency/REFERENCE/REFERENCE-DEVELOPMENT-METHODOLOGY.md"
    [ "$status" -eq 0 ]
}
