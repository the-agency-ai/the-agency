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
    # Should proceed past the gate. Exit 0 is ideal, but rsync quirks in
    # a stub fixture can produce non-zero — the gate itself must NOT be hit.
    [[ "$output" != *"uncommitted framework file"* ]]
}

@test "agency update: clean tree proceeds past gate" {
    local root
    root=$(setup_update_fixture)
    # No modifications — clean target
    AGENCY_SOURCE="$root/source" run_agency update "$root/target"
    # Gate should not fire
    [[ "$output" != *"uncommitted framework file"* ]]
}

@test "agency update: dirty tree OUTSIDE claude/ does not block" {
    local root
    root=$(setup_update_fixture)
    # Modify a non-framework file (e.g., app code / readme)
    echo "unrelated" > "$root/target/README.md"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target"
    [[ "$output" != *"uncommitted framework file"* ]]
}

@test "agency update: dry-run skips dirty-tree gate" {
    local root
    root=$(setup_update_fixture)
    echo "stale" > "$root/target/claude/tools/some-stale-tool"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --dry-run
    # Dry-run should not trip the gate — it's read-only
    [[ "$output" != *"uncommitted framework file"* ]]
}
