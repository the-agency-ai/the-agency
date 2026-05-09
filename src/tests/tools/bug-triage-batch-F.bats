#!/usr/bin/env bats
#
# What Problem: Bug-triage batch F — 26 MEDIUM bugs. Exposing tests for the
# fixes applied in the same commits. Each test pins a specific behavior that
# was previously broken or silently mis-handled.
#
# Coverage:
#   #204 — git-safe-commit: loud error when git identity unset (was silent 128)
#   #212 — git-captain push: bash 3.2 empty-array safe (already-fixed — regression guard)
#   #254 — diff-hash: exit 2 with clear message outside a git repo
#   #268 — detect_main_branch: fall back to origin/HEAD when local main missing
#   #283 — git-safe-commit: --force / -f alias recognized
#   #284 — git-safe add: -u / --update rejected loudly (not treated as filename)
#   #286 — agency-bootstrap help: placeholders, not literal 'alex'/'myapp'
#
# Written: 2026-04-22 during captain bug-triage batch F

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

    # Install tools under test
    mkdir -p agency/tools/lib
    for tool in git-safe git-safe-commit git-captain diff-hash commit-precheck agency-bootstrap.sh; do
        if [[ -f "${REPO_ROOT}/agency/tools/${tool}" ]]; then
            cp "${REPO_ROOT}/agency/tools/${tool}" "agency/tools/${tool}"
            chmod +x "agency/tools/${tool}"
        fi
    done
    for lib in _log-helper _colors _path-resolve _commit-prefix _test-isolation; do
        cp "${REPO_ROOT}/agency/tools/lib/${lib}" "agency/tools/lib/${lib}" 2>/dev/null || true
    done

    echo "# Test" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet
    if [[ "$(git branch --show-current)" == "master" ]]; then
        git branch -m master main
    fi
}

teardown() {
    test_isolation_teardown
    rm -rf "${BATS_TEST_TMPDIR}"
}

# ── #254 diff-hash outside a git repo ─────────────────────────────────────────
@test "#254 diff-hash exits 2 with clear error outside a git repo" {
    local outside="$(mktemp -d)"
    local tool="${BATS_TEST_TMPDIR}/agency/tools/diff-hash"
    cd "${outside}"
    run "${tool}"
    [ "$status" -eq 2 ]
    [[ "$output" == *"must be run inside a git repository"* ]]
    rm -rf "${outside}"
}

# ── #283 git-safe-commit --force alias ────────────────────────────────────────
@test "#283 git-safe-commit accepts --force as an alias for --no-work-item" {
    echo "change" >> README.md
    git add README.md
    run ./agency/tools/git-safe-commit --dry-run --force "chore: doc tweak"
    [ "$status" -eq 0 ]
}

@test "#283 git-safe-commit accepts -f as an alias for --no-work-item" {
    echo "change" >> README.md
    git add README.md
    run ./agency/tools/git-safe-commit --dry-run -f "chore: doc tweak"
    [ "$status" -eq 0 ]
}

# ── #284 git-safe add rejects -u / --update loudly ────────────────────────────
@test "#284 git-safe add rejects -u with a clear error" {
    echo "change" >> README.md
    run ./agency/tools/git-safe add -u
    [ "$status" -ne 0 ]
    [[ "$output" == *"blocks '-u'"* || "$output" == *"-u"* ]]
}

@test "#284 git-safe add rejects --update with a clear error" {
    echo "change" >> README.md
    run ./agency/tools/git-safe add --update
    [ "$status" -ne 0 ]
    [[ "$output" == *"--update"* ]]
}

@test "#284 git-safe add still accepts explicit file paths" {
    echo "change" >> README.md
    run ./agency/tools/git-safe add README.md
    [ "$status" -eq 0 ]
    [[ "$output" == *"Staged:"* ]]
}

# ── #268 detect_main_branch fallback to origin/HEAD ───────────────────────────
@test "#268 git-captain finds main via origin/HEAD when local main deleted" {
    # Bare remote that has main
    local remote="$(mktemp -d)/origin.git"
    git init --bare --quiet --initial-branch=main "${remote}" 2>/dev/null || git init --bare --quiet "${remote}"
    git remote add origin "${remote}"
    git push --quiet origin main
    # Create a feature branch so we can delete local main
    git checkout -b feat --quiet
    git branch -D main --quiet
    # Ensure origin/HEAD is set
    git remote set-head origin main 2>/dev/null || true
    # Now invoke a subcommand that uses detect_main_branch — push with no args
    # from a non-main branch should NOT die with "Cannot find main or master"
    run ./agency/tools/git-captain switch-branch feat
    # switch-branch prints something — it must NOT die on detect_main_branch
    [[ "$output" != *"Cannot find main or master"* ]]
}

# ── #212 git-captain push no-args bash 3.2 empty-array safety (regression) ───
@test "#212 git-captain push source contains bash-3.2-safe empty-array idiom" {
    run grep -F 'push_args[@]+"${push_args[@]}"' ./agency/tools/git-captain
    [ "$status" -eq 0 ]
}

# ── #286 agency-bootstrap help text uses placeholders ─────────────────────────
@test "#286 agency-bootstrap --help shows placeholder names, not 'alex'/'myapp'" {
    run ./agency/tools/agency-bootstrap.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"YOUR_NAME"* ]]
    [[ "$output" == *"YOUR_PROJECT"* ]]
    # The prior literal examples must not appear verbatim as copy-paste targets
    [[ "$output" != *"--principal alex "* ]]
}

# ── #204 git-safe-commit identity precondition ────────────────────────────────
@test "#204 git-safe-commit errors loudly when git identity is unconfigured" {
    # Blow away identity
    git config --unset user.name || true
    git config --unset user.email || true
    # Also need global absent — but BATS test isolation should already handle that
    # Use -c override to null out globals within the invocation
    echo "change" >> README.md
    git add README.md
    run env HOME="${BATS_TEST_TMPDIR}/fake-home" ./agency/tools/git-safe-commit --no-work-item "chore: test"
    # Exit code should be 128 (preserved from git) and NOT a silent success
    [ "$status" -ne 0 ]
    [[ "$output" == *"Git identity not configured"* || "$output" == *"user.name"* ]]
}

# ── #236 commit-precheck emits end event on unexpected exit (trap) ────────────
@test "#236 commit-precheck source installs an EXIT trap for end-event emission" {
    run grep -E "trap '_on_exit' EXIT|trap _on_exit EXIT" ./agency/tools/commit-precheck
    [ "$status" -eq 0 ]
}

# ── #197 / #207 skill-verify does not require allowed-tools ───────────────────
@test "#197/#207 skill-verify does not require allowed-tools field" {
    # Source-file regression guard: the check for allowed-tools must not exist
    run grep -F 'allowed-tools' "${REPO_ROOT}/agency/tools/skill-verify"
    # It appears in the explanatory comment — but must NOT be an `if !` grep check
    # Assert: no line that would FAIL a skill for missing allowed-tools
    run grep -E '^\s*if[[:space:]].*grep.*allowed-tools' "${REPO_ROOT}/agency/tools/skill-verify"
    [ "$status" -ne 0 ]
}
