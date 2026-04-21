#!/usr/bin/env bats
# test-agency-update-prune-safety.bats — regression tests for the #297 BUG 1
# data-loss path closed by issue #364 (re-implementation of PR #299 on v46.1).
#
# What Problem: Before the fix, agency update's --prune appended --delete to
# a single shared rsync_flags array. That array was reused across five rsync
# calls (agency/, .claude/skills/, .claude/commands/, tests/tools/, test_helper).
# Only the first had preview + confirmation. The other four silently deleted
# adopter-custom content.
#
# How & Why (fix): Two separate arrays — rsync_flags (agency/ only, gated by
# --prune) and rsync_flags_extras (everything else, gated by --prune-all).
# These tests lock the data-loss-prevention properties:
#   1. --prune alone does NOT delete adopter content in extras dirs
#   2. --prune-all DOES delete extras (per confirmed opt-in)
#   3. Default (no flags) deletes nothing (purely additive)
#   4. --help documents both flags with safety language
#
# Each test runs in a BATS_TEST_TMPDIR sandbox with a fake SOURCE_DIR and
# TARGET_DIR, so it exercises the real _agency-update logic without touching
# the live repo.
#
# Written: 2026-04-21 during issue #364 fix (the-agency PR fix/agency-update-v46-both-bugs).

setup() {
    SANDBOX="$BATS_TEST_TMPDIR/sb"
    mkdir -p "$SANDBOX/source" "$SANDBOX/target"

    # --- Fake SOURCE_DIR: a "the-agency" snapshot ---
    # Source has: agency/, .claude/skills/, .claude/commands/, src/tests/tools/
    mkdir -p "$SANDBOX/source/agency/tools"
    echo "#!/bin/bash" > "$SANDBOX/source/agency/tools/framework-tool"
    mkdir -p "$SANDBOX/source/.claude/skills/framework-skill"
    echo "---" > "$SANDBOX/source/.claude/skills/framework-skill/SKILL.md"
    mkdir -p "$SANDBOX/source/.claude/commands"
    echo "# fcmd" > "$SANDBOX/source/.claude/commands/framework-cmd.md"
    mkdir -p "$SANDBOX/source/src/tests/tools"
    echo "@test 'fw' { :; }" > "$SANDBOX/source/src/tests/tools/framework.bats"
    echo "load_helper() { :; }" > "$SANDBOX/source/src/tests/test_helper.bash"

    # Source registry.json (empty protected_paths — tests don't use them here)
    mkdir -p "$SANDBOX/source/agency/config"
    cat > "$SANDBOX/source/agency/config/registry.json" <<'EOF'
{"protected_paths": []}
EOF
    # Source agency.yaml is required — agency update validates it exists
    # at $SOURCE_DIR/agency/config/agency.yaml before proceeding.
    cat > "$SANDBOX/source/agency/config/agency.yaml" <<'EOF'
repo:
  name: the-agency-test-source
EOF

    # --- Fake TARGET_DIR: an "adopter" snapshot ---
    # Target has the same framework files PLUS adopter-custom content in each dir.
    mkdir -p "$SANDBOX/target/agency/tools"
    echo "#!/bin/bash" > "$SANDBOX/target/agency/tools/framework-tool"
    echo "#!/bin/bash # adopter-only" > "$SANDBOX/target/agency/tools/adopter-tool"

    mkdir -p "$SANDBOX/target/.claude/skills/framework-skill"
    echo "---" > "$SANDBOX/target/.claude/skills/framework-skill/SKILL.md"
    mkdir -p "$SANDBOX/target/.claude/skills/adopter-custom-skill"
    echo "---" > "$SANDBOX/target/.claude/skills/adopter-custom-skill/SKILL.md"

    mkdir -p "$SANDBOX/target/.claude/commands"
    echo "# fcmd" > "$SANDBOX/target/.claude/commands/framework-cmd.md"
    echo "# adopter" > "$SANDBOX/target/.claude/commands/adopter-custom-cmd.md"

    mkdir -p "$SANDBOX/target/tests/tools"
    echo "@test 'fw' { :; }" > "$SANDBOX/target/tests/tools/framework.bats"
    echo "@test 'adopter' { :; }" > "$SANDBOX/target/tests/tools/adopter-custom.bats"

    # Adopter has its own principal sandbox + workstreams — also must survive
    mkdir -p "$SANDBOX/target/usr/adopter"
    echo "my sandbox" > "$SANDBOX/target/usr/adopter/notes.md"
    mkdir -p "$SANDBOX/target/agency/workstreams/adopter-ws"
    echo "# adopter workstream" > "$SANDBOX/target/agency/workstreams/adopter-ws/README.md"

    # Make target a minimal git repo for agency update (--force skips the
    # clean-tree check so we don't need a real commit history).
    (
        cd "$SANDBOX/target"
        git init -q
        git -c user.email=t@t -c user.name=t add -A 2>/dev/null
        git -c user.email=t@t -c user.name=t commit -qm "baseline" 2>/dev/null || true
    )

    # target agency.yaml so agency update's identity resolution has something
    mkdir -p "$SANDBOX/target/agency/config"
    cat > "$SANDBOX/target/agency/config/agency.yaml" <<'EOF'
repo:
  name: adopter-test
EOF
}

# Helper: run _agency-update with given args against sandbox target+source.
# AGENCY_ARGS is a bash array — can't be exported through `bash -c` env prefix —
# so we pass the flags as positional args ("$@") and rebuild the array inside
# the sub-shell before sourcing.
_run_update() {
    AGENCY_SOURCE="$SANDBOX/source" \
    CLAUDE_PROJECT_DIR="$SANDBOX/target" \
    SB_TARGET="$SANDBOX/target" \
    bash -c 'AGENCY_ARGS=("--force" "--yes" "$@" "$SB_TARGET"); source /Users/jdm/code/the-agency/agency/tools/lib/_agency-update; _update_main' _run_update "$@" 2>&1
}

@test "default (no --prune): nothing deleted, including framework orphans, adopter-custom untouched" {
    run _run_update
    [ -f "$SANDBOX/target/agency/tools/adopter-tool" ]
    [ -f "$SANDBOX/target/.claude/skills/adopter-custom-skill/SKILL.md" ]
    [ -f "$SANDBOX/target/.claude/commands/adopter-custom-cmd.md" ]
    [ -f "$SANDBOX/target/tests/tools/adopter-custom.bats" ]
    [ -f "$SANDBOX/target/usr/adopter/notes.md" ]
    [ -f "$SANDBOX/target/agency/workstreams/adopter-ws/README.md" ]
}

@test "--prune --yes: extras dirs safe — adopter skills/commands/tests survive" {
    run _run_update --prune
    # The whole point of the fix: extras dirs are NEVER --deleted by --prune alone.
    [ -f "$SANDBOX/target/.claude/skills/adopter-custom-skill/SKILL.md" ]
    [ -f "$SANDBOX/target/.claude/commands/adopter-custom-cmd.md" ]
    [ -f "$SANDBOX/target/tests/tools/adopter-custom.bats" ]
    # Principal sandbox + workstreams always safe (excluded from rsync entirely)
    [ -f "$SANDBOX/target/usr/adopter/notes.md" ]
    [ -f "$SANDBOX/target/agency/workstreams/adopter-ws/README.md" ]
    # agency/ adopter-tool is inside the --prune scope, MAY be deleted
    # (no adopter-custom carve-out in agency/ by default). Not asserted.
}

@test "--prune-all --yes: extras dirs ARE pruned — adopter skills/commands/tests DELETED (per confirmed opt-in)" {
    run _run_update --prune-all
    # With --prune-all, adopter-custom content in extras is deleted.
    # This is the explicit opt-in semantic — adopter asked for it.
    [ ! -f "$SANDBOX/target/.claude/skills/adopter-custom-skill/SKILL.md" ]
    [ ! -f "$SANDBOX/target/.claude/commands/adopter-custom-cmd.md" ]
    [ ! -f "$SANDBOX/target/tests/tools/adopter-custom.bats" ]
    # Framework content still synced correctly
    [ -f "$SANDBOX/target/.claude/skills/framework-skill/SKILL.md" ]
    # Principal sandbox + workstreams still safe even with --prune-all
    [ -f "$SANDBOX/target/usr/adopter/notes.md" ]
    [ -f "$SANDBOX/target/agency/workstreams/adopter-ws/README.md" ]
}

@test "--help documents both --prune and --prune-all with safety language" {
    run _run_update --help
    [ "$status" -eq 0 ]
    echo "$output" | grep -q -- "--prune "
    echo "$output" | grep -q -- "--prune-all"
    # Cross-reference to tracking issues
    echo "$output" | grep -qE "(#297|#364|BUG 1)"
    # Safety language present
    echo "$output" | grep -qiE "(safety|adopter|custom|preview|opt-in)"
}
