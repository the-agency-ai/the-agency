#!/usr/bin/env bats
#
# Tests for agency/tools/worktree-create
#
# Two contracts are covered here:
#
#   1. NAMING — the --workstream/--agent collapse rule (dispatch #166, resolved
#      in #169). Exercised via --compute-only; no worktrees are created.
#
#   2. BRANCH RESOLUTION — the local / --from / remote-tracking / fresh-from-HEAD
#      decision (v2.3.0). These DO create real worktrees, so they run against
#      an isolated bare-origin + clone fixture (make_origin_repo) and never
#      touch the live checkout.
#
# ISOLATION IS LOAD-BEARING HERE. The only thing keeping group 2 out of the
# live repo is worktree-create honoring AGENCY_PROJECT_ROOT — and during
# development it did NOT (lib/_path-resolve reassigns that variable on source),
# which put three real worktrees in the live devex checkout. Two guards now
# make a regression fail loudly instead of scribbling on the repo:
#   - setup() points AGENCY_PROJECT_ROOT at a nonexistent path, so any test
#     that reaches the creation path without the fixture dies there.
#   - assert_no_live_repo_leak() checks the live repo after each creation test.
#
# Written: 2026-04-09 — dispatch #166/#169, task #9
# Extended: 2026-08-08 — --from / local-first landing start point (v2.2.0)
# Extended: 2026-08-12 — branch-resolution DWIM + isolation guards, reconciled
#                        with --from into one four-case ladder (v2.3.0)

load test_helper

setup() {
    test_isolation_setup
    export TOOL="${REPO_ROOT}/agency/tools/worktree-create"

    # Poison the default. Only make_origin_repo sets a usable root; anything
    # else that reaches the worktree-creation path fails on a missing dir
    # rather than defaulting to the live repo. See the header note.
    export AGENCY_PROJECT_ROOT="${BATS_TEST_TMPDIR}/no-such-project-root"

    # Snapshot the live repo's worktrees and branches. teardown() diffs these,
    # so a leak is caught no matter where in the test body it happened — an
    # in-body assertion would be skipped by an earlier failure.
    git -C "$REPO_ROOT" worktree list > "${BATS_TEST_TMPDIR}/wt-before" 2>/dev/null || true
    git -C "$REPO_ROOT" for-each-ref --format='%(refname)' refs/heads \
        > "${BATS_TEST_TMPDIR}/heads-before" 2>/dev/null || true
}

teardown() {
    # Leak guard first — report it even if the isolation teardown also fails.
    local leaked=0
    git -C "$REPO_ROOT" worktree list > "${BATS_TEST_TMPDIR}/wt-after" 2>/dev/null || true
    git -C "$REPO_ROOT" for-each-ref --format='%(refname)' refs/heads \
        > "${BATS_TEST_TMPDIR}/heads-after" 2>/dev/null || true

    if ! diff -q "${BATS_TEST_TMPDIR}/wt-before" "${BATS_TEST_TMPDIR}/wt-after" >/dev/null 2>&1; then
        echo "LEAK: this test changed the live repo's worktree list:" >&2
        diff "${BATS_TEST_TMPDIR}/wt-before" "${BATS_TEST_TMPDIR}/wt-after" >&2 || true
        leaked=1
    fi
    if ! diff -q "${BATS_TEST_TMPDIR}/heads-before" "${BATS_TEST_TMPDIR}/heads-after" >/dev/null 2>&1; then
        echo "LEAK: this test created or removed branches in the live repo:" >&2
        diff "${BATS_TEST_TMPDIR}/heads-before" "${BATS_TEST_TMPDIR}/heads-after" >&2 || true
        leaked=1
    fi

    # The shared teardown has its own guard (it detects live .git/config
    # pollution and returns 1). Swallowing that status would let exactly the
    # class of incident this file's isolation story exists to prevent pass
    # silently whenever the two diffs above happen to be clean.
    test_isolation_teardown || leaked=1

    return "$leaked"
}

# In-body companion to the teardown guard — asserts at the point of use that a
# named worktree did not land in the live checkout. Redundant by design: the
# teardown catches everything, this makes the intent legible where it matters.
assert_no_live_repo_leak() {
    local name
    for name in "$@"; do
        if [[ -e "${REPO_ROOT}/.claude/worktrees/${name}" ]]; then
            echo "LEAK: ${REPO_ROOT}/.claude/worktrees/${name} was created" >&2
            return 1
        fi
    done
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

    # git < 2.28 ignores --initial-branch, leaving the bare HEAD on master.
    # Repoint it explicitly or the second clone below checks out nothing and
    # the tests fail with a confusing unborn-HEAD error instead of a clear one.
    git -C "$upstream" symbolic-ref HEAD refs/heads/main

    git clone --quiet "$upstream" "$seed" 2>/dev/null
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

    # 'local-work' exists on origin at MAIN's commit. Tests that want to prove
    # local-beats-remote precedence create a local local-work pointing
    # somewhere else, so the two candidates are distinguishable by SHA.
    git -C "$seed" push --quiet origin main:refs/heads/local-work

    # Fresh clone: has origin/stale-pr, has no local stale-pr.
    git clone --quiet "$upstream" "$TEST_REPO"
    git -C "$TEST_REPO" config user.email "test@test.com"
    git -C "$TEST_REPO" config user.name "Test"
    git -C "$TEST_REPO" config commit.gpgsign false

    export AGENCY_PROJECT_ROOT="$TEST_REPO"
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
    # Pin the tool name + a semver shape, not an exact patch level — the exact
    # string churns on every feature bump.
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

@test "help: documents --from" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--from"* ]]
}

@test "help: documents the branch-resolution order" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Branch resolution"* ]]
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
# Name validation
# ─────────────────────────────────────────────────────────────────────────────

@test "name validation: a leading underscore is allowed (machine scratch worktrees)" {
    # The name must survive validation; the run may still fail later for
    # unrelated environment reasons, so assert on the validation message only.
    run "$TOOL" _land-example --from no/such/ref
    [[ "$output" != *"name must start with"* ]]
}

@test "name validation: a leading digit is still rejected" {
    run "$TOOL" 9bad
    [ "$status" -ne 0 ]
    [[ "$output" == *"name must start with"* ]]
}

@test "name validation: a slash in the name is still rejected" {
    run "$TOOL" bad/name
    [ "$status" -ne 0 ]
    [[ "$output" == *"name must start with"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Branch resolution — four cases (v2.3.0)
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

    assert_no_live_repo_leak revive
}

@test "branch resolution: origin-only branch sets upstream tracking and a local ref" {
    make_origin_repo
    cd "$TEST_REPO"

    run "$TOOL" revive --branch stale-pr
    [ "$status" -eq 0 ]
    # The tool must say which path it took — a matching SHA alone could be luck.
    [[ "$output" == *"tracking origin/stale-pr"* ]]

    run git -C "${TEST_REPO}/.claude/worktrees/revive" \
        rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'
    [ "$status" -eq 0 ]
    [ "$output" = "origin/stale-pr" ]

    # Observable side effect in the parent repo: the local branch now exists.
    git -C "$TEST_REPO" show-ref --verify --quiet refs/heads/stale-pr

    assert_no_live_repo_leak revive
}

@test "branch resolution: local branch WINS over a same-named origin branch" {
    make_origin_repo
    cd "$TEST_REPO"

    # origin/local-work sits at main. Point the LOCAL local-work at stale-pr's
    # commit instead, so the two candidates have different SHAs and the
    # precedence question actually has an observable answer.
    git -C "$TEST_REPO" branch local-work refs/remotes/origin/stale-pr

    local origin_sha local_sha
    origin_sha=$(git -C "$TEST_REPO" rev-parse refs/remotes/origin/local-work)
    local_sha=$(git -C "$TEST_REPO" rev-parse refs/heads/local-work)
    [ "$origin_sha" != "$local_sha" ]

    run "$TOOL" reuse --branch local-work
    [ "$status" -eq 0 ]
    # Must NOT have taken the remote path.
    [[ "$output" != *"tracking origin/local-work"* ]]

    local wt="${TEST_REPO}/.claude/worktrees/reuse"
    run git -C "$wt" rev-parse --abbrev-ref HEAD
    [ "$status" -eq 0 ]
    [ "$output" = "local-work" ]

    # Landed on the LOCAL sha, not origin's — this fails if the remote check
    # is ever hoisted above the local one.
    local wt_sha
    wt_sha=$(git -C "$wt" rev-parse HEAD)
    [ "$wt_sha" = "$local_sha" ]
    [ "$wt_sha" != "$origin_sha" ]
    [ -f "$wt/pr-only.txt" ]

    assert_no_live_repo_leak reuse
}

@test "branch resolution: unknown branch is created fresh from HEAD" {
    make_origin_repo
    cd "$TEST_REPO"

    run "$TOOL" brandnew --branch never-seen
    [ "$status" -eq 0 ]
    [[ "$output" == *"creating it fresh from HEAD"* ]]

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

    assert_no_live_repo_leak brandnew
}

@test "branch resolution: no --branch defaults to the worktree name" {
    make_origin_repo
    cd "$TEST_REPO"

    # The most common real invocation, and previously untested end-to-end.
    run "$TOOL" solo
    [ "$status" -eq 0 ]

    local wt="${TEST_REPO}/.claude/worktrees/solo"
    run git -C "$wt" rev-parse --abbrev-ref HEAD
    [ "$status" -eq 0 ]
    [ "$output" = "solo" ]

    assert_no_live_repo_leak solo
}

@test "branch resolution: default branch name also resolves an origin-only branch" {
    make_origin_repo
    cd "$TEST_REPO"

    # Worktree name == branch name is how agents are created (worktree 'devex'
    # on branch 'devex'). If that branch already exists on origin, creating a
    # fresh one from HEAD would shadow the agent's real work — so the remote
    # path must apply here too, not only when --branch is typed.
    run "$TOOL" stale-pr
    [ "$status" -eq 0 ]
    [[ "$output" == *"tracking origin/stale-pr"* ]]

    local wt="${TEST_REPO}/.claude/worktrees/stale-pr"
    [ -f "$wt/pr-only.txt" ]

    assert_no_live_repo_leak stale-pr
}

@test "branch resolution: slash-bearing remote branch resolves (the real PR shape)" {
    make_origin_repo
    cd "$TEST_REPO"

    git -C "$TEST_REPO" push --quiet origin \
        refs/remotes/origin/stale-pr:refs/heads/fix/pr-submit-org-resolution
    git -C "$TEST_REPO" fetch --quiet origin

    run "$TOOL" slashy --branch fix/pr-submit-org-resolution
    [ "$status" -eq 0 ]
    [[ "$output" == *"tracking origin/fix/pr-submit-org-resolution"* ]]

    local wt="${TEST_REPO}/.claude/worktrees/slashy"
    run git -C "$wt" rev-parse --abbrev-ref HEAD
    [ "$status" -eq 0 ]
    [ "$output" = "fix/pr-submit-org-resolution" ]
    [ -f "$wt/pr-only.txt" ]

    assert_no_live_repo_leak slashy
}

# ─────────────────────────────────────────────────────────────────────────────
# --from <ref> — explicit start point (local-first landing cuts its scratch
# worktree from a pristine origin ref, never from whatever HEAD happens to be)
# ─────────────────────────────────────────────────────────────────────────────

@test "--from: rejects a ref that does not resolve to a commit" {
    # Against a REAL repo, so the rejection proves the ref lookup failed — not
    # merely that $PROJECT_ROOT wasn't a git repo at all.
    make_origin_repo
    cd "$TEST_REPO"

    run "$TOOL" _scratch-nope --from no/such/ref
    [ "$status" -ne 0 ]
    [[ "$output" == *"does not resolve"* ]]
    [ ! -d "${TEST_REPO}/.claude/worktrees/_scratch-nope" ]

    assert_no_live_repo_leak _scratch-nope
}

@test "--from: a tag and a raw SHA both resolve" {
    make_origin_repo
    cd "$TEST_REPO"

    git -C "$TEST_REPO" tag pinned refs/remotes/origin/stale-pr
    local sha
    sha=$(git -C "$TEST_REPO" rev-parse refs/remotes/origin/stale-pr)

    run "$TOOL" from-tag --branch from-tag --from pinned
    [ "$status" -eq 0 ]
    [ -f "${TEST_REPO}/.claude/worktrees/from-tag/pr-only.txt" ]

    run "$TOOL" from-sha --branch from-sha --from "$sha"
    [ "$status" -eq 0 ]
    [ -f "${TEST_REPO}/.claude/worktrees/from-sha/pr-only.txt" ]

    assert_no_live_repo_leak from-tag from-sha
}

@test "--from: cuts a new branch at the given ref (the _land- scratch shape)" {
    make_origin_repo
    cd "$TEST_REPO"

    run "$TOOL" _land-stale-pr --branch _land-stale-pr --from origin/stale-pr
    [ "$status" -eq 0 ]

    local wt="${TEST_REPO}/.claude/worktrees/_land-stale-pr"
    run git -C "$wt" rev-parse --abbrev-ref HEAD
    [ "$status" -eq 0 ]
    [ "$output" = "_land-stale-pr" ]

    local wt_sha origin_sha
    wt_sha=$(git -C "$wt" rev-parse HEAD)
    origin_sha=$(git -C "$TEST_REPO" rev-parse refs/remotes/origin/stale-pr)
    [ "$wt_sha" = "$origin_sha" ]
    [ -f "$wt/pr-only.txt" ]

    assert_no_live_repo_leak _land-stale-pr
}

@test "--from: refuses when the branch already exists locally" {
    make_origin_repo
    cd "$TEST_REPO"

    git -C "$TEST_REPO" branch already-here refs/remotes/origin/stale-pr

    run "$TOOL" clash --branch already-here --from origin/main
    [ "$status" -ne 0 ]
    [[ "$output" == *"already exists"* ]]

    [ ! -d "${TEST_REPO}/.claude/worktrees/clash" ]
    assert_no_live_repo_leak clash
}

@test "--from: outranks the remote-branch search, and says so" {
    make_origin_repo
    cd "$TEST_REPO"

    # origin/stale-pr exists, but the caller explicitly asked for origin/main.
    # Explicit wins — and the shadowing must be announced, not silent.
    run "$TOOL" explicit --branch stale-pr --from origin/main
    [ "$status" -eq 0 ]
    [[ "$output" != *"tracking origin/stale-pr"* ]]
    [[ "$output" == *"--from wins"* ]]

    local wt="${TEST_REPO}/.claude/worktrees/explicit"
    local wt_sha main_sha
    wt_sha=$(git -C "$wt" rev-parse HEAD)
    main_sha=$(git -C "$TEST_REPO" rev-parse refs/remotes/origin/main)
    [ "$wt_sha" = "$main_sha" ]
    [ ! -f "$wt/pr-only.txt" ]

    assert_no_live_repo_leak explicit
}

# ─────────────────────────────────────────────────────────────────────────────
# Branch-resolution error paths
# ─────────────────────────────────────────────────────────────────────────────

@test "branch resolution: existing worktree directory is refused" {
    make_origin_repo
    cd "$TEST_REPO"

    mkdir -p "${TEST_REPO}/.claude/worktrees/taken"
    run "$TOOL" taken --branch never-seen
    [ "$status" -ne 0 ]
    [[ "$output" == *"already exists"* ]]
}

@test "branch resolution: branch already checked out elsewhere fails cleanly" {
    make_origin_repo
    cd "$TEST_REPO"

    run "$TOOL" first --branch stale-pr
    [ "$status" -eq 0 ]

    # git refuses to check the same branch out twice; the tool must surface it.
    run "$TOOL" second --branch stale-pr
    [ "$status" -ne 0 ]

    assert_no_live_repo_leak first second
}

@test "branch resolution: origin wins when several remotes carry the branch" {
    make_origin_repo
    cd "$TEST_REPO"

    # A second remote that also has 'stale-pr'. origin must break the tie.
    git -C "$TEST_REPO" remote add mirror "${BATS_TEST_TMPDIR}/upstream.git"
    git -C "$TEST_REPO" fetch --quiet mirror

    run "$TOOL" tiebreak --branch stale-pr
    [ "$status" -eq 0 ]
    [[ "$output" == *"tracking origin/stale-pr"* ]]

    assert_no_live_repo_leak tiebreak
}

@test "branch resolution: a single non-origin remote is used without complaint" {
    make_origin_repo
    cd "$TEST_REPO"

    # No origin at all — exactly one remote carries the branch, so there is
    # nothing ambiguous and the DWIM path must still fire.
    git -C "$TEST_REPO" remote add mirror "${BATS_TEST_TMPDIR}/upstream.git"
    git -C "$TEST_REPO" fetch --quiet mirror
    git -C "$TEST_REPO" remote remove origin

    run "$TOOL" solo-remote --branch stale-pr
    [ "$status" -eq 0 ]
    [[ "$output" == *"tracking mirror/stale-pr"* ]]
    [ -f "${TEST_REPO}/.claude/worktrees/solo-remote/pr-only.txt" ]

    assert_no_live_repo_leak solo-remote
}

@test "branch resolution: several non-origin remotes is refused, not guessed" {
    make_origin_repo
    cd "$TEST_REPO"

    # Two remotes carry 'stale-pr' and neither is 'origin' — genuinely
    # ambiguous, so the tool must refuse rather than pick one.
    git -C "$TEST_REPO" remote add mirror-a "${BATS_TEST_TMPDIR}/upstream.git"
    git -C "$TEST_REPO" remote add mirror-b "${BATS_TEST_TMPDIR}/upstream.git"
    git -C "$TEST_REPO" fetch --quiet mirror-a
    git -C "$TEST_REPO" fetch --quiet mirror-b
    git -C "$TEST_REPO" remote remove origin

    run "$TOOL" ambiguous --branch stale-pr
    [ "$status" -ne 0 ]
    [[ "$output" == *"multiple remotes"* ]]
    [ ! -d "${TEST_REPO}/.claude/worktrees/ambiguous" ]

    assert_no_live_repo_leak ambiguous
}

@test "branch resolution: --from settles a multi-remote ambiguity" {
    make_origin_repo
    cd "$TEST_REPO"

    git -C "$TEST_REPO" remote add mirror-a "${BATS_TEST_TMPDIR}/upstream.git"
    git -C "$TEST_REPO" remote add mirror-b "${BATS_TEST_TMPDIR}/upstream.git"
    git -C "$TEST_REPO" fetch --quiet mirror-a
    git -C "$TEST_REPO" fetch --quiet mirror-b
    git -C "$TEST_REPO" remote remove origin

    run "$TOOL" settled --branch stale-pr --from mirror-a/stale-pr
    [ "$status" -eq 0 ]
    [ -f "${TEST_REPO}/.claude/worktrees/settled/pr-only.txt" ]

    assert_no_live_repo_leak settled
}

@test "invalid: --branch with an illegal git branch name is rejected" {
    make_origin_repo
    cd "$TEST_REPO"

    run "$TOOL" bad --branch "HEAD"
    [ "$status" -ne 0 ]
    [[ "$output" == *"not a valid git branch name"* ]]
}

@test "invalid: --branch with no value fails with a usage hint, not a bash error" {
    run "$TOOL" foo --branch
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
    [[ "$output" != *"unbound variable"* ]]
}

@test "invalid: --from with no value fails with a usage hint, not a bash error" {
    run "$TOOL" foo --from
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
    [[ "$output" != *"unbound variable"* ]]
}

@test "invalid: --workstream with no value fails with a usage hint" {
    run "$TOOL" --workstream
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
    [[ "$output" != *"unbound variable"* ]]
}

@test "invalid: --agent with no value fails with a usage hint" {
    run "$TOOL" --workstream devex --agent
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
    [[ "$output" != *"unbound variable"* ]]
}

@test "invalid: --compute-only --workstream with no value fails with a usage hint" {
    run "$TOOL" --compute-only --workstream
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
    [[ "$output" != *"unbound variable"* ]]
}

@test "invalid: a flag swallowed as another flag's value is rejected" {
    # Without the look-ahead guard this sets BRANCH=--from and dies much later
    # with a raw git message about an invalid branch name.
    run "$TOOL" foo --branch --from bar
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
    [[ "$output" == *"looks like a flag"* ]]
}

@test "invalid: an unknown option is rejected in the main flow" {
    run "$TOOL" foo --bogus
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "invalid: an unknown option is rejected in --compute-only mode" {
    run "$TOOL" --compute-only --bogus x
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# --workstream/--agent through the REAL creation path
#
# Every other collapse-rule test uses --compute-only, which short-circuits
# before the main flag loop. The real path re-implements the pairing check and
# feeds the computed name into branch resolution — separate code, separate risk.
# ─────────────────────────────────────────────────────────────────────────────

@test "workstream form: creates a worktree at the collapsed name" {
    make_origin_repo
    cd "$TEST_REPO"

    run "$TOOL" --workstream mdpal --agent mdpal-app
    [ "$status" -eq 0 ]

    local wt="${TEST_REPO}/.claude/worktrees/mdpal-app"
    [ -d "$wt" ]
    run git -C "$wt" rev-parse --abbrev-ref HEAD
    [ "$status" -eq 0 ]
    [ "$output" = "mdpal-app" ]

    assert_no_live_repo_leak mdpal-app
}

@test "workstream form: computed name still resolves an origin-only branch" {
    make_origin_repo
    cd "$TEST_REPO"

    # Push the branch the collapse rule will compute, so the DWIM path must
    # apply to a name the caller never typed.
    git -C "$TEST_REPO" push --quiet origin \
        refs/remotes/origin/stale-pr:refs/heads/agency-captain

    run "$TOOL" --workstream agency --agent captain
    [ "$status" -eq 0 ]
    [[ "$output" == *"tracking origin/agency-captain"* ]]
    [ -f "${TEST_REPO}/.claude/worktrees/agency-captain/pr-only.txt" ]

    assert_no_live_repo_leak agency-captain
}

@test "workstream form: --workstream without --agent fails in the real path too" {
    run "$TOOL" --workstream devex
    [ "$status" -ne 0 ]
    [[ "$output" == *"must be given together"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Dependency bootstrap
# ─────────────────────────────────────────────────────────────────────────────

@test "bootstrap: no package.json means no install is attempted" {
    make_origin_repo
    cd "$TEST_REPO"

    run "$TOOL" nodeps --branch never-seen
    [ "$status" -eq 0 ]
    [[ "$output" != *"Installing dependencies"* ]]

    assert_no_live_repo_leak nodeps
}

@test "bootstrap: package-lock.json selects npm, and a failing install is not fatal" {
    make_origin_repo
    cd "$TEST_REPO"

    # Commit a node-shaped project on a branch, so the new worktree has one.
    git -C "$TEST_REPO" checkout --quiet -b nodeish
    echo '{"name":"fixture","version":"1.0.0"}' > "$TEST_REPO/package.json"
    echo '{}' > "$TEST_REPO/package-lock.json"
    git -C "$TEST_REPO" add package.json package-lock.json
    git -C "$TEST_REPO" commit --quiet --no-verify -m "node fixture"
    git -C "$TEST_REPO" checkout --quiet main

    # Stub npm so the test neither hits the network nor depends on a real npm.
    # It records the invocation and exits nonzero — the tool swallows install
    # failures by design, so the worktree must still be reported as created.
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    cat > "${BATS_TEST_TMPDIR}/bin/npm" <<'STUB'
#!/bin/bash
echo "$@" >> "${NPM_STUB_LOG}"
exit 3
STUB
    chmod +x "${BATS_TEST_TMPDIR}/bin/npm"
    export NPM_STUB_LOG="${BATS_TEST_TMPDIR}/npm-calls"
    export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"

    run "$TOOL" nodey --branch nodeish
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing dependencies"* ]]
    [[ "$output" == *"created successfully"* ]]

    [ -f "$NPM_STUB_LOG" ]
    grep -q "ci" "$NPM_STUB_LOG"

    assert_no_live_repo_leak nodey
}
