#!/usr/bin/env bats
#
# What Problem: Issue #297 BUG 1 — `agency update --prune` on a consumer repo
# with an adopter-custom skill/command/test in .claude/skills/, .claude/commands/,
# or tests/tools/ silently deleted that content. Root cause: the --prune
# preview + confirmation only gated the main claude/ sync, but `--delete`
# was appended to a shared `rsync_flags` array reused for all sync calls.
# So adopter-custom content in extras dirs was wiped without the preview
# warning.
#
# How & Why: D45-R2 split rsync_flags into two arrays. rsync_flags (for
# claude/) gets --delete from --prune as before. rsync_flags_extras (for
# .claude/skills/, .claude/commands/, tests/tools/) does NOT get --delete
# from --prune — a separate --prune-all flag is required, with its own
# preview + confirmation. Belt + suspenders: adopters get defense against
# data loss even if they mis-use --prune.
#
# This test is the regression guard: if someone reintroduces the data-loss
# path (e.g., by sharing rsync_flags across all sync calls with --delete,
# or by forgetting to branch on PRUNE_ALL), this BATS fails loud at PR time.
#
# Written: 2026-04-19 during captain D45 — in response to monofolk/captain
# filing issue #297 and principal directive to review + fix.

load 'test_helper'

# Build a minimal source + target for prune-safety tests.
#
# Source (the-agency):
#   claude/config/agency.yaml
#   claude/tools/framework-tool         (framework, will be kept)
#   .claude/skills/framework-skill/SKILL.md
#
# Target (adopter repo):
#   claude/config/agency.yaml
#   claude/tools/framework-tool         (framework, matches source)
#   claude/tools/orphan-framework-tool  (stale framework — will be pruned by --prune)
#   claude/tools/my-project-tool        (ADOPTER-CUSTOM — must be preserved)
#   .claude/skills/framework-skill/SKILL.md
#   .claude/skills/adopter-custom-skill/SKILL.md   (ADOPTER-CUSTOM — must be preserved with --prune alone)
#   .claude/commands/adopter-custom.md             (ADOPTER-CUSTOM — must be preserved with --prune alone)
#   tests/tools/adopter-custom.bats                (ADOPTER-CUSTOM — must be preserved with --prune alone)
#   registry.json with protected_paths listing my-project-tool
setup_prune_fixture() {
    local root="${BATS_TEST_TMPDIR}/prune-fixture"
    mkdir -p "$root/source/claude/config" \
             "$root/source/claude/tools" \
             "$root/source/.claude/skills/framework-skill" \
             "$root/source/.claude/commands" \
             "$root/source/tests/tools"
    mkdir -p "$root/target/claude/config" \
             "$root/target/claude/tools" \
             "$root/target/.claude/skills/framework-skill" \
             "$root/target/.claude/skills/adopter-custom-skill" \
             "$root/target/.claude/commands" \
             "$root/target/tests/tools"

    # --- Source ---
    cat > "$root/source/claude/config/agency.yaml" <<EOF
framework:
  version: "99.0.0"
  source_commit: "abc1234"
  updated_at: "2026-04-19T00:00:00+00:00"
EOF
    echo "#!/usr/bin/env bash" > "$root/source/claude/tools/framework-tool"
    chmod +x "$root/source/claude/tools/framework-tool"
    cat > "$root/source/.claude/skills/framework-skill/SKILL.md" <<EOF
---
name: framework-skill
description: A framework skill from source
---
framework content
EOF

    # --- Target ---
    cat > "$root/target/claude/config/agency.yaml" <<EOF
framework:
  version: "1.0.0"
  source_commit: "deadbee"
  updated_at: "2026-04-01T00:00:00+00:00"
EOF
    # registry protects adopter's custom tool
    cat > "$root/target/registry.json" <<EOF
{
  "protected_paths": [
    "claude/tools/my-project-tool"
  ]
}
EOF
    echo "#!/usr/bin/env bash" > "$root/target/claude/tools/framework-tool"
    chmod +x "$root/target/claude/tools/framework-tool"
    echo "#!/usr/bin/env bash" > "$root/target/claude/tools/orphan-framework-tool"
    chmod +x "$root/target/claude/tools/orphan-framework-tool"
    echo "#!/usr/bin/env bash" > "$root/target/claude/tools/my-project-tool"
    chmod +x "$root/target/claude/tools/my-project-tool"
    cat > "$root/target/.claude/skills/framework-skill/SKILL.md" <<EOF
---
name: framework-skill
description: A framework skill from target
---
target content
EOF
    cat > "$root/target/.claude/skills/adopter-custom-skill/SKILL.md" <<EOF
---
name: adopter-custom-skill
description: My project-specific skill. MUST SURVIVE --prune.
---
adopter content
EOF
    cat > "$root/target/.claude/commands/adopter-custom.md" <<EOF
# adopter-custom — project-specific command. MUST SURVIVE --prune.
EOF
    cat > "$root/target/tests/tools/adopter-custom.bats" <<EOF
#!/usr/bin/env bats
@test "adopter custom bats — MUST SURVIVE --prune" { true; }
EOF

    # git-init both so _agency-update can record source_commit
    ( cd "$root/source" && git init --quiet && git add -A && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify )
    ( cd "$root/target" && git init --quiet && git add -A && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify )

    echo "$root"
}

@test "prune-safety: --prune alone does NOT delete adopter-custom skills/commands/tests (belt + suspenders)" {
    # The CORE of issue #297 BUG 1 — before D45-R2, --prune alone would
    # silently delete adopter content in .claude/skills/, .claude/commands/,
    # and tests/tools/ because they all shared one rsync_flags array.
    # After D45-R2: --prune only touches claude/; extras dirs are protected.
    local root
    root=$(setup_prune_fixture)

    AGENCY_SOURCE="$root/source" run "${TOOLS_DIR}/agency" update --prune --yes "$root/target"

    # Adopter-custom content MUST survive --prune
    [ -f "$root/target/.claude/skills/adopter-custom-skill/SKILL.md" ]
    [ -f "$root/target/.claude/commands/adopter-custom.md" ]
    [ -f "$root/target/tests/tools/adopter-custom.bats" ]

    # Framework content remains
    [ -f "$root/target/claude/tools/framework-tool" ]
}

@test "prune-safety: --prune-all deletes adopter-custom in extras dirs on confirmation" {
    # --prune-all is the explicit opt-in for deleting extras orphans.
    # Adopters who really want to clean up their custom extras invoke this.
    local root
    root=$(setup_prune_fixture)

    AGENCY_SOURCE="$root/source" run "${TOOLS_DIR}/agency" update --prune-all --yes "$root/target"

    # With --prune-all + --yes, adopter-custom extras WILL be deleted
    [ ! -f "$root/target/.claude/skills/adopter-custom-skill/SKILL.md" ]
    [ ! -f "$root/target/.claude/commands/adopter-custom.md" ]
    [ ! -f "$root/target/tests/tools/adopter-custom.bats" ]

    # Framework content remains
    [ -f "$root/target/claude/tools/framework-tool" ]
    [ -f "$root/target/.claude/skills/framework-skill/SKILL.md" ]
}

@test "prune-safety: default (no flags) is purely additive — nothing gets deleted" {
    local root
    root=$(setup_prune_fixture)

    AGENCY_SOURCE="$root/source" run "${TOOLS_DIR}/agency" update "$root/target"

    # EVERYTHING in target survives — default update is additive
    [ -f "$root/target/.claude/skills/adopter-custom-skill/SKILL.md" ]
    [ -f "$root/target/.claude/commands/adopter-custom.md" ]
    [ -f "$root/target/tests/tools/adopter-custom.bats" ]
    [ -f "$root/target/claude/tools/framework-tool" ]
    [ -f "$root/target/claude/tools/orphan-framework-tool" ]   # no --prune means orphan stays
}

@test "prune-safety: --help documents both --prune and --prune-all with safety language" {
    run "${TOOLS_DIR}/agency" update --help
    assert_success
    assert_output_contains "--prune"
    assert_output_contains "--prune-all"
    assert_output_contains "belt"   # belt+suspenders language in help
    assert_output_contains "#297"   # issue cross-ref
}
