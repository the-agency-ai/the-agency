#!/usr/bin/env bats
#
# pr-captain-land regression guards.
#
# The PR-landing wrapper hardcoded `master` in three live places — the
# receipt-verify diff base (origin/master), the switch-back-to-default-branch
# calls (switch-branch master), and the release target (gh-release --target
# master). In a repo whose default branch is `main` (this one) that fails
# closed: diff-hash resolves nothing so receipt-verify aborts, and the
# switch/release target a branch that does not exist. These guards keep the
# hardcode from returning and confirm the script reuses the shared, unit-tested
# remote/branch helpers instead of re-deriving ORG/REPO/default-branch inline.

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
LAND="${REPO_ROOT}/.claude/skills/pr-captain-land/scripts/pr-captain-land"
PR_SUBMIT="${REPO_ROOT}/.claude/skills/pr-submit/scripts/pr-submit"

# ─────────────────────────────────────────────────────────────────────────────
# Script shape
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land: script exists and is executable" {
    [ -x "$LAND" ]
}

@test "pr-captain-land: script is syntactically valid" {
    bash -n "$LAND"
}

# ─────────────────────────────────────────────────────────────────────────────
# The master hardcode must not come back
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land: no live 'switch-branch master' remains" {
    run grep -n 'switch-branch master' "$LAND"
    [ "$status" -ne 0 ]
}

@test "pr-captain-land: no live 'gh-release --target master' remains" {
    run grep -nE '[-][-]target master([[:space:]]|$|[^-])' "$LAND"
    [ "$status" -ne 0 ]
}

@test "pr-captain-land: no literal origin/master outside comments" {
    run grep -n 'origin/master' "$LAND"
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        text="${line#*:}"
        [[ "$text" =~ ^[[:space:]]*# ]] || {
            echo "live origin/master reference: $line"
            false
        }
    done <<< "$output"
}

# ─────────────────────────────────────────────────────────────────────────────
# Reuses the shared, tested helper lib (single source of truth)
# ─────────────────────────────────────────────────────────────────────────────

@test "pr-captain-land: sources the shared pr-submit helper lib" {
    grep -q 'PR_SUBMIT_LIB_ONLY=1 source' "$LAND"
}

@test "pr-captain-land: uses resolve_default_branch / parse_org / parse_repo" {
    grep -q 'resolve_default_branch' "$LAND"
    grep -q 'parse_org_from_remote' "$LAND"
    grep -q 'parse_repo_from_remote' "$LAND"
}

@test "pr-captain-land: the lib it sources actually defines those functions" {
    run bash -c "PR_SUBMIT_LIB_ONLY=1 source '$PR_SUBMIT' && declare -F resolve_default_branch parse_org_from_remote parse_repo_from_remote redact_remote_url"
    [ "$status" -eq 0 ]
}

@test "pr-captain-land: never echoes a raw remote on the parse-failure path" {
    # The failure branch must print the REDACTED url, never the raw remote —
    # a credential-bearing origin would otherwise leak into terminal/logs.
    run grep -n "cannot parse origin remote URL '\$REMOTE_URL'" "$LAND"
    [ "$status" -ne 0 ]
    grep -q 'redact_remote_url "\$REMOTE_URL"' "$LAND"
}
