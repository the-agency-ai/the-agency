# ─────────────────────────────────────────────────────────────────────
# reset-shim.sh — Captain-session alias shim for v46.0 Phase 1
#
# UNTRACKED, SESSION-SCOPED, CAPTAIN-PRIVATE.
# Plan v4 Principle 12 — defense-in-depth for mid-reset tool-path resolution.
#
# Activation (at Phase 1 entry):
#   cp usr/jordan/captain/reset-baseline-20260419/reset-shim.sh.template \
#      usr/jordan/captain/reset-baseline-20260419/reset-shim.sh
#   source usr/jordan/captain/reset-baseline-20260419/reset-shim.sh
#
# NEVER commit reset-shim.sh (only the .template in Phase 0 baseline dir).
# The shim is removed at Phase 4.5 / Gate 6.
#
# Rationale: between Phase 1 (git mv claude agency) and Phase 4.5
# (@import rewrites), tool invocations that still use `./claude/tools/X`
# paths would ENOENT. This shim aliases them so captain can continue
# executing reset phases without first sweeping every invocation site.
# ─────────────────────────────────────────────────────────────────────

# Guard against double-source
if [[ "${AGENCY_RESET_SHIM_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || exit 0
fi
export AGENCY_RESET_SHIM_LOADED=1

# Claim the sentinel (picked up by hookify.block-git-clean-during-reset)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -n "$REPO_ROOT" && -d "$REPO_ROOT/.git" ]]; then
    touch "$REPO_ROOT/.git/RESET_IN_FLIGHT"
fi

# Function-based shim: `claude-tool X` invokes the post-rename tool.
# We use a function rather than an alias so command-substitution works in
# non-interactive shells (aliases are often disabled in non-interactive bash).
claude-tool() {
    local cmd="$1"; shift
    if [[ -x "$REPO_ROOT/agency/tools/$cmd" ]]; then
        "$REPO_ROOT/agency/tools/$cmd" "$@"
    elif [[ -x "$REPO_ROOT/claude/tools/$cmd" ]]; then
        "$REPO_ROOT/claude/tools/$cmd" "$@"
    else
        echo "[shim] tool not found: $cmd" >&2
        return 127
    fi
}

# Tear-down helper: called at Gate 6.
reset-shim-teardown() {
    unset -f claude-tool
    unset AGENCY_RESET_SHIM_LOADED
    [[ -n "$REPO_ROOT" ]] && rm -f "$REPO_ROOT/.git/RESET_IN_FLIGHT"
    # Caller removes this file (reset-shim.sh) themselves — Plan v4 Phase 4.5 step 4.
}

# Announce activation
echo "[shim] v46.0 reset alias-shim active — use 'claude-tool <name> [args]' for tool invocations during reset"
