#!/usr/bin/env bats
#
# Structural tests for auto-release.yml workflow — C#372 Fix D.
#
# What Problem: Auto-release is the eliminator — it removes captain's
# manual step of cutting releases after every merge. End-to-end behavior
# runs on GitHub only; these tests lock in the STRUCTURE so nobody
# accidentally breaks the contract at edit time.
#
# Written: 2026-04-21 during C#372 Fix D.
#

load 'test_helper'

setup() {
    cd "${REPO_ROOT}"
}

@test "auto-release.yml exists" {
    [ -f .github/workflows/auto-release.yml ]
}

@test "auto-release.yml is valid YAML" {
    run python3 -c "
import yaml
with open('.github/workflows/auto-release.yml') as f:
    yaml.safe_load(f)
print('ok')
"
    [ "$status" -eq 0 ]
    [[ "$output" == "ok" ]]
}

@test "auto-release: triggers on push to main/master" {
    run python3 -c "
import yaml
with open('.github/workflows/auto-release.yml') as f: y = yaml.safe_load(f)
trig = y.get('on') or y.get(True) or {}
push = trig.get('push', {})
branches = push.get('branches', [])
assert 'main' in branches or 'master' in branches, f'expected main or master: {branches}'
print('ok')
"
    [ "$status" -eq 0 ]
}

@test "auto-release: grants contents: write permission" {
    run python3 -c "
import yaml
with open('.github/workflows/auto-release.yml') as f: y = yaml.safe_load(f)
perms = y.get('permissions', {})
assert perms.get('contents') == 'write', f'contents=write required for release creation: {perms}'
print('ok')
"
    [ "$status" -eq 0 ]
}

@test "auto-release: detects merge commits (two-parent)" {
    run grep -q "parent_count.*2" .github/workflows/auto-release.yml
    [ "$status" -eq 0 ]
}

@test "auto-release: reads agency_version from manifest.json" {
    run grep -q 'agency_version agency/config/manifest.json' .github/workflows/auto-release.yml
    [ "$status" -eq 0 ]
}

@test "auto-release: idempotent — checks if release already exists before creating" {
    # The 'already=true' branch signals Fix D detected manual creation.
    run grep -q "already=true" .github/workflows/auto-release.yml
    [ "$status" -eq 0 ]
}

@test "auto-release: uses --generate-notes for release body" {
    run grep -q '\-\-generate-notes' .github/workflows/auto-release.yml
    [ "$status" -eq 0 ]
}

@test "auto-release: hard-verifies release after create (fail-loud pattern)" {
    # Post-create gh release view matches the pr-captain-post-merge pattern
    run grep -c 'gh release view' .github/workflows/auto-release.yml
    [ "$status" -eq 0 ]
    # Should appear at least twice: once for exists-check, once for post-create verify
    [[ "$output" -ge 2 ]]
}

@test "auto-release: non-merge commits are skipped" {
    run grep -q "Not a merge commit" .github/workflows/auto-release.yml
    [ "$status" -eq 0 ]
}
