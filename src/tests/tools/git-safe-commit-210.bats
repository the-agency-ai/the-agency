#!/usr/bin/env bats
#
# Tests for git-safe-commit #210 guard — commit-notify cascade prevention.
#
# What Problem: Every commit via git-safe-commit fires a "committed" dispatch
# to captain that writes a notify file at
# `usr/{principal}/{agent}/dispatches/commit-to-captain-committed-*.md`.
# That file is in a tracked directory, so the NEXT commit includes it, which
# fires ANOTHER dispatch, which writes ANOTHER notify file — infinite
# cascade. Observed on mdpal-cli 2026-04-20 as a 3-deep "carry-over commit
# cascade" in the branch history.
#
# How & Why: The guard (git-safe-commit lines 541-553) runs `git diff-tree
# --name-only -r HEAD` after the commit and classifies files. If EVERY file
# in the commit matches the notify-file pattern, skip dispatch-create. Any
# non-notify file in the commit → dispatch fires normally.
#
# Tests cover:
#   1. Commit of ONE notify-only file → guard fires, no dispatch
#   2. Commit of MIXED notify + non-notify files → guard does NOT fire
#   3. Commit of TWO notify files from different agents → guard still fires
#   4. Verbose log message "#210 guard" appears (#210)
#
# Written: 2026-04-21 during Bucket 0b of A-B-C-D-E-F-G stabilization push
# (the-agency#210 fix).
#

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    cd "${BATS_TEST_TMPDIR}"
    git init --quiet --initial-branch=main 2>/dev/null || git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    git config commit.gpgsign false
    git config init.defaultBranch main

    # Install git-safe + git-safe-commit + lib deps
    mkdir -p agency/tools/lib
    for t in git-safe git-safe-commit; do
        cp "${REPO_ROOT}/agency/tools/$t" "agency/tools/$t"
        chmod +x "agency/tools/$t"
    done
    for lib in _log-helper _colors; do
        cp "${REPO_ROOT}/agency/tools/lib/$lib" "agency/tools/lib/$lib" 2>/dev/null || true
    done

    # Stub dispatch tool + agent-identity so the commit-notify dispatch path
    # is REACHABLE in tests. Without these stubs, `[[ -x "$DISPATCH_TOOL" ]]`
    # short-circuits and no dispatch runs — making the negative "guard did
    # NOT fire" assertion tautological (QG finding M-01).
    #
    # The dispatch stub writes a marker file per invocation. Tests that
    # expect the dispatch path to run assert the marker exists; tests that
    # expect the guard to short-circuit assert the marker does NOT exist.
    cat > agency/tools/dispatch <<'STUB'
#!/usr/bin/env bash
# Test stub: record each invocation to a marker file.
marker_dir="${BATS_TEST_TMPDIR}/dispatch-stub-invocations"
mkdir -p "$marker_dir"
printf '%s\n' "$*" >> "$marker_dir/calls.log"
echo "stub dispatch invoked: $*" >&2
exit 0
STUB
    chmod +x agency/tools/dispatch

    cat > agency/tools/agent-identity <<'STUB'
#!/usr/bin/env bash
# Test stub: return a deterministic non-captain identity.
echo "the-agency/jordan/testagent"
STUB
    chmod +x agency/tools/agent-identity

    # Disable pre-commit hook and skip-validation paths (speed + self-contained).
    git config core.hooksPath /dev/null 2>/dev/null || true

    # Baseline commit so HEAD exists. Include the copied tool files so
    # they are NOT untracked during tests (would otherwise get swept in
    # by `git add .` and pollute the commit file-list).
    echo "base" > README.md
    git add README.md agency/tools/
    git commit -m "base" --quiet --no-verify

    if [[ "$(git branch --show-current)" == "master" ]]; then
        git branch -m master main
    fi

    # Switch to a feature branch (the dispatch path only runs off main/master).
    git checkout -b feature/test-210 --quiet

    # Ignore test-isolation's fakehome bytecode cache + agency logs — these
    # get written during git-safe-commit's telemetry and shouldn't pollute
    # the test's commit-file-list.
    cat > .gitignore <<EOF
fakehome/
.claude/logs/
EOF
    git add .gitignore
    git commit -m "ignore test-runtime dirs" --quiet --no-verify
}

teardown() {
    test_isolation_teardown
    [[ -d "${BATS_TEST_TMPDIR}" ]] && rm -rf "${BATS_TEST_TMPDIR}"
}

# Helper: create a fake notify-file payload at the standard path.
_make_notify_file() {
    local principal="${1:-jordan}"
    local agent="${2:-testagent}"
    local shortsha="${3:-abc1234}"
    mkdir -p "usr/${principal}/${agent}/dispatches"
    local path="usr/${principal}/${agent}/dispatches/commit-to-captain-committed-${shortsha}-on-feature-test-210-test-commit-20260421-1200.md"
    cat >"$path" <<EOF
# Commit: ${shortsha}
This is a fake notify file for #210 regression testing.
EOF
    echo "$path"
}

# Helper: assert dispatch stub was (or was not) invoked — M-01 positive signal.
_assert_dispatch_invoked() {
    local should_invoke="$1"  # "yes" or "no"
    local marker="${BATS_TEST_TMPDIR}/dispatch-stub-invocations/calls.log"
    if [[ "$should_invoke" == "yes" ]]; then
        [[ -f "$marker" ]] || { echo "Expected dispatch to be invoked, marker missing"; return 1; }
        [[ -s "$marker" ]] || { echo "Marker exists but is empty"; return 1; }
    else
        # Marker may exist from a prior test, but for THIS test's purposes
        # we check whether dispatch ran for THIS commit. Simplest: marker
        # should not exist (each test runs in a fresh BATS_TEST_TMPDIR).
        [[ ! -f "$marker" ]] || {
            echo "Expected dispatch NOT to be invoked, but marker found:"
            cat "$marker"
            return 1
        }
    fi
}

@test "#210 guard: commit with ONLY notify files fires the skip log + dispatch NOT invoked" {
    cd "${BATS_TEST_TMPDIR}"
    _make_notify_file jordan testagent abc1234 >/dev/null

    git add .
    run ./agency/tools/git-safe-commit --staged "carry-over notify only" --no-work-item
    [ "$status" -eq 0 ]
    [[ "$output" == *"#210 guard"* ]] || {
        echo "Expected skip log not found in output:"
        echo "$output"
        return 1
    }
    _assert_dispatch_invoked no
}

@test "#210 guard: commit with MIXED notify + non-notify files does NOT skip + dispatch IS invoked" {
    cd "${BATS_TEST_TMPDIR}"
    _make_notify_file jordan testagent def5678 >/dev/null
    echo "real work" > src.txt

    git add .
    run ./agency/tools/git-safe-commit --staged "mixed scope" --no-work-item
    [ "$status" -eq 0 ]
    # Guard should NOT have fired the skip path — non-notify file present.
    [[ "$output" != *"#210 guard"* ]]
    _assert_dispatch_invoked yes
}

@test "#210 guard: commit with TWO notify files (different agents) still skips + dispatch NOT invoked" {
    cd "${BATS_TEST_TMPDIR}"
    _make_notify_file jordan alpha aaaa111 >/dev/null
    _make_notify_file jordan beta bbbb222 >/dev/null

    git add .
    run ./agency/tools/git-safe-commit --staged "two notify files" --no-work-item
    [ "$status" -eq 0 ]
    [[ "$output" == *"#210 guard"* ]]
    _assert_dispatch_invoked no
}

@test "#210 guard: commit with notify file in non-standard principal path still skips + dispatch NOT invoked" {
    cd "${BATS_TEST_TMPDIR}"
    # Pattern: usr/{anything}/{anything}/dispatches/commit-to-captain-committed-*.md
    _make_notify_file andrew somebody cccc333 >/dev/null

    git add .
    run ./agency/tools/git-safe-commit --staged "other-principal notify" --no-work-item
    [ "$status" -eq 0 ]
    [[ "$output" == *"#210 guard"* ]]
    _assert_dispatch_invoked no
}

@test "#210 guard: commit of regular handoff file does NOT trigger skip + dispatch IS invoked" {
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p usr/jordan/captain
    echo "handoff content" > usr/jordan/captain/captain-handoff.md

    git add .
    run ./agency/tools/git-safe-commit --staged "handoff update" --no-work-item
    [ "$status" -eq 0 ]
    # Handoff is NOT a notify file; guard must NOT fire.
    [[ "$output" != *"#210 guard"* ]]
    _assert_dispatch_invoked yes
}

# T4 (QG finding): near-miss filenames in the same dispatches/ dir that don't
# match the notify pattern must NOT trigger the guard — protects against
# regex drift if ISCP adds more commit-to-captain-* file types.
@test "#210 guard: near-miss filename 'commit-to-captain-resolved-*' does NOT trigger guard" {
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p usr/jordan/testagent/dispatches
    echo "resolved dispatch" > "usr/jordan/testagent/dispatches/commit-to-captain-resolved-xyz7890-on-foo-bar-20260421-1200.md"

    git add .
    run ./agency/tools/git-safe-commit --staged "commit-to-captain-resolved near-miss" --no-work-item
    [ "$status" -eq 0 ]
    # Guard's regex specifically requires 'committed-' — 'resolved-' must NOT match.
    [[ "$output" != *"#210 guard"* ]]
    _assert_dispatch_invoked yes
}

@test "#210 guard: near-miss filename 'dispatch-to-captain-*.md' does NOT trigger guard" {
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p usr/jordan/testagent/dispatches
    echo "other dispatch" > "usr/jordan/testagent/dispatches/dispatch-to-captain-re-pr-397-xyz-20260421-1200.md"

    git add .
    run ./agency/tools/git-safe-commit --staged "dispatch-to-captain near-miss" --no-work-item
    [ "$status" -eq 0 ]
    # Guard's regex specifically requires 'commit-to-captain-committed-' prefix — other dispatch names must NOT match.
    [[ "$output" != *"#210 guard"* ]]
    _assert_dispatch_invoked yes
}
