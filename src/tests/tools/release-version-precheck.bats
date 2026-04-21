#!/usr/bin/env bats
#
# Structural tests for release-version-precheck.yml workflow.
#
# What Problem: The workflow is a PR-time gate that blocks merges when
# agency_version isn't bumped. End-to-end behavior runs on GitHub only;
# these tests lock in the STRUCTURE so nobody accidentally breaks the
# contract at edit time (e.g. removes the version comparison, or
# changes the trigger, or drops the D.R parse).
#
# Written: 2026-04-21 during C#372 Fix C.
#

load 'test_helper'

setup() {
    cd "${REPO_ROOT}"
}

@test "release-version-precheck.yml exists" {
    [ -f .github/workflows/release-version-precheck.yml ]
}

@test "release-version-precheck.yml is valid YAML" {
    run python3 -c "
import yaml, sys
with open('.github/workflows/release-version-precheck.yml') as f:
    yaml.safe_load(f)
print('ok')
"
    [ "$status" -eq 0 ]
    [[ "$output" == "ok" ]]
}

@test "release-version-precheck: triggers on pull_request to main/master" {
    run python3 -c "
import yaml
with open('.github/workflows/release-version-precheck.yml') as f: y = yaml.safe_load(f)
# PyYAML parses 'on:' as True when unquoted. Accept either.
trig = y.get('on') or y.get(True) or {}
pr = trig.get('pull_request', {})
branches = pr.get('branches', [])
assert 'main' in branches or 'master' in branches, f'expected main or master: {branches}'
print('ok')
"
    [ "$status" -eq 0 ]
    [[ "$output" == "ok" ]]
}

@test "release-version-precheck: has version-bump-check job" {
    run python3 -c "
import yaml
with open('.github/workflows/release-version-precheck.yml') as f: y = yaml.safe_load(f)
assert 'version-bump-check' in y['jobs'], f'missing job: {list(y[\"jobs\"].keys())}'
print('ok')
"
    [ "$status" -eq 0 ]
}

@test "release-version-precheck: skips Dependabot + fork PRs at step level (NOT job level)" {
    # QG round 1: the skip MUST live at step level, not job level — a
    # job-level `if: false` makes the whole job "skipped", and a skipped
    # required-status-check is treated by branch protection as "missing"
    # → blocks the merge. The skip step must set an output, subsequent
    # steps gate on `steps.skip_check.outputs.skip != 'true'`.
    run python3 -c "
import yaml
with open('.github/workflows/release-version-precheck.yml') as f: y = yaml.safe_load(f)
job = y['jobs']['version-bump-check']
# Job-level if must NOT contain the Dependabot/fork guard (would trap at required-check level)
job_if = job.get('if', '')
assert 'dependabot' not in job_if.lower(), f'job-level if: contains dependabot skip — this is the #13 trap: {job_if}'
# Skip must live in a step
steps = job['steps']
skip_step = next((s for s in steps if s.get('id') == 'skip_check'), None)
assert skip_step is not None, 'no step with id=skip_check'
cond = skip_step.get('if', '')
assert 'dependabot' in cond.lower(), f'skip step missing dependabot condition: {cond}'
assert 'head.repo.full_name' in cond, f'skip step missing fork condition: {cond}'
# Subsequent steps must gate on steps.skip_check.outputs.skip
non_skip_steps = [s for s in steps if s.get('id') != 'skip_check']
for s in non_skip_steps:
    step_if = s.get('if', '')
    assert 'skip_check.outputs.skip' in step_if, f'step {s.get(\"name\")} missing skip_check guard: {step_if}'
print('ok')
"
    [ "$status" -eq 0 ]
    [[ "$output" == "ok" ]]
}

@test "release-version-precheck: reads agency_version from manifest.json" {
    run grep -q 'agency_version agency/config/manifest.json' .github/workflows/release-version-precheck.yml
    [ "$status" -eq 0 ]
}

@test "release-version-precheck: compares PR version to latest release tag" {
    # Look for the greater-than comparison — the core logic.
    run grep -Eq 'pr_d.*-gt.*lt_d|\\$pr_r.*-gt.*\\$lt_r' .github/workflows/release-version-precheck.yml
    [ "$status" -eq 0 ]
}

@test "release-version-precheck: fails when version not bumped" {
    # Error message must name Fix C and guide the adopter
    run grep -q 'C#372 Fix C' .github/workflows/release-version-precheck.yml
    [ "$status" -eq 0 ]
    run grep -q 'NOT a bump' .github/workflows/release-version-precheck.yml
    [ "$status" -eq 0 ]
}
