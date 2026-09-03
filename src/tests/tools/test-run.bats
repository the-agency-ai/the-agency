#!/usr/bin/env bats
#
# Tests for agency/tools/test-run — the --isolated / --working-tree wire-in
# (#42 step 3). Live in-container execution needs a container backend, so the
# functional tests here force a BOGUS backend (CONTAINER_PROVIDER=nonexistent):
# container-test-run prints its routing/mode diagnostic BEFORE the backend gate,
# then exits 127 — letting us verify routing + flag propagation fast, without
# spinning (or depending on) a real container.

load 'test_helper'

TR="${REPO_ROOT}/agency/tools/test-run"
CTR="${REPO_ROOT}/agency/tools/container-test-run"

# grep excluding comment lines — so a guard pins CODE, not a comment mention.
_code() { grep -vE '^[[:space:]]*#' "$1"; }

@test "test-run: --help documents --isolated and --working-tree" {
    run bash "$TR" --help
    assert_success
    assert_output_contains "--isolated"
    assert_output_contains "--working-tree"
}

@test "test-run: --isolated is a recognized flag (not 'unknown option')" {
    run bash "$TR" --isolated --list
    assert_success
    [[ "$output" != *"unknown option"* ]]
    assert_output_contains "Configured test suites"
}

@test "test-run: a genuinely unknown flag is still rejected" {
    run bash "$TR" --totally-bogus
    assert_failure
    assert_output_contains "unknown option"
}

@test "test-run: --list still works normally" {
    run bash "$TR" --list
    assert_success
    assert_output_contains "tools"
    assert_output_contains "hookify"
}

# ── Functional routing (bogus backend → fast fail, diagnostic still prints) ───

@test "test-run --isolated routes a bats suite to container-test-run" {
    run env CONTAINER_PROVIDER=nonexistent bash "$TR" --isolated --suite tools
    # container-test-run's pre-gate diagnostic proves the routing + path handoff.
    assert_output_contains "container-test-run: mode=committed-HEAD"
    assert_output_contains "src/tests/tools/"
    # and the suite is reported failed (no backend) — routing reached execution.
    assert_output_contains "tools failed"
}

@test "test-run --working-tree propagates working-tree mode into the container run" {
    run env CONTAINER_PROVIDER=nonexistent bash "$TR" --working-tree --suite tools
    assert_output_contains "container-test-run: mode=working-tree"
}

@test "test-run --isolated: a NON-bats suite falls back to the host (not the container)" {
    # mdpal's command is a swift-test shell command, not 'bats ...'; under
    # --isolated it must run on the HOST, never route to container-test-run.
    run env CONTAINER_PROVIDER=nonexistent bash "$TR" --isolated --suite mdpal
    assert_success
    assert_output_contains "host — not a bats suite"
    [[ "$output" != *"container-test-run:"* ]]
}

@test "test-run: suite commands containing '|' are NOT truncated (tab-delimited parse)" {
    # Regression for the |-delimiter bug: mdpal's command ends in '|| true'. If
    # the name|command|desc parse split on '|', the '|| true' (and the soft-skip
    # it provides) would be lost and the suite would fail when apps/mdpal is absent.
    run bash "$TR" --suite mdpal
    assert_success
    # literal glob match (assert_output_contains treats '|' as a regex alternation)
    [[ "$output" == *'|| true'* ]]
}

@test "test-run: a single-'|' suite command survives parsing (fixture, not prod config)" {
    # Decoupled from mdpal: a synthetic suite whose command contains a single '|'
    # and NO description, so `--list` displays the COMMAND. Parsed WHOLE
    # (tab-delimited) it shows 'echo a | grep a'; if the '|' delimiter regressed,
    # the command truncates to 'echo a ' and the '| grep a' vanishes.
    local repo="$BATS_TEST_TMPDIR/pipe-repo"
    mkdir -p "$repo/agency/config"
    cat > "$repo/agency/config/agency.yaml" <<'YAML'
testing:
  provider: "multi"
  suites:
    piped:
      command: "echo a | grep a"
YAML
    cd "$repo"
    git init -q
    run bash "$TR" --list
    assert_success
    [[ "$output" == *'| grep a'* ]]
}

# ── Structural guards on the container-test-run integration (code, not comments) ──

@test "test-run: --isolated actually invokes container-test-run (code path)" {
    run bash -c "$(declare -f _code); _code '$TR' | grep -qE '_ctr.*container-test-run'"
    assert_success
}

@test "container-test-run: honors a --working-tree flag in its arg parser" {
    run bash -c "$(declare -f _code); _code '$CTR' | grep -qE '\-\-working-tree\|-w\) *WORKING_TREE=1'"
    assert_success
}

@test "container-test-run: the --working-tree flag is wired to the container via CT_WORKING_TREE" {
    # THE critical wire: without this --env, --working-tree silently no-ops.
    run bash -c "$(declare -f _code); _code '$CTR' | grep -qE 'CT_WORKING_TREE='"
    assert_success
}

@test "container-test-run: overlay both LISTS and APPLIES the uncommitted delta" {
    # producer (ls-files) AND consumer (rsync/rm) must both be present.
    run bash -c "$(declare -f _code); _code '$CTR' | grep -qE 'ls-files.*--modified.*--others.*--exclude-standard'"
    assert_success
    run bash -c "$(declare -f _code); _code '$CTR' | grep -qE 'rsync.*--files-from'"
    assert_success
    run bash -c "$(declare -f _code); _code '$CTR' | grep -qE 'ls-files.*--deleted'"
    assert_success
    run bash -c "$(declare -f _code); _code '$CTR' | grep -qE 'rm -f .*/work/'"
    assert_success
}

@test "container-test-run: overlay guards against '..' path components" {
    run bash -c "$(declare -f _code); _code '$CTR' | grep -qE '[.][.]'"
    assert_success   # a .. filter/guard exists in the overlay
}

@test "container-test-run: rejects an unknown flag (does not treat it as a test path)" {
    run env CONTAINER_PROVIDER=nonexistent bash "$CTR" --verbse
    assert_failure
    assert_output_contains "unknown option"
}

@test "container-test-run: routes through the container_run abstraction" {
    run bash -c "$(declare -f _code); _code '$CTR' | grep -qE 'container_run'"
    assert_success
}
