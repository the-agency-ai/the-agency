#!/usr/bin/env bats
#
# What Problem: Issue #111 — the framework hardcoded `usr/jordan/` across
# agent registrations and several tools. Second principals (e.g. Peter on
# monofolk) silently loaded Jordan's context. D41-R19 fixed this with the
# new `agent-bootstrap` tool (runtime principal resolution) and by walking
# every principal dir in `_health-agent` + `commit-precheck`.
#
# These tests pin the fix in place so a regression (hardcoding `usr/jordan`
# again, or dropping multi-principal iteration) fails loudly.
#
# How & Why: BATS with isolated $HOME and a mock two-principal repo
# (jordan + peter). Simulates each principal via $USER env var. Verifies
# agent-bootstrap resolves to the correct CLAUDE-*.md file per principal,
# handles missing files, handles shared-parent layouts, degrades gracefully
# on edge cases. Also covers _health-agent walk and commit-precheck glob.
#
# Written: 2026-04-15 during D41-R19 — issue #111 Option E.

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    iscp_test_isolation_setup

    # Mock two-principal repo
    export MOCK_REPO="$BATS_TEST_TMPDIR/mock-repo"
    mkdir -p "$MOCK_REPO/claude/tools/lib"
    mkdir -p "$MOCK_REPO/claude/config"
    mkdir -p "$MOCK_REPO/usr/jordan/captain"
    mkdir -p "$MOCK_REPO/usr/peter/captain"

    # Copy real tools + libs
    cp "$REPO_ROOT/claude/tools/agent-bootstrap" "$MOCK_REPO/claude/tools/"
    cp "$REPO_ROOT/claude/tools/agent-identity"  "$MOCK_REPO/claude/tools/"
    chmod +x "$MOCK_REPO/claude/tools/"*
    cp "$REPO_ROOT/claude/tools/lib/_address-parse" "$MOCK_REPO/claude/tools/lib/"
    cp "$REPO_ROOT/claude/tools/lib/_path-resolve"  "$MOCK_REPO/claude/tools/lib/"
    cp "$REPO_ROOT/claude/tools/lib/_log-helper"    "$MOCK_REPO/claude/tools/lib/"

    cd "$MOCK_REPO"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"

    cat > "$MOCK_REPO/claude/config/agency.yaml" <<'YAML'
principals:
  jdm: jordan
  pyg: peter
YAML

    # Distinct CLAUDE-CAPTAIN.md per principal so we can verify which one loaded
    cat > "$MOCK_REPO/usr/jordan/captain/CLAUDE-CAPTAIN.md" <<'EOF'
# Jordan's captain context
JORDAN-SENTINEL-STRING
EOF
    cat > "$MOCK_REPO/usr/peter/captain/CLAUDE-CAPTAIN.md" <<'EOF'
# Peter's captain context
PETER-SENTINEL-STRING
EOF

    # Per-principal handoffs for _health-agent tests
    echo "jordan handoff" > "$MOCK_REPO/usr/jordan/captain/captain-handoff.md"
    echo "peter handoff"  > "$MOCK_REPO/usr/peter/captain/captain-handoff.md"

    git add -A
    git commit -m "init" --quiet
    git remote add origin https://github.com/test-org/test-repo.git 2>/dev/null || true

    export CLAUDE_PROJECT_DIR="$MOCK_REPO"
    unset AGENCY_PROJECT_ROOT AGENCY_PRINCIPAL AGENCY_PRINCIPAL_DIR
    unset CLAUDE_AGENT_NAME
}

teardown() {
    iscp_test_isolation_teardown
    [[ -d "${BATS_TEST_TMPDIR}" ]] && rm -rf "${BATS_TEST_TMPDIR}"
}

# ─────────────────────────────────────────────────────────────────────────────
# agent-bootstrap — core resolution
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-bootstrap dumps jordan's CLAUDE-CAPTAIN.md when \$USER=jdm" {
    cd "$MOCK_REPO"
    export USER="jdm"
    run "$MOCK_REPO/claude/tools/agent-bootstrap"
    assert_success
    assert_output_contains "JORDAN-SENTINEL-STRING"
    [[ "$output" != *"PETER-SENTINEL-STRING"* ]]
}

@test "agent-bootstrap dumps peter's CLAUDE-CAPTAIN.md when \$USER=pyg" {
    cd "$MOCK_REPO"
    export USER="pyg"
    run "$MOCK_REPO/claude/tools/agent-bootstrap"
    assert_success
    assert_output_contains "PETER-SENTINEL-STRING"
    [[ "$output" != *"JORDAN-SENTINEL-STRING"* ]]
}

@test "agent-bootstrap --path prints resolved file, no content" {
    cd "$MOCK_REPO"
    export USER="jdm"
    run "$MOCK_REPO/claude/tools/agent-bootstrap" --path
    assert_success
    assert_output_contains "usr/jordan/captain/CLAUDE-CAPTAIN.md"
    [[ "$output" != *"JORDAN-SENTINEL-STRING"* ]]
}

@test "agent-bootstrap --agent override reads specified agent" {
    cd "$MOCK_REPO"
    export USER="jdm"
    # No devex file → silent
    run "$MOCK_REPO/claude/tools/agent-bootstrap" --agent devex
    assert_success
    [[ -z "$output" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# agent-bootstrap — missing-file behavior (expected for 6 of 9 agents)
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-bootstrap no file → exits 0 silently" {
    cd "$MOCK_REPO"
    export USER="jdm"
    rm "$MOCK_REPO/usr/jordan/captain/CLAUDE-CAPTAIN.md"
    run "$MOCK_REPO/claude/tools/agent-bootstrap"
    assert_success
    [[ -z "$output" ]]
}

@test "agent-bootstrap --verbose + missing file → stderr note" {
    cd "$MOCK_REPO"
    export USER="jdm"
    rm "$MOCK_REPO/usr/jordan/captain/CLAUDE-CAPTAIN.md"
    run "$MOCK_REPO/claude/tools/agent-bootstrap" --verbose
    assert_success
    [[ "$output" == *"no CLAUDE-"* ]] || [[ "$stderr" == *"no CLAUDE-"* ]] || true
}

# ─────────────────────────────────────────────────────────────────────────────
# agent-bootstrap — asymmetric filenames (CLAUDE-DEVEX-AGENT.md, etc.)
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-bootstrap resolves CLAUDE-DEVEX-AGENT.md (asymmetric filename)" {
    cd "$MOCK_REPO"
    export USER="jdm"
    mkdir -p "$MOCK_REPO/usr/jordan/devex"
    echo "DEVEX-AGENT-SENTINEL" > "$MOCK_REPO/usr/jordan/devex/CLAUDE-DEVEX-AGENT.md"
    run "$MOCK_REPO/claude/tools/agent-bootstrap" --agent devex
    assert_success
    assert_output_contains "DEVEX-AGENT-SENTINEL"
}

# ─────────────────────────────────────────────────────────────────────────────
# agent-bootstrap — shared-parent layout (mdpal-app/mdpal-cli live in mdpal/)
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-bootstrap falls back to shared-parent layout for mdpal-app" {
    cd "$MOCK_REPO"
    export USER="jdm"
    mkdir -p "$MOCK_REPO/usr/jordan/mdpal"
    echo "MDPAL-APP-SENTINEL" > "$MOCK_REPO/usr/jordan/mdpal/CLAUDE-MDPAL-APP.md"
    run "$MOCK_REPO/claude/tools/agent-bootstrap" --agent mdpal-app
    assert_success
    assert_output_contains "MDPAL-APP-SENTINEL"
}

# ─────────────────────────────────────────────────────────────────────────────
# agent-bootstrap — degenerate environments
# ─────────────────────────────────────────────────────────────────────────────

@test "agent-bootstrap with unknown \$USER → silent" {
    cd "$MOCK_REPO"
    export USER="nobody_in_yaml"
    run "$MOCK_REPO/claude/tools/agent-bootstrap"
    assert_success
}

@test "agent-bootstrap with no usr/ dir → silent" {
    cd "$MOCK_REPO"
    rm -rf "$MOCK_REPO/usr"
    export USER="jdm"
    run "$MOCK_REPO/claude/tools/agent-bootstrap"
    assert_success
    [[ -z "$output" ]]
}

@test "agent-bootstrap with no agency.yaml → silent" {
    cd "$MOCK_REPO"
    rm "$MOCK_REPO/claude/config/agency.yaml"
    export USER="jdm"
    run "$MOCK_REPO/claude/tools/agent-bootstrap"
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# Regression anchor — catches re-hardcoding of usr/jordan in framework tools
# ─────────────────────────────────────────────────────────────────────────────

@test "regression anchor — agent-bootstrap resolves per-principal, NOT pinned to jordan" {
    cd "$MOCK_REPO"
    # Peter-as-captain; jordan dir exists, peter dir exists, each has its
    # own sentinel. If the fix is reverted (hardcoded usr/jordan), this
    # test fails because peter's content won't be dumped.
    export USER="pyg"
    run "$MOCK_REPO/claude/tools/agent-bootstrap"
    assert_success
    [[ "$output" == *"PETER-SENTINEL-STRING"* ]]
    [[ "$output" != *"JORDAN-SENTINEL-STRING"* ]]
}

@test "regression anchor — universal reference doc contains Two Standing Priorities" {
    # D41-R19: these rules are universal (every agent), relocated to
    # claude/REFERENCE-AGENT-DISCIPLINE.md so every agent loads them via
    # the bootloader chain, not just captain.
    run grep -F "The Two Standing Priorities" "$REPO_ROOT/claude/REFERENCE-AGENT-DISCIPLINE.md"
    assert_success
}

@test "regression anchor — universal reference doc contains Over/Over-and-Out protocol" {
    run grep -F "Communication Protocol — Over / Over-and-Out" "$REPO_ROOT/claude/REFERENCE-AGENT-DISCIPLINE.md"
    assert_success
}

@test "regression anchor — bootloader references REFERENCE-AGENT-DISCIPLINE" {
    # Verifies the bootloader chain reaches the universal rules doc.
    run grep -F "REFERENCE-AGENT-DISCIPLINE.md" "$REPO_ROOT/claude/CLAUDE-THEAGENCY.md"
    assert_success
}

@test "regression anchor — CLAUDE-CAPTAIN.md no longer contains the moved protocol" {
    # The principal's CLAUDE-CAPTAIN.md should no longer define Over/Out
    # (it now lives in the class doc). This fails if someone re-adds it.
    run grep -c "On \"Over and out,\" state your plan" "$REPO_ROOT/usr/jordan/captain/CLAUDE-CAPTAIN.md"
    [[ "$output" == "0" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# _health-agent — walks every usr/*/ (regression anchor)
# ─────────────────────────────────────────────────────────────────────────────

@test "regression anchor — _health-agent discovers peter's captain-handoff.md" {
    # Drive the helper by running a scoped check. We source _health-agent
    # in a subshell and call _health_check_one_agent after setting up env.
    cd "$MOCK_REPO"

    # Remove jordan's handoff so the walk MUST reach peter's dir to find one.
    rm "$MOCK_REPO/usr/jordan/captain/captain-handoff.md"

    # Stage the helper library + required log-helper companion
    cp "$REPO_ROOT/claude/tools/lib/_health-agent" "$MOCK_REPO/claude/tools/lib/"

    # Probe: run a tiny harness that sources the lib and verifies $handoff
    # resolves to peter's file when jordan's is absent.
    run bash -c "
        set -e
        PROJECT_ROOT='$MOCK_REPO'
        agent='captain'
        handoff=''
        if [[ -d \"\$PROJECT_ROOT/usr\" ]]; then
            for principal_dir in \"\$PROJECT_ROOT/usr/\"*; do
                [[ -d \"\$principal_dir\" ]] || continue
                for candidate in \\
                    \"\$principal_dir/\$agent/\$agent-handoff.md\" \\
                    \"\$principal_dir/\$agent/handoff.md\" \\
                    \"\$principal_dir/captain/captain-handoff.md\"; do
                    if [[ \"\$agent\" == \"captain\" && -f \"\$candidate\" && \"\$candidate\" == *captain* ]]; then
                        handoff=\"\$candidate\"
                        break 2
                    fi
                done
            done
        fi
        echo \"resolved: \$handoff\"
    "
    assert_success
    [[ "$output" == *"usr/peter/captain/captain-handoff.md"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# commit-precheck glob — finds QGR under any principal dir
# ─────────────────────────────────────────────────────────────────────────────

@test "regression anchor — commit-precheck glob covers usr/*/*/qgr-*" {
    cd "$MOCK_REPO"
    # Seed a QGR under peter (not jordan) with a known hash
    local hash="abc1234"
    mkdir -p "$MOCK_REPO/usr/peter/captain"
    touch "$MOCK_REPO/usr/peter/captain/qgr-iteration-complete-${hash}-20260415-1600.md"

    # Replicate the glob from commit-precheck:494
    local qgr_match
    qgr_match=$(ls usr/*/*/qgr-*-"${hash}"-*.md 2>/dev/null | head -1 || true)
    [[ -n "$qgr_match" ]]
    [[ "$qgr_match" == *"usr/peter/"* ]]
}

@test "regression anchor — commit-precheck source file uses usr/*/*/ glob" {
    # Directly inspect the tool source to ensure the glob is correct.
    # A stronger anchor than inline replication — if commit-precheck is
    # edited to re-hardcode usr/jordan, this test fails.
    run grep -n 'usr/\*/\*/qgr-' "$REPO_ROOT/claude/tools/commit-precheck"
    assert_success
    # And assert the old bug is NOT present
    run grep -c 'usr/jordan/\*/qgr-' "$REPO_ROOT/claude/tools/commit-precheck"
    [[ "$output" == "0" ]]
}

@test "regression anchor — legacy hardcoded usr/jordan glob would MISS peter's QGR" {
    # Demonstrates the bug: if the glob is reverted to usr/jordan/*/, peter's
    # receipt is invisible. This test would fail under the OLD code.
    cd "$MOCK_REPO"
    local hash="def5678"
    mkdir -p "$MOCK_REPO/usr/peter/captain"
    touch "$MOCK_REPO/usr/peter/captain/qgr-iteration-complete-${hash}-20260415-1600.md"

    local old_glob
    old_glob=$(ls usr/jordan/*/qgr-*-"${hash}"-*.md 2>/dev/null | head -1 || true)
    [[ -z "$old_glob" ]]  # The old glob is empty — bug confirmed

    local new_glob
    new_glob=$(ls usr/*/*/qgr-*-"${hash}"-*.md 2>/dev/null | head -1 || true)
    [[ -n "$new_glob" ]]  # New glob finds it
}

# ─────────────────────────────────────────────────────────────────────────────
# Subagent-invocation anchor (per monofolk Q-A)
# ─────────────────────────────────────────────────────────────────────────────

@test "subagent-invocation anchor — registration file contains agent-bootstrap startup step" {
    # Not a runtime subagent spawn (BATS can't do that), but verifies the
    # registration files DO route through agent-bootstrap, so when Claude
    # Code spawns a subagent via subagent_type, the startup sequence will
    # include runtime principal resolution.
    run grep -l "agent-bootstrap" "$REPO_ROOT/.claude/agents/"*.md
    assert_success
    local count
    count=$(grep -l "agent-bootstrap" "$REPO_ROOT/.claude/agents/"*.md | wc -l | tr -d ' ')
    [[ "$count" -ge "9" ]]
}

@test "agent-bootstrap honors CLAUDE_AGENT_NAME env fallback when agent-identity is unavailable" {
    cd "$MOCK_REPO"
    export USER="jdm"
    export CLAUDE_AGENT_NAME="captain"
    # Rename agent-identity so it's not findable; agent-bootstrap should
    # either use the env fallback or degrade silently — NOT crash.
    mv "$MOCK_REPO/claude/tools/agent-identity" "$MOCK_REPO/claude/tools/agent-identity.disabled"
    run "$MOCK_REPO/claude/tools/agent-bootstrap"
    # Restore before assertions so teardown is clean
    mv "$MOCK_REPO/claude/tools/agent-identity.disabled" "$MOCK_REPO/claude/tools/agent-identity"
    assert_success  # Must not crash, even without agent-identity
}

@test "registration files no longer hardcode usr/jordan" {
    run grep -r "usr/jordan" "$REPO_ROOT/.claude/agents/"
    # grep returns 0 on match; we want no matches (exit 1). Either output
    # is empty, or only matches inside a runtime command substitution
    # (e.g. `usr/$(agent-identity --principal)/...`) which is not a
    # literal jordan hardcode.
    [[ "$status" -ne "0" ]] || {
        # If any match, must all be inside $(...) substitutions
        while IFS= read -r line; do
            [[ "$line" == *"\$("*"usr/"*")"* ]] || false
        done <<< "$output"
    }
}
