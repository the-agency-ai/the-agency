#!/usr/bin/env bats
#
# Skill validation tests — static tier testing for all framework skills
#
# Validates:
#   - Every skill has a SKILL.md that exists and is non-empty
#   - No skill contains monofolk-specific residue
#   - No skill references non-existent tools
#   - Skill count matches expected
#   - Valid SKILL.md frontmatter (has allowed-tools line)
#

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/.claude/skills"

# Minimum expected framework skills (threshold, not exact count)
EXPECTED_SKILL_MIN=50

# ─────────────────────────────────────────────────────────────────────────────
# Skill existence and count
# ─────────────────────────────────────────────────────────────────────────────

@test "skills: directory exists" {
    [ -d "$SKILLS_DIR" ]
}

@test "skills: at least $EXPECTED_SKILL_MIN skills" {
    local count
    count=$(find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
    [ "$count" -ge "$EXPECTED_SKILL_MIN" ]
}

@test "skills: every skill has a non-empty SKILL.md" {
    local failures=""
    for skill_dir in "$SKILLS_DIR"/*/; do
        local name
        name=$(basename "$skill_dir")
        local skill_file="$skill_dir/SKILL.md"
        if [ ! -f "$skill_file" ]; then
            failures="${failures}MISSING: $name\n"
        elif [ ! -s "$skill_file" ]; then
            failures="${failures}EMPTY: $name\n"
        fi
    done
    if [ -n "$failures" ]; then
        echo -e "$failures" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Frontmatter validation
# ─────────────────────────────────────────────────────────────────────────────

@test "skills: no SKILL.md has allowed-tools in frontmatter (flag #62/#63 — removed)" {
    # Flag #62/#63: allowed-tools was removed from all skills because restricting
    # to specific subcommand patterns silently blocks agents on permission prompts
    # they cannot see. Skills inherit from .claude/settings.json instead.
    local failures=""
    for skill_dir in "$SKILLS_DIR"/*/; do
        local name
        name=$(basename "$skill_dir")
        if head -5 "$skill_dir/SKILL.md" | grep -q "allowed-tools:"; then
            failures="${failures}$name\n"
        fi
    done
    if [ -n "$failures" ]; then
        echo -e "Skills still have allowed-tools (should be removed per flag #62/#63):\n$failures" >&2
        return 1
    fi
}

@test "skills: every SKILL.md has description in frontmatter" {
    local failures=""
    for skill_dir in "$SKILLS_DIR"/*/; do
        local name
        name=$(basename "$skill_dir")
        if ! head -10 "$skill_dir/SKILL.md" | grep -q "description:"; then
            failures="${failures}$name\n"
        fi
    done
    if [ -n "$failures" ]; then
        echo -e "Missing description:\n$failures" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# No monofolk residue
# ─────────────────────────────────────────────────────────────────────────────

@test "skills: no hardcoded usr/jordan/" {
    local hits
    hits=$(grep -rl "usr/jordan/" "$SKILLS_DIR" 2>/dev/null || true)
    if [ -n "$hits" ]; then
        echo "Found usr/jordan/ in:" >&2
        echo "$hits" >&2
        return 1
    fi
}

@test "skills: no monofolk references" {
    local hits
    hits=$(grep -rli "monofolk" "$SKILLS_DIR" 2>/dev/null || true)
    if [ -n "$hits" ]; then
        echo "Found monofolk in:" >&2
        echo "$hits" >&2
        return 1
    fi
}

@test "skills: no hardcoded doppler references" {
    local hits
    hits=$(grep -rli "doppler" "$SKILLS_DIR" 2>/dev/null || true)
    if [ -n "$hits" ]; then
        echo "Found doppler in:" >&2
        echo "$hits" >&2
        return 1
    fi
}

@test "skills: no hardcoded prisma references" {
    local hits
    hits=$(grep -rli "prisma" "$SKILLS_DIR" 2>/dev/null || true)
    if [ -n "$hits" ]; then
        echo "Found prisma in:" >&2
        echo "$hits" >&2
        return 1
    fi
}

@test "skills: no hardcoded pnpm references (use configurable test/lint commands)" {
    local hits
    # Exclude comments that mention pnpm as an example
    hits=$(grep -rl '\bpnpm\b' "$SKILLS_DIR" 2>/dev/null | while read -r f; do
        if grep -v '^#\|^<!--\|example\|e\.g\.' "$f" | grep -q '\bpnpm\b'; then
            echo "$f"
        fi
    done || true)
    if [ -n "$hits" ]; then
        echo "Found hardcoded pnpm in:" >&2
        echo "$hits" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Tool reference validation
# ─────────────────────────────────────────────────────────────────────────────

@test "skills: tool references in allowed-tools point to existing tools" {
    local failures=""
    for skill_dir in "$SKILLS_DIR"/*/; do
        local name
        name=$(basename "$skill_dir")
        # Extract tool names from Bash(./agency/tools/{name}*) patterns
        local tools
        tools=$(grep -o 'Bash(\./agency/tools/[a-z_-]*' "$skill_dir/SKILL.md" 2>/dev/null | sed 's|Bash(\./agency/tools/||' || true)
        for tool in $tools; do
            # Provider-dispatch tools use wildcards (e.g., deploy-*) — check for any matching tool
            if echo "$tool" | grep -q -- '-$'; then
                # Tool name ends with hyphen — it's a provider-dispatch prefix (e.g., "deploy-")
                # Skip validation — actual tool depends on configured provider
                continue
            fi
            if [ ! -f "$REPO_ROOT/agency/tools/$tool" ]; then
                failures="${failures}$name references missing tool: $tool\n"
            fi
        done
    done
    if [ -n "$failures" ]; then
        echo -e "$failures" >&2
        return 1
    fi
}

@test "skills: required_reading frontmatter paths point to existing files" {
    # Regression guard for flag #213: 11 skills' required_reading pointed at
    # pre-Great-Rename paths (agency/REFERENCE-*.md instead of
    # agency/REFERENCE/REFERENCE-*.md) and rotted silently because nothing
    # checked them. Every path listed under a required_reading: block must exist.
    # Parser assumes block-style YAML (one "  - path" per line, no trailing
    # inline comments). Flow-style (required_reading: [a, b]) would be skipped;
    # no skill uses it today. Broaden the parser if that convention ever changes.
    local failures=""
    for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
        [ -f "$skill_file" ] || continue
        local name
        name=$(basename "$(dirname "$skill_file")")
        local paths
        paths=$(SKILL_FILE="$skill_file" python3 -c '
import os, re
text = open(os.environ["SKILL_FILE"]).read()
# List items must be INDENTED (leading whitespace) so the column-0 "---"
# frontmatter terminator is not mistaken for an entry.
m = re.search(r"^required_reading:[ \t]*\n((?:[ \t]+-[ \t]*.+\n?)+)", text, re.M)
out = []
if m:
    for line in m.group(1).splitlines():
        s = line.strip()
        if s.startswith("-"):
            p = s[1:].strip().strip("\"").strip("'"'"'")
            # Real required_reading entries are file paths (have a directory
            # component); skip anything that is not path-shaped.
            if p and "/" in p:
                out.append(p)
print("\n".join(out))
' 2>/dev/null)
        for p in $paths; do
            if [ ! -f "$REPO_ROOT/$p" ]; then
                failures="${failures}$name required_reading missing: $p\n"
            fi
        done
    done
    if [ -n "$failures" ]; then
        echo -e "$failures" >&2
        return 1
    fi
}

@test "quality-gate: every reviewer subagent_type is a registered agent" {
    # Guard for flag #186/#194: the reviewer-* classes existed in agency/agents/
    # but were NOT registered under .claude/agents/, so every /quality-gate
    # invocation of subagent_type: reviewer-code (etc.) failed and the gate
    # silently degraded. Each reviewer subagent_type the quality-gate skill names
    # must have a registration discoverable somewhere under .claude/agents/.
    local qg="$REPO_ROOT/.claude/skills/quality-gate/SKILL.md"
    [ -f "$qg" ] || skip "quality-gate SKILL.md not found"
    local types
    types=$(grep -oE 'subagent_type: `?reviewer-[a-z]+`?' "$qg" | grep -oE 'reviewer-[a-z]+' | sort -u)
    [ -n "$types" ] || skip "no reviewer subagent_types referenced"
    local failures=""
    for t in $types; do
        # find (not ** glob) for bash-3.2 portability
        if [ -z "$(find "$REPO_ROOT/.claude/agents" -name "$t.md" -type f 2>/dev/null | head -1)" ]; then
            failures="${failures}quality-gate references unregistered subagent: $t\n"
        fi
    done
    if [ -n "$failures" ]; then
        echo -e "$failures" >&2
        return 1
    fi
}

@test "agents: registrations import via @agency/, never the pre-Rename @claude/" {
    # Guard for flag #246: agent registrations imported @claude/agents/... and
    # @claude/workstreams/... but claude/ was renamed to agency/, so every agent
    # loaded its frontmatter (name/description/model) but NOT its class definition
    # or workstream context on startup — a silent context degradation.
    local hits
    hits=$(grep -rn "@claude/" "$REPO_ROOT/.claude/agents" 2>/dev/null || true)
    if [ -n "$hits" ]; then
        echo "agent registrations still import pre-Rename @claude/ paths:" >&2
        echo "$hits" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Ref-injector security
# ─────────────────────────────────────────────────────────────────────────────

@test "ref-injector: uses exact skill name matching (no substring leakage)" {
    local ref_injector="$REPO_ROOT/agency/hooks/ref-injector.sh"
    [ -f "$ref_injector" ] || skip "ref-injector.sh not found"
    # Should NOT contain wildcard patterns like *quality-gate*
    if grep -q '\*[a-z-]*\*' "$ref_injector"; then
        echo "ref-injector.sh contains substring wildcard patterns — use exact matching" >&2
        grep '\*[a-z-]*\*' "$ref_injector" >&2
        return 1
    fi
}
