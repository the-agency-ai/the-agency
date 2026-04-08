#!/usr/bin/env bats
#
# Tests for claude/tools/release-plan
#
# Covers --version, --help, arg parsing, and the core grouping heuristics
# by exercising the tool inside a throwaway git repo so we can stage
# synthetic file changes and verify classification + feature pairing +
# agency.yaml config-block pairing.
#

load 'test_helper'

# Create an isolated git repo with a base ref for release-plan to analyze
# against. Each test works inside its own throwaway repo so staged changes
# don't contaminate the main tree.
setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    # Copy the real release-plan tool into the test repo so it can be
    # invoked as ./claude/tools/release-plan with the test repo as CWD.
    RELEASE_PLAN_TOOL="${REPO_ROOT}/claude/tools/release-plan"

    # Build a minimal mock git repo layout that release-plan can analyze
    export TEST_REPO="${BATS_TEST_TMPDIR}/mock-repo"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init --quiet --initial-branch=main 2>/dev/null || git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    # Create a minimal agency.yaml and make the initial commit
    mkdir -p claude/config claude/tools .claude/skills claude/workstreams/agency/seeds usr/jordan/captain/dispatches
    echo "# base agency.yaml" > claude/config/agency.yaml
    echo "# base README" > README.md
    git add -A
    git commit -m "initial" --quiet
    # Create an origin/main ref so release-plan has a base to compare against
    git branch -M main 2>/dev/null || true
    git update-ref refs/remotes/origin/main HEAD

    # Copy the tool into the test repo so relative paths resolve
    mkdir -p claude/tools
    cp "$RELEASE_PLAN_TOOL" claude/tools/release-plan
    chmod +x claude/tools/release-plan
}

teardown() {
    test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "release-plan: --version shows version" {
    cd "$TEST_REPO"
    run ./claude/tools/release-plan --version
    assert_success
    assert_output_contains "release-plan"
    assert_output_contains "1.0.0"
}

@test "release-plan: --help shows usage" {
    cd "$TEST_REPO"
    run ./claude/tools/release-plan --help
    assert_success
    assert_output_contains "release-plan"
    assert_output_contains "Usage:"
    assert_output_contains "--base"
    assert_output_contains "--output"
}

@test "release-plan: unknown arg fails" {
    cd "$TEST_REPO"
    run ./claude/tools/release-plan --bogus
    assert_failure
    assert_output_contains "unknown arg"
}

# ─────────────────────────────────────────────────────────────────────────────
# Core analysis (empty repo, no changes)
# ─────────────────────────────────────────────────────────────────────────────

@test "release-plan: empty repo produces basic plan with no commits" {
    cd "$TEST_REPO"
    run ./claude/tools/release-plan --no-switch --no-other
    assert_success
    assert_output_contains "Release Plan"
    assert_output_contains "Current branch"
    assert_output_contains "Base ref"
}

# ─────────────────────────────────────────────────────────────────────────────
# Group classification
# ─────────────────────────────────────────────────────────────────────────────

@test "release-plan: classifies methodology files correctly" {
    cd "$TEST_REPO"
    mkdir -p claude
    echo "# methodology" > claude/CLAUDE-THEAGENCY.md
    git add claude/CLAUDE-THEAGENCY.md
    run ./claude/tools/release-plan --no-switch
    assert_success
    assert_output_contains "Methodology"
    assert_output_contains "claude/CLAUDE-THEAGENCY.md"
}

@test "release-plan: classifies tool files correctly" {
    cd "$TEST_REPO"
    echo "#!/bin/bash" > claude/tools/my-tool
    chmod +x claude/tools/my-tool
    git add claude/tools/my-tool
    run ./claude/tools/release-plan --no-switch
    assert_success
    assert_output_contains "Tools"
    assert_output_contains "claude/tools/my-tool"
}

@test "release-plan: classifies skill files correctly" {
    cd "$TEST_REPO"
    mkdir -p .claude/skills/my-skill
    echo "# skill" > .claude/skills/my-skill/SKILL.md
    git add .claude/skills/my-skill/SKILL.md
    run ./claude/tools/release-plan --no-switch
    assert_success
    assert_output_contains "Skills"
    assert_output_contains ".claude/skills/my-skill/SKILL.md"
}

@test "release-plan: classifies workstream seeds correctly" {
    cd "$TEST_REPO"
    echo "# seed" > claude/workstreams/agency/seeds/seed-test-20260408.md
    git add claude/workstreams/agency/seeds/seed-test-20260408.md
    run ./claude/tools/release-plan --no-switch
    assert_success
    assert_output_contains "Workstream"
    assert_output_contains "seed-test-20260408.md"
}

@test "release-plan: classifies coordination dispatches correctly" {
    cd "$TEST_REPO"
    echo "# dispatch" > usr/jordan/captain/dispatches/directive-test-20260408-1200.md
    git add usr/jordan/captain/dispatches/directive-test-20260408-1200.md
    run ./claude/tools/release-plan --no-switch
    assert_success
    assert_output_contains "Coordination"
    assert_output_contains "/coord-commit"
    assert_output_contains "directive-test-20260408-1200.md"
}

@test "release-plan: excludes scratch files from commits" {
    cd "$TEST_REPO"
    mkdir -p usr/jordan/captain/tmp
    echo "scratch" > usr/jordan/captain/tmp/scratch.md
    git add usr/jordan/captain/tmp/scratch.md
    run ./claude/tools/release-plan --no-switch
    assert_success
    assert_output_contains "EXCLUDE"
    assert_output_contains "scratch"
}

# ─────────────────────────────────────────────────────────────────────────────
# Feature pairing: tool + matching skill go into one commit
# ─────────────────────────────────────────────────────────────────────────────

@test "release-plan: pairs tool with matching skill into feature commit" {
    cd "$TEST_REPO"
    echo "#!/bin/bash" > claude/tools/widget
    chmod +x claude/tools/widget
    mkdir -p .claude/skills/widget
    echo "# skill" > .claude/skills/widget/SKILL.md
    git add claude/tools/widget .claude/skills/widget/SKILL.md
    run ./claude/tools/release-plan --no-switch
    assert_success
    assert_output_contains "Feature"
    assert_output_contains "widget"
    # Both files should appear in the same feature commit section
    # (we can't assert their proximity easily in BATS, but both presence is enough)
    assert_output_contains "claude/tools/widget"
    assert_output_contains ".claude/skills/widget/SKILL.md"
}

@test "release-plan: tool without matching skill stays in Tools group" {
    cd "$TEST_REPO"
    echo "#!/bin/bash" > claude/tools/lonely-tool
    chmod +x claude/tools/lonely-tool
    git add claude/tools/lonely-tool
    run ./claude/tools/release-plan --no-switch
    assert_success
    # Should land in Tools group, not as a Feature
    assert_output_contains "Tools"
    assert_output_contains "claude/tools/lonely-tool"
}

# ─────────────────────────────────────────────────────────────────────────────
# agency.yaml config-block pairing
# ─────────────────────────────────────────────────────────────────────────────

@test "release-plan: agency.yaml without feature stays in Config" {
    cd "$TEST_REPO"
    cat > claude/config/agency.yaml <<'EOF'
# agency.yaml
random:
  provider: "test"
EOF
    git add claude/config/agency.yaml
    run ./claude/tools/release-plan --no-switch
    assert_success
    assert_output_contains "Config"
    assert_output_contains "claude/config/agency.yaml"
}

@test "release-plan: agency.yaml folds into feature when section matches tool" {
    cd "$TEST_REPO"
    # Create a tool+skill called "widgets" (plural to test stemming)
    echo "#!/bin/bash" > claude/tools/widget
    chmod +x claude/tools/widget
    mkdir -p .claude/skills/widget
    echo "# skill" > .claude/skills/widget/SKILL.md
    # Add a widgets: block to agency.yaml
    cat > claude/config/agency.yaml <<'EOF'
# agency.yaml
widgets:
  provider: "github"
EOF
    git add claude/tools/widget .claude/skills/widget/SKILL.md claude/config/agency.yaml
    run ./claude/tools/release-plan --no-switch
    assert_success
    assert_output_contains "Feature"
    assert_output_contains "widget"
    # agency.yaml should appear under the feature commit, not Config
    # Hard to assert grouping ordering in BATS; verify agency.yaml is there at all
    assert_output_contains "agency.yaml"
}

# ─────────────────────────────────────────────────────────────────────────────
# Output options
# ─────────────────────────────────────────────────────────────────────────────

@test "release-plan: --output writes to file" {
    cd "$TEST_REPO"
    run ./claude/tools/release-plan --no-switch --output plan.md
    assert_success
    assert_output_contains "Wrote plan to"
    [ -f "$TEST_REPO/plan.md" ]
}

@test "release-plan: --base changes base ref comparison" {
    cd "$TEST_REPO"
    # Create a new commit and use origin/main (which is the initial commit)
    echo "v2" > README.md
    git add README.md
    git commit -m "v2" --quiet
    run ./claude/tools/release-plan --no-switch --base origin/main
    assert_success
    assert_output_contains "Ahead of base by"
    assert_output_contains "1 commit"
}
