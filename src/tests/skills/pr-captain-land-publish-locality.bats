#!/usr/bin/env bats
#
# pr-captain-land — publish path (steps 4-9) SCRATCH-LOCALITY.
#
# What Problem: the v2 rewrite validates in a scratch worktree and publishes
# only validated work. It does that by running the CAPTAIN'S trusted tools with
# the cwd set to the scratch — captain's code, scratch's data. Three of those
# tools (receipt-sign, pr-create, dispatch) resolved their target repo from
# their own INSTALL location and never looked at cwd, so on a real land:
#
#   - step 5's landing receipt was written into the captain's MAIN CHECKOUT,
#     the find-in-scratch that follows returned nothing, and the land aborted
#     with "landing receipt was signed but could not be located";
#   - step 4's version-bump commit announced itself into the main checkout,
#     leaving a dispatch for a commit that repo does not contain;
#   - step 6's pr-create would have read BRANCH from the main checkout (=main)
#     and blocked, had step 5 not failed first.
#
# The rollback was clean and origin was untouched — the safety design held. Only
# the targeting was wrong.
#
# How & Why: this slipped through because --rehearse stops at step 3 and NOTHING
# exercised 4-9. So this suite runs the step-4 and step-5 composition for real
# — real git-safe-commit, real receipt-sign, installed in one repo and pointed
# at another — and asserts on BOTH repos: the artifact appears in the scratch
# AND the captain's checkout is untouched. A single-repo fixture cannot tell
# those apart, which is precisely how the bug survived.
#
# Step 5's locate step is not re-implemented here: the `find` expression is
# EXTRACTED FROM pr-captain-land ITSELF and evaluated against the fixture. The
# original failure was the sign call and the locate call disagreeing about which
# repo they meant, so a test that hardcodes its own pattern would have passed
# through the whole outage. Steps 6-9 are network-bound (gh, origin), so they
# are pinned structurally, at the specific call sites that carry the defect.
#
# Companions: pr-captain-land-localfirst.bats (flow invariants),
# src/tests/tools/repo-root-targeting.bats (the -C contract, per tool).
#
# Written: 2026-08-11 (devex) — publish-path repo-root targeting

load '../tools/test_helper'

LAND="${REPO_ROOT}/.claude/skills/pr-captain-land/scripts/pr-captain-land"

live_code() {
    grep -v '^[[:space:]]*#' "$LAND"
}

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    iscp_test_isolation_setup

    # CAPTAIN_REPO: the main checkout. The tools are installed HERE, so anything
    # resolving SCRIPT_DIR/../.. lands here — that is the trap being tested.
    # SCRATCH_REPO: stands in for .claude/worktrees/_land-<branch>/.
    export CAPTAIN_REPO="$BATS_TEST_TMPDIR/captain"
    export SCRATCH_REPO="$BATS_TEST_TMPDIR/scratch"

    mkdir -p "$CAPTAIN_REPO/agency/tools/lib" "$CAPTAIN_REPO/agency/config"
    mkdir -p "$SCRATCH_REPO/agency/config"

    for tool in dispatch agent-identity receipt-sign git-safe git-safe-commit \
                stage-hash commit-precheck; do
        [[ -f "$REPO_ROOT/agency/tools/$tool" ]] || continue
        cp "$REPO_ROOT/agency/tools/$tool" "$CAPTAIN_REPO/agency/tools/"
        chmod +x "$CAPTAIN_REPO/agency/tools/$tool"
    done
    cp "$REPO_ROOT"/agency/tools/lib/* "$CAPTAIN_REPO/agency/tools/lib/" 2>/dev/null || true

    for root in "$CAPTAIN_REPO" "$SCRATCH_REPO"; do
        cat > "$root/agency/config/agency.yaml" <<YAML
principals:
  testuser: testprincipal
  default: testprincipal
YAML
        git init --quiet "$root"
        git -C "$root" config user.email "test@example.com"
        git -C "$root" config user.name "Test User"
        git -C "$root" remote add origin https://github.com/test-org/test-repo.git
    done

    # The scratch identifies as the land agent, exactly as worktree-create
    # leaves it — this is what put payloads under usr/<principal>/_land-*/.
    echo "captain" > "$CAPTAIN_REPO/.agency-agent"
    echo "landagent" > "$SCRATCH_REPO/.agency-agent"
    printf '{"agency_version": "46.28"}\n' > "$SCRATCH_REPO/agency/config/manifest.json"
    printf '{"agency_version": "46.28"}\n' > "$CAPTAIN_REPO/agency/config/manifest.json"

    git -C "$CAPTAIN_REPO" add -A && git -C "$CAPTAIN_REPO" commit -qm init
    git -C "$SCRATCH_REPO" add -A && git -C "$SCRATCH_REPO" commit -qm init
    git -C "$SCRATCH_REPO" branch -m "_land-devex-fix"

    export USER="testuser"
    unset CLAUDE_PROJECT_DIR AGENCY_PROJECT_ROOT AGENCY_PRINCIPAL CLAUDE_AGENT_NAME

    TOOLS="$CAPTAIN_REPO/agency/tools"
    LAND_HASH_FULL="abc1234deadbeefcafe0000111122223333444455556666777788889999aaaa"
}

teardown() {
    iscp_test_isolation_teardown
    [[ -d "${BATS_TEST_TMPDIR}" ]] && rm -rf "${BATS_TEST_TMPDIR}"
}

_captain_receipts()  { find "$CAPTAIN_REPO/agency/workstreams" -name '*.md' 2>/dev/null | wc -l | tr -d ' '; }
_captain_payloads()  { find "$CAPTAIN_REPO/usr" -name '*.md' 2>/dev/null | wc -l | tr -d ' '; }
_scratch_payloads()  { find "$SCRATCH_REPO/usr" -name '*.md' 2>/dev/null | wc -l | tr -d ' '; }

# Step 4, as pr-captain-land performs it: edit the SCRATCH manifest, stage it
# with the captain's git-safe, commit it with the captain's git-safe-commit,
# cwd in the scratch throughout.
_run_step_4() {
    printf '{"agency_version": "46.29"}\n' > "$SCRATCH_REPO/agency/config/manifest.json"
    (cd "$SCRATCH_REPO" && bash "$TOOLS/git-safe" add agency/config/manifest.json) >/dev/null
    (cd "$SCRATCH_REPO" && bash "$TOOLS/git-safe-commit" \
        "chore(manifest): bump agency_version 46.28 → 46.29 for PR landing (captain)" \
        --no-work-item) >/dev/null 2>&1
}

# Step 5's signing call, with the same -C the real script passes.
_run_step_5_sign() {
    (cd "$SCRATCH_REPO" && bash "$TOOLS/receipt-sign" \
        -C "$SCRATCH_REPO" \
        --type qgr --boundary pr-captain-land \
        --org testorg --principal testprincipal --agent captain \
        --workstream agency --project "devex-fix" \
        --hash-a aaaa --hash-b bbbb --hash-c cccc --hash-d dddd \
        --hash-e "$LAND_HASH_FULL") >/dev/null
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 4 — the version bump and its commit stay in the scratch
# ─────────────────────────────────────────────────────────────────────────────

@test "step 4: the version bump is committed in the scratch, not the captain checkout" {
    _run_step_4
    run git -C "$SCRATCH_REPO" log -1 --pretty=%s
    assert_output_contains "bump agency_version"
    # The captain checkout still has exactly its init commit.
    run bash -c "git -C '$CAPTAIN_REPO' rev-list --count HEAD"
    [ "$output" -eq 1 ]
    run bash -c "grep -o '46\\.[0-9]*' '$CAPTAIN_REPO/agency/config/manifest.json'"
    assert_output_contains "46.28"
}

@test "step 4: the commit-announce dispatch lands in the scratch" {
    _run_step_4
    [ "$(_scratch_payloads)" -ge 1 ]
    run find "$SCRATCH_REPO/usr" -name 'commit-to-captain-committed-*.md'
    assert_success
    [ -n "$output" ]
}

@test "step 4: the commit-announce does NOT leak into the captain's main checkout" {
    # The observed symptom: a stray usr/<principal>/_land-<branch>/dispatches/
    # file in the main checkout, announcing a commit that repo does not contain.
    _run_step_4
    [ "$(_captain_payloads)" -eq 0 ]
}

@test "step 4: the captain's working tree is left clean by a scratch commit" {
    _run_step_4
    run bash -c "git -C '$CAPTAIN_REPO' status --porcelain"
    assert_success
    [ -z "$output" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 5 — the landing receipt is signed into, and findable in, the scratch
# ─────────────────────────────────────────────────────────────────────────────

@test "step 5: the landing receipt is written into the scratch worktree" {
    _run_step_5_sign
    run find "$SCRATCH_REPO/agency/workstreams/agency/qgr" -name '*-pr-captain-land-*.md'
    assert_success
    [ -n "$output" ]
}

@test "step 5: the landing receipt does NOT land in the captain's main checkout" {
    # This exact leak aborted a real land: signed successfully, into the wrong
    # repo, so the locate step below found nothing and rolled everything back.
    _run_step_5_sign
    [ "$(_captain_receipts)" -eq 0 ]
}

@test "step 5: pr-captain-land's OWN locate expression finds the signed receipt" {
    # The heart of the regression. The `find` is lifted verbatim out of the
    # script rather than restated, so if the sign call and the locate call ever
    # disagree about which repo they mean — the original bug — this fails.
    _run_step_5_sign

    locate_line="$(grep -n 'LANDING_RECEIPT=\$(find' "$LAND" | head -1 | cut -d: -f2-)"
    [ -n "$locate_line" ]

    run bash -c "
        set -uo pipefail
        SCRATCH_DIR='$SCRATCH_REPO'
        LAND_HASH_FULL='$LAND_HASH_FULL'
        $locate_line
        echo \"\$LANDING_RECEIPT\"
    "
    assert_success
    [ -n "$output" ]
    [[ "$output" == "$SCRATCH_REPO"* ]]
    [[ "$output" == *"pr-captain-land"* ]]
}

@test "step 5: the located receipt relativizes to a path inside the scratch" {
    # LANDING_RECEIPT_REL is what gets staged and what the PR body advertises.
    # An absolute captain-checkout path here is what produced the abort.
    _run_step_5_sign
    receipt="$(find "$SCRATCH_REPO/agency/workstreams/agency/qgr" -name '*-pr-captain-land-*.md' | head -1)"
    rel="${receipt#"$SCRATCH_REPO"/}"
    [ "$rel" != "$receipt" ]
    [ -f "$SCRATCH_REPO/$rel" ]
    [[ "$rel" == agency/workstreams/agency/qgr/* ]]
}

@test "steps 4+5 together: the captain checkout gains nothing at all" {
    # The composite property the whole scratch-worktree design rests on.
    before="$(cd "$CAPTAIN_REPO" && find . -path ./.git -prune -o -type f -print | sort)"
    _run_step_4
    _run_step_5_sign
    after="$(cd "$CAPTAIN_REPO" && find . -path ./.git -prune -o -type f -print | sort)"
    [ "$before" == "$after" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Steps 4-9 call sites — the -C wiring, and the class of bug behind it
# ─────────────────────────────────────────────────────────────────────────────

@test "step 5 call site: receipt-sign is invoked with -C \$SCRATCH_DIR" {
    live_code | grep -q 'TOOLS/receipt-sign"'
    run bash -c "sed -n '/TOOLS\/receipt-sign\"/,/receipt-sign\"\$/p' '$LAND' | head -3 | grep -q -- '-C \"\$SCRATCH_DIR\"'"
    assert_success
}

@test "step 6 call site: pr-create is invoked with -C \$SCRATCH_DIR" {
    run bash -c "sed -n '/TOOLS\/pr-create\"/,+3p' '$LAND' | grep -q -- '-C \"\$SCRATCH_DIR\"'"
    assert_success
}

@test "steps 4-9: every dispatch call names its repo root explicitly" {
    # Both dispatch call sites belong to the CAPTAIN's checkout: the failure
    # notice is written moments before destroy_scratch, and the success notice
    # after it. Neither may inherit a root from CLAUDE_PROJECT_DIR — a captain
    # whose env points at a worktree would file both into a directory that is
    # deleted or wrong.
    total="$(live_code | grep -c 'TOOLS/dispatch"' || true)"
    with_c="$(live_code | grep -c 'TOOLS/dispatch" -C "\$REPO_ROOT"' || true)"
    [ "$total" -ge 2 ]
    [ "$total" -eq "$with_c" ]
}

@test "steps 4-9: no install-rooted tool is run against the scratch without -C" {
    # The class guard, not just the two known instances. Any tool that resolves
    # its repo from SCRIPT_DIR/../.. is mis-targeted the moment pr-captain-land
    # runs it with the cwd in the scratch. Enumerate them from the SOURCE rather
    # than from a list someone has to remember to update.
    #
    # Allowlist, each with a reason that must still hold if you extend it:
    #   receipt-verify   — always called with an ABSOLUTE --file path, so its
    #                      REPO_ROOT is never consulted on that code path.
    #   post-merge-state — captain-side state by design; the scratch is gone by
    #                      the time it is cleared.
    #   dispatch         — checked above; passes -C "$REPO_ROOT" deliberately.
    #   git-safe-commit  — resolves PROJECT_ROOT from `git rev-parse
    #                      --show-toplevel` FIRST and only falls back to its
    #                      install dir; run with the cwd in the scratch it is
    #                      already correct, and it forwards that root to
    #                      dispatch via -C.
    allow=" receipt-verify post-merge-state dispatch git-safe-commit "
    offenders=""

    for tool in $(live_code | grep -oE 'TOOLS/[a-z0-9-]+' | cut -d/ -f2 | sort -u); do
        src="$REPO_ROOT/agency/tools/$tool"
        [[ -f "$src" ]] || continue
        # LIVE CODE only. A comment that merely NAMES the bad pattern — such as
        # the one in pr-merge explaining why it has no repo root — is not the
        # bug, and flagging it teaches authors to stop documenting the trap.
        grep -v '^[[:space:]]*#' "$src" | grep -q 'SCRIPT_DIR/\.\./\.\.' || continue
        [[ "$allow" == *" $tool "* ]] && continue
        # Install-rooted and used here: every invocation must carry -C.
        if ! live_code | grep -A3 "TOOLS/$tool\"" | grep -q -- '-C '; then
            offenders="$offenders $tool"
        fi
    done

    [ -z "$offenders" ] || {
        echo "Install-rooted tools invoked without -C: $offenders" >&2
        echo "Each resolves its repo from its own install dir and will target" >&2
        echo "the captain's main checkout, not the scratch. Pass -C, or add to" >&2
        echo "the allowlist above WITH a reason." >&2
        false
    }
}

@test "steps 4-9: pr-merge carries no install-rooted repo root to be misused" {
    # It is repo-agnostic (operates on a PR number, lets gh infer the repo). It
    # used to carry a dead PROJECT_ROOT="$SCRIPT_DIR/../.." — the exact pattern
    # that broke the other three, sitting there waiting to be "used".
    run bash -c "grep -v '^[[:space:]]*#' '$REPO_ROOT/agency/tools/pr-merge' | grep -q 'PROJECT_ROOT='"
    assert_failure
}

@test "the publish path is no longer wholly untested" {
    # Meta-guard on the gap itself. --rehearse stops at step 3, so for as long
    # as this file is the only runtime coverage of steps 4-5, deleting it must
    # be a deliberate act rather than a quiet one.
    [ -f "$BATS_TEST_FILENAME" ]
    run bash -c "grep -c '^@test' '$BATS_TEST_FILENAME'"
    [ "$output" -ge 10 ]
}
