#!/usr/bin/env bats
#
# pr-captain-land — local-first (v2) invariant guards.
#
# The v2 rewrite inverted the flow: integrate + validate in a scratch worktree
# cut from origin/<default>, publish only already-validated work. Four
# properties make that rewrite worth having, and all four are invisible to a
# passing happy path — they only show up when something goes wrong. So they are
# pinned structurally here:
#
#   1. The agent's branch is never checked out in the main checkout (the
#      worktree-collision bug the old flow shipped with).
#   2. main/master is never pushed.
#   3. Rollback is "delete the scratch worktree" — never `git reset --hard`,
#      never a merge abort on local main.
#   4. The local validation gate exists and runs BEFORE anything is published,
#      and the CI gate reads the aggregate rollup rather than one hardcoded
#      check name that this repo does not even have.
#
# Companion suite: pr-captain-land-helpers.bats (the master-hardcode guards and
# the shared-helper-lib contract, both still live).

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
LAND="${REPO_ROOT}/.claude/skills/pr-captain-land/scripts/pr-captain-land"

# Body of the script with comment lines stripped — every guard below asserts on
# LIVE CODE. Grepping the raw file would let a deleted safeguard keep passing
# because the comment that described it survived.
live_code() {
    grep -v '^[[:space:]]*#' "$LAND"
}

# ─────────────────────────────────────────────────────────────────────────────
# Shape
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land v2: script is syntactically valid" {
    bash -n "$LAND"
}

@test "pr-captain-land v2: --help documents --rehearse and --dry-run" {
    run bash "$LAND" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--rehearse"* ]]
    [[ "$output" == *"--dry-run"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Invariant 1 — the agent's branch is never checked out in the main checkout
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land v2: never switches the main checkout to any branch" {
    # The old flow ran `git-captain switch-branch $AGENT_BRANCH`, which fails
    # outright when the agent still has that branch checked out in its own
    # worktree — and left the captain stranded there on any mid-flight abort.
    #
    # The pattern covers every way to move HEAD, not just the one tool the v1
    # code happened to use: a guard that only knows `switch-branch` passes
    # happily the day someone reaches for `git checkout` instead.
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -nE 'switch-branch|checkout-branch|git(-safe)? +(checkout|switch)'"
    [ "$status" -ne 0 ]
}

@test "pr-captain-land v2: never checks out or merges the agent branch locally" {
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -nE 'checkout-branch|merge-to-master'"
    [ "$status" -ne 0 ]
}

@test "pr-captain-land v2: integrates by cutting a scratch worktree from the origin ref" {
    live_code | grep -q 'worktree-create'
    live_code | grep -q -- '--from "origin/\$AGENT_BRANCH"'
}

@test "pr-captain-land v2: the scratch worktree name is namespaced _land-" {
    live_code | grep -q 'LAND_SLUG="_land-'
}

# ─────────────────────────────────────────────────────────────────────────────
# Invariant 2 — master is never pushed
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land v2: no push of main/master anywhere" {
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -nE 'git-push[[:space:]]+\"?(main|master)\"?|git-push[[:space:]]+\"?\\\$DEFAULT_BRANCH\"?'"
    [ "$status" -ne 0 ]
}

@test "pr-captain-land v2: the only branch pushed is the scratch land branch" {
    # Exactly one git-push call site, and it pushes $LAND_SLUG.
    count="$(live_code | grep -c 'git-push' || true)"
    [ "$count" -eq 1 ]
    live_code | grep -q 'git-push" "\$LAND_SLUG"'
}

# ─────────────────────────────────────────────────────────────────────────────
# Invariant 3 — rollback is "delete the scratch", never a reset of local main
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land v2: rollback deletes the scratch worktree" {
    live_code | grep -q 'destroy_scratch()'
    live_code | grep -q 'worktree-delete" "\$LAND_SLUG" --force'
    # And abort_land — the pre-publish failure path — must call it.
    run bash -c "sed -n '/^abort_land()/,/^}/p' '$LAND' | grep -q destroy_scratch"
    [ "$status" -eq 0 ]
}

@test "pr-captain-land v2: never hard-resets, never aborts a merge on local main" {
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -nE 'reset --hard|reset-soft|merge-abort|merge --abort'"
    [ "$status" -ne 0 ]
}

@test "pr-captain-land v2: local main is only ever moved by merge-from-origin" {
    # merge-from-origin is a normal, idempotent fast-forward — safe to run
    # again from /captain-sync-all. Any other mutation of local main would
    # reintroduce the data-loss hazard the scratch worktree exists to avoid.
    live_code | grep -q 'merge-from-origin'
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -nE 'update-ref|_sync-main-ref|branch +-f|sync-main'"
    [ "$status" -ne 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Invariant 4 — the local gate, and the CI gate that is not hardcoded
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land v2: a local validation gate exists" {
    live_code | grep -q 'run_validation_step()'
    live_code | grep -q 'VALIDATION_FAILED'
    live_code | grep -q 'VALIDATION_STEPS'
    # The ladder resolves a package manager through the shared primitive
    # rather than naming one inline.
    live_code | grep -q 'pkg-manager'
}

@test "pr-captain-land v2: validation failure aborts before anything is published" {
    # The abort_land call for a failed validation must appear BEFORE the first
    # git-push line — otherwise the gate is decorative.
    fail_line="$(grep -n 'local validation failed at step' "$LAND" | head -1 | cut -d: -f1)"
    push_line="$(grep -n 'git-push' "$LAND" | head -1 | cut -d: -f1)"
    [ -n "$fail_line" ]
    [ -n "$push_line" ]
    [ "$fail_line" -lt "$push_line" ]
}

@test "pr-captain-land v2: run_validation_step actually returns the command's status" {
    # A real unit test, not a grep: the function is self-contained (its only
    # dependency is $VALIDATION_LOG), so extract and run it. A brace group
    # ending in `echo` would swallow the failure and the gate could never
    # fail — and a source-grep for the fix cannot tell you the fix works.
    run bash -c "
        set -uo pipefail
        VALIDATION_LOG='$BATS_TEST_TMPDIR/vlog'
        eval \"\$(sed -n '/^run_validation_step()/,/^}/p' '$LAND')\"
        run_validation_step failing false >/dev/null 2>&1 && echo 'BUG: false reported success'
        run_validation_step passing true  >/dev/null 2>&1 || echo 'BUG: true reported failure'
        echo OK
    "
    [ "$status" -eq 0 ]
    [[ "$output" != *BUG* ]]
    [[ "$output" == *OK* ]]
}

@test "pr-captain-land v2: run_validation_step records both label and exit code in the log" {
    # The log's SHA-256 becomes hash_b of the landing receipt, so it has to
    # actually contain what ran and how it went.
    run bash -c "
        set -uo pipefail
        VALIDATION_LOG='$BATS_TEST_TMPDIR/vlog2'
        eval \"\$(sed -n '/^run_validation_step()/,/^}/p' '$LAND')\"
        run_validation_step 'my-step' sh -c 'exit 3' >/dev/null 2>&1 || true
        cat \"\$VALIDATION_LOG\"
    "
    [[ "$output" == *"my-step"* ]]
    [[ "$output" == *"exit: 3"* ]]
}

@test "pr-captain-land v2: validation runs with the captain's credentials scrubbed" {
    # The command comes from the branch under review and its output is tailed
    # to stderr on failure. A `build` script of `gh auth token` must not be
    # able to put the captain's PAT into the transcript.
    body="$(sed -n '/^run_validation_step()/,/^}/p' "$LAND")"
    [[ "$body" == *"-u GH_TOKEN"* ]]
    [[ "$body" == *"-u GITHUB_TOKEN"* ]]
}

@test "pr-captain-land v2: the CI gate is NOT hardcoded to lint-and-test" {
    # This repo's checks are 'bash 3.2 probe' / 'manifest version' / 'smoke'.
    # The old hardcode meant the wait loop could only ever time out.
    # Live code only — the header comment names the old hardcode on purpose,
    # to explain why the rollup gate exists.
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -n 'lint-and-test'"
    [ "$status" -ne 0 ]
}

@test "pr-captain-land v2: the CI gate reads the aggregate statusCheckRollup" {
    live_code | grep -q 'statusCheckRollup'
}

@test "pr-captain-land v2: an empty check rollup is a distinct error, not a pass" {
    live_code | grep -q 'NO_CHECKS'
    grep -q 'no status checks found' "$LAND"
}

@test "pr-captain-land v2: the CI gate fails fast on a failing check" {
    live_code | grep -q 'FAILED\*)'
}

@test "pr-captain-land v2: a repo with no resolvable local gate FAILS CLOSED" {
    # A landing with no local validation is the old PR-first flow with extra
    # steps — and it would sign a five-hash receipt attesting to a gate that
    # never ran. It must abort unless the captain explicitly opts out.
    live_code | grep -q 'ALLOW_UNVALIDATED'
    run bash -c "sed -n '/VALIDATION_STEPS.*-eq 0/,/^fi$/p' '$LAND' | grep -q abort_land"
    [ "$status" -eq 0 ]
}

@test "pr-captain-land v2: commit-precheck is not counted as a validation step" {
    # It gates on STAGED files and the scratch tree is clean, so it exits 0
    # having inspected nothing. Counting it suppressed the fail-closed check
    # above and inflated the receipt summary.
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -n 'commit-precheck'"
    [ "$status" -ne 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Trust boundary — the branch under review must not supply its own verifier
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land v2: no tool is executed from the scratch worktree" {
    # A branch that ships its own receipt-verify (or diff-hash, or pr-create)
    # would otherwise pass its own gate, and the "pr-create is not weakened"
    # guarantee would be unenforceable.
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -n 'SCRATCH_DIR/agency/tools'"
    [ "$status" -ne 0 ]
}

@test "pr-captain-land v2: tools resolve from the captain's checkout" {
    live_code | grep -q 'TOOLS="\$REPO_ROOT/agency/tools"'
    live_code | grep -q 'TOOLS/receipt-verify'
    live_code | grep -q 'TOOLS/pr-create'
}

# ─────────────────────────────────────────────────────────────────────────────
# Cleanup is unconditional, and branch protection is not bypassed by default
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land v2: an EXIT trap cleans up, so a set -e abort cannot strand the scratch" {
    live_code | grep -qE 'trap .*EXIT'
    live_code | grep -q 'PUBLISHED=false'
    live_code | grep -q 'PUBLISHED=true'
}

@test "pr-captain-land v2: cleanup only touches a scratch THIS run created" {
    # Step 2 most often fails because a previous run's branch survives. Force-
    # deleting it on the way out would destroy the state step 0 just told the
    # captain to inspect.
    live_code | grep -q 'SCRATCH_IS_OURS'
    run bash -c "sed -n '/^destroy_scratch()/,/^}/p' '$LAND' | grep -q 'SCRATCH_IS_OURS'"
    [ "$status" -eq 0 ]
}

@test "pr-captain-land v2: step 0 refuses a leftover land BRANCH, not just a leftover directory" {
    live_code | grep -q 'refs/heads/\$LAND_SLUG'
}

@test "pr-captain-land v2: --principal-approved is a flag, never hardcoded on pr-merge" {
    # pr-merge treats it as the captain's attestation that the principal
    # approved, and it is the only route to `gh pr merge --admin`. Asserting
    # it unconditionally makes branch-protection bypass the default.
    live_code | grep -q 'PRINCIPAL_APPROVED'
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -nE 'pr-merge.*--principal-approved'"
    [ "$status" -ne 0 ]
}

@test "pr-captain-land v2: the preflight fetch failure is fatal, not swallowed" {
    # Every downstream guarantee — base freshness, the receipt's diff_base,
    # "validated against pristine origin/<default>" — assumes origin refs are
    # current. `|| true` there means an offline captain validates stale refs
    # and still publishes.
    #
    # Scoped to the preflight: the post-merge fetch in step 8 is legitimately
    # best-effort, since the merge already happened.
    live_code | grep -q 'could not fetch origin'
    fetch_line="$(grep -n 'could not fetch origin' "$LAND" | head -1 | cut -d: -f1)"
    step1_line="$(grep -n 'Step 1 — Verify the agent branch' "$LAND" | head -1 | cut -d: -f1)"
    [ -n "$fetch_line" ]
    [ "$fetch_line" -lt "$step1_line" ]
}

@test "pr-captain-land v2: the scratch slug collapses dots as well as slashes" {
    # worktree-create rejects dots; the branch-name gate permits them. Slugging
    # only slashes made every dotted branch (v1.2, 46.20) unlandable.
    live_code | grep -q "LAND_SLUG=.*tr '/\.' '--'"
    # And the slug-only-slashes form must not come back.
    run grep -c "LAND_SLUG=.*tr '/' '-'" "$LAND"
    [ "$status" -ne 0 ]
}

@test "pr-captain-land v2: mktemp uses a portable template" {
    # `mktemp -t <prefix>` is a BSD-ism; GNU coreutils needs XXXXXX.
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -nE 'mktemp -t'"
    [ "$status" -ne 0 ]
    live_code | grep -q 'XXXXXX'
}

@test "pr-captain-land v2: post-merge state is not cleared when no release was cut" {
    live_code | grep -q 'RELEASE_CUT'
    run bash -c "sed -n '/RELEASE_CUT.*==.*true/,/^fi$/p' '$LAND' | grep -q 'post-merge-state\" clear'"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Receipt integrity — verify BEFORE the bump (#463 trap), and sign a landing
# receipt rather than weakening pr-create
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land v2: the agent receipt is verified before the version bump" {
    verify_line="$(grep -n 'receipt-verify' "$LAND" | head -1 | cut -d: -f1)"
    bump_line="$(grep -n 'Bumping agency_version' "$LAND" | head -1 | cut -d: -f1)"
    [ -n "$verify_line" ]
    [ -n "$bump_line" ]
    [ "$verify_line" -lt "$bump_line" ]
}

@test "pr-captain-land v2: captain signs a landing receipt chained to the agent's" {
    live_code | grep -q 'receipt-sign'
    live_code | grep -q -- '--boundary pr-captain-land'
    # hash_a chains to the agent receipt's hash_e.
    live_code | grep -q 'AGENT_HASH_E'
}

@test "pr-captain-land v2: pr-create is still the publish gate (not bypassed)" {
    live_code | grep -q 'TOOLS/pr-create'
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -n 'gh pr create'"
    [ "$status" -ne 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# --rehearse — steps 0-3 only
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land v2: --rehearse exits before the version bump" {
    rehearse_exit="$(grep -n 'rehearsal complete' "$LAND" | head -1 | cut -d: -f1)"
    bump_line="$(grep -n 'Bumping agency_version' "$LAND" | head -1 | cut -d: -f1)"
    [ -n "$rehearse_exit" ]
    [ "$rehearse_exit" -lt "$bump_line" ]
}

@test "pr-captain-land v2: --rehearse cleans up its scratch worktree" {
    block="$(sed -n '/if \[\[ "\$REHEARSE" == true \]\]/,/^fi$/p' "$LAND")"
    [[ "$block" == *"destroy_scratch"* ]]
    [[ "$block" == *"exit 0"* ]]
}

@test "pr-captain-land v2: --dry-run implies --rehearse" {
    grep -q 'dry-run) DRY_RUN=true; REHEARSE=true' "$LAND"
}

# ─────────────────────────────────────────────────────────────────────────────
# Runtime: argument and precondition handling (no network, no side effects)
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land v2: missing branch argument exits 2" {
    run bash "$LAND"
    [ "$status" -eq 2 ]
}

@test "pr-captain-land v2: unknown flag exits 2" {
    run bash "$LAND" some-branch --bogus
    [ "$status" -eq 2 ]
}

@test "pr-captain-land v2: path-traversal branch names are rejected" {
    run bash "$LAND" "../evil"
    [ "$status" -eq 2 ]
    run bash "$LAND" "a/../../evil"
    [ "$status" -eq 2 ]
}

@test "pr-captain-land v2: refuses to run outside the repo it belongs to" {
    # Hermetic: cwd is a throwaway repo, so the refusal is structural rather
    # than incidental to wherever the suite happens to run. Previously this
    # test reached `git-captain fetch` against the REAL origin — a network
    # call and a mutation of real refs from a unit suite.
    tmp="$BATS_TEST_TMPDIR/elsewhere"
    mkdir -p "$tmp"
    git init --quiet "$tmp"
    run bash -c "cd '$tmp' && bash '$LAND' some-branch --rehearse"
    [ "$status" -ne 0 ]
    # Whichever guard fires first, it must be a refusal — never a started land.
    [[ "$output" != *"Creating scratch worktree"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Shared default-branch primitive
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land v2: default branch comes from the shared resolver" {
    live_code | grep -qE '\$\(resolve_default_branch\)'
}

@test "pr-captain-land v2: the shared resolver primitive exists and is executable" {
    [ -x "${REPO_ROOT}/agency/tools/resolve-default-branch" ]
}
