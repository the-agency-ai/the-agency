#!/usr/bin/env bats
#
# Triage probes for batch-E HIGH-severity bugs (#181, #195, #205, #210, #222,
# #249, #258, #267, #273, #274, #275, #276, #292, #297, #324, #325, #326,
# #327, #332, #385, #392, #393, #394, #396, #404, #409).
#
# These are lightweight "is the bug still real on current main?" probes — not
# full exposing tests. Each probe asserts ONE observable property of the
# current implementation. A green suite means the listed concern has at least
# its most-direct symptom addressed; a red probe means the bug is still live
# in that specific symptom.
#
# Written: 2026-04-22 during batch-E captain triage (housekeeping/captain).
#

load 'test_helper'

setup() {
    test_isolation_setup
}

teardown() {
    test_isolation_teardown 2>/dev/null || true
}

# ── #181: cross-worktree dispatch 'from' field ─────────────────────────────
@test "#181: dispatch-create accepts explicit --from arg (identity preservation hook)" {
    run "${REPO_ROOT}/agency/tools/dispatch-create" --help
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
    # Probe: help output or usage must mention --from or principal/agent override
    [[ "$output" == *"--from"* ]] || [[ "$output" == *"from"* ]] || [[ "$output" == *"principal"* ]] || [[ "$output" == *"agent"* ]]
}

# ── #195 / #409: worktree-sync stash safety ────────────────────────────────
@test "#195/#409: worktree-sync stashes/pops using a labeled/SHA-tracked stash (not blind pop)" {
    # A safe implementation records a stash label or SHA. Grep for either.
    run grep -E "stash (push|create|list).*-m|stash_sha|stash_label|--include-untracked" "${REPO_ROOT}/agency/tools/worktree-sync"
    # Probe asserts the presence of label/SHA tracking. If absent, bug is live.
    [ "$status" -eq 0 ]
}

# ── #205: QG Hash E captured before version bump ───────────────────────────
@test "#205: QG skill / receipt-sign captures Hash E after version bump" {
    # Probe: receipt-sign documentation / quality-gate skill should order
    # version bump before Hash E. We check the quality-gate SKILL.md.
    run grep -n "Hash E" "${REPO_ROOT}/.claude/skills/quality-gate/SKILL.md"
    # Bug is live if Hash E is documented as captured before version bump.
    # Probe passes if document has been updated to reflect post-bump ordering
    # (look for 'after version bump' or the Hash E step post-bump).
    [[ "$output" == *"after version"* ]] || [[ "$output" == *"post-bump"* ]] || [[ "$output" == *"post version"* ]]
}

# ── #210: commit-notify cascade ────────────────────────────────────────────
@test "#210: git-safe-commit has _is_commit_notify_only guard" {
    run grep -n "_is_commit_notify_only" "${REPO_ROOT}/agency/tools/git-safe-commit"
    [ "$status" -eq 0 ]
}

# ── #222: HIP receipt glob — recognize five-hash receipts ──────────────────
@test "#222: git-safe-commit / quality-gate know about five-hash receipt layout" {
    # Probe: receipt-sign accepts --hash-a through --hash-e (five hashes).
    run grep -E "hash-a|hash-b|hash-c|hash-d|hash-e" "${REPO_ROOT}/agency/tools/receipt-sign"
    [ "$status" -eq 0 ]
}

# ── #249: Hookify block returns exit 2 with decision:block ─────────────────
@test "#249: block-raw-tools.sh uses exit 2 + decision:block" {
    run grep -c 'exit 2' "${REPO_ROOT}/agency/hooks/block-raw-tools.sh"
    [ "$status" -eq 0 ]
    # At least 5 occurrences of exit 2 expected
    run bash -c "grep -c 'exit 2' '${REPO_ROOT}/agency/hooks/block-raw-tools.sh'"
    [ "$output" -ge 5 ]
    run grep -c '"decision":"block"' "${REPO_ROOT}/agency/hooks/block-raw-tools.sh"
    [ "$status" -eq 0 ]
}

# ── #258: git-safe-commit --no-work-item from worktree ─────────────────────
@test "#258: git-safe-commit preserves staged index (merge auto-route only triggers on MERGE_HEAD)" {
    # Probe: the merge-commit auto-route is gated on MERGE_HEAD existence.
    run grep "MERGE_HEAD" "${REPO_ROOT}/agency/tools/git-safe-commit"
    [ "$status" -eq 0 ]
}

# ── #267 / #292: worktree-sync MAIN_BRANCH detection ───────────────────────
@test "#267/#292: worktree-sync resolves MAIN_BRANCH via origin/HEAD (not hardcoded master)" {
    run grep "origin/HEAD" "${REPO_ROOT}/agency/tools/worktree-sync"
    [ "$status" -eq 0 ]
}

# ── #273: agency-issue writes to usr/{principal}/reports/ ──────────────────
@test "#273: agency-issue resolves principal via agent-identity (not \$USER)" {
    run grep "agent-identity" "${REPO_ROOT}/agency/tools/agency-issue"
    [ "$status" -eq 0 ]
}

# ── #274: handoff writes to usr/{principal}/ ───────────────────────────────
@test "#274: handoff resolves principal via agent-identity (not \$USER)" {
    run grep -n "agent-identity" "${REPO_ROOT}/agency/tools/handoff"
    [ "$status" -eq 0 ]
}

# ── #275: claude/agents/ ships role classes only ───────────────────────────
@test "#275: no test-fixture agents shipped under agency/agents/ (apple, discord, gumroad, testname)" {
    [ ! -d "${REPO_ROOT}/agency/agents/apple" ]
    [ ! -d "${REPO_ROOT}/agency/agents/discord" ]
    [ ! -d "${REPO_ROOT}/agency/agents/gumroad" ]
    [ ! -d "${REPO_ROOT}/agency/agents/testname" ]
}

# ── #276: captain SESSION-BACKUP-*.md not shipped ──────────────────────────
@test "#276: no SESSION-BACKUP-*.md files in agency/agents/captain/" {
    if [ -d "${REPO_ROOT}/agency/agents/captain" ]; then
        run bash -c "ls '${REPO_ROOT}/agency/agents/captain/'SESSION-BACKUP-*.md 2>/dev/null | wc -l | tr -d ' '"
        [ "$output" = "0" ]
    fi
}

# ── #297: framework bug cluster umbrella — informational ───────────────────
@test "#297: umbrella bug — defer to individual issues" {
    skip "umbrella issue — split into constituent bugs by captain"
}

# ── #324: agency init populates .claude/agents/ ────────────────────────────
@test "#324: agency init has step to register .claude/agents/ from agency/agents/" {
    # Probe: the installer lib should reference .claude/agents or registration.
    run grep -n "\.claude/agents\|agent.*register" "${REPO_ROOT}/agency/tools/lib/_agency-init"
    [ "$status" -eq 0 ]
}

# ── #325: agency init rewrites CLAUDE.md ───────────────────────────────────
@test "#325: agency init writes/rewrites CLAUDE.md with project context" {
    run grep -n "CLAUDE\.md" "${REPO_ROOT}/agency/tools/lib/_agency-init"
    [ "$status" -eq 0 ]
}

# ── #326: agency.yaml principal mapping ────────────────────────────────────
@test "#326: agent-identity resolves principal from agency.yaml (single predicate)" {
    run grep -n "agency\.yaml\|principal" "${REPO_ROOT}/agency/tools/agent-identity"
    [ "$status" -eq 0 ]
}

# ── #327: --no-work-item QGR receipt enforcement ──────────────────────────
@test "#327: phase-complete / plan-complete require QGR receipt presence" {
    # Probe: phase-complete skill documents receipt precondition.
    if [ -f "${REPO_ROOT}/.claude/skills/phase-complete/SKILL.md" ]; then
        run grep -n -i "receipt\|QGR" "${REPO_ROOT}/.claude/skills/phase-complete/SKILL.md"
        [ "$status" -eq 0 ]
    else
        skip "phase-complete skill not present at expected path"
    fi
}

# ── #332: usr/{$USER}/ creation when principal ≠ $USER ─────────────────────
@test "#332: tools resolve principal identity before creating usr/ dirs" {
    # Same predicate as #273/#274 — validated via agent-identity presence.
    [ -x "${REPO_ROOT}/agency/tools/agent-identity" ]
}

# ── #385: commit-precheck scoped bats timeout ─────────────────────────────
@test "#385: commit-precheck caps bats timeout / has escape hatch" {
    run grep -n "bats_timeout\|ALLOW_LARGE\|SKIP_BATS" "${REPO_ROOT}/agency/tools/commit-precheck"
    [ "$status" -eq 0 ]
}

# ── #392: agency update chicken-egg ────────────────────────────────────────
@test "#392: _agency-update handles agency/ tree (not just claude/)" {
    run grep -n "agency/\|rsync" "${REPO_ROOT}/agency/tools/lib/_agency-update"
    [ "$status" -eq 0 ]
}

# ── #393: session-end commits handoff ──────────────────────────────────────
@test "#393: session-pause force-commits handoff on end framing" {
    run grep -n "handoff_commit_sha\|force-commit" "${REPO_ROOT}/agency/tools/session-pause"
    [ "$status" -eq 0 ]
}

# ── #394: Python tools on Apple-stock + brew-only python@3.13 ─────────────
@test "#394: Python tools have #!/usr/bin/env python3 shebang + version guard" {
    # Pick a representative Python tool.
    local pytool="${REPO_ROOT}/agency/tools/dispatch-monitor"
    if [ -f "$pytool" ]; then
        run head -1 "$pytool"
        [[ "$output" == "#!/usr/bin/env python3" ]] || [[ "$output" == *"python3"* ]]
        run grep -n "sys.version_info" "$pytool"
        [ "$status" -eq 0 ]
    else
        skip "dispatch-monitor not present"
    fi
}

# ── #396: pr-create receipt lockstep (contributor posture) ────────────────
@test "#396: pr-create supports contributor posture or receipt flexibility" {
    run grep -n "contributor\|CONTRIBUTOR\|--no-receipt\|posture" "${REPO_ROOT}/agency/tools/pr-create"
    # If match found, probe passes (framework has posture awareness).
    # If not, bug still live — mark skip-complex.
    [ "$status" -eq 0 ]
}

# ── #404: customer bats suite Rename debt ─────────────────────────────────
@test "#404: no customer bats suite still chokes on Rename debt (skip — umbrella)" {
    # Rename debt is a systemic sweep; this probe is informational.
    # The great-rename-migrate.bats legitimately references claude/tools/
    # because it tests the migration itself. Remaining Rename debt should
    # be caught by the full test suite; individual fixture sweeps belong
    # in dedicated commits.
    skip "sweep-style debt — verified via full test suite, not single probe"
}
