#!/usr/bin/env bats
#
# What Problem: agency/hooks/block-raw-tools.sh is the ONLY runtime evaluator
# that actually enforces the fleet's bash-command discipline (block raw git,
# gh, cat, sed/awk, head/tail; conditional grep/find; git-captain gating). It
# fires on every Bash tool call across every captain + worktree agent. Before
# this harness its only coverage was a 6-case ad-hoc smoke script — a regex
# regression here silently blocks (or wrongly frees) the entire fleet.
#
# The 40 hookify .md "rules" in agency/hookify/ are a DSL with NO runtime
# engine (the hookify plugin is disabled in .claude/settings.json). They are
# spec, not enforcement. This harness therefore tests the thing that is REAL:
# block-raw-tools.sh. Each canary encodes an EMPIRICALLY-VERIFIED behavior of
# that hook — not the aspirational .md action. (See #144, Phase 1.)
#
# How & Why: Data-driven. Every *.canary file under canaries/block-raw-tools/
# is parsed for its expected decision + match substring + optional PATH mode,
# cwd mode, and env; its BODY is wrapped as a PreToolUse JSON payload, piped
# through the hook, and the decision (block exit 2 + reason substring, or allow
# exit 0 + exact "{}") is asserted. Drop a new .canary file → it is covered.
# The grep/find auto-detect arms are exercised via PATH stubs (ugrep/bfs present
# vs absent). The git-captain authorization gate is exercised via cwd:isolated
# (the hook resolves ./agency/tools/agent-identity relative to cwd; from an
# isolated dir it can't, so identity != captain and the captain-only gate fires).
#
# Canary schema (frontmatter keys, then a `---BODY---` line, then the command):
#   rule:              informational label (which discipline this exercises)
#   expected_decision: block | allow          (required)
#   expected_match:    substring of the block reason (required when block)
#   path_mode:         default | stubbed | bare (optional; default 'default')
#                        stubbed → ugrep+bfs on PATH (auto-detect arm fires)
#                        bare    → PATH without ugrep/bfs (arm falls through).
#                                  If the hook would STILL reach ugrep/bfs via
#                                  its force-prepended /opt/homebrew/bin (line
#                                  34), the canary is SKIPPED, never failed —
#                                  the determinism precondition can't hold on a
#                                  box with brew-installed ugrep/bfs.
#   cwd:               repo | isolated (optional; default 'repo')
#                        isolated → run the hook from a fresh temp dir so its
#                                   relative ./agency/tools/* calls don't resolve
#   env:               extra NAME=VALUE for the hook process (optional)
#
# KNOWN LIMITATIONS of the hook this suite documents (not defects in the tests):
#   - Leading-token matching only: `foo && cat bar` is NOT blocked (TRIMMED
#     still starts with `foo`). Distinct from the disconnected compound-bash
#     .md rule. Deliberately NOT canaried as allow (that would bless it).
#   - The `warn` decision tier is not producible by this hook (it only emits
#     block or {}). A warn tier is #144 Phase 2 and will need a schema arm.
#
# Written: 2026-08-14 captain session (#144 Phase 1 — hookify canary harness).

# REPO_ROOT: this file lives at src/tests/hookify/ — same depth as
# src/tests/tools/, so the helper's formula (dirname of test dir, up two)
# resolves the repo root identically. Computed inline to avoid coupling the
# hook test to the git-isolation helper (this test never touches git state).
# See src/tests/hookify/README.md for the suite convention rationale.
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
HOOK="${REPO_ROOT}/agency/hooks/block-raw-tools.sh"
CANARY_DIR="${BATS_TEST_DIRNAME}/canaries/block-raw-tools"

setup() {
    [ -x "$HOOK" ] || {
        echo "FATAL: hook not executable: $HOOK" >&2
        return 1
    }
    command -v jq >/dev/null 2>&1 || {
        echo "FATAL: jq required (the hook itself requires jq)" >&2
        return 1
    }
    # STUB dir carries fake ugrep/bfs so the grep/find auto-detect arms fire.
    # command -v only checks existence + exec bit — the stubs never run.
    STUB="$(mktemp -d)"
    for t in ugrep bfs; do
        printf '#!/bin/sh\nexit 0\n' >"$STUB/$t"
        chmod +x "$STUB/$t"
    done
}

teardown() {
    [ -n "${STUB:-}" ] && rm -rf "$STUB"
}

# _trim <string> — strip leading AND trailing whitespace from a scalar value.
_trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"   # leading
    s="${s%"${s##*[![:space:]]}"}"   # trailing
    printf '%s' "$s"
}

# _parse_canary <file> — sets CANARY_RULE/DECISION/MATCH/PATHMODE/CWD/ENV/BODY.
_parse_canary() {
    local file="$1" line in_body=0 body_started=0
    CANARY_RULE=""; CANARY_DECISION=""; CANARY_MATCH=""
    CANARY_PATHMODE="default"; CANARY_CWD="repo"; CANARY_ENV=""; CANARY_BODY=""
    while IFS= read -r line || [ -n "$line" ]; do
        if [ "$in_body" -eq 1 ]; then
            # body_started (not emptiness) distinguishes "no body line yet"
            # from "a body line that is itself blank" — else a leading blank
            # line in the body is silently dropped.
            if [ "$body_started" -eq 0 ]; then
                CANARY_BODY="$line"; body_started=1
            else
                CANARY_BODY="${CANARY_BODY}"$'\n'"${line}"
            fi
            continue
        fi
        case "$line" in
            '---BODY---')          in_body=1 ;;
            rule:*)                CANARY_RULE="$(_trim "${line#rule:}")" ;;
            expected_decision:*)   CANARY_DECISION="$(_trim "${line#expected_decision:}")" ;;
            expected_match:*)      CANARY_MATCH="$(_trim "${line#expected_match:}")" ;;
            path_mode:*)           CANARY_PATHMODE="$(_trim "${line#path_mode:}")" ;;
            cwd:*)                 CANARY_CWD="$(_trim "${line#cwd:}")" ;;
            env:*)                 CANARY_ENV="$(_trim "${line#env:}")" ;;
        esac
    done <"$file"
    # Strip ALL trailing newlines from the body (a canary may end with one or
    # more blank lines; none of them belong to the command string).
    while [ -n "$CANARY_BODY" ] && [ "${CANARY_BODY: -1}" = $'\n' ]; do
        CANARY_BODY="${CANARY_BODY%$'\n'}"
    done
}

# _bare_tool_present <body> — true if the hook, under a bare PATH, would STILL
# reach the embedded tool (ugrep for grep-family, bfs for find) via its
# force-prepended /opt/homebrew/bin. Used to skip bare-mode allow canaries on
# boxes where the determinism precondition cannot hold.
_bare_tool_present() {
    local body="$1" tool="" probe="/usr/bin:/bin"
    case "$body" in
        find*)                     tool="bfs" ;;
        grep*|rg*|egrep*|fgrep*)   tool="ugrep" ;;
        *)                         return 1 ;;
    esac
    [ -d /opt/homebrew/bin ] && probe="/opt/homebrew/bin:$probe"
    PATH="$probe" command -v "$tool" >/dev/null 2>&1
}

# _run_hook — feeds CANARY_BODY through the hook under the canary's PATH/cwd/env,
# setting HOOK_OUT + HOOK_EXIT. Returns non-zero only on an internal error
# (unknown path_mode/cwd) — callers MUST check the return before trusting
# HOOK_OUT/HOOK_EXIT, else stale values from a prior canary leak through.
_run_hook() {
    HOOK_OUT=""; HOOK_EXIT=""
    local json path_use="" run_dir="$REPO_ROOT"
    json="$(jq -cn --arg c "$CANARY_BODY" '{tool_input:{command:$c}}')"
    case "$CANARY_PATHMODE" in
        stubbed)    path_use="$STUB:/usr/bin:/bin" ;;
        bare)       path_use="/usr/bin:/bin" ;;
        default|"") path_use="" ;;
        *) echo "unknown path_mode: $CANARY_PATHMODE" >&2; return 2 ;;
    esac
    case "$CANARY_CWD" in
        repo|"")  run_dir="$REPO_ROOT" ;;
        isolated) run_dir="$(mktemp -d)" ;;
        *) echo "unknown cwd: $CANARY_CWD" >&2; return 2 ;;
    esac
    local -a envargs=()
    [ -n "$path_use" ] && envargs+=("PATH=$path_use")
    [ -n "$CANARY_ENV" ] && envargs+=("$CANARY_ENV")
    if [ "${#envargs[@]}" -gt 0 ]; then
        HOOK_OUT="$(cd "$run_dir" && printf '%s' "$json" | env "${envargs[@]}" "$HOOK" 2>&1)"
    else
        HOOK_OUT="$(cd "$run_dir" && printf '%s' "$json" | "$HOOK" 2>&1)"
    fi
    HOOK_EXIT=$?
    [ "$CANARY_CWD" = "isolated" ] && rm -rf "$run_dir"
    return 0
}

# _assert_canary <file> — returns 0 pass, 1 fail/malformed (appends to REPORT),
# 3 skip (bare-mode precondition unmet on this box).
_assert_canary() {
    local file="$1" name; name="$(basename "$file")"
    _parse_canary "$file"

    # --- Well-formedness validation (guards the fixtures themselves) ---
    if [ -z "$CANARY_DECISION" ]; then
        REPORT+="  MALFORMED  $name — missing expected_decision"$'\n'; return 1
    fi
    case "$CANARY_DECISION" in
        block|allow) ;;
        *) REPORT+="  MALFORMED  $name — unknown expected_decision '$CANARY_DECISION'"$'\n'; return 1 ;;
    esac
    if [ "$CANARY_DECISION" = "block" ] && [ -z "$CANARY_MATCH" ]; then
        REPORT+="  MALFORMED  $name — block canary missing expected_match"$'\n'; return 1
    fi
    if [ -z "$CANARY_BODY" ]; then
        REPORT+="  MALFORMED  $name — empty BODY"$'\n'; return 1
    fi
    case "$CANARY_PATHMODE" in
        default|stubbed|bare) ;;
        *) REPORT+="  MALFORMED  $name — unknown path_mode '$CANARY_PATHMODE'"$'\n'; return 1 ;;
    esac
    case "$CANARY_CWD" in
        repo|isolated) ;;
        *) REPORT+="  MALFORMED  $name — unknown cwd '$CANARY_CWD'"$'\n'; return 1 ;;
    esac
    if [ -n "$CANARY_ENV" ]; then
        case "$CANARY_ENV" in
            -*)  REPORT+="  MALFORMED  $name — env must be NAME=VALUE, got option-like '$CANARY_ENV'"$'\n'; return 1 ;;
            *=*) : ;;
            *)   REPORT+="  MALFORMED  $name — env must be NAME=VALUE, got '$CANARY_ENV'"$'\n'; return 1 ;;
        esac
    fi

    # --- Determinism guard: skip bare-mode allow canaries when the box has
    #     the embedded tool the hook would still find (see _bare_tool_present). ---
    if [ "$CANARY_PATHMODE" = "bare" ] && _bare_tool_present "$CANARY_BODY"; then
        return 3
    fi

    if ! _run_hook; then
        REPORT+="  MALFORMED  $name — _run_hook internal error (see stderr)"$'\n'; return 1
    fi

    case "$CANARY_DECISION" in
        block)
            if [ "$HOOK_EXIT" -ne 2 ]; then
                REPORT+="  FAIL  $name — want exit 2, got $HOOK_EXIT (out: $HOOK_OUT)"$'\n'; return 1
            fi
            if [[ "$HOOK_OUT" != *'"decision":"block"'* ]]; then
                REPORT+="  FAIL  $name — want decision:block, got: $HOOK_OUT"$'\n'; return 1
            fi
            if [[ "$HOOK_OUT" != *"$CANARY_MATCH"* ]]; then
                REPORT+="  FAIL  $name — reason missing '$CANARY_MATCH' (out: $HOOK_OUT)"$'\n'; return 1
            fi
            ;;
        allow)
            if [ "$HOOK_EXIT" -ne 0 ]; then
                REPORT+="  FAIL  $name — want exit 0, got $HOOK_EXIT (out: $HOOK_OUT)"$'\n'; return 1
            fi
            if [ "$HOOK_OUT" != "{}" ]; then
                REPORT+="  FAIL  $name — want exact '{}', got: $HOOK_OUT"$'\n'; return 1
            fi
            ;;
    esac
    return 0
}

@test "canary directory exists and is non-empty" {
    [ -d "$CANARY_DIR" ]
    local files=("$CANARY_DIR"/*.canary)
    [ -e "${files[0]}" ] || {
        echo "no .canary files in $CANARY_DIR"
        return 1
    }
}

@test "every block-raw-tools canary matches the live hook" {
    REPORT=""
    local pass=0 fail=0 skip=0 f rc
    for f in "$CANARY_DIR"/*.canary; do
        [ -e "$f" ] || continue
        _assert_canary "$f"; rc=$?
        case "$rc" in
            0) pass=$((pass + 1)) ;;
            3) skip=$((skip + 1)); REPORT+="  SKIP  $(basename "$f") — bare-mode precondition (ugrep/bfs installed on this box)"$'\n' ;;
            *) fail=$((fail + 1)) ;;
        esac
    done
    if [ "$fail" -gt 0 ]; then
        echo "block-raw-tools canary failures ($fail failed, $pass passed, $skip skipped):"
        printf '%s' "$REPORT"
        return 1
    fi
    echo "all $pass block-raw-tools canaries passed ($skip skipped)"
    [ "$skip" -gt 0 ] && printf '%s' "$REPORT"
    return 0
}

# --- Meta-tests: the harness's own well-formedness validation must reject
#     malformed fixtures. These write fixtures OUTSIDE the canary glob so they
#     never enter the data-driven suite above. ---

@test "harness rejects a canary missing expected_decision" {
    REPORT=""
    local f="${BATS_TEST_TMPDIR}/no-decision.canary" rc
    printf 'rule: x\n---BODY---\ncat f\n' >"$f"
    _assert_canary "$f" && rc=0 || rc=$?
    [ "$rc" -eq 1 ]
    [[ "$REPORT" == *"missing expected_decision"* ]]
}

@test "harness rejects a block canary missing expected_match" {
    REPORT=""
    local f="${BATS_TEST_TMPDIR}/no-match.canary"
    printf 'expected_decision: block\n---BODY---\ncat f\n' >"$f"
    _assert_canary "$f" || true
    [[ "$REPORT" == *"missing expected_match"* ]]
}

@test "harness rejects a canary with an empty BODY" {
    REPORT=""
    local f="${BATS_TEST_TMPDIR}/empty-body.canary"
    printf 'expected_decision: allow\n---BODY---\n' >"$f"
    _assert_canary "$f" || true
    [[ "$REPORT" == *"empty BODY"* ]]
}

@test "harness rejects an unknown expected_decision" {
    REPORT=""
    local f="${BATS_TEST_TMPDIR}/bad-decision.canary"
    printf 'expected_decision: warn\nexpected_match: x\n---BODY---\ncat f\n' >"$f"
    _assert_canary "$f" || true
    [[ "$REPORT" == *"unknown expected_decision"* ]]
}

@test "harness rejects an unknown path_mode" {
    REPORT=""
    local f="${BATS_TEST_TMPDIR}/bad-pathmode.canary"
    printf 'expected_decision: allow\npath_mode: bogus\n---BODY---\nls\n' >"$f"
    _assert_canary "$f" || true
    [[ "$REPORT" == *"unknown path_mode"* ]]
}

@test "harness rejects an option-like env value" {
    REPORT=""
    local f="${BATS_TEST_TMPDIR}/bad-env.canary"
    printf 'expected_decision: allow\nenv: -S evil\n---BODY---\nls\n' >"$f"
    _assert_canary "$f" || true
    [[ "$REPORT" == *"env must be NAME=VALUE"* ]]
}

@test "parser preserves a leading blank line in a multi-line body" {
    _parse_canary <(printf 'expected_decision: allow\n---BODY---\n\necho foo\n')
    [ "$CANARY_BODY" = $'\necho foo' ]
}

@test "parser tolerates extra whitespace after the colon" {
    _parse_canary <(printf 'expected_decision:   block\nexpected_match:   x\n---BODY---\ncat f\n')
    [ "$CANARY_DECISION" = "block" ]
    [ "$CANARY_MATCH" = "x" ]
}
