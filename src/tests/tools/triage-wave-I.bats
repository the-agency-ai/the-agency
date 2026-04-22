#!/usr/bin/env bats
#
# What Problem: Bug triage wave I — 14 medium-severity issues from the
# skip-complex backlog (#161, #178, #194, #196, #198, #199, #248, #272,
# #285, #340, #343, #350, #363, #383). Each test is anchored to an issue
# number and exposes the behavior that the fix cements — or stands as a
# regression guard where the fix was already in place.
#
# How & Why: One file per wave keeps triage archeology findable. Tests
# use REPO_ROOT-anchored path resolution (issue #403) so they survive
# repo renames.
#
# Written: 2026-04-22 during wave-I triage (captain).
#
# Legend:
#   fix-applied    — fix landed in this wave, test guards new behavior
#   already-fixed  — prior wave or concurrent PR landed the fix; test regression-guards
#   needs-1B1      — test is skipped; resolution needs principal decision

load 'test_helper'

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export REPO_ROOT
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #161 / #198 — Skills reference raw git commands blocked by hookify
# Status: already-fixed (session-resume Step 5 now uses git-safe)
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #161/#198: session-resume Step 5 uses git-safe not raw git" {
    # Step 5 (Report and hand off) must direct agents to git-safe, not raw git.
    run grep -E '^\- \*\*Branch:\*\*.*git-safe' "$REPO_ROOT/.claude/skills/session-resume/SKILL.md"
    [ "$status" -eq 0 ]
}

@test "issue #161/#198: session-resume does not embed bare git branch --show-current as instruction" {
    # No prescriptive "run git branch --show-current" instructions remain —
    # only prose references in "Inspect git status" are tolerated (not as
    # an executable instruction to an agent).
    run grep -E '^\s*-\s*\*\*.+:\*\*\s+`git (branch|log|status) ' "$REPO_ROOT/.claude/skills/session-resume/SKILL.md"
    [ "$status" -ne 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #199 — session-preflight fails on framework-managed dirty state
# Status: fix-applied — Check 1 filters framework-owned paths
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #199: session-preflight Check 1 filters framework-owned paths" {
    # Check 1 must exclude tool-runs.jsonl, captain-handoff.md, and
    # captain/history/* from the dirty-count so that framework-managed
    # churn doesn't false-fail a freshly-resumed session.
    run grep -E "tool-runs.jsonl|captain-handoff|captain/history" \
        "$REPO_ROOT/agency/tools/session-preflight"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #272 — Fresh `agency init` does not wire statusline.sh
# Status: already-fixed (PR #369 landed statusLine in settings-template.json)
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #272: settings-template.json wires statusLine to statusline.sh" {
    run grep -E '"statusLine"' "$REPO_ROOT/agency/config/settings-template.json"
    [ "$status" -eq 0 ]
}

@test "issue #272: settings-template.json statusLine command points at agency/tools/statusline.sh" {
    run grep -E 'statusline\.sh' "$REPO_ROOT/agency/config/settings-template.json"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #285 — `git-safe add <directory>` blocks directory staging
# Status: fix-applied — --confirm flag allows scoped directory add
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #285: git-safe add supports --confirm flag for directory staging" {
    run grep -E '\-\-confirm' "$REPO_ROOT/agency/tools/git-safe"
    [ "$status" -eq 0 ]
}

@test "issue #285: git-safe add directory still blocked without --confirm" {
    # Regression guard: default behavior is still to block bare directory
    # adds. --confirm is the explicit opt-in.
    run grep -E "blocks directory.*specify individual files" "$REPO_ROOT/agency/tools/git-safe"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #340 — dispatch-monitor should filter commit-type dispatches by default
# Status: fix-applied — commits filtered by default, --include-commits opt-in
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #340: dispatch-monitor has --include-commits flag" {
    run grep -E '\-\-include-commits' "$REPO_ROOT/agency/tools/dispatch-monitor"
    [ "$status" -eq 0 ]
}

@test "issue #340: dispatch-monitor filters commit-type by default" {
    # Default path must skip commit-type dispatches from the unread feed.
    # Check the type filter is applied in the check_dispatches path.
    run grep -E 'type.*commit|commit.*type' "$REPO_ROOT/agency/tools/dispatch-monitor"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #343 — Skills defaulting project=captain must use repo-basename resolver
# Status: already-fixed — transcript skill uses basename rule per _agency-init
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #343: transcript skill uses basename resolver (not default-to-captain)" {
    # The skill must reference the basename-of-CLAUDE_PROJECT_DIR rule,
    # not the legacy "default to captain on master" pattern.
    run grep -E 'basename.*CLAUDE_PROJECT_DIR' "$REPO_ROOT/.claude/skills/transcript/SKILL.md"
    [ "$status" -eq 0 ]
}

@test "issue #343: no skills default project=captain via legacy pattern" {
    # Negative test: no SKILL.md should contain the legacy
    # "default to captain" pattern.
    run grep -rlE "default.*to.*captain|project=captain" "$REPO_ROOT/.claude/skills/"
    # grep -l returns 1 when no matches — that's the pass condition.
    [ "$status" -ne 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #178 — dispatch-monitor Python fails catastrophically when invoked via bash
# Status: needs-1B1 — requires rename to .py OR convention change in skill docs
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #178: dispatch-monitor is a python script (shebang)" {
    # Regression guard: dispatch-monitor's first line must identify it as
    # python. When/if an agent wraps with `bash`, the error should be the
    # python-syntax-in-bash noise surfaced in the issue — fix direction is
    # open (rename + skill-doc update, or bash-shim detection); captured
    # for principal 1B1.
    run head -1 "$REPO_ROOT/agency/tools/dispatch-monitor"
    [[ "$output" == *"python"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #194 — Monitor routes routine commit-dispatches to principal chat
# Status: needs-1B1 — partial mitigation via #340 default filter
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #194: partial mitigation — commit-type dispatches filtered by default" {
    # Once #340's default filter lands, routine commits no longer flood the
    # monitor's output, which means they no longer surface to principal's
    # chat. The full two-channel routing still needs principal design input.
    run grep -E '\-\-include-commits' "$REPO_ROOT/agency/tools/dispatch-monitor"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #196 — REPORTS-INDEX.md produces merge conflict every day
# Status: needs-1B1 — redesign choices (auto-gen, per-agent index, sorted write, etc.)
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #196: REPORTS-INDEX.md still appends via single shared file (needs redesign)" {
    # Guard that the current append-to-shared-file pattern still exists, so
    # a redesign that changes the structure is an obvious diff. This will
    # flip to a different assertion once principal chooses an option.
    run grep -E "AGENCY-ISSUE-INDEX-END" "$REPO_ROOT/agency/tools/agency-issue"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #248 — pr-create should require a pr-prep boundary receipt
# Status: needs-1B1 — requires receipt boundary field enforcement design
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #248: pr-create currently accepts any valid receipt" {
    # Exposing test: pr-create runs receipt-verify but does NOT check the
    # receipt's `boundary` field for pr-prep. Guard the current behavior
    # so a future fix is an obvious diff.
    run grep -E 'receipt-verify' "$REPO_ROOT/agency/tools/pr-create"
    [ "$status" -eq 0 ]
    run grep -E 'boundary.*pr-prep|pr-prep.*boundary' "$REPO_ROOT/agency/tools/pr-create"
    [ "$status" -ne 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #350 — Hookify canary coverage gap (6 rules) + runner improvements
# Status: needs-1B1 — runner path not finalized; 6 rules un-synthesizable
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #350: hookify-rule-canary runner lives in src/tools-developer" {
    # Guard on the runner location — if it moves to agency/tools/, the
    # runner-improvement PR has landed and this assertion flips.
    [ -f "$REPO_ROOT/src/tools-developer/hookify-rule-canary" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #363 — ci-monitor lacks state-transition dedup
# Status: needs-1B1 — tool lives in src/tools-developer/, skill references
#         agency/tools path (mismatch); design choice A/B/C for cache strategy
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #363: ci-monitor still emits on every poll (no state cache)" {
    # Exposing test: the ci-monitor loop does not read or write a state
    # cache file. Guards current behavior; flips when fix lands.
    run grep -E 'ci-monitor-state|last-seen|state_cache|previous_state' "$REPO_ROOT/src/tools-developer/ci-monitor"
    [ "$status" -ne 0 ]
}

@test "issue #363: monitor-ci skill references agency/tools path (mismatch to src/tools-developer)" {
    # Architectural observation: skill doc points at agency/tools/ but
    # tool lives in src/tools-developer/. Fix path depends on principal's
    # decision re: tool promotion.
    run grep -E 'agency/tools/ci-monitor' "$REPO_ROOT/.claude/skills/monitor-ci/SKILL.md"
    [ "$status" -eq 0 ]
    [ ! -f "$REPO_ROOT/agency/tools/ci-monitor" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Issue #383 — status-line does not display the-agency version on presence-detect
# Status: already-fixed (PR #369 wired statusLine in settings-template.json,
#         per-adopter `agency update` required). Cannot reproduce from this repo.
# ─────────────────────────────────────────────────────────────────────────────

@test "issue #383: statusline.sh reads agency_version via agency-version tool" {
    run grep -E 'agency-version.*--statusline' "$REPO_ROOT/agency/tools/statusline.sh"
    [ "$status" -eq 0 ]
}

@test "issue #383: agency-version --statusline prints framework version" {
    # Regression guard: the --statusline flavor of agency-version must print
    # the version from manifest.json when run in-tree.
    run "$REPO_ROOT/agency/tools/agency-version" --statusline
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}
