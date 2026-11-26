#!/usr/bin/env bats
#
# What Problem: git-safe-commit staged EVERYTHING (git add -A) unless --staged
# was passed, and --help truncated the options list so --staged, --amend,
# --dry-run and --verbose were invisible. A caller that staged exactly the
# files it meant to commit (`git-safe add f && git-safe-commit "msg"`) silently
# swept every other dirty or untracked file into the commit. That bundled an
# unrelated settings change into a coord commit (2026-10-10), and
# pr-captain-land's bump/receipt commits follow the same stage-then-commit
# pattern inside a scratch tree.
#
# How & Why: an explicitly staged index is the caller's statement of intent.
# If anything is staged, commit only the index and leave the rest alone (with
# a notice). If nothing is staged, keep the historical stage-all default so
# callers that rely on it are unchanged. --all forces stage-all explicitly.
#

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    # Own subdir: test_isolation_setup puts a fake $HOME under BATS_TEST_TMPDIR,
    # and stage-all would sweep it into the commit.
    mkdir -p "${BATS_TEST_TMPDIR}/repo"
    cd "${BATS_TEST_TMPDIR}/repo"
    git init --quiet --initial-branch=main 2>/dev/null || git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    git config commit.gpgsign false

    install_git_safe_commit_suite

    echo "base" > a.txt
    echo "base" > b.txt
    # The tool writes telemetry under .claude/logs/ — gitignored in real repos.
    printf '.claude/logs/\n' > .gitignore
    # Commit the installed tool suite too, so the tree starts clean and
    # stage-all assertions see only the files each test touches.
    git add -A
    git commit -m "base" --quiet --no-verify
}

teardown() {
    test_isolation_teardown
    [[ -d "${BATS_TEST_TMPDIR}" ]] && rm -rf "${BATS_TEST_TMPDIR}"
}

committed_files() {
    git show --name-only --format= HEAD | sort | tr '\n' ' '
}

# assert_committed "<expected space-separated sorted list with trailing space>"
assert_committed() {
    local got
    got="$(committed_files)"
    [ "$got" = "$1" ] || { echo "expected commit files: [$1]"; echo "got:                   [$got]"; return 1; }
}

@test "staging: explicitly staged file is committed alone; other changes stay out" {
    echo "change" > a.txt
    echo "change" > b.txt          # modified, NOT staged
    echo "new" > stray.txt         # untracked
    git add a.txt
    run ./agency/tools/git-safe-commit "only a" --no-work-item --no-verify
    [ "$status" -eq 0 ]
    assert_committed "a.txt "
    # b.txt still modified, stray.txt still untracked
    git status --porcelain | grep -q '^ M b.txt'
    git status --porcelain | grep -q '^?? stray.txt'
}

@test "staging: partial staging prints a notice naming the leftovers" {
    echo "change" > a.txt
    echo "change" > b.txt
    git add a.txt
    run ./agency/tools/git-safe-commit "only a" --no-work-item --no-verify
    [ "$status" -eq 0 ]
    [[ "$output" == *"staged"* ]]
    [[ "$output" == *"not committed"* ]]
}

@test "staging: nothing staged keeps the stage-all default" {
    echo "change" > a.txt
    echo "new" > stray.txt
    run ./agency/tools/git-safe-commit "all" --no-work-item --no-verify
    [ "$status" -eq 0 ]
    assert_committed "a.txt stray.txt "
    [ -z "$(git status --porcelain)" ]
}

@test "staging: --all stages everything even when something is staged" {
    echo "change" > a.txt
    echo "change" > b.txt
    git add a.txt
    run ./agency/tools/git-safe-commit "everything" --all --no-work-item --no-verify
    [ "$status" -eq 0 ]
    assert_committed "a.txt b.txt "
}

@test "staging: --staged still commits only the index" {
    echo "change" > a.txt
    echo "change" > b.txt
    git add a.txt
    run ./agency/tools/git-safe-commit "only a" --staged --no-work-item --no-verify
    [ "$status" -eq 0 ]
    assert_committed "a.txt "
}

@test "help: lists every option the parser accepts" {
    run ./agency/tools/git-safe-commit --help
    [ "$status" -eq 0 ]
    for opt in --work-item --stage --no-work-item --coord --allow-large --body \
               --principal --no-verify --amend --dry-run --staged --all --verbose; do
        [[ "$output" == *"$opt"* ]] || { echo "missing from --help: $opt"; return 1; }
    done
}

@test "staging: --staged with --all is refused" {
    echo "change" > a.txt
    git add a.txt
    run ./agency/tools/git-safe-commit "x" --staged --all --no-work-item --no-verify
    [ "$status" -ne 0 ]
    [[ "$output" == *"mutually exclusive"* ]]
    # nothing committed
    [ "$(git log --oneline | wc -l | tr -d ' ')" = "1" ]
}

@test "staging: staged-then-modified file commits the staged version and reports the rest" {
    echo "staged" > a.txt
    git add a.txt
    echo "later" > a.txt           # porcelain: MM a.txt
    run ./agency/tools/git-safe-commit "staged a" --no-work-item --no-verify
    [ "$status" -eq 0 ]
    [ "$(git show HEAD:a.txt)" = "staged" ]
    [ "$(cat a.txt)" = "later" ]
    [[ "$output" == *"a.txt"* ]]
}
