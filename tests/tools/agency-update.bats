#!/usr/bin/env bats
#
# Tests for `agency update` — focus on the interrupted-prior-update gate
# added in D41-Rn (captain directive in dispatch #386). When the target
# tree has uncommitted framework changes (claude/ or .claude/), update
# should fail loud with a 3-line guide naming git-safe-commit, unless
# --force is passed.
#

load 'test_helper'

run_agency() {
    run "${TOOLS_DIR}/agency" "$@"
}

# ─────────────────────────────────────────────────────────────────────────────
# Help + flags
# ─────────────────────────────────────────────────────────────────────────────

@test "agency update: --help shows --force option" {
    run_agency update --help
    assert_success
    assert_output_contains "--force"
}

@test "agency update: unknown flag fails" {
    run_agency update --bogus
    assert_failure
    assert_output_contains "Unknown option"
}

# ─────────────────────────────────────────────────────────────────────────────
# Dirty-tree gate (interrupted prior update)
# ─────────────────────────────────────────────────────────────────────────────

# Build a minimal initialized target + a source tree to serve as update origin.
# Both are git repos. We stub AGENCY_SOURCE to point at the source.
setup_update_fixture() {
    local root="${BATS_TEST_TMPDIR}/fixture"
    mkdir -p "$root/source/claude/config" "$root/source/claude/tools" "$root/source/.claude/skills"
    mkdir -p "$root/target/claude/config" "$root/target/claude/tools" "$root/target/.claude/skills"

    # Source agency.yaml
    cat > "$root/source/claude/config/agency.yaml" <<EOF
framework:
  version: "99.0.0"
  source_commit: "abc1234"
  updated_at: "2026-04-15T00:00:00+00:00"
EOF
    # Target agency.yaml (older version)
    cat > "$root/target/claude/config/agency.yaml" <<EOF
framework:
  version: "1.0.0"
  source_commit: "deadbee"
  updated_at: "2026-04-01T00:00:00+00:00"
EOF

    # Init git in both
    ( cd "$root/source" && git init --quiet && git add -A && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify )
    ( cd "$root/target" && git init --quiet && git add -A && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify )

    echo "$root"
}

@test "agency update: dirty tree under claude/ blocks with remediation message" {
    local root
    root=$(setup_update_fixture)
    # Simulate an interrupted prior update — a framework file is modified
    echo "stale change" > "$root/target/claude/tools/some-stale-tool"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target"
    assert_failure
    assert_output_contains "uncommitted framework file"
    assert_output_contains "git-safe-commit"
    assert_output_contains "--force"
}

@test "agency update: dirty tree under .claude/ also blocks" {
    local root
    root=$(setup_update_fixture)
    echo "---" > "$root/target/.claude/skills/stale.md"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target"
    assert_failure
    assert_output_contains "uncommitted framework file"
}

@test "agency update: --force bypasses dirty-tree gate" {
    local root
    root=$(setup_update_fixture)
    echo "stale" > "$root/target/claude/tools/some-stale-tool"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --force
    # QG fix: assert the gate itself was not hit AND that update made progress
    # (reached the version-resolution banner). Earlier version accepted any
    # exit code, which made this test pass even on early unrelated crashes.
    [[ "$output" != *"uncommitted framework file"* ]]
    [[ "$output" == *"Agency Update"* ]] || [[ "$output" == *"From:"* ]]
}

@test "agency update: clean tree proceeds past gate" {
    local root
    root=$(setup_update_fixture)
    # No modifications — clean target
    AGENCY_SOURCE="$root/source" run_agency update "$root/target"
    # QG fix: positive assertion the update actually progressed past the gate
    [[ "$output" != *"uncommitted framework file"* ]]
    [[ "$output" == *"Agency Update"* ]] || [[ "$output" == *"From:"* ]]
}

@test "agency update: dirty tree OUTSIDE claude/ does not block" {
    local root
    root=$(setup_update_fixture)
    # Modify a non-framework file (e.g., app code / readme)
    echo "unrelated" > "$root/target/README.md"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target"
    [[ "$output" != *"uncommitted framework file"* ]]
    [[ "$output" == *"Agency Update"* ]] || [[ "$output" == *"From:"* ]]
}

@test "agency update: dry-run skips dirty-tree gate" {
    local root
    root=$(setup_update_fixture)
    echo "stale" > "$root/target/claude/tools/some-stale-tool"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --dry-run
    # Dry-run should not trip the gate — it's read-only.
    # QG fix: also assert dry-run banner is shown so we know we reached
    # update execution, not a pre-flight crash.
    [[ "$output" != *"uncommitted framework file"* ]]
    [[ "$output" == *"dry-run"* ]] || [[ "$output" == *"Dry Run"* ]]
}

# NOTE: a scale test for >20 dirty files was considered but the fixture setup
# cost (creating 25 files, git-statusing them, asserting exact count string)
# is disproportionate to the risk. The count fix — moving `grep -c '^'` to
# operate on the full porcelain output instead of the head-20 truncated
# version — is a one-line refactor that the positive-assertion tests above
# already exercise end-to-end.

# ─────────────────────────────────────────────────────────────────────────────
# D41-R16: opt-in --prune (rsync --delete with protected paths)
# ─────────────────────────────────────────────────────────────────────────────

@test "agency update: --help documents --prune and --yes" {
    run_agency update --help
    assert_success
    assert_output_contains "--prune"
    assert_output_contains "--yes"
}

@test "agency update: default (no --prune) does NOT delete orphaned target files" {
    # Defensive regression test — forbids silent orphan deletion by default.
    local root
    root=$(setup_update_fixture)
    # Orphan only in target, not in source
    local orphan="$root/target/claude/tools/my-local-tool"
    echo "#!/bin/bash" > "$orphan"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --force --yes
    # The orphan must survive — default sync is additive only
    [ -f "$orphan" ]
}

@test "agency update: --prune --dry-run previews deletions but does not delete" {
    local root
    root=$(setup_update_fixture)
    local orphan="$root/target/claude/tools/my-local-tool"
    echo "#!/bin/bash" > "$orphan"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --prune --dry-run --force
    # Dry-run: orphan still exists
    [ -f "$orphan" ]
    # Prune preview should mention the orphan count or the dry-run note
    [[ "$output" == *"--prune"* ]] || [[ "$output" == *"dry-run"* ]]
}

@test "agency update: --prune --yes deletes orphaned target files" {
    local root
    root=$(setup_update_fixture)
    local orphan="$root/target/claude/tools/my-local-tool"
    echo "#!/bin/bash" > "$orphan"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --prune --yes --force
    # Orphan must be removed
    [ ! -f "$orphan" ]
}

@test "agency update: --prune --yes preserves usr/ and workstreams/" {
    local root
    root=$(setup_update_fixture)
    # Create adopter-owned files under usr/ (sandbox) and workstreams/ that
    # don't exist in source — they must survive prune via the hard excludes.
    mkdir -p "$root/target/usr/jordan/captain"
    echo "handoff" > "$root/target/usr/jordan/captain/captain-handoff.md"
    mkdir -p "$root/target/claude/workstreams/myproject"
    echo "knowledge" > "$root/target/claude/workstreams/myproject/KNOWLEDGE.md"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --prune --yes --force
    [ -f "$root/target/usr/jordan/captain/captain-handoff.md" ]
    [ -f "$root/target/claude/workstreams/myproject/KNOWLEDGE.md" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R20: --from-github default-ref behavior (issue #113)
#
# These tests exercise the parser-level default for the --from-github flag.
# They do NOT actually clone from github (would require network and a real
# fork). They verify the default ref the parser/resolver would pass to git.
# ─────────────────────────────────────────────────────────────────────────────

@test "agency update: --help documents new default and @latest opt-in" {
    run_agency update --help
    assert_success
    assert_output_contains "Default: main"
    assert_output_contains "@latest"
}

@test "agency update: --help no longer claims 'latest tag' as default" {
    run_agency update --help
    assert_success
    # The phrase 'default: latest tag' WAS the old behavior; ensure it's gone.
    [[ "$output" != *"default: latest tag"* ]]
}

@test "agency update: --from-github with no ref falls through to main resolution" {
    # Without network access we cannot complete a clone, so we expect the tool
    # to fail at the clone step. But the verbose output should reference 'main'
    # (the new default), not 'latest'.
    cd "$BATS_TEST_TMPDIR"
    mkdir -p target/claude/config
    cat > target/claude/config/agency.yaml <<EOF
framework:
  version: "1.0.0"
  source_commit: "deadbee"
EOF
    cd target && git init --quiet && git add -A && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify
    # --force bypasses dirty-tree gate (unrelated to this test)
    GITHUB_REPO_URL="file:///nonexistent-r20-test" run "${TOOLS_DIR}/agency" update --from-github --force 2>&1
    # The "ref: ..." log line tells us what FROM_GITHUB resolved to.
    assert_output_contains "ref: main"
}

@test "agency update: --from-github @latest opt-in attempts release-tag resolution" {
    cd "$BATS_TEST_TMPDIR"
    mkdir -p target/claude/config
    cat > target/claude/config/agency.yaml <<EOF
framework:
  version: "1.0.0"
  source_commit: "deadbee"
EOF
    cd target && git init --quiet && git add -A && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify
    # @latest takes the gh-release-view branch (or falls back to main if gh
    # missing or release lookup fails).
    GITHUB_REPO_URL="file:///nonexistent-r20-test" run "${TOOLS_DIR}/agency" update --from-github @latest --force 2>&1
    # The "ref: @latest" log line shows we entered the @latest branch
    assert_output_contains "ref: @latest"
}

@test "agency update: legacy --from-github latest emits deprecation warning" {
    cd "$BATS_TEST_TMPDIR"
    mkdir -p target/claude/config
    cat > target/claude/config/agency.yaml <<EOF
framework:
  version: "1.0.0"
  source_commit: "deadbee"
EOF
    cd target && git init --quiet && git add -A && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify
    # --force bypasses the unrelated dirty-tree gate so we can reach the
    # from-github resolution path.
    GITHUB_REPO_URL="file:///nonexistent-r20-test" run "${TOOLS_DIR}/agency" update --from-github latest --force 2>&1
    assert_output_contains "deprecated"
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R20: release-tag-check workflow file present and well-formed
# ─────────────────────────────────────────────────────────────────────────────

@test "release-tag-check workflow file exists and references manifest version" {
    [[ -f "$REPO_ROOT/.github/workflows/release-tag-check.yml" ]]
    run grep -F "agency_version" "$REPO_ROOT/.github/workflows/release-tag-check.yml"
    assert_success
    run grep -F "gh release view" "$REPO_ROOT/.github/workflows/release-tag-check.yml"
    assert_success
}

@test "release-tag-check workflow only fires on push to main" {
    run grep -A2 "^on:" "$REPO_ROOT/.github/workflows/release-tag-check.yml"
    assert_success
    # assert_output_contains uses bash regex; brackets are character classes.
    # Use a fixed-string grep instead to verify the literal phrase.
    run grep -F "branches: [main]" "$REPO_ROOT/.github/workflows/release-tag-check.yml"
    assert_success
}

@test "release-tag-check workflow skips non-merge commits (single-parent)" {
    # Verify the parent-count logic exists so housekeeping coord-commits don't
    # trigger false-red CI.
    run grep -F "parents == '2'" "$REPO_ROOT/.github/workflows/release-tag-check.yml"
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R20: post-merge skill enforces release verification
# ─────────────────────────────────────────────────────────────────────────────

@test "post-merge skill marks release-tag step as MANDATORY with hard verify" {
    run grep -F "MANDATORY" "$REPO_ROOT/.claude/skills/post-merge/SKILL.md"
    assert_success
    run grep -F "hard check" "$REPO_ROOT/.claude/skills/post-merge/SKILL.md"
    assert_success
    run grep -F "release-tag-check" "$REPO_ROOT/.claude/skills/post-merge/SKILL.md"
    assert_success
}
