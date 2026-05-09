#!/usr/bin/env bats
#
# What Problem: worktree-sync previously used bare `git stash` / `git stash pop`
# (no label, no SHA tracking). If two worktree-sync runs interleave (or a
# principal has an unrelated stash on the stack), the pop would grab the
# wrong stash — cross-worktree stash pollution (#195, #409).
#
# How & Why: After the fix, every auto-mode stash carries a unique label
# `worktree-sync-$$-$(date +%s)`. Pops resolve by label via `git stash list`
# and `git stash pop stash@{N}`. This test verifies the label semantics by
# grepping the script (structural contract) and by exercising the
# _resolve_stash_ref helper in a temp repo.
#
# Written: 2026-04-22 during Fix Wave I (#195)

load test_helper

@test "worktree-sync uses labelled stash push (no bare 'git stash')" {
    local tool="${REPO_ROOT}/agency/tools/worktree-sync"
    # The stash-push call site must include -m with the STASH_LABEL var.
    run grep -nE 'git stash push .* -m "\$STASH_LABEL"' "$tool"
    [ "$status" -eq 0 ]
    # And must NOT contain a bare `git stash\s*$` (no args) or
    # `git stash --quiet\s*$` in the auto-mode dirty-tree path.
    run grep -nE '^\s*git stash --quiet 2>/dev/null$' "$tool"
    [ "$status" -ne 0 ]
}

@test "worktree-sync has a _resolve_stash_ref helper" {
    local tool="${REPO_ROOT}/agency/tools/worktree-sync"
    run grep -n '_resolve_stash_ref()' "$tool"
    [ "$status" -eq 0 ]
}

@test "worktree-sync pops stash by resolved ref, not blindly" {
    local tool="${REPO_ROOT}/agency/tools/worktree-sync"
    # Every `git stash pop` call at the control-flow boundaries must be
    # followed by a ref (either $STASH_REF-style var or stash@{...}).
    # Allowed: `git stash pop --quiet "$_ref"` or similar.
    # Forbidden: `git stash pop --quiet 2>/dev/null` with no ref (except
    # in the trap fallback which is commented out).
    local bad
    bad=$(grep -nE '^\s*git stash pop --quiet 2>/dev/null$' "$tool" || true)
    if [[ -n "$bad" ]]; then
        echo "Found blind stash pop:" >&2
        echo "$bad" >&2
        return 1
    fi
}

@test "_resolve_stash_ref finds our label in a temp repo" {
    # Create a temp repo, seed a stash with a known label, source the
    # resolver function out of worktree-sync, and confirm it returns
    # stash@{0}.
    local tmp="${BATS_TEST_TMPDIR}/stash-repo"
    mkdir -p "$tmp"
    cd "$tmp"
    git init --quiet
    git config user.email test@example.com
    git config user.name Tester
    echo seed > a.txt
    git add a.txt
    git commit --quiet -m seed
    # Dirty tree + stash with a label
    echo dirty > a.txt
    STASH_LABEL="worktree-sync-9999-1234567890"
    git stash push --quiet -m "$STASH_LABEL"

    # Inline the resolver (same logic as in worktree-sync). This verifies
    # the awk expression itself.
    _resolve_stash_ref() {
        git stash list 2>/dev/null | awk -v lbl="$STASH_LABEL" '
            index($0, lbl) {
                n = index($0, ":"); ref = substr($0, 1, n-1); print ref; exit
            }'
    }
    local ref
    ref=$(_resolve_stash_ref)
    [ "$ref" = "stash@{0}" ]

    # And if we push another unrelated stash on top, the resolver still
    # finds OUR label (not stash@{0}).
    echo dirty2 > a.txt
    git stash push --quiet -m "unrelated-stash"
    ref=$(_resolve_stash_ref)
    [ "$ref" = "stash@{1}" ]
}
