#!/usr/bin/env bats
#
# What Problem: git-sync violated two of the framework's sacred invariants and
# nothing caught it. It ran `git pull --rebase` (the repo's rule is merge, never
# rebase) and `git push -u origin "$BRANCH"` with NO main/master guard (the rule
# is that nothing reaches the default branch except through a PR). Invoked on
# main it did both in one go — rewrote main's history AND pushed main directly.
# That is not hypothetical; it happened. `git-push`, sitting in the same
# directory, has blocked main since Day 40, so the tool contradicted both the
# methodology and its own neighbour.
#
# How & Why: the guard is tested against a REAL local origin, not a mock — a
# refusal that only holds because the network was absent proves nothing. Each
# case asserts the refusal AND that nothing moved: no new commit on origin, no
# rewritten history, and no row appended to the accountability log. "It printed
# BLOCKED" and "it changed nothing" are separate claims and the second is the
# one that matters.
#
# The rebase ban is asserted on LIVE CODE with comments stripped, because the
# header comment necessarily names the thing it stopped doing.
#
# Written: 2026-08-11 (devex) — git-sync main-guard + merge-not-rebase

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    iscp_test_isolation_setup

    SYNC="$REPO_ROOT/agency/tools/git-sync"

    # A real bare origin + a clone. The guard must hold with a reachable remote,
    # since resolve-default-branch consults origin/HEAD first.
    export ORIGIN="$BATS_TEST_TMPDIR/origin.git"
    export CLONE="$BATS_TEST_TMPDIR/clone"

    git init --quiet --bare -b main "$ORIGIN"

    git init --quiet -b main "$CLONE"
    git -C "$CLONE" config user.email "test@example.com"
    git -C "$CLONE" config user.name "Test User"
    git -C "$CLONE" remote add origin "$ORIGIN"
    echo "seed" > "$CLONE/file.txt"
    git -C "$CLONE" add -A
    git -C "$CLONE" commit -qm "init"
    git -C "$CLONE" push -q -u origin main
    git -C "$CLONE" remote set-head origin -a >/dev/null 2>&1 || true

    PUSH_LOG="$CLONE/history/push-log.md"
}

teardown() {
    iscp_test_isolation_teardown
    [[ -d "${BATS_TEST_TMPDIR}" ]] && rm -rf "${BATS_TEST_TMPDIR}"
}

_origin_main_sha() { git -C "$ORIGIN" rev-parse main; }
_log_rows() { [[ -f "$PUSH_LOG" ]] && grep -c '^| 2' "$PUSH_LOG" || echo 0; }

# Put a local-only commit on the current branch so there is genuinely something
# to push — otherwise git-sync exits early on "nothing to push" and a guard that
# does not exist would still look like it worked.
_add_local_commit() {
    echo "local change" >> "$CLONE/file.txt"
    git -C "$CLONE" add -A
    git -C "$CLONE" commit -qm "local work"
}

# ─────────────────────────────────────────────────────────────────────────────
# The guard
# ─────────────────────────────────────────────────────────────────────────────

@test "git-sync: refuses on main" {
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_failure
    assert_output_contains "BLOCKED"
}

@test "git-sync: refusing on main pushes NOTHING to origin" {
    before="$(_origin_main_sha)"
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_failure
    [ "$(_origin_main_sha)" == "$before" ]
}

@test "git-sync: refusing on main does not rewrite local history" {
    _add_local_commit
    before="$(git -C "$CLONE" rev-parse HEAD)"
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_failure
    [ "$(git -C "$CLONE" rev-parse HEAD)" == "$before" ]
}

@test "git-sync: refusing on main appends no row to the push log" {
    # The guard sits BEFORE the log append. A refused run must leave no trace —
    # an accountability log with entries for pushes that never happened is worse
    # than no log.
    _add_local_commit
    before="$(_log_rows)"
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_failure
    [ "$(_log_rows)" -eq "$before" ]
}

@test "git-sync: refuses on master too, in a master-default repo" {
    # Not just the string "main". A repo whose default is master gets the same
    # protection, which is why the branch name is resolved rather than assumed.
    git -C "$CLONE" branch -m master
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_failure
    assert_output_contains "BLOCKED"
}

@test "git-sync: refuses on main even with the remote unreachable" {
    # resolve-default-branch falls back to "main" when it cannot reach origin.
    # A guard that softens the moment the network does is not a guard, so the
    # literals are checked independently of resolution.
    git -C "$CLONE" remote set-url origin "$BATS_TEST_TMPDIR/does-not-exist.git"
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_failure
    assert_output_contains "BLOCKED"
}

@test "git-sync: the refusal names the PR flow, not just the rule" {
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_output_contains "pr-submit"
    assert_output_contains "pr-captain-land"
}

@test "git-sync: --check on main is refused as well" {
    # --check is read-only, but reporting "N commits ready" for a branch that
    # may never be synced is a false green that invites someone to drop --check.
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$SYNC' --check --verbose"
    assert_failure
    assert_output_contains "BLOCKED"
}

# ─────────────────────────────────────────────────────────────────────────────
# A feature branch still works — the guard must not break the tool
# ─────────────────────────────────────────────────────────────────────────────

@test "git-sync: a feature branch still pushes" {
    git -C "$CLONE" checkout -q -b feature-work
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_success
    run git -C "$ORIGIN" rev-parse feature-work
    assert_success
}

@test "git-sync: a feature branch sync leaves main on origin untouched" {
    before="$(_origin_main_sha)"
    git -C "$CLONE" checkout -q -b feature-work
    _add_local_commit
    bash -c "cd '$CLONE' && bash '$SYNC' --verbose" >/dev/null 2>&1
    [ "$(_origin_main_sha)" == "$before" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Merge, never rebase
# ─────────────────────────────────────────────────────────────────────────────

@test "git-sync: no --rebase anywhere in live code" {
    # Comments stripped: the header explains the rebase this tool stopped doing,
    # and flagging that would teach authors to delete the explanation.
    run bash -c "grep -v '^[[:space:]]*#' '$SYNC' | grep -n 'pull --rebase'"
    assert_failure
}

@test "git-sync: the pull is explicitly --no-rebase" {
    # Explicit, not merely git's default: a user with pull.rebase=true in global
    # config would otherwise silently get the rewrite back.
    run bash -c "grep -v '^[[:space:]]*#' '$SYNC' | grep -q 'git pull --no-rebase'"
    assert_success
}

@test "git-sync: a real sync with diverged history produces a MERGE, not a rewrite" {
    # The behavioural proof. Push a commit to origin from a second clone, make a
    # different local commit, sync, and assert the original local commit is
    # still reachable by its ORIGINAL sha. A rebase would have replayed it under
    # a new sha; a merge preserves it and adds a merge commit.
    git -C "$CLONE" checkout -q -b feature-work
    _add_local_commit
    git -C "$CLONE" push -q -u origin feature-work

    other="$BATS_TEST_TMPDIR/other"
    git clone -q "$ORIGIN" "$other"
    git -C "$other" config user.email "other@example.com"
    git -C "$other" config user.name "Other User"
    git -C "$other" checkout -q feature-work
    echo "remote change" > "$other/remote.txt"
    git -C "$other" add -A
    git -C "$other" commit -qm "remote work"
    git -C "$other" push -q origin feature-work

    echo "more local" > "$CLONE/local2.txt"
    git -C "$CLONE" add -A
    git -C "$CLONE" commit -qm "more local work"
    local_sha="$(git -C "$CLONE" rev-parse HEAD)"

    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_success

    # The pre-sync commit survives under its original sha — no history rewrite.
    run git -C "$CLONE" merge-base --is-ancestor "$local_sha" HEAD
    assert_success
    # And a merge commit (two parents) now exists.
    run bash -c "git -C '$CLONE' rev-list --merges HEAD --count"
    [ "$output" -ge 1 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Accountability
# ─────────────────────────────────────────────────────────────────────────────

@test "git-sync: the push log records a resolved agent, not 'unknown'" {
    # The log read $AGENTNAME, which Claude Code does not set, so every row said
    # "unknown" and the accountability log accounted for nobody.
    git -C "$CLONE" checkout -q -b feature-work
    _add_local_commit
    bash -c "cd '$CLONE' && bash '$SYNC' --verbose" >/dev/null 2>&1
    [ -f "$PUSH_LOG" ]
    run bash -c "grep '^| 2' '$PUSH_LOG' | tail -1"
    [[ "$output" != *"| unknown |"* ]]
}

@test "git-sync: AGENTNAME still wins when it is set" {
    git -C "$CLONE" checkout -q -b feature-work
    _add_local_commit
    AGENTNAME="explicit-agent" bash -c "cd '$CLONE' && bash '$SYNC' --verbose" >/dev/null 2>&1
    run bash -c "grep '^| 2' '$PUSH_LOG' | tail -1"
    assert_output_contains "explicit-agent"
}

@test "git-sync: identity resolution never blocks the push" {
    # Best-effort by design. If agent-identity cannot resolve, the row falls back
    # to "unknown" — a degraded log entry, never a failed push.
    git -C "$CLONE" checkout -q -b feature-work
    _add_local_commit
    run bash -c "cd '$CLONE' && PATH=/usr/bin:/bin bash '$SYNC' --verbose"
    assert_success
}
