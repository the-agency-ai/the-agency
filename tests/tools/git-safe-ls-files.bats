#!/usr/bin/env bats
#
# BATS: git-safe ls-files subcommand (v46.0 reset — Phase 0b)
#
# Required min-test-count: 4 (per Plan v4 §3 Phase 0b)
# Actual tests: 5

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    cd "$REPO_ROOT"
}

@test "ls-files returns tracked files" {
    run ./agency/tools/git-safe ls-files
    [ "$status" -eq 0 ]
    # Should include at least one known tracked file
    [[ "$output" == *"agency/tools/git-safe"* ]]
}

@test "ls-files with explicit path filters to that subtree" {
    run ./agency/tools/git-safe ls-files agency/tools/git-safe
    [ "$status" -eq 0 ]
    [ "$output" = "agency/tools/git-safe" ]
}

@test "ls-files on missing path returns empty, exit 0" {
    run ./agency/tools/git-safe ls-files -- does/not/exist/anywhere
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "ls-files respects pathspec pseudo-separator '--'" {
    # After --, an argument that happens to look like a flag is treated as a path.
    run ./agency/tools/git-safe ls-files -- agency/tools/git-safe
    [ "$status" -eq 0 ]
    [ "$output" = "agency/tools/git-safe" ]
}

@test "ls-files is enumerated in --help" {
    run ./agency/tools/git-safe --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"ls-files"* ]]
}
