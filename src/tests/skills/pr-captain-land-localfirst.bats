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
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -n 'switch-branch'"
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
    run bash -c "$(declare -f live_code); LAND='$LAND'; live_code | grep -nE 'update-ref|_sync-main-ref'"
    [ "$status" -ne 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Invariant 4 — the local gate, and the CI gate that is not hardcoded
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land v2: a local validation gate exists" {
    live_code | grep -q 'run_validation_step()'
    live_code | grep -q 'VALIDATION_FAILED'
    live_code | grep -q 'commit-precheck'
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

@test "pr-captain-land v2: run_validation_step returns the command's status, not the echo's" {
    # A brace group ending in `echo` swallows the failure and the gate can
    # never fail. Assert the explicit capture is present.
    body="$(sed -n '/^run_validation_step()/,/^}/p' "$LAND")"
    [[ "$body" == *'|| st=$?'* ]]
    [[ "$body" == *'return "$st"'* ]]
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
    live_code | grep -q 'agency/tools/pr-create'
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

@test "pr-captain-land v2: refuses to run from a worktree" {
    # This suite runs inside a worktree during development; when it runs from
    # the main checkout the branch precondition catches it instead. Either way
    # the tool must refuse a bare invocation rather than start a land.
    run bash "$LAND" definitely-not-a-real-branch --rehearse
    [ "$status" -ne 0 ]
    [[ "$output" == *"main checkout"* ]] || [[ "$output" == *"not found on origin"* ]] || [[ "$output" == *"must be on"* ]]
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
