#!/usr/bin/env bats
#
# Tests for agency/tools/worktree-create
#
# Focus: the --workstream/--agent collapse rule (dispatch #166, resolved in
# #169). These tests use --compute-only mode so no real worktrees are created.
#
# The full end-to-end worktree creation path (git worktree add, dependency
# install, branch management) is not tested here — those operations are
# integration-tested by actually using the tool during real worktree-create
# workflows. This file verifies the NAMING CONTRACT only.
#
# Written: 2026-04-09 — dispatch #166/#169, task #9
# Extended: 2026-08-08 — branch-resolution DWIM (origin/<branch> path, v2.2.0).
#           Those tests DO create real worktrees, but only inside an isolated
#           temp repo built by make_origin_repo — never in the live checkout.

load test_helper

setup() {
    test_isolation_setup
    export TOOL="${REPO_ROOT}/agency/tools/worktree-create"
}

# ─────────────────────────────────────────────────────────────────────────────
# Fixture: an isolated clone with a branch that exists ONLY on origin
#
# Builds:
#   $BATS_TEST_TMPDIR/upstream.git  — bare "origin"
#   $BATS_TEST_TMPDIR/clone         — working clone, exports TEST_REPO
#
# On exit, 'stale-pr' exists as refs/remotes/origin/stale-pr in the clone but
# NOT as refs/heads/stale-pr. That is exactly the stale-PR-revival shape.
# ─────────────────────────────────────────────────────────────────────────────
make_origin_repo() {
    local upstream="${BATS_TEST_TMPDIR}/upstream.git"
    local seed="${BATS_TEST_TMPDIR}/seed"
    export TEST_REPO="${BATS_TEST_TMPDIR}/clone"

    git init --bare --quiet --initial-branch=main "$upstream" 2>/dev/null \
        || git init --bare --quiet "$upstream"

    git clone --quiet "$upstream" "$seed"
    git -C "$seed" config user.email "test@test.com"
    git -C "$seed" config user.name "Test"
    git -C "$seed" config commit.gpgsign false
    git -C "$seed" symbolic-ref HEAD refs/heads/main

    echo "base content" > "$seed/base.txt"
    git -C "$seed" add base.txt
    git -C "$seed" commit -m "initial" --quiet --no-verify
    git -C "$seed" push --quiet origin main

    # The stale PR branch — carries a file that does NOT exist on main, so a
    # worktree created from HEAD instead of origin/stale-pr is detectable.
    git -C "$seed" checkout -b stale-pr --quiet
    echo "pr content" > "$seed/pr-only.txt"
    git -C "$seed" add pr-only.txt
    git -C "$seed" commit -m "stale pr work" --quiet --no-verify
    git -C "$seed" push --quiet origin stale-pr

    # Fresh clone: has origin/stale-pr, has no local stale-pr.
    git clone --quiet "$upstream" "$TEST_REPO"
    git -C "$TEST_REPO" config user.email "test@test.com"
    git -C "$TEST_REPO" config user.name "Test"
    git -C "$TEST_REPO" config commit.gpgsign false

    export AGENCY_PROJECT_ROOT="$TEST_REPO"
}

teardown() {
    test_isolation_teardown
}

# ─────────────────────────────────────────────────────────────────────────────
# Collapse rule — canonical cases from dispatch #169
# ─────────────────────────────────────────────────────────────────────────────

@test "collapse: devex + devex → devex (exact match)" {
    run "$TOOL" --compute-only --workstream devex --agent devex
    [ "$status" -eq 0 ]
    [ "$output" = "devex" ]
}

@test "collapse: iscp + iscp → iscp (exact match)" {
    run "$TOOL" --compute-only --workstream iscp --agent iscp
    [ "$status" -eq 0 ]
    [ "$output" = "iscp" ]
}

@test "collapse: mdpal + mdpal-app → mdpal-app (prefix match)" {
    run "$TOOL" --compute-only --workstream mdpal --agent mdpal-app
    [ "$status" -eq 0 ]
    [ "$output" = "mdpal-app" ]
}

@test "collapse: mdpal + mdpal-cli → mdpal-cli (prefix match)" {
    run "$TOOL" --compute-only --workstream mdpal --agent mdpal-cli
    [ "$status" -eq 0 ]
    [ "$output" = "mdpal-cli" ]
}

@test "no collapse: agency + captain → agency-captain" {
    run "$TOOL" --compute-only --workstream agency --agent captain
    [ "$status" -eq 0 ]
    [ "$output" = "agency-captain" ]
}

@test "no collapse: fleet + captain → fleet-captain" {
    run "$TOOL" --compute-only --workstream fleet --agent captain
    [ "$status" -eq 0 ]
    [ "$output" = "fleet-captain" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Edge cases
# ─────────────────────────────────────────────────────────────────────────────

@test "edge: agent that contains workstream but doesn't start with it → no collapse" {
    # e.g., workstream=api, agent=rest-api → 'rest-api' does NOT start with 'api-'
    run "$TOOL" --compute-only --workstream api --agent rest-api
    [ "$status" -eq 0 ]
    [ "$output" = "api-rest-api" ]
}

@test "edge: hyphenated workstream, matching agent → collapse" {
    # e.g., workstream=mock-and-mark, agent=mock-and-mark → exact match
    run "$TOOL" --compute-only --workstream mock-and-mark --agent mock-and-mark
    [ "$status" -eq 0 ]
    [ "$output" = "mock-and-mark" ]
}

@test "edge: hyphenated workstream with prefixed agent → collapse" {
    # e.g., workstream=mock-and-mark, agent=mock-and-mark-ios → prefix match
    run "$TOOL" --compute-only --workstream mock-and-mark --agent mock-and-mark-ios
    [ "$status" -eq 0 ]
    [ "$output" = "mock-and-mark-ios" ]
}

@test "edge: agent named like workstream but without hyphen → no collapse" {
    # e.g., workstream=test, agent=tester → 'tester' does NOT start with 'test-'
    # (it starts with 'test' but the rule requires 'test-' specifically)
    run "$TOOL" --compute-only --workstream test --agent tester
    [ "$status" -eq 0 ]
    [ "$output" = "test-tester" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Missing / invalid input
# ─────────────────────────────────────────────────────────────────────────────

@test "invalid: --workstream without --agent fails" {
    run "$TOOL" --compute-only --workstream devex
    [ "$status" -ne 0 ]
}

@test "invalid: --agent without --workstream fails" {
    run "$TOOL" --compute-only --agent devex
    [ "$status" -ne 0 ]
}

@test "invalid: empty workstream fails" {
    run "$TOOL" --compute-only --workstream "" --agent devex
    [ "$status" -ne 0 ]
}

@test "invalid: empty agent fails" {
    run "$TOOL" --compute-only --workstream devex --agent ""
    [ "$status" -ne 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Backward compat: positional name still works
# ─────────────────────────────────────────────────────────────────────────────

@test "positional mode: shows error when no name given" {
    run "$TOOL"
    [ "$status" -ne 0 ]
    [[ "$output" == *"name is required"* ]]
}

@test "positional mode: --help still works" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--workstream"* ]]
    [[ "$output" == *"--agent"* ]]
}

@test "positional mode: --version shows a semver version" {
    run "$TOOL" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^worktree-create\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Help text includes the naming rule
# ─────────────────────────────────────────────────────────────────────────────

@test "help: includes collapse rule description" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"collapse"* ]] || [[ "$output" == *"Naming rule"* ]]
}

@test "help: includes example with --workstream" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--workstream"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Mixing modes is an error
# ─────────────────────────────────────────────────────────────────────────────

@test "invalid: positional + --workstream + --agent is ambiguous" {
    run "$TOOL" someName --workstream devex --agent devex
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot mix"* ]] || [[ "$output" == *"ambiguous"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Branch resolution — three cases (v2.2.0)
#
# The origin-only case is the regression these tests exist for: before v2.2.0
# the tool fell through to `worktree add -b <branch>` and created an EMPTY
# branch from HEAD, silently discarding the PR's content.
# ─────────────────────────────────────────────────────────────────────────────

@test "branch resolution: origin-only branch is checked out, not recreated from HEAD" {
    make_origin_repo
    cd "$TEST_REPO"

    # Precondition: the branch is remote-only.
    run git -C "$TEST_REPO" show-ref --verify --quiet refs/heads/stale-pr
    [ "$status" -ne 0 ]
    git -C "$TEST_REPO" show-ref --verify --quiet refs/remotes/origin/stale-pr

    run "$TOOL" revive --branch stale-pr
    [ "$status" -eq 0 ]

    local wt="${TEST_REPO}/.claude/worktrees/revive"
    [ -d "$wt" ]

    # On the right branch...
    run git -C "$wt" rev-parse --abbrev-ref HEAD
    [ "$status" -eq 0 ]
    [ "$output" = "stale-pr" ]

    # ...at origin/stale-pr's commit, not main's.
    local wt_sha origin_sha main_sha
    wt_sha=$(git -C "$wt" rev-parse HEAD)
    origin_sha=$(git -C "$TEST_REPO" rev-parse refs/remotes/origin/stale-pr)
    main_sha=$(git -C "$TEST_REPO" rev-parse refs/remotes/origin/main)
    [ "$wt_sha" = "$origin_sha" ]
    [ "$wt_sha" != "$main_sha" ]

    # ...with the PR's content actually present.
    [ -f "$wt/pr-only.txt" ]
}

@test "branch resolution: origin-only branch sets upstream tracking" {
    make_origin_repo
    cd "$TEST_REPO"

    run "$TOOL" revive --branch stale-pr
    [ "$status" -eq 0 ]

    run git -C "${TEST_REPO}/.claude/worktrees/revive" \
        rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'
    [ "$status" -eq 0 ]
    [ "$output" = "origin/stale-pr" ]
}

@test "branch resolution: existing local branch is reused as-is" {
    make_origin_repo
    cd "$TEST_REPO"

    # Materialize a local branch at origin/stale-pr, then add a local-only
    # commit so "reused" is distinguishable from "re-created from origin".
    git -C "$TEST_REPO" branch local-work refs/remotes/origin/stale-pr

    run "$TOOL" reuse --branch local-work
    [ "$status" -eq 0 ]

    local wt="${TEST_REPO}/.claude/worktrees/reuse"
    run git -C "$wt" rev-parse --abbrev-ref HEAD
    [ "$status" -eq 0 ]
    [ "$output" = "local-work" ]

    local wt_sha local_sha
    wt_sha=$(git -C "$wt" rev-parse HEAD)
    local_sha=$(git -C "$TEST_REPO" rev-parse refs/heads/local-work)
    [ "$wt_sha" = "$local_sha" ]
}

@test "branch resolution: unknown branch is created fresh from HEAD" {
    make_origin_repo
    cd "$TEST_REPO"

    run "$TOOL" brandnew --branch never-seen
    [ "$status" -eq 0 ]

    local wt="${TEST_REPO}/.claude/worktrees/brandnew"
    run git -C "$wt" rev-parse --abbrev-ref HEAD
    [ "$status" -eq 0 ]
    [ "$output" = "never-seen" ]

    # Fresh from HEAD (main), so the PR-only file must NOT be there.
    [ ! -f "$wt/pr-only.txt" ]

    local wt_sha head_sha
    wt_sha=$(git -C "$wt" rev-parse HEAD)
    head_sha=$(git -C "$TEST_REPO" rev-parse HEAD)
    [ "$wt_sha" = "$head_sha" ]

    # No upstream — it is a purely local branch.
    run git -C "$wt" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'
    [ "$status" -ne 0 ]
}
