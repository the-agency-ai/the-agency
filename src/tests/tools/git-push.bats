#!/usr/bin/env bats
#
# git-push tests — push discipline enforcement
#

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
GIT_PUSH="${REPO_ROOT}/agency/tools/git-push"

@test "git-push: blocks main" {
    run bash "$GIT_PUSH" main
    [ "$status" -eq 1 ]
    [[ "$output" == *"BLOCKED"* ]]
    [[ "$output" == *"PRs"* ]]
}

@test "git-push: blocks master" {
    run bash "$GIT_PUSH" master
    [ "$status" -eq 1 ]
    [[ "$output" == *"BLOCKED"* ]]
}

@test "git-push: accepts --force-with-lease without treating as branch" {
    # This will fail at git push (no remote), but should NOT block
    # The important thing is it doesn't set BRANCH to --force-with-lease
    run bash "$GIT_PUSH" --force-with-lease test-branch
    # Will fail because no remote, but should NOT say "BLOCKED"
    [[ "$output" != *"BLOCKED"* ]]
}
