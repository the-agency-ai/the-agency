#!/usr/bin/env bats
#
# What Problem: Test-pollution dirs (testname/, unknown/, shell-injection
# named dirs, test-auto QGR files) have crept into the tree multiple times
# from unscoped test runs (#419). Each purge is only as durable as the next
# test pollution cycle. We need a standing assertion that these paths never
# re-appear on main.
#
# How & Why: This test acts as a tripwire — it runs as part of the standard
# BATS suite and fails loudly if any of the known pollution paths come back.
# If a new legitimate workstream ever needs one of these names, update this
# test at the same time.
#
# Written: 2026-04-22 during Fix Wave I (#419)

load test_helper

@test "agency/agents/testname/ does not exist on disk" {
    [ ! -d "${REPO_ROOT}/agency/agents/testname" ]
}

@test "agency/agents/unknown/ does not exist on disk" {
    [ ! -d "${REPO_ROOT}/agency/agents/unknown" ]
}

@test "agency/workstreams/ contains no shell-injection-named dir" {
    # Matches anything with ';' or 'rm -rf' in the name — covers 'test; rm -rf '
    # and variants. Use a glob through bash because `find` is hookify-blocked.
    local ws_dir="${REPO_ROOT}/agency/workstreams"
    local d
    for d in "$ws_dir"/*\;* "$ws_dir"/*rm\ -rf* ; do
        [ -e "$d" ] || continue
        echo "Found shell-injection-named workstream: $d" >&2
        return 1
    done
}

@test "no test-auto QGR files exist in agency/workstreams" {
    # Globstar isn't on by default — iterate workstreams and check qgr/ + rgr/
    local ws_dir="${REPO_ROOT}/agency/workstreams"
    local ws sub f
    for ws in "$ws_dir"/*/; do
        [ -d "$ws" ] || continue
        for sub in qgr rgr; do
            [ -d "$ws$sub" ] || continue
            for f in "$ws$sub"/test-*-test-auto-*.md; do
                [ -e "$f" ] || continue
                echo "Found test-auto pollution: $f" >&2
                return 1
            done
        done
    done
}

@test "agency/workstreams/housekeeping/ has been consolidated away" {
    # Per plan, housekeeping workstream is consolidated into agency/
    # workstream. The directory itself may still exist as an untracked
    # artifact from prior runs — but it MUST NOT be tracked in git.
    cd "${REPO_ROOT}"
    if git ls-files agency/workstreams/housekeeping 2>/dev/null | grep -q .; then
        echo "agency/workstreams/housekeeping/ is tracked in git — should be consolidated into agency/" >&2
        return 1
    fi
}
