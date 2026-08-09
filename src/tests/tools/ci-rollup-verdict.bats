#!/usr/bin/env bats
#
# ci-rollup-verdict — the CI gate's classification logic.
#
# This logic used to live in a python heredoc inside a command substitution
# inside pr-captain-land's polling loop, where the only tests possible were
# `grep` for a string. Every one of those guards still passed if the PASS and
# FAIL state sets were swapped. Extracted so the real property can be
# asserted: given this rollup, what does the gate decide?
#
# The two rows that matter most are the ones a naive gate gets wrong:
#   - a required context that has not reported yet is PENDING, not absent
#   - an empty rollup is NO_CHECKS, never PASSED

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
TOOL="${REPO_ROOT}/agency/tools/ci-rollup-verdict"

# classify <rollup-json> [required-json]
classify() {
    if [ -n "${2:-}" ]; then
        printf '%s' "$1" | python3 "$TOOL" --required "$2"
    else
        printf '%s' "$1" | python3 "$TOOL"
    fi
}

# Shorthand builders keep the table rows readable.
check_run() {  # name, status, conclusion
    printf '{"__typename":"CheckRun","name":"%s","status":"%s","conclusion":%s}' \
        "$1" "$2" "$3"
}
status_ctx() { # context, state
    printf '{"__typename":"StatusContext","context":"%s","state":"%s"}' "$1" "$2"
}
rollup() {     # ...nodes
    local IFS=,
    printf '{"statusCheckRollup":[%s]}' "$*"
}

# ─────────────────────────────────────────────────────────────────────────────
# Shape
# ─────────────────────────────────────────────────────────────────────────────

@test "ci-rollup-verdict: exists and is executable" {
    [ -x "$TOOL" ]
}

@test "ci-rollup-verdict: --help exits 0" {
    run python3 "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"NO_CHECKS"* ]]
}

@test "ci-rollup-verdict: unknown argument is a usage error" {
    run bash -c "echo '{}' | python3 '$TOOL' --bogus"
    [ "$status" -eq 2 ]
}

@test "ci-rollup-verdict: --required with no value is a usage error" {
    run bash -c "echo '{}' | python3 '$TOOL' --required"
    [ "$status" -eq 2 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Empty and unreadable — the two "must never look green" cases
# ─────────────────────────────────────────────────────────────────────────────

@test "ci-rollup-verdict: empty rollup → NO_CHECKS (never PASSED)" {
    run classify '{"statusCheckRollup":[]}'
    [ "$output" = "NO_CHECKS" ]
}

@test "ci-rollup-verdict: null rollup → NO_CHECKS" {
    run classify '{"statusCheckRollup":null}'
    [ "$output" = "NO_CHECKS" ]
}

@test "ci-rollup-verdict: missing key → NO_CHECKS" {
    run classify '{}'
    [ "$output" = "NO_CHECKS" ]
}

@test "ci-rollup-verdict: non-JSON input → UNREADABLE" {
    run classify 'not json at all'
    [ "$output" = "UNREADABLE" ]
}

@test "ci-rollup-verdict: empty input → UNREADABLE" {
    run classify ''
    [ "$output" = "UNREADABLE" ]
}

@test "ci-rollup-verdict: JSON array at top level → UNREADABLE" {
    run classify '[]'
    [ "$output" = "UNREADABLE" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# CheckRun nodes — status must gate the conclusion
# ─────────────────────────────────────────────────────────────────────────────

@test "ci-rollup-verdict: completed SUCCESS → PASSED" {
    run classify "$(rollup "$(check_run build COMPLETED '"SUCCESS"')")"
    [[ "$output" == PASSED* ]]
    [[ "$output" == *build* ]]
}

@test "ci-rollup-verdict: IN_PROGRESS with a stale SUCCESS conclusion → PENDING" {
    # Reading `conclusion` before `status` is COMPLETED is exactly how an
    # in-progress check gets counted green.
    run classify "$(rollup "$(check_run build IN_PROGRESS '"SUCCESS"')")"
    [[ "$output" == PENDING* ]]
}

@test "ci-rollup-verdict: QUEUED with null conclusion → PENDING" {
    run classify "$(rollup "$(check_run build QUEUED null)")"
    [[ "$output" == PENDING* ]]
}

@test "ci-rollup-verdict: completed FAILURE → FAILED, naming the check" {
    run classify "$(rollup "$(check_run smoke COMPLETED '"FAILURE"')")"
    [[ "$output" == FAILED* ]]
    [[ "$output" == *smoke* ]]
}

@test "ci-rollup-verdict: NEUTRAL and SKIPPED count as pass" {
    run classify "$(rollup "$(check_run a COMPLETED '"NEUTRAL"')" "$(check_run b COMPLETED '"SKIPPED"')")"
    [[ "$output" == PASSED* ]]
}

@test "ci-rollup-verdict: TIMED_OUT and CANCELLED count as failure" {
    run classify "$(rollup "$(check_run a COMPLETED '"TIMED_OUT"')")"
    [[ "$output" == FAILED* ]]
    run classify "$(rollup "$(check_run a COMPLETED '"CANCELLED"')")"
    [[ "$output" == FAILED* ]]
}

@test "ci-rollup-verdict: failure wins over pending (fail fast)" {
    run classify "$(rollup "$(check_run a IN_PROGRESS null)" "$(check_run b COMPLETED '"FAILURE"')")"
    [[ "$output" == FAILED* ]]
}

@test "ci-rollup-verdict: mixed pass + pending → PENDING, naming only the pending one" {
    run classify "$(rollup "$(check_run a COMPLETED '"SUCCESS"')" "$(check_run b IN_PROGRESS null)")"
    [ "$output" = "PENDING b" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# StatusContext nodes (the other rollup shape)
# ─────────────────────────────────────────────────────────────────────────────

@test "ci-rollup-verdict: StatusContext success → PASSED" {
    run classify "$(rollup "$(status_ctx legacy-ci SUCCESS)")"
    [[ "$output" == PASSED* ]]
}

@test "ci-rollup-verdict: lowercase StatusContext state is normalized" {
    run classify "$(rollup "$(status_ctx legacy-ci failure)")"
    [[ "$output" == FAILED* ]]
}

@test "ci-rollup-verdict: StatusContext pending → PENDING" {
    run classify "$(rollup "$(status_ctx legacy-ci pending)")"
    [[ "$output" == PENDING* ]]
}

@test "ci-rollup-verdict: both node shapes in one rollup" {
    run classify "$(rollup "$(check_run a COMPLETED '"SUCCESS"')" "$(status_ctx b failure)")"
    [[ "$output" == FAILED* ]]
    [[ "$output" == *b* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Required-contexts narrowing — the partial-evidence trap
# ─────────────────────────────────────────────────────────────────────────────

@test "ci-rollup-verdict: a required context that has not reported is PENDING, not absent" {
    # 1 of 3 required checks green must NOT read as PASSED.
    run classify "$(rollup "$(check_run build COMPLETED '"SUCCESS"')")" '["build","test","lint"]'
    [[ "$output" == PENDING* ]]
    [[ "$output" == *lint* ]]
    [[ "$output" == *test* ]]
}

@test "ci-rollup-verdict: all required contexts present and green → PASSED" {
    run classify "$(rollup "$(check_run build COMPLETED '"SUCCESS"')" "$(check_run test COMPLETED '"SUCCESS"')")" '["build","test"]'
    [[ "$output" == PASSED* ]]
}

@test "ci-rollup-verdict: a failing required context fails fast even with others missing" {
    run classify "$(rollup "$(check_run build COMPLETED '"FAILURE"')")" '["build","test"]'
    [[ "$output" == FAILED* ]]
    [[ "$output" == *build* ]]
}

@test "ci-rollup-verdict: non-required checks are ignored when required is given" {
    run classify "$(rollup "$(check_run build COMPLETED '"SUCCESS"')" "$(check_run flaky COMPLETED '"FAILURE"')")" '["build"]'
    [[ "$output" == PASSED* ]]
}

@test "ci-rollup-verdict: required names matching nothing → PENDING, not a green PASS" {
    # Branch-protection contexts are often "workflow / job" while check runs
    # are named just "job". A name mismatch must not resolve to PASSED.
    run classify "$(rollup "$(check_run build COMPLETED '"SUCCESS"')")" '["ci / build"]'
    [[ "$output" == PENDING* ]]
}

@test "ci-rollup-verdict: an error OBJECT from the protection API is ignored, not obeyed" {
    # /protection/required_status_checks/contexts 404s on unprotected repos
    # and returns {"message": "..."} — that must mean "no narrowing", not
    # "no required contexts, therefore vacuously green".
    run classify "$(rollup "$(check_run build COMPLETED '"SUCCESS"')")" '{"message":"Branch not protected"}'
    [[ "$output" == PASSED* ]]
}

@test "ci-rollup-verdict: an empty required array means no narrowing" {
    run classify "$(rollup "$(check_run build COMPLETED '"FAILURE"')")" '[]'
    [[ "$output" == FAILED* ]]
}

@test "ci-rollup-verdict: unparseable required value means no narrowing" {
    run classify "$(rollup "$(check_run build COMPLETED '"SUCCESS"')")" 'gh: command failed'
    [[ "$output" == PASSED* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# --file
# ─────────────────────────────────────────────────────────────────────────────

@test "ci-rollup-verdict: --file reads the rollup from disk" {
    printf '%s' "$(rollup "$(check_run build COMPLETED '"SUCCESS"')")" > "$BATS_TEST_TMPDIR/r.json"
    run python3 "$TOOL" --file "$BATS_TEST_TMPDIR/r.json"
    [ "$status" -eq 0 ]
    [[ "$output" == PASSED* ]]
}

@test "ci-rollup-verdict: --file on a missing path is a usage error" {
    run python3 "$TOOL" --file "$BATS_TEST_TMPDIR/nope.json"
    [ "$status" -eq 2 ]
}
