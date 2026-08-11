#!/usr/bin/env bats
#
# What Problem: three framework tools — receipt-sign, pr-create, dispatch —
# resolved the repository they operate on from SCRIPT_DIR/../.., i.e. their own
# INSTALL location, and ignored the cwd entirely. pr-captain-land runs the
# CAPTAIN'S trusted tools against a scratch worktree by setting the cwd, so on a
# real land every one of them silently targeted the captain's main checkout
# instead of the scratch: the landing receipt was written to the wrong repo (the
# land then aborted, unable to find it), a commit-announce dispatch was littered
# into a checkout that did not contain the commit, and pr-create would have read
# BRANCH=main and blocked outright.
#
# How & Why: each tool now takes `-C <repo-root>` as its FIRST argument. These
# tests are two-repo by construction — the tool is INSTALLED in one repo and
# pointed at another — because a single-repo fixture cannot tell "honoured -C"
# apart from "fell back to its install dir", which is the entire bug. Every case
# asserts BOTH that the write landed in the target AND that the install repo
# stayed clean; the leak, not just the miss, is what burned a real land.
#
# The default (no -C) paths are pinned too. -C exists to fix pr-captain-land
# without touching the dozens of existing callers, so "unchanged when absent" is
# a contract, not an implementation detail.
#
# Written: 2026-08-11 (devex) — publish-path repo-root targeting

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    iscp_test_isolation_setup

    # INSTALL_REPO: stands in for the captain's main checkout — the tools live
    # here, so SCRIPT_DIR/../.. resolves here. TARGET_REPO: stands in for the
    # scratch worktree. Distinct roots are the whole point of the fixture.
    export INSTALL_REPO="$BATS_TEST_TMPDIR/install-repo"
    export TARGET_REPO="$BATS_TEST_TMPDIR/target-repo"

    mkdir -p "$INSTALL_REPO/agency/tools/lib" "$INSTALL_REPO/agency/config"
    mkdir -p "$TARGET_REPO/agency/config" "$TARGET_REPO/agency/tools"

    for tool in dispatch agent-identity receipt-sign receipt-verify \
                pr-create resolve-default-branch; do
        cp "$REPO_ROOT/agency/tools/$tool" "$INSTALL_REPO/agency/tools/"
        chmod +x "$INSTALL_REPO/agency/tools/$tool"
    done
    cp "$REPO_ROOT"/agency/tools/lib/* "$INSTALL_REPO/agency/tools/lib/" 2>/dev/null || true

    for root in "$INSTALL_REPO" "$TARGET_REPO"; do
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

    echo "captainagent" > "$INSTALL_REPO/.agency-agent"
    echo "landagent" > "$TARGET_REPO/.agency-agent"
    echo "seed" > "$TARGET_REPO/file.txt"
    git -C "$INSTALL_REPO" add -A && git -C "$INSTALL_REPO" commit -qm init
    git -C "$TARGET_REPO" add -A && git -C "$TARGET_REPO" commit -qm init
    # The target is on a feature branch and the install repo is on main: that
    # asymmetry is what makes pr-create's BRANCH gate observable.
    git -C "$TARGET_REPO" branch -m feature-branch

    export USER="testuser"
    unset CLAUDE_PROJECT_DIR AGENCY_PROJECT_ROOT AGENCY_PRINCIPAL CLAUDE_AGENT_NAME

    RECEIPT_SIGN="$INSTALL_REPO/agency/tools/receipt-sign"
    PR_CREATE="$INSTALL_REPO/agency/tools/pr-create"
    DISPATCH="$INSTALL_REPO/agency/tools/dispatch"
}

teardown() {
    iscp_test_isolation_teardown
    [[ -d "${BATS_TEST_TMPDIR}" ]] && rm -rf "${BATS_TEST_TMPDIR}"
}

# $1 = repo root to target, or "" to omit -C entirely.
# No arrays: bash 3.2 is the floor and empty-array expansion is a trap there.
_sign_into() {
    local target="$1"
    if [[ -n "$target" ]]; then
        "$RECEIPT_SIGN" -C "$target" \
            --type qgr --boundary test-boundary \
            --org testorg --principal testprincipal --agent testagent \
            --workstream testws --project testproj \
            --hash-a aaaa --hash-b bbbb --hash-c cccc --hash-d dddd \
            --hash-e eeee1111
    else
        "$RECEIPT_SIGN" \
            --type qgr --boundary test-boundary \
            --org testorg --principal testprincipal --agent testagent \
            --workstream testws --project testproj \
            --hash-a aaaa --hash-b bbbb --hash-c cccc --hash-d dddd \
            --hash-e eeee1111
    fi
}

_count_receipts() { find "$1/agency/workstreams" -name '*.md' 2>/dev/null | wc -l | tr -d ' '; }
_count_payloads() { find "$1/usr" -name '*.md' 2>/dev/null | wc -l | tr -d ' '; }

# ─────────────────────────────────────────────────────────────────────────────
# receipt-sign
# ─────────────────────────────────────────────────────────────────────────────

@test "receipt-sign -C: writes the receipt into the named repo" {
    run _sign_into "$TARGET_REPO"
    assert_success
    [ "$(_count_receipts "$TARGET_REPO")" -eq 1 ]
}

@test "receipt-sign -C: does NOT write into its own install location" {
    # The leak, stated as its own assertion. This is the failure that aborted a
    # real land — the receipt existed, just in the wrong repo.
    _sign_into "$TARGET_REPO"
    [ "$(_count_receipts "$INSTALL_REPO")" -eq 0 ]
}

@test "receipt-sign -C: the receipt is findable under the target's workstream path" {
    _sign_into "$TARGET_REPO"
    [ -d "$TARGET_REPO/agency/workstreams/testws/qgr" ]
    run find "$TARGET_REPO/agency/workstreams/testws/qgr" -name '*-qgr-test-boundary-*.md'
    assert_success
    [ -n "$output" ]
}

@test "receipt-sign: WITHOUT -C the install location is still the target (no regression)" {
    run _sign_into ""
    assert_success
    [ "$(_count_receipts "$INSTALL_REPO")" -eq 1 ]
    [ "$(_count_receipts "$TARGET_REPO")" -eq 0 ]
}

@test "receipt-sign: cwd is deliberately NOT consulted without -C" {
    # Pins the root cause as documented behaviour rather than a bug that might
    # get "fixed" by quietly adding a cwd fallback. A tool that follows cwd
    # implicitly is how this class of mis-targeting hides; callers must be
    # explicit. If this ever changes, pr-captain-land's -C wiring must be
    # revisited at the same time.
    cd "$TARGET_REPO"
    _sign_into ""
    [ "$(_count_receipts "$INSTALL_REPO")" -eq 1 ]
    [ "$(_count_receipts "$TARGET_REPO")" -eq 0 ]
}

@test "receipt-sign -C: rejects a nonexistent directory" {
    run "$RECEIPT_SIGN" -C "$BATS_TEST_TMPDIR/no-such-dir" --type qgr
    assert_failure
    assert_output_contains "does not exist"
}

@test "receipt-sign -C: rejects a missing directory argument" {
    run "$RECEIPT_SIGN" -C
    assert_failure
    assert_output_contains "requires a directory"
}

@test "receipt-sign: -C is advertised in --help" {
    run "$RECEIPT_SIGN" --help
    assert_success
    assert_output_contains "\-C <repo-root>"
}

# ─────────────────────────────────────────────────────────────────────────────
# dispatch
# ─────────────────────────────────────────────────────────────────────────────

@test "dispatch -C: writes the payload into the named repo, not the install one" {
    run "$DISPATCH" -C "$TARGET_REPO" create \
        --to "test-repo/testprincipal/captain" \
        --subject "locality probe" --body "body" --type commit
    assert_success
    [ "$(_count_payloads "$TARGET_REPO")" -eq 1 ]
    [ "$(_count_payloads "$INSTALL_REPO")" -eq 0 ]
}

@test "dispatch -C: outranks CLAUDE_PROJECT_DIR" {
    # An explicit argument must beat an inherited environment variable. The
    # captain's own CLAUDE_PROJECT_DIR is set to its main checkout in every real
    # session, so if the env won, -C would be inert exactly where it is needed.
    CLAUDE_PROJECT_DIR="$INSTALL_REPO" run "$DISPATCH" -C "$TARGET_REPO" create \
        --to "test-repo/testprincipal/captain" \
        --subject "override probe" --body "body" --type commit
    assert_success
    [ "$(_count_payloads "$TARGET_REPO")" -eq 1 ]
    [ "$(_count_payloads "$INSTALL_REPO")" -eq 0 ]
}

@test "dispatch: WITHOUT -C, CLAUDE_PROJECT_DIR still wins (no regression)" {
    CLAUDE_PROJECT_DIR="$TARGET_REPO" run "$DISPATCH" create \
        --to "test-repo/testprincipal/captain" \
        --subject "env probe" --body "body" --type commit
    assert_success
    [ "$(_count_payloads "$TARGET_REPO")" -eq 1 ]
}

@test "dispatch: WITHOUT -C and without env, cwd is ignored — reproduces the leak" {
    # The pre-fix behaviour, pinned so the regression is legible: running from
    # the scratch wrote into the captain's checkout. This test PASSING with the
    # payload in INSTALL_REPO is correct — it is why -C had to be added rather
    # than "just make it use cwd", which would have changed every caller.
    cd "$TARGET_REPO"
    run "$DISPATCH" create \
        --to "test-repo/testprincipal/captain" \
        --subject "cwd probe" --body "body" --type commit
    assert_success
    [ "$(_count_payloads "$INSTALL_REPO")" -eq 1 ]
    [ "$(_count_payloads "$TARGET_REPO")" -eq 0 ]
}

@test "dispatch -C: rejects a nonexistent directory" {
    run "$DISPATCH" -C "$BATS_TEST_TMPDIR/no-such-dir" list
    assert_failure
    assert_output_contains "does not exist"
}

@test "dispatch: -C is advertised in --help" {
    run "$DISPATCH" --help
    assert_success
    assert_output_contains "\-C <repo-root>"
}

# ─────────────────────────────────────────────────────────────────────────────
# pr-create
# ─────────────────────────────────────────────────────────────────────────────
#
# None of these reach `gh pr create`: every case stops at a gate first, which is
# exactly the surface under test. No network, no PRs.

@test "pr-create -C: the BRANCH gate reads the named repo" {
    run "$PR_CREATE" -C "$TARGET_REPO" --title t --body b
    assert_output_contains "On branch: feature-branch"
}

@test "pr-create: WITHOUT -C the BRANCH gate reads the install repo — the reported bug" {
    # cwd is the target's feature branch, yet the gate sees the install repo's
    # main and blocks. This is what would have killed the land at step 6 had
    # step 5's receipt failure not aborted it first.
    cd "$TARGET_REPO"
    run "$PR_CREATE" --title t --body b
    assert_failure
    assert_output_contains "Cannot create PR from main"
}

@test "pr-create -C: the receipt gate searches the named repo" {
    run "$PR_CREATE" -C "$TARGET_REPO" --title t --body b
    assert_failure
    # Past the branch gate, blocked on the target having no receipt.
    assert_output_contains "No receipt found"
}

@test "pr-create -C: does NOT run the TARGET's copy of receipt-verify" {
    # The trust boundary: captain's code, scratch's data. If -C retargeted the
    # sub-tools too, a branch could ship a receipt-verify that rubber-stamps
    # itself and the "pr-create is not weakened" guarantee would be void.
    printf '#!/usr/bin/env bash\necho POISONED-VERIFIER-RAN\nexit 0\n' \
        > "$TARGET_REPO/agency/tools/receipt-verify"
    chmod +x "$TARGET_REPO/agency/tools/receipt-verify"
    _sign_into "$TARGET_REPO"

    run "$PR_CREATE" -C "$TARGET_REPO" --title t --body b
    assert_failure
    [[ "$output" != *POISONED-VERIFIER-RAN* ]]
}

@test "pr-create -C: rejects a nonexistent directory" {
    run "$PR_CREATE" -C "$BATS_TEST_TMPDIR/no-such-dir" --title t --body b
    assert_failure
    assert_output_contains "does not exist"
}

@test "pr-create -C: the flag is consumed, never forwarded to gh" {
    # -C is not a `gh pr create` flag. If the parse ever stopped shifting it
    # away, gh would reject the invocation at the very last step of a land —
    # after the push, past the point where rollback is still clean. Asserted on
    # source because reaching gh needs a receipt that matches a real diff hash;
    # the parse is one `shift 2` and that is the thing that can rot.
    run grep -q 'shift 2' "$PR_CREATE"
    assert_success
    run grep -q 'gh pr create "\$@"' "$PR_CREATE"
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# git-safe-commit → dispatch
# ─────────────────────────────────────────────────────────────────────────────

@test "git-safe-commit passes its cwd-resolved root to dispatch via -C" {
    # git-safe-commit already resolved PROJECT_ROOT correctly from cwd; it just
    # had no way to tell the dispatch tool. Structural, because reaching the
    # commit-announce needs a full commit with hooks — the runtime proof that -C
    # is honoured is the dispatch block above.
    run grep -q '"\$DISPATCH_TOOL" -C "\$PROJECT_ROOT" create' \
        "$REPO_ROOT/agency/tools/git-safe-commit"
    assert_success
}

@test "git-safe-commit: PROJECT_ROOT is cwd-derived, so -C carries a real root" {
    run grep -q 'PROJECT_ROOT="\$(git rev-parse --show-toplevel' \
        "$REPO_ROOT/agency/tools/git-safe-commit"
    assert_success
}
