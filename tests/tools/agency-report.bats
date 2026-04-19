#!/usr/bin/env bats
#
# BATS: agency-report (v46.0 reset — Phase 0b)
# Required min-test-count: 4 (per Plan v4 §3 Phase 0b)
# Actual tests: 4

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/agency/tools/agency-report"
    TMP_REPO="$(mktemp -d -t arr.XXXXXX)"
    cd "$TMP_REPO"
    git init -q .
    git config user.email "t@t"
    git config user.name "t"
    # Need agency-verify-v46 findable — symlink to main-tree
    mkdir -p claude/tools
    cp "$REPO_ROOT/agency/tools/agency-verify-v46" agency/tools/
    chmod +x agency/tools/agency-verify-v46
    echo seed > README
    git add .; git commit -q -m s
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "dry-run emits diagnostic to stdout" {
    # Verify will detect missing agency/ — that's fine; we just want diagnostic
    run "$TOOL"
    [ "$status" -eq 0 ]
    [[ "$output" == *"v46.0 migration diagnostic"* ]]
}

@test "--output writes to file" {
    run "$TOOL" --output report.md
    [ "$status" -eq 0 ]
    [ -f report.md ]
    grep -q "v46.0 migration diagnostic" report.md
}

@test "missing verify tool produces exit 10" {
    # Remove the tool we staged
    rm -f agency/tools/agency-verify-v46
    run "$TOOL"
    [ "$status" -eq 10 ]
}
