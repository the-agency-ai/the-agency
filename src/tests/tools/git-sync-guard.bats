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

# Rebuild ORIGIN + CLONE with an arbitrary default branch name. Needed because
# renaming only the local branch leaves origin/HEAD pointing at the old default,
# which quietly turns a "resolved default" test into a "hardcoded literal" test.
_make_repo_with_default() {
    local name="$1"
    rm -rf "$ORIGIN" "$CLONE"
    git init --quiet --bare -b "$name" "$ORIGIN"
    git init --quiet -b "$name" "$CLONE"
    git -C "$CLONE" config user.email "test@example.com"
    git -C "$CLONE" config user.name "Test User"
    git -C "$CLONE" remote add origin "$ORIGIN"
    echo "seed" > "$CLONE/file.txt"
    git -C "$CLONE" add -A
    git -C "$CLONE" commit -qm "init"
    git -C "$CLONE" push -q -u origin "$name"
    git -C "$CLONE" remote set-head origin -a >/dev/null 2>&1 || true
}

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

@test "git-sync: refuses on master in a genuinely master-default repo" {
    # An earlier version of this test only renamed the LOCAL branch, leaving
    # origin on main — so it exercised the hardcoded "master" literal, the exact
    # opposite of what its comment claimed. Build a real master-default repo.
    _make_repo_with_default master
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_failure
    assert_output_contains "BLOCKED"
}

@test "git-sync: refuses a default branch that is NEITHER main NOR master" {
    # The clause the change argues hardest for, and the one nothing covered:
    # deleting the resolver test from the guard left the old suite 16/16 green,
    # because every case was reachable through the two literals. A trunk-default
    # repo can only be caught by resolution.
    _make_repo_with_default trunk
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_failure
    assert_output_contains "BLOCKED"
}

@test "git-sync: a feature branch in a trunk-default repo still syncs" {
    # The other half of the resolver clause — it must block the default branch
    # without blocking everything else in a repo that does not use main.
    _make_repo_with_default trunk
    git -C "$CLONE" checkout -q -b feature-work
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_success
}

@test "git-sync: refuses main/master even when they are NOT the default branch" {
    # This is the case that makes the two literals load-bearing, and nothing
    # else reaches it. Mutation-verified: strip the literals from the guard and
    # this is the only test that fails — every other "refuses on main" case is
    # also caught by the resolver clause, because resolve-default-branch falls
    # back to refs/heads/main whenever a local main exists.
    #
    # Scenario: a trunk-default repo carrying a stale local `master`. The
    # resolver correctly says "trunk", so only the hardcoded literal stops a
    # direct push of a conventionally protected branch name.
    _make_repo_with_default trunk
    git -C "$CLONE" checkout -q -b master
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_failure
    assert_output_contains "BLOCKED"
}

@test "git-sync: refuses on main with the default branch UNRESOLVABLE" {
    # The literals must stand on their own. Merely repointing the remote URL did
    # not test this: resolve-default-branch reads refs/remotes/origin/main, which
    # is local data and still resolved. Delete the remote-tracking refs so
    # resolution genuinely has nothing to go on.
    git -C "$CLONE" remote set-url origin "$BATS_TEST_TMPDIR/does-not-exist.git"
    rm -rf "$CLONE/.git/refs/remotes/origin"
    git -C "$CLONE" pack-refs --all >/dev/null 2>&1 || true
    rm -rf "$CLONE/.git/refs/remotes/origin"
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_failure
    assert_output_contains "BLOCKED"
}

@test "git-sync: refuses on a detached HEAD" {
    # `git branch --show-current` prints nothing when detached, which matched
    # none of the guard's clauses. The tool went on to run `git push -u origin ""`
    # — fatal, so origin was safe, but only after writing a push-log row with an
    # empty branch and reporting "push failed" instead of the real reason.
    _add_local_commit
    git -C "$CLONE" checkout -q --detach HEAD
    before="$(_log_rows)"
    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_failure
    assert_output_contains "detached HEAD"
    [ "$(_log_rows)" -eq "$before" ]
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
    # pull.rebase=true locally: without this the test proves nothing, because
    # the isolation helper nulls GIT_CONFIG_GLOBAL so git's default is already
    # merge and the flag could be deleted with the test still green. This is the
    # exact config the explicit --no-rebase exists to defeat.
    git -C "$CLONE" config pull.rebase true

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
    # Positively, not just "not unknown" — a negative match passes vacuously
    # when grep finds nothing at all, which is exactly what happened while the
    # rows were being split across two lines.
    [ -n "$output" ]
    assert_output_contains "feature-work"
    [[ "$output" != *"| unknown |"* ]]
}

@test "git-sync: each push-log entry is ONE row, not split across lines" {
    # `grep -c ... || echo "0"` wrote a second zero on top of grep's own, so
    # every sync after the first produced "0\n0" and broke the markdown table.
    # Two syncs, so the second one goes through the branch that has an upstream.
    git -C "$CLONE" checkout -q -b feature-work
    _add_local_commit
    bash -c "cd '$CLONE' && bash '$SYNC' --verbose" >/dev/null 2>&1
    _add_local_commit
    bash -c "cd '$CLONE' && bash '$SYNC' --verbose" >/dev/null 2>&1

    # Every non-header table line must be a complete row: starts with '|',
    # ends with '|', and has the full column count.
    run bash -c "grep '^| 2' '$PUSH_LOG' | grep -vc '|\$'"
    [ "$output" -eq 0 ]
    run bash -c "grep -c '^| 2' '$PUSH_LOG'"
    [ "$output" -eq 2 ]
}

@test "git-sync: a degraded identity still pushes, logging 'unknown'" {
    # Best-effort means best-effort. Shadow agent-identity with a failing stub in
    # a copied tools dir so resolution genuinely fails, and assert BOTH that the
    # push succeeded and that the row degraded rather than the run dying.
    # (Repointing PATH does not do it — the tool is invoked by absolute path.)
    fake_tools="$BATS_TEST_TMPDIR/faketools/agency/tools"
    mkdir -p "$fake_tools/lib"
    cp "$REPO_ROOT/agency/tools/git-sync" "$fake_tools/"
    cp "$REPO_ROOT/agency/tools/resolve-default-branch" "$fake_tools/"
    cp "$REPO_ROOT"/agency/tools/lib/* "$fake_tools/lib/" 2>/dev/null || true
    printf '#!/usr/bin/env bash\nexit 1\n' > "$fake_tools/agent-identity"
    chmod +x "$fake_tools/agent-identity" "$fake_tools/git-sync"

    git -C "$CLONE" checkout -q -b feature-work
    _add_local_commit
    run bash -c "cd '$CLONE' && bash '$fake_tools/git-sync' --verbose"
    assert_success
    run bash -c "grep '^| 2' '$PUSH_LOG' | tail -1"
    assert_output_contains "unknown"
}

@test "git-sync: the src/ mirror is byte-identical to the shipped tool" {
    # These tests run the agency/ copy. The self-bootstrapping repo ships both,
    # and a guard that exists in only one of them is not a guard.
    run diff -q "$REPO_ROOT/agency/tools/git-sync" "$REPO_ROOT/src/agency/tools/git-sync"
    assert_success
}

@test "git-sync: AGENTNAME still wins when it is set" {
    git -C "$CLONE" checkout -q -b feature-work
    _add_local_commit
    AGENTNAME="explicit-agent" bash -c "cd '$CLONE' && bash '$SYNC' --verbose" >/dev/null 2>&1
    run bash -c "grep '^| 2' '$PUSH_LOG' | tail -1"
    assert_output_contains "explicit-agent"
}

@test "git-sync: a merge conflict stops the run instead of pushing anyway" {
    # A failed pull was treated as uniformly benign ("no remote branch yet"), so
    # a conflicted merge left MERGE_HEAD and conflict markers in the tree, then
    # pushed regardless and reported "push failed" — never naming the conflict
    # the operator now had to go find.
    git -C "$CLONE" checkout -q -b feature-work
    echo "base" > "$CLONE/conflict.txt"
    git -C "$CLONE" add -A && git -C "$CLONE" commit -qm "base"
    git -C "$CLONE" push -q -u origin feature-work

    other="$BATS_TEST_TMPDIR/other-conflict"
    git clone -q "$ORIGIN" "$other"
    git -C "$other" config user.email "o@example.com"
    git -C "$other" config user.name "O"
    git -C "$other" checkout -q feature-work
    echo "theirs" > "$other/conflict.txt"
    git -C "$other" add -A && git -C "$other" commit -qm "theirs"
    git -C "$other" push -q origin feature-work

    echo "ours" > "$CLONE/conflict.txt"
    git -C "$CLONE" add -A && git -C "$CLONE" commit -qm "ours"
    origin_before="$(git -C "$ORIGIN" rev-parse feature-work)"

    run bash -c "cd '$CLONE' && bash '$SYNC' --verbose"
    assert_failure
    assert_output_contains "Merge conflict"
    # And it pushed nothing.
    [ "$(git -C "$ORIGIN" rev-parse feature-work)" == "$origin_before" ]
}
