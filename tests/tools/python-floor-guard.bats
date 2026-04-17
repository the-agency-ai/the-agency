#!/usr/bin/env bats
#
# What Problem: The D45-R1 Python 3.13 floor migration replaced the
# `#!/usr/bin/env python3.12` shebang with `#!/usr/bin/env python3` plus a
# runtime `sys.version_info < (3, 13)` guard. Without a test, a regression
# (wrong tuple, wrong message, or accidental removal of the guard) would
# ship silently — the exact class of failure the guard exists to prevent.
#
# How & Why: Invoke claude/tools/dispatch-monitor under `/usr/bin/python3`
# (Apple stock Python on macOS, always < 3.13 on supported macOS versions).
# Assert the tool exits non-zero with the expected guard message. Also
# assert that invoking under a 3.13+ interpreter does NOT emit the guard
# message — i.e., the guard only fires on sub-floor interpreters.
#
# Portability: This test is pinned to macOS / Apple-stock-Python hosts
# where `/usr/bin/python3` is guaranteed pre-3.13. On Linux / CI hosts
# where `/usr/bin/python3` may already be 3.13+, the below-floor assertion
# is skipped.
#
# Written: 2026-04-18 D45-R1 — Python 3.13 floor migration

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    SCRIPT="${REPO_ROOT:-$(pwd)}/claude/tools/dispatch-monitor"
}

teardown() {
    rm -rf "$BATS_TEST_TMPDIR"
}

@test "runtime-guard: sub-3.13 interpreter emits guard message and exits non-zero" {
    # Pick a sub-3.13 python binary. Apple stock /usr/bin/python3 is 3.9 on
    # macOS 14. If neither is available as pre-3.13, skip.
    if [ -x /usr/bin/python3 ]; then
        SUB_PY=/usr/bin/python3
        SUB_VERSION=$(/usr/bin/python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')
        MAJOR=${SUB_VERSION%.*}
        MINOR=${SUB_VERSION#*.}
        if [ "$MAJOR" -ge 3 ] && [ "$MINOR" -ge 13 ]; then
            skip "system /usr/bin/python3 is >= 3.13 on this host ($SUB_VERSION); cannot exercise sub-floor path"
        fi
    else
        skip "/usr/bin/python3 not available on this host"
    fi

    run "$SUB_PY" "$SCRIPT" --help
    [ "$status" -ne 0 ]
    [[ "$output" == *"Python 3.13+ required"* ]]
    [[ "$output" == *"See claude/config/dependencies.yaml"* ]]
}

@test "runtime-guard: 3.13+ interpreter does NOT emit guard message" {
    # Pick a 3.13+ python binary. Prefer brew's explicit /opt/homebrew/bin/python3.13,
    # fall back to `python3` on PATH if it's 3.13+.
    if [ -x /opt/homebrew/bin/python3.13 ]; then
        PY=/opt/homebrew/bin/python3.13
    elif command -v python3 >/dev/null 2>&1; then
        VERSION=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')
        MAJOR=${VERSION%.*}
        MINOR=${VERSION#*.}
        if [ "$MAJOR" -ge 3 ] && [ "$MINOR" -ge 13 ]; then
            PY=$(command -v python3)
        else
            skip "no python3.13+ interpreter available (python3 is $VERSION)"
        fi
    else
        skip "no python3 available on this host"
    fi

    run "$PY" "$SCRIPT" --help
    # --help succeeds (exit 0), and crucially the guard message is absent
    [ "$status" -eq 0 ]
    [[ "$output" != *"Python 3.13+ required"* ]]
}

@test "runtime-guard: source of truth is claude/tools/dispatch-monitor" {
    # Sanity: the shebang is python3 (not python3.13, not python3.12), and the
    # guard tuple is (3, 13). A regression that flips either flag would be
    # caught here before merge.
    FIRST_LINE=$(head -n 1 "$SCRIPT")
    [ "$FIRST_LINE" = "#!/usr/bin/env python3" ]

    run grep -c "sys.version_info < (3, 13)" "$SCRIPT"
    [ "$output" -eq 1 ]
}

@test "runtime-guard: template TOOL.py matches convention" {
    # Every new framework tool is scaffolded from TOOL.py. If the template
    # drifts, new tools will silently miss the floor.
    TPL="${REPO_ROOT:-$(pwd)}/claude/templates/TOOL.py"
    FIRST_LINE=$(head -n 1 "$TPL")
    [ "$FIRST_LINE" = "#!/usr/bin/env python3" ]

    run grep -c "sys.version_info < (3, 13)" "$TPL"
    [ "$output" -eq 1 ]
}
