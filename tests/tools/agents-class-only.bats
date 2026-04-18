#!/usr/bin/env bats
#
# What Problem: `claude/agents/` ships to every adopter via `agency init`.
# Historically, it accumulated specific agent instances (apple, designex,
# discord, gumroad, iscp, testname) masquerading as classes; plus per-agent
# accumulation (IDEAS.md, ONBOARDING.md, SESSION-*.md) in class directories.
# Adopters received dev-state pollution as if it were framework contract.
# Surfaced on andrew-demo init (2026-04-18, issues #275, #276, #288).
#
# How & Why: Enforce the class-only rule mechanically. `claude/agents/{name}/`
# is install surface ONLY for role classes, and within each class directory
# ONLY `agent.md` is framework surface. Everything else is per-agent
# accumulation and belongs in `usr/{principal}/{agent}/`.
#
# This test is the regression guard. It runs on CI so new drift (someone
# adds `claude/agents/newthing/` or drops `SESSION-*.md` into a class dir)
# fails the build at PR time, not in an adopter install.
#
# Written: 2026-04-18 during captain D45 — agent-class-only cleanup.

load 'test_helper'

# Canonical role classes shipped to adopters. Adding a new class REQUIRES
# updating this list (and it should be reviewed — class proliferation has
# a cost). Removing a class also requires updating this list.
CANONICAL_CLASSES=(
    captain
    cos
    marketing-lead
    platform-specialist
    project-manager
    researcher
    reviewer-code
    reviewer-design
    reviewer-scorer
    reviewer-security
    reviewer-test
    tech-lead
)

# `templates/` is a special class directory: it holds agent-creation templates
# (INDEX.md + per-template agent.md/KNOWLEDGE.md/ONBOARDING.md). Not subject
# to the single-agent.md rule — templates intentionally carry their own files.
SPECIAL_DIRS=(templates)

@test "agents-class-only: every top-level dir in claude/agents/ is either a canonical class or a known special dir" {
    local agents_dir="${REPO_ROOT:-$(pwd)}/claude/agents"
    [ -d "$agents_dir" ]

    local dir name
    for dir in "$agents_dir"/*/; do
        [ -d "$dir" ] || continue
        name=$(basename "$dir")

        local matched=0
        local allowed
        for allowed in "${CANONICAL_CLASSES[@]}" "${SPECIAL_DIRS[@]}"; do
            if [ "$name" = "$allowed" ]; then
                matched=1
                break
            fi
        done

        if [ "$matched" -eq 0 ]; then
            echo "FAIL: claude/agents/$name/ is not a canonical class or known special dir."
            echo "Canonical classes: ${CANONICAL_CLASSES[*]}"
            echo "Special dirs: ${SPECIAL_DIRS[*]}"
            echo ""
            echo "If $name is a new role class, add it to CANONICAL_CLASSES in this test."
            echo "If $name is a specific agent instance, move it to usr/{principal}/$name/."
            return 1
        fi
    done
}

@test "agents-class-only: every canonical class directory contains an agent.md" {
    local agents_dir="${REPO_ROOT:-$(pwd)}/claude/agents"
    local cls
    for cls in "${CANONICAL_CLASSES[@]}"; do
        if [ ! -f "$agents_dir/$cls/agent.md" ]; then
            echo "FAIL: claude/agents/$cls/agent.md missing — every canonical class must define agent.md."
            return 1
        fi
    done
}

@test "agents-class-only: no per-agent files leak into class directories (tracked content only)" {
    # Check git-tracked content rather than filesystem — gitignored runtime
    # dirs (backups/, logs/) are expected locally but never ship. This test
    # guards the SHIPPED install surface.
    local repo_root="${REPO_ROOT:-$(pwd)}"
    local cls leaked=()
    for cls in "${CANONICAL_CLASSES[@]}"; do
        local tracked
        tracked=$(cd "$repo_root" && git ls-files "claude/agents/$cls/" 2>/dev/null || true)
        [ -z "$tracked" ] && continue
        local line
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            # Strip the class-dir prefix to get the relative name
            local rel="${line#claude/agents/$cls/}"
            case "$rel" in
                agent.md)
                    # legitimate class definition
                    ;;
                IDEAS.md|ONBOARDING.md)
                    leaked+=("$line (per-agent file belongs in usr/)")
                    ;;
                SESSION-*|*/SESSION-*)
                    leaked+=("$line (session backup belongs in usr/{principal}/{agent}/history/)")
                    ;;
                logs/*|backups/*)
                    leaked+=("$line (runtime dir — should be gitignored)")
                    ;;
                notes/*)
                    leaked+=("$line (per-agent notes belong in usr/{principal}/{agent}/history/)")
                    ;;
                *)
                    leaked+=("$line (unexpected — class dirs should contain only agent.md)")
                    ;;
            esac
        done <<< "$tracked"
    done

    if [ "${#leaked[@]}" -gt 0 ]; then
        echo "FAIL: tracked per-agent or unexpected items in class directories:"
        local x
        for x in "${leaked[@]}"; do
            echo "  $x"
        done
        echo ""
        echo "Class dirs must contain only agent.md (tracked). Per-agent accumulation belongs in usr/{principal}/{agent}/."
        return 1
    fi
}

@test "agents-class-only: templates/ contains INDEX.md" {
    local agents_dir="${REPO_ROOT:-$(pwd)}/claude/agents"
    [ -f "$agents_dir/templates/INDEX.md" ]
}
