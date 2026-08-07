#!/bin/bash
# What Problem: agency/hooks/block-raw-tools.sh is a fleet-wide PreToolUse
# hook that fires on every Bash invocation. Regressions in this file silently
# block (or wrongly allow) commands across every captain + worktree agent.
# Manual ad-hoc testing was the only verification before this file existed.
#
# How & Why: Minimal smoke harness. Pipes 6 fixture JSON payloads to the
# hook (mocked PATH for ugrep/bfs presence/absence), asserts exit code +
# substring of stdout. No bats, no fixtures dir, no mock framework — `PATH`
# manipulation IS the mock. Designed to grow as the hook grows; keep
# additions in the same key/value style.
#
# Usage:
#   ./agency/hooks/__tests__/block-raw-tools.test.sh
# Exits 0 if all pass, 1 on first failure. Prints PASS/FAIL per case.
#
# Wire into iteration boundaries touching this hook: run from the iteration
# QG or pre-commit when block-raw-tools.sh is in the diff.
#
# Written: 2026-05-17 monofolk v4.70 (Iteration 4.70.1) per reviewer-test
# recommendation from /quality-gate run on the ugrep/bfs auto-detect change.

set -uo pipefail  # NOT -e — we want to keep running after a failed assertion

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/block-raw-tools.sh"
if [[ ! -x "$HOOK" ]]; then
    echo "FATAL: hook not found or not executable: $HOOK" >&2
    exit 1
fi

PASS=0
FAIL=0
FAILURES=()

# assert_hook <name> <expected_exit> <expected_substring> <stdin_json> [PATH_OVERRIDE]
# expected_substring of "{}" means "exactly {}" (allow). Otherwise it's a substring match.
assert_hook() {
    local name="$1"
    local want_exit="$2"
    local want_substr="$3"
    local stdin_json="$4"
    local path_override="${5:-}"

    local actual_stdout
    local actual_exit
    if [[ -n "$path_override" ]]; then
        actual_stdout=$(echo "$stdin_json" | PATH="$path_override" "$HOOK" 2>&1)
    else
        actual_stdout=$(echo "$stdin_json" | "$HOOK" 2>&1)
    fi
    actual_exit=$?

    local ok=1
    if [[ "$actual_exit" != "$want_exit" ]]; then
        ok=0
    fi
    if [[ "$want_substr" == "{}" ]]; then
        # allow case: stdout must be exactly "{}"
        if [[ "$actual_stdout" != "{}" ]]; then
            ok=0
        fi
    else
        if [[ "$actual_stdout" != *"$want_substr"* ]]; then
            ok=0
        fi
    fi

    if [[ "$ok" == "1" ]]; then
        PASS=$((PASS + 1))
        echo "  PASS  $name"
    else
        FAIL=$((FAIL + 1))
        FAILURES+=("$name (want_exit=$want_exit want_substr='$want_substr' got_exit=$actual_exit got_stdout='$actual_stdout')")
        echo "  FAIL  $name"
    fi
}

# Build PATH stubs for the ugrep-reachable / bfs-reachable cases. Tempdir
# + tiny executable scripts is portable (avoids /bin/true vs /usr/bin/true
# path differences across macOS versions and Linux distros). The stub
# binaries do nothing — `command -v` only checks existence + exec bit,
# never runs them.
STUB=$(mktemp -d)
EMPTY_PATH=$(mktemp -d)
trap 'rm -rf "$STUB" "$EMPTY_PATH"' EXIT
for tool in ugrep bfs; do
    printf '#!/bin/sh\nexit 0\n' > "$STUB/$tool"
    chmod +x "$STUB/$tool"
done
STUBBED_PATH="$STUB:/usr/bin:/bin"

# A PATH that DEFINITELY lacks ugrep/bfs (the system default on this box
# does too, but be explicit so the test is reproducible across machines).
# Hook prepends /opt/homebrew/bin if present — that dir does not contain
# ugrep/bfs on our reference machines, but if it does on yours, the
# "NOT reachable" cases will fail. That's working as intended.
BARE_PATH="$EMPTY_PATH:/usr/bin:/bin"

echo "Running block-raw-tools.sh smoke tests…"
echo ""

# --- Auto-detect arms (the new behavior in v4.70) ---

assert_hook "grep blocked when ugrep reachable" \
    2 "ugrep" \
    '{"tool_input":{"command":"grep foo bar.txt"}}' \
    "$STUBBED_PATH"

assert_hook "grep allowed when ugrep NOT reachable" \
    0 "{}" \
    '{"tool_input":{"command":"grep foo bar.txt"}}' \
    "$BARE_PATH"

assert_hook "find blocked when bfs reachable" \
    2 "bfs" \
    '{"tool_input":{"command":"find . -name foo"}}' \
    "$STUBBED_PATH"

assert_hook "find allowed when bfs NOT reachable" \
    0 "{}" \
    '{"tool_input":{"command":"find . -name foo"}}' \
    "$BARE_PATH"

# --- Regression-coverage: unchanged blocks still fire ---

assert_hook "cat still blocked (Read tool exists)" \
    2 "Read tool" \
    '{"tool_input":{"command":"cat README.md"}}'

# --- AGENCY_ALLOW_RAW opt-out still wins ---

# Subshell to scope the env override
opt_out_stdout=$(echo '{"tool_input":{"command":"grep foo bar.txt"}}' | AGENCY_ALLOW_RAW=1 "$HOOK" 2>&1)
opt_out_exit=$?
if [[ "$opt_out_exit" == "0" && "$opt_out_stdout" == "{}" ]]; then
    PASS=$((PASS + 1))
    echo "  PASS  AGENCY_ALLOW_RAW=1 opt-out wins (grep allowed)"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("AGENCY_ALLOW_RAW=1 opt-out (got_exit=$opt_out_exit got_stdout='$opt_out_stdout')")
    echo "  FAIL  AGENCY_ALLOW_RAW=1 opt-out wins (grep allowed)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
    echo ""
    echo "Failures:"
    for f in "${FAILURES[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
exit 0
