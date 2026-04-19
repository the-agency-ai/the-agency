#!/usr/bin/env bats
#
# sandbox-sync tests — engineer detection + symlink behavior (D44-R4 / issue #420).
#
# Each test builds an isolated repo fixture with:
#   - minimal claude/config/agency.yaml (defines principals)
#   - claude/tools/config (copied from the live repo — sandbox-sync reads it)
#   - claude/tools/sandbox-sync (the subject of the test)
#   - usr/<principal>/ sandbox layout under test
#
# No dependency on the live usr/ layout.

load 'test_helper'

SANDBOX_SYNC="${REPO_ROOT}/claude/tools/sandbox-sync"

# Build an isolated repo fixture with the pieces sandbox-sync needs. Accepts
# a list of principal slugs — scaffolds usr/<slug>/ and an agency.yaml that
# maps a chosen $USER to the first slug.
_setup_fixture() {
    local primary_principal="${1:-jordan}"
    local primary_user="${2:-testuser}"

    export FIX="${BATS_TEST_TMPDIR}/sandbox-sync-repo"
    mkdir -p "$FIX"
    cd "$FIX"
    git init --quiet --initial-branch=main 2>/dev/null || git init --quiet
    git config user.email "t@t.com"
    git config user.name "Test"
    git config commit.gpgsign false

    mkdir -p .claude/commands .claude/hooks
    mkdir -p claude/tools/lib claude/config

    # Copy the minimum framework tools sandbox-sync depends on
    cp "${REPO_ROOT}/claude/tools/sandbox-sync" claude/tools/sandbox-sync
    cp "${REPO_ROOT}/claude/tools/config" claude/tools/config
    chmod +x claude/tools/sandbox-sync claude/tools/config

    cat > claude/config/agency.yaml <<YAML
principals:
  ${primary_user}:
    name: ${primary_principal}
    display_name: "Primary"
  default:
    name: unknown
YAML

    mkdir -p "usr/${primary_principal}/commands"
    mkdir -p "usr/${primary_principal}/hookify"
    mkdir -p "usr/${primary_principal}/hooks"
    mkdir -p "usr/${primary_principal}/agents"

    echo "placeholder" > README.md
    git add -A
    git commit -m "fixture" --quiet --no-verify
}

# ─────────────────────────────────────────────────────────────────────────────
# Engineer detection (Bug #1 — no alphabetical fallback)
# ─────────────────────────────────────────────────────────────────────────────

@test "sandbox-sync: resolves principal via agency.yaml for matching \$USER" {
    _setup_fixture jordan testuser
    cd "$FIX"
    run env HOME="$ORIGINAL_HOME" USER=testuser ./claude/tools/sandbox-sync
    [ "$status" -eq 0 ]
    [[ "$output" == *"sandbox-sync:"* ]]
}

@test "sandbox-sync: refuses on unmapped \$USER — no alphabetical fallback" {
    # Multi-principal fixture with jordan AND alice. Previous code fell back
    # to alphabetical (alice) for an unknown $USER. After D44-R4 it must refuse.
    _setup_fixture jordan jdm
    cd "$FIX"
    mkdir -p usr/alice/commands
    touch usr/alice/.gitkeep
    git add usr/alice
    git commit -m "add alice" --quiet --no-verify

    run env HOME="$ORIGINAL_HOME" USER=peter ./claude/tools/sandbox-sync
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot resolve principal"* ]] || [[ "$output" == *"peter"* ]]
    # Critical regression check: MUST NOT silently pick alice or jordan.
    [[ "$output" != *"sandbox-sync: 0 commands"* ]]
}

@test "sandbox-sync: refuses when \$USER maps to 'unknown' default sentinel" {
    _setup_fixture jordan jdm
    cd "$FIX"

    # Simulate the default catchall — should be rejected, not used.
    run env HOME="$ORIGINAL_HOME" USER=someone_not_in_principals ./claude/tools/sandbox-sync
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot resolve principal"* ]]
}

@test "sandbox-sync: PRINCIPAL env var overrides \$USER lookup" {
    _setup_fixture jordan jdm
    cd "$FIX"
    # Wrong USER but right PRINCIPAL — should succeed.
    run env HOME="$ORIGINAL_HOME" USER=wronguser PRINCIPAL=jordan ./claude/tools/sandbox-sync
    [ "$status" -eq 0 ]
    [[ "$output" == *"sandbox-sync:"* ]]
}

@test "sandbox-sync: falls back to \$USER if usr/\$USER/ exists and no agency.yaml mapping" {
    # Bootstrap scenario: sandbox named after system username but not yet
    # registered in agency.yaml. sandbox-sync should still succeed.
    _setup_fixture jordan jdm
    cd "$FIX"
    mkdir -p usr/newuser/commands
    touch usr/newuser/.gitkeep
    git add usr/newuser
    git commit -m "new sandbox" --quiet --no-verify

    run env HOME="$ORIGINAL_HOME" USER=newuser ./claude/tools/sandbox-sync
    [ "$status" -eq 0 ]
    [[ "$output" == *"sandbox-sync:"* ]]
}

@test "sandbox-sync: refuses when resolved principal has no sandbox dir" {
    _setup_fixture jordan jdm
    cd "$FIX"
    # Edit agency.yaml to map testuser → ghost, but usr/ghost/ doesn't exist.
    cat > claude/config/agency.yaml <<YAML
principals:
  testuser:
    name: ghost
    display_name: "Ghost"
  default:
    name: unknown
YAML

    run env HOME="$ORIGINAL_HOME" USER=testuser ./claude/tools/sandbox-sync
    [ "$status" -ne 0 ]
    [[ "$output" == *"no sandbox at usr/ghost"* ]] || [[ "$output" == *"ghost"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Path alignment (Bug #2 — sandbox-sync reads commands/ not claude/commands/)
# ─────────────────────────────────────────────────────────────────────────────

@test "sandbox-sync: reads commands from usr/<principal>/commands/ (no claude/ prefix)" {
    _setup_fixture jordan testuser
    cd "$FIX"
    # Put a command at the POST-D44-R4 path
    echo "# test command" > usr/jordan/commands/my-cmd.md

    run env HOME="$ORIGINAL_HOME" USER=testuser ./claude/tools/sandbox-sync
    [ "$status" -eq 0 ]
    # The symlink should be created at .claude/commands/usr-jordan.my-cmd.md
    [ -L .claude/commands/usr-jordan.my-cmd.md ]
}

@test "sandbox-sync: ignores usr/<principal>/claude/commands/ (legacy path)" {
    _setup_fixture jordan testuser
    cd "$FIX"
    # Put a command at the LEGACY path — sandbox-sync should NOT pick it up.
    mkdir -p usr/jordan/claude/commands
    echo "# legacy" > usr/jordan/claude/commands/legacy-cmd.md

    run env HOME="$ORIGINAL_HOME" USER=testuser ./claude/tools/sandbox-sync
    [ "$status" -eq 0 ]
    # The legacy symlink should NOT have been created.
    [ ! -L .claude/commands/usr-jordan.legacy-cmd.md ]
}

@test "sandbox-sync: reads hookify from usr/<principal>/hookify/ (no claude/ prefix)" {
    _setup_fixture jordan testuser
    cd "$FIX"
    echo "# hookify rule" > usr/jordan/hookify/my-rule.md

    run env HOME="$ORIGINAL_HOME" USER=testuser ./claude/tools/sandbox-sync
    [ "$status" -eq 0 ]
    [ -L .claude/hookify.usr-jordan.my-rule.md ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Basic symlink behavior
# ─────────────────────────────────────────────────────────────────────────────

@test "sandbox-sync: idempotent — second run reports existing, no changes" {
    _setup_fixture jordan testuser
    cd "$FIX"
    echo "# cmd" > usr/jordan/commands/x.md

    env HOME="$ORIGINAL_HOME" USER=testuser ./claude/tools/sandbox-sync >/dev/null
    run env HOME="$ORIGINAL_HOME" USER=testuser ./claude/tools/sandbox-sync
    [ "$status" -eq 0 ]
    [[ "$output" == *"existing: 1 already current"* ]]
    [[ "$output" == *"created:  0"* ]]
}

@test "sandbox-sync: --quiet suppresses output when no changes" {
    _setup_fixture jordan testuser
    cd "$FIX"
    echo "# cmd" > usr/jordan/commands/x.md

    env HOME="$ORIGINAL_HOME" USER=testuser ./claude/tools/sandbox-sync >/dev/null
    run env HOME="$ORIGINAL_HOME" USER=testuser ./claude/tools/sandbox-sync --quiet
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Filename / dir-name safety (D44-R4 QG findings #1/#2 — symlink path traversal)
# ─────────────────────────────────────────────────────────────────────────────

@test "sandbox-sync: skips commands with '..' in filename (no symlink created)" {
    _setup_fixture jordan testuser
    cd "$FIX"
    # basename("...evil.md") == "...evil.md" — contains '..'
    echo "evil" > "usr/jordan/commands/...evil.md"
    echo "# good" > "usr/jordan/commands/good.md"

    run env HOME="$ORIGINAL_HOME" USER=testuser ./claude/tools/sandbox-sync
    [ "$status" -eq 0 ]
    [[ "$output" == *"unsafe command filename"* ]] || [[ "$output" == *"...evil.md"* ]]
    # Good file still gets symlinked
    [ -L .claude/commands/usr-jordan.good.md ]
    # Unsafe file does NOT get symlinked
    [ ! -L ".claude/commands/usr-jordan....evil.md" ]
}

@test "sandbox-sync: skips agent dirs with '..' in name" {
    _setup_fixture jordan testuser
    cd "$FIX"
    # A directory literally named "..escape" — contains ".." prefix
    mkdir -p "usr/jordan/agents/..escape"
    touch "usr/jordan/agents/..escape/agent.md"
    mkdir -p "usr/jordan/agents/goodagent"
    touch "usr/jordan/agents/goodagent/agent.md"

    run env HOME="$ORIGINAL_HOME" USER=testuser ./claude/tools/sandbox-sync
    [ "$status" -eq 0 ]
    # Good agent dir gets symlinked
    [ -L .claude/agents/usr-jordan.goodagent ]
    # Unsafe agent dir rejected
    [ ! -L ".claude/agents/usr-jordan...escape" ]
}

@test "sandbox-sync: leading-dot hidden files in commands/ are skipped" {
    _setup_fixture jordan testuser
    cd "$FIX"
    # Dotfiles other than .gitkeep are rejected (leading dot could be traversal-adjacent)
    echo "hidden" > "usr/jordan/commands/.hidden.md"
    echo "# good" > "usr/jordan/commands/good.md"

    run env HOME="$ORIGINAL_HOME" USER=testuser ./claude/tools/sandbox-sync
    [ "$status" -eq 0 ]
    [ -L .claude/commands/usr-jordan.good.md ]
    [ ! -L .claude/commands/usr-jordan..hidden.md ]
}
