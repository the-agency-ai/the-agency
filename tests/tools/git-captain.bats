#!/usr/bin/env bats
#
# Tests for git-captain — captain-only git operations with safety guardrails
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Fixture setup — create a mock git repo with git-captain available
# ─────────────────────────────────────────────────────────────────────────────

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    cd "${BATS_TEST_TMPDIR}"
    git init --quiet -b main
    git config user.email "test@example.com"
    git config user.name "Test User"
    git config commit.gpgsign false

    mkdir -p claude/tools/lib
    cp "${REPO_ROOT}/claude/tools/git-captain" claude/tools/git-captain
    chmod +x claude/tools/git-captain
    cp "${REPO_ROOT}/claude/tools/lib/_log-helper" claude/tools/lib/_log-helper 2>/dev/null || true
    cp "${REPO_ROOT}/claude/tools/lib/_colors" claude/tools/lib/_colors 2>/dev/null || true

    echo "hello" > README.md
    git add README.md
    git add claude
    git commit -m "Initial commit" --quiet
}

teardown() {
    test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# Helper: create a secondary branch with a commit on top
make_feature_branch() {
    local name="$1"
    git checkout -q -b "$name"
    echo "feature content" > feature.txt
    git add feature.txt
    git commit -q -m "feature commit on $name"
    git checkout -q main
}

# ─────────────────────────────────────────────────────────────────────────────
# Basic behavior
# ─────────────────────────────────────────────────────────────────────────────

@test "git-captain --help shows usage" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain --help
    assert_success
    assert_output_contains "Captain-only git operations"
    assert_output_contains "merge-to-master"
}

@test "git-captain --version shows version" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain --version
    assert_success
    assert_output_contains "git-captain"
}

@test "git-captain with no args shows usage" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain
    assert_success
    assert_output_contains "Captain-only git operations"
}

@test "git-captain unknown subcommand fails" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain bogus-cmd
    assert_failure
    assert_output_contains "Unknown subcommand"
}

# ─────────────────────────────────────────────────────────────────────────────
# merge-to-master
# ─────────────────────────────────────────────────────────────────────────────

@test "merge-to-master: on main, merges named branch with --no-ff" {
    cd "${BATS_TEST_TMPDIR}"
    make_feature_branch featbranch
    run ./claude/tools/git-captain merge-to-master featbranch
    assert_success
    assert_output_contains "Merge complete"
    # --no-ff should produce a merge commit
    run git log -1 --pretty=%P
    [[ $(echo "$output" | wc -w) -eq 2 ]]
}

@test "merge-to-master: NOT on main refuses with clear message" {
    cd "${BATS_TEST_TMPDIR}"
    make_feature_branch featbranch
    git checkout -q -b otherbranch
    run ./claude/tools/git-captain merge-to-master featbranch
    assert_failure
    assert_output_contains "Must be on main"
}

@test "merge-to-master: nonexistent branch fails" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain merge-to-master nosuchbranch
    assert_failure
    assert_output_contains "does not exist"
}

@test "merge-to-master: requires branch argument" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain merge-to-master
    assert_failure
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# checkout-branch
# ─────────────────────────────────────────────────────────────────────────────

@test "checkout-branch: valid name feature/foo succeeds" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch feature/foo
    assert_success
    run git branch --show-current
    [[ "$output" == "feature/foo" ]]
}

@test "checkout-branch: valid name test-branch succeeds and creates the branch" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch test-branch
    assert_success
    # D44-R6 (QG finding #10): strengthen assertion — verify branch was
    # actually created and checked out, not just that exit code was 0.
    run git branch --show-current
    [[ "$output" == "test-branch" ]]
}

@test "checkout-branch: uppercase name succeeds (D44-R3 / issue #428)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch MyBranch
    assert_success
    run git branch --show-current
    [[ "$output" == "MyBranch" ]]
}

@test "checkout-branch: mixed-case release name D7-R1 succeeds (D44-R3 / issue #428)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch D7-R1
    assert_success
    run git branch --show-current
    [[ "$output" == "D7-R1" ]]
}

@test "checkout-branch: nested uppercase path Feature/ABC succeeds (D44-R3 / issue #428)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch Feature/ABC
    assert_success
    run git branch --show-current
    [[ "$output" == "Feature/ABC" ]]
}

@test "checkout-branch: digits-only name succeeds (D44-R3 coverage)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch 20260417
    assert_success
    run git branch --show-current
    [[ "$output" == "20260417" ]]
}

@test "checkout-branch: non-ASCII letters rejected (D44-R3 coverage)" {
    cd "${BATS_TEST_TMPDIR}"
    # café contains non-ASCII é, outside [a-zA-Z0-9._/-] — must fail
    run ./claude/tools/git-captain checkout-branch "café"
    assert_failure
    assert_output_contains "Invalid branch name"
}

@test "checkout-branch: invalid characters still fail after D44-R3 widening" {
    cd "${BATS_TEST_TMPDIR}"
    # @ is not in the allowed set [a-zA-Z0-9._/-]
    run ./claude/tools/git-captain checkout-branch "Bad@Name"
    assert_failure
    assert_output_contains "Invalid branch name"
}

# D44-R6 — reject structural patterns that git itself rejects, so the
# error surfaces at the tool level with a clear message instead of bubbling
# up from git's internals later.

@test "checkout-branch: rejects '..' sequences (D44-R6 / git ref-format)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch "D44..R6"
    assert_failure
    assert_output_contains "'..'"
}

@test "checkout-branch: rejects trailing '.lock' suffix (D44-R6 / git ref lockfiles)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch "feature.lock"
    assert_failure
    assert_output_contains ".lock"
}

@test "checkout-branch: rejects trailing hyphen (D44-R6 / git ref-format)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch "feature-"
    assert_failure
    assert_output_contains "end with '-'"
}

@test "checkout-branch: rejects trailing dot (D44-R6 / git ref-format)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch "release."
    assert_failure
    assert_output_contains "end with '.'"
}

@test "checkout-branch: rejects trailing slash (D44-R6 / git ref-format)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch "feature/"
    assert_failure
    assert_output_contains "end with '/'"
}

# Positive regression — structural rules must not reject legitimate names.

@test "checkout-branch: accepts dotted version name v1.0 (D44-R6 coverage)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch v1.0
    assert_success
    run git branch --show-current
    [[ "$output" == "v1.0" ]]
}

@test "checkout-branch: accepts underscored name my_branch (D44-R6 coverage)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch my_branch
    assert_success
    run git branch --show-current
    [[ "$output" == "my_branch" ]]
}

@test "checkout-branch: accepts 'lock' (no dot) — only '.lock' suffix is forbidden" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch feature-lock
    assert_success
    run git branch --show-current
    [[ "$output" == "feature-lock" ]]
}

@test "checkout-branch: accepts '.lock' mid-name (e.g. foo.lock-bar) — only suffix is forbidden" {
    cd "${BATS_TEST_TMPDIR}"
    # D44-R6 QG (finding #12): the suffix-only rule `[[ $name == *.lock ]]`
    # must not reject `.lock` as a substring. Positive regression.
    run ./claude/tools/git-captain checkout-branch foo.lock-bar
    assert_success
    run git branch --show-current
    [[ "$output" == "foo.lock-bar" ]]
}

@test "checkout-branch: name starting with hyphen fails" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch -- -badstart
    assert_failure
}

@test "checkout-branch: name with spaces fails" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch "has space"
    assert_failure
    assert_output_contains "Invalid branch name"
}

@test "checkout-branch: requires name argument" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain checkout-branch
    assert_failure
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# switch-branch
# ─────────────────────────────────────────────────────────────────────────────

@test "switch-branch: switches to existing branch" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b existing
    git checkout -q main
    run ./claude/tools/git-captain switch-branch existing
    assert_success
    run git branch --show-current
    [[ "$output" == "existing" ]]
}

@test "switch-branch: can switch to main" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b sidekick
    run ./claude/tools/git-captain switch-branch main
    assert_success
    run git branch --show-current
    [[ "$output" == "main" ]]
}

@test "switch-branch: nonexistent branch fails" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain switch-branch nosuchbranch
    assert_failure
    assert_output_contains "does not exist"
}

@test "switch-branch: requires name argument" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain switch-branch
    assert_failure
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# push
# ─────────────────────────────────────────────────────────────────────────────

@test "push: from main is blocked" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain push
    assert_failure
    assert_output_contains "blocked"
}

@test "push: explicit main target blocked" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b featb
    run ./claude/tools/git-captain push origin main
    assert_failure
    assert_output_contains "blocked"
}

@test "push: bare --force is blocked (no --force-with-lease)" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b featb
    run ./claude/tools/git-captain push --force origin featb
    assert_failure
    assert_output_contains "Bare --force is blocked"
}

@test "push: -f shorthand is blocked" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b featb
    run ./claude/tools/git-captain push -f origin featb
    assert_failure
    assert_output_contains "Bare --force is blocked"
}

@test "push: --force-with-lease is allowed past guard" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b featb
    # No remote, so git push will fail — but we only care that the guard
    # passes and we get past the block to the actual git push invocation.
    run ./claude/tools/git-captain push --force-with-lease origin featb
    assert_failure
    # Must NOT be blocked by the guard
    [[ ! "$output" =~ "Bare --force is blocked" ]]
    [[ ! "$output" =~ "Push to main is blocked" ]]
}

@test "push: to feature branch passes guards (no remote causes git failure)" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b featb
    run ./claude/tools/git-captain push origin featb
    # Guards pass; git push fails because no remote is configured
    [[ ! "$output" =~ "blocked" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# fetch
# ─────────────────────────────────────────────────────────────────────────────

@test "fetch: invokes git fetch origin (graceful on no remote)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain fetch
    # Either succeeds or fails due to no remote, but the tool must invoke it
    assert_output_contains "Fetching from origin"
}

# ─────────────────────────────────────────────────────────────────────────────
# tag
# ─────────────────────────────────────────────────────────────────────────────

@test "tag: creates annotated tag" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain tag v1.0.0
    assert_success
    assert_output_contains "Created annotated tag"
    run git tag -l v1.0.0
    [[ "$output" == "v1.0.0" ]]
    # Annotated tag has a tag object
    run git cat-file -t v1.0.0
    [[ "$output" == "tag" ]]
}

@test "tag: creates annotated tag with -m message" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain tag v1.0.0 -m "first release"
    assert_success
    run git tag -l --format='%(contents)' v1.0.0
    [[ "$output" =~ "first release" ]]
}

@test "tag: duplicate tag fails" {
    cd "${BATS_TEST_TMPDIR}"
    ./claude/tools/git-captain tag v1.0.0 >/dev/null
    run ./claude/tools/git-captain tag v1.0.0
    assert_failure
    assert_output_contains "already exists"
}

@test "tag: requires name argument" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain tag
    assert_failure
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# branch-delete
# ─────────────────────────────────────────────────────────────────────────────

@test "branch-delete: safe-deletes merged branch" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b mergedb
    git checkout -q main
    run ./claude/tools/git-captain branch-delete mergedb
    assert_success
    assert_output_contains "Deleted branch"
}

@test "branch-delete: deleting main is blocked" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b sidekick
    run ./claude/tools/git-captain branch-delete main
    assert_failure
    assert_output_contains "Cannot delete main"
}

@test "branch-delete: deleting master is blocked (when master is main)" {
    cd "${BATS_TEST_TMPDIR}"
    # Create a fresh repo where master is the main branch
    local masterdir="${BATS_TEST_TMPDIR}/masterrepo"
    mkdir -p "$masterdir"
    cd "$masterdir"
    git init -q -b master
    git config user.email "test@example.com"
    git config user.name "Test User"
    git config commit.gpgsign false
    echo x > f && git add f && git commit -q -m init
    git checkout -q -b sidekick
    run "${BATS_TEST_TMPDIR}/claude/tools/git-captain" branch-delete master
    assert_failure
    assert_output_contains "Cannot delete master"
}

@test "branch-delete: deleting current branch is blocked" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b currentb
    run ./claude/tools/git-captain branch-delete currentb
    assert_failure
    assert_output_contains "Cannot delete the current branch"
}

@test "branch-delete: unmerged branch fails (safe -d)" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b unmerged
    echo "unmerged work" > u.txt
    git add u.txt
    git commit -q -m "unmerged commit"
    git checkout -q main
    run ./claude/tools/git-captain branch-delete unmerged
    assert_failure
    assert_output_contains "unmerged changes"
}

@test "branch-delete: requires name argument" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain branch-delete
    assert_failure
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R21: --force flag for post-merge cleanup (issue #110)
# ─────────────────────────────────────────────────────────────────────────────

@test "branch-delete --force: deletes unmerged branch (post-merge cleanup case)" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b unmerged-r21
    echo "RGR receipt content" > rgr.md
    git add rgr.md
    git commit -q -m "RGR receipt — not in main"
    git checkout -q main
    # Without --force: refuses (existing behavior, regression-anchored above)
    # With --force: succeeds
    run ./claude/tools/git-captain branch-delete unmerged-r21 --force
    assert_success
    assert_output_contains "Force-deleted branch"
    # Confirm branch is gone
    run git rev-parse --verify unmerged-r21
    assert_failure
}

@test "branch-delete -f: short form works the same way" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b unmerged-r21-short
    echo "x" > a && git add a && git commit -q -m "unreachable"
    git checkout -q main
    run ./claude/tools/git-captain branch-delete unmerged-r21-short -f
    assert_success
    assert_output_contains "Force-deleted branch"
}

@test "branch-delete --force: still refuses to delete main" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b sidekick-r21
    run ./claude/tools/git-captain branch-delete main --force
    assert_failure
    assert_output_contains "Cannot delete main"
}

@test "branch-delete --force: still refuses to delete current branch" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b currentb-r21
    run ./claude/tools/git-captain branch-delete currentb-r21 --force
    assert_failure
    assert_output_contains "Cannot delete the current branch"
}

@test "branch-delete: error message points at --force when safe-delete fails" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b unmerged-r21-msg
    echo "x" > b && git add b && git commit -q -m "unreachable"
    git checkout -q main
    run ./claude/tools/git-captain branch-delete unmerged-r21-msg
    assert_failure
    # New error message includes --force guidance
    assert_output_contains "--force"
}

@test "branch-delete: --help mentions --force flag" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain --help
    assert_success
    assert_output_contains "branch-delete"
    assert_output_contains "force"
}

@test "branch-delete: rejects unknown flag" {
    cd "${BATS_TEST_TMPDIR}"
    git checkout -q -b sidekick-bogus
    run ./claude/tools/git-captain branch-delete sidekick-bogus --bogus
    assert_failure
    assert_output_contains "Unknown flag"
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R28: reset-soft — sanctioned recovery for local commits (issue #128)
# ─────────────────────────────────────────────────────────────────────────────

@test "reset-soft: default undoes last local commit, keeps changes staged" {
    cd "${BATS_TEST_TMPDIR}"
    # Make a second commit that we'll reset
    echo "to-undo" > undo.txt
    git add undo.txt
    git commit -q -m "commit to be undone" --no-verify
    run ./claude/tools/git-captain reset-soft
    assert_success
    assert_output_contains "Reset complete"
    # File is still present and staged (soft reset)
    run git status --porcelain
    [[ "$output" == *"A "* ]] || [[ "$output" == *"M "* ]]
}

@test "reset-soft: refuses when ref does not resolve" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain reset-soft does-not-exist
    assert_failure
    assert_output_contains "does not resolve"
}

@test "git-captain --help mentions reset-soft — D41-R28" {
    cd "${BATS_TEST_TMPDIR}"
    run ./claude/tools/git-captain --help
    assert_success
    assert_output_contains "reset-soft"
}
