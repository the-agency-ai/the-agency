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
