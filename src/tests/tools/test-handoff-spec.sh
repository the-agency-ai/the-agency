#!/usr/bin/env bash
# test-handoff-spec.sh — conformance tests for claude/REFERENCE-HANDOFF-SPEC.md
#
# Asserts that:
#   1. Handoffs emitted by the framework (session-pause output + current
#      live handoffs) carry the required frontmatter fields per spec.
#   2. The mode: enum values in live handoffs are one of:
#        continuation | resumption | resume (legacy)
#      Writers MUST emit only continuation|resumption; readers SHOULD
#      tolerate legacy resume (normalization lands in Iteration 5.2).
#   3. session-pickup accepts all three mode values — legacy=resume
#      maps to handoff_mode=legacy, the rest pass through.
#
# Session-lifecycle-refactor Plan v3 Iteration 4.2. Spec:
# claude/REFERENCE-HANDOFF-SPEC.md
#
# Usage: ./claude/tools/tests/test-handoff-spec.sh
#   Exit 0 on all-pass; non-zero on any fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

PICKUP="$REPO_ROOT/claude/tools/session-pickup"
PAUSE="$REPO_ROOT/claude/tools/session-pause"

pass_count=0
fail_count=0
fail_messages=()

_pass() {
    pass_count=$((pass_count + 1))
    echo "  ok  $1"
}

_fail() {
    fail_count=$((fail_count + 1))
    fail_messages+=("$1")
    echo "  FAIL  $1"
}

# ── Part 1: Required fields in live handoffs ─────────────────────────────
echo "Part 1: Required frontmatter fields in live handoffs"

REQUIRED_FIELDS=(type agent date trigger)
# mode is required since D45 but older archived handoffs predate that —
# we check it separately with migration tolerance.
#
# Required-field assertions apply ONLY to `type: session` handoffs. Other
# handoff types (agency-bootstrap, agency-update) have different contracts
# per the handoff tool's --type flag.

# Glob live handoffs (not history archives)
while IFS= read -r handoff; do
    [[ -f "$handoff" ]] || continue
    name="${handoff#$REPO_ROOT/}"

    # Extract frontmatter (between first two `---` delimiters)
    fm=$(awk '
        BEGIN{count=0; in_fm=0}
        /^---[[:space:]]*$/{count++; if(count==1){in_fm=1; next} else if(count==2){exit}}
        in_fm{print}
    ' "$handoff")

    if [[ -z "$fm" ]]; then
        _fail "${name}: no frontmatter found (missing `---` delimiters)"
        continue
    fi

    # Scope required-field check to type: session handoffs. Other types
    # (agency-bootstrap, agency-update) have distinct contracts.
    type_value=$(echo "$fm" | awk '/^type:/{sub(/^type:[[:space:]]*/, ""); sub(/[[:space:]]+$/, ""); print; exit}')
    if [[ "$type_value" != "session" ]]; then
        _pass "${name}: type=${type_value:-<none>} (non-session; required-field check scoped to session handoffs)"
        continue
    fi

    missing=()
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! echo "$fm" | grep -qE "^${field}:"; then
            missing+=("$field")
        fi
    done
    if (( ${#missing[@]} > 0 )); then
        _fail "${name}: missing required fields: ${missing[*]}"
    else
        _pass "${name}: required fields present"
    fi
done < <(find "$REPO_ROOT/usr" -maxdepth 4 -name "*-handoff.md" -type f 2>/dev/null | grep -v "/history/")

# ── Part 2: mode: enum tolerance in live handoffs ────────────────────────
echo
echo "Part 2: mode: enum values (continuation|resumption|legacy-resume)"

while IFS= read -r handoff; do
    [[ -f "$handoff" ]] || continue
    name="${handoff#$REPO_ROOT/}"

    fm=$(awk '
        BEGIN{count=0; in_fm=0}
        /^---[[:space:]]*$/{count++; if(count==1){in_fm=1; next} else if(count==2){exit}}
        in_fm{print}
    ' "$handoff")

    mode_raw=$(echo "$fm" | awk '/^mode:/{sub(/^mode:[[:space:]]*/, ""); sub(/[[:space:]]+$/, ""); sub(/[[:space:]]+#.*$/, ""); print; exit}')

    # Strip free-form suffix (per spec §mode Migration): extract leading keyword
    mode_keyword=$(echo "$mode_raw" | awk '{print $1}')

    case "$mode_keyword" in
        continuation|resumption)
            _pass "${name}: mode=${mode_keyword} (current spec)"
            ;;
        resume)
            _pass "${name}: mode=resume (legacy; tolerated per spec §Migration — Iteration 5.2 normalizes)"
            ;;
        "")
            _pass "${name}: mode absent (legacy; readers treat as resumption per spec)"
            ;;
        *)
            _fail "${name}: mode='${mode_raw}' is not in the enum {continuation, resumption, resume}"
            ;;
    esac
done < <(find "$REPO_ROOT/usr" -maxdepth 4 -name "*-handoff.md" -type f 2>/dev/null | grep -v "/history/")

# ── Part 3: session-pickup legacy-tolerance contract ────────────────────
echo
echo "Part 3: session-pickup reads all three mode values correctly"

SANDBOX="$(mktemp -d -t handoff-spec-XXXXXX)"
trap 'rm -rf "$SANDBOX"' EXIT

mkdir -p "$SANDBOX/usr/testp/testa"
cd "$SANDBOX"
git init -q
git config user.email test@example.com
git config user.name "Test"
git config commit.gpgsign false
cat > .gitignore <<'EOF'
claude/data/
.claude/logs/
claude/logs/*
!claude/logs/reviews/
EOF
touch usr/testp/testa/testa-handoff.md
git add .gitignore usr/testp/testa/testa-handoff.md
git commit -qm "sandbox init"

export CLAUDE_PROJECT_DIR="$SANDBOX"
export AGENCY_PROJECT_ROOT="$SANDBOX"
export ISCP_DB_PATH="$SANDBOX/test-iscp.db"

_write_handoff_and_check_mode() {
    local write_mode="$1" expected_out="$2"
    cat > "$SANDBOX/usr/testp/testa/testa-handoff.md" <<EOF
---
type: session
agent: test-repo/testp/testa
date: 2026-04-20 14:00
trigger: conformance-test
mode: ${write_mode}
next-action: test
---
body
EOF
    git add usr/testp/testa/testa-handoff.md
    git commit -qm "mode=${write_mode}" 2>/dev/null || true

    out=$("$PICKUP" --from compact --principal testp --agent testa 2>&1 || true)
    actual=$(echo "$out" | awk -F= '/^handoff_mode=/{print $2; exit}')

    if [[ "$actual" == "$expected_out" ]]; then
        _pass "mode:${write_mode} in handoff → handoff_mode=${actual}"
    else
        _fail "mode:${write_mode} in handoff: expected handoff_mode=${expected_out}, got ${actual}"
    fi
}

_write_handoff_and_check_mode continuation continuation
_write_handoff_and_check_mode resumption resumption
_write_handoff_and_check_mode resume legacy

# Missing mode field — should produce unknown per pickup impl (spec says
# readers "SHOULD treat as resumption"; pickup reports it as unknown and
# leaves the decision to the caller skill, which is spec-compliant).
cat > "$SANDBOX/usr/testp/testa/testa-handoff.md" <<EOF
---
type: session
agent: test-repo/testp/testa
date: 2026-04-20 14:00
trigger: no-mode-field
next-action: test
---
body
EOF
git add usr/testp/testa/testa-handoff.md
git commit -qm "no mode field" 2>/dev/null || true

out=$("$PICKUP" --from compact --principal testp --agent testa 2>&1 || true)
actual=$(echo "$out" | awk -F= '/^handoff_mode=/{print $2; exit}')
if [[ "$actual" == "unknown" ]]; then
    _pass "missing mode: field → handoff_mode=unknown (spec-compliant; caller decides)"
else
    _fail "missing mode: field: expected handoff_mode=unknown, got ${actual}"
fi

# ── Part 4: session-pause output contract shape ─────────────────────────
echo
echo "Part 4: session-pause output contract shape (§3.1)"

out=$("$PAUSE" --framing continuation --trigger conformance-pause --principal testp --agent testa 2>&1 || true)
for key in schema_version tool_version handoff_path archived_previous_handoff commit_sha handoff_commit_sha framing status; do
    if echo "$out" | grep -qE "^${key}="; then
        _pass "session-pause emits ${key}"
    else
        _fail "session-pause missing output key: ${key}"
    fi
done

# Revert the sandbox cd so the trap cleanup works correctly
cd "$REPO_ROOT"

# ── Summary ──────────────────────────────────────────────────────────────
echo
echo "─────────────────────────────────────"
echo "Conformance: ${pass_count} pass, ${fail_count} fail"
if (( fail_count > 0 )); then
    echo
    echo "Failures:"
    for msg in "${fail_messages[@]}"; do
        echo "  - ${msg}"
    done
    exit 1
fi
exit 0
