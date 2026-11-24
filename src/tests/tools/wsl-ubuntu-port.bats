#!/usr/bin/env bats
#
# Regression tests for the WSL / Ubuntu port.
#
# What Problem: The framework was written on macOS. On Ubuntu LTS (and Ubuntu
# under WSL) it failed in ways the Ubuntu CI placeholder never exercised:
#   - sqlite3 from apt is below the ISCP floor (22.04 ships 3.37, floor 3.38)
#   - `python3` is below the framework floor (22.04: 3.10, 24.04: 3.12)
#   - `agency deps install` was macOS-only and `agency deps` probed the wrong
#     binary names (bats-core, ripgrep) and treated ghostty as required
#   - the only terminal provider was Ghostty, which has no Windows build
# (Platform-neutral bugs found on the way are in cross-platform-fixes.bats.)
#
# How & Why: Each test pins one of those behaviours. Platform is forced with
# AGENCY_PLATFORM_OVERRIDE and PATH stubs so the tests give the same answer on
# macOS, Linux and WSL — nothing here needs network or sudo.
#
# Written: 2026-11-24 for the WSL/Ubuntu port.

load 'test_helper'

LIB="${REPO_ROOT}/agency/tools/lib"

# Build a PATH directory containing only the named real tools plus any stubs
# the test adds — lets a test hide sqlite3/python3.13/etc. deterministically.
_stub_path() {
    local dir="$BATS_TEST_TMPDIR/bin" t p
    mkdir -p "$dir"
    for t in "$@"; do
        p=$(command -v "$t" 2>/dev/null) || continue
        ln -sf "$p" "$dir/$t"
    done
    echo "$dir"
}

# ─────────────────────────────────────────────────────────────────────────────
# lib/_platform
# ─────────────────────────────────────────────────────────────────────────────

@test "_platform: agency_platform honours AGENCY_PLATFORM_OVERRIDE" {
    run bash -c "source '$LIB/_platform'; AGENCY_PLATFORM_OVERRIDE=wsl agency_platform"
    assert_success
    [ "$output" = "wsl" ]
    run bash -c "source '$LIB/_platform'; AGENCY_PLATFORM_OVERRIDE=darwin agency_platform"
    [ "$output" = "darwin" ]
}

@test "_platform: agency_platform returns a known value without override" {
    run bash -c "unset AGENCY_PLATFORM_OVERRIDE; source '$LIB/_platform'; agency_platform"
    assert_success
    [[ "$output" =~ ^(darwin|wsl|linux|unknown)$ ]]
}

@test "_platform: agency_is_wsl follows the override both ways" {
    run bash -c "source '$LIB/_platform'; AGENCY_PLATFORM_OVERRIDE=wsl agency_is_wsl"
    assert_success
    run bash -c "source '$LIB/_platform'; AGENCY_PLATFORM_OVERRIDE=linux agency_is_wsl"
    assert_failure
}

@test "_platform: agency_is_windows_mount is false off WSL" {
    run bash -c "source '$LIB/_platform'; AGENCY_PLATFORM_OVERRIDE=linux agency_is_windows_mount /tmp"
    assert_failure
}

@test "_platform: agency_version_gte compares numerically, not lexically" {
    run bash -c "source '$LIB/_platform'; agency_version_gte 3.37.2 3.38.0"
    assert_failure
    run bash -c "source '$LIB/_platform'; agency_version_gte 3.54.1 3.38.0"
    assert_success
    run bash -c "source '$LIB/_platform'; agency_version_gte 3.9 3.13"
    assert_failure
    run bash -c "source '$LIB/_platform'; agency_version_gte 3.13 3.13"
    assert_success
    run bash -c "source '$LIB/_platform'; agency_version_gte 1.10.0 1.2.1"
    assert_success
    run bash -c "source '$LIB/_platform'; agency_version_gte 3.38 3.38.0"
    assert_success
}

@test "_platform: agency_tool_version extracts the first dotted version" {
    local dir; dir=$(_stub_path)
    printf '#!/bin/sh\necho "Bats 1.14.0"\n' > "$dir/faketool"; chmod +x "$dir/faketool"
    run bash -c "source '$LIB/_platform'; agency_tool_version '$dir/faketool'"
    assert_success
    [ "$output" = "1.14.0" ]
}

@test "_platform: agency_find_python picks python3.13 when python3 is too old" {
    local dir; dir=$(_stub_path)
    printf '#!/bin/sh\necho 3.10\n' > "$dir/python3"
    printf '#!/bin/sh\necho 3.13\n' > "$dir/python3.13"
    chmod +x "$dir/python3" "$dir/python3.13"
    run env PATH="$dir" /bin/bash -c "source '$LIB/_platform'; agency_find_python 3.13"
    assert_success
    [ "$output" = "$dir/python3.13" ]
}

@test "_platform: agency_find_python fails when nothing meets the floor" {
    local dir; dir=$(_stub_path)
    printf '#!/bin/sh\necho 3.10\n' > "$dir/python3"; chmod +x "$dir/python3"
    run env PATH="$dir" /bin/bash -c "source '$LIB/_platform'; agency_find_python 3.13"
    assert_failure
}

# ─────────────────────────────────────────────────────────────────────────────
# Python floor: re-exec under python3.13 instead of failing
# ─────────────────────────────────────────────────────────────────────────────

@test "python floor: sub-3.13 python3 re-execs under python3.13 found on PATH" {
    local sub
    sub=$(command -v python3) || skip "no python3"
    if "$sub" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 13) else 1)'; then
        skip "python3 is already >= 3.13 here; nothing to re-exec from"
    fi
    local dir; dir=$(_stub_path)
    # A stand-in python3.13 that proves it was exec'd with the script + args.
    printf '#!/bin/sh\necho "REEXEC:$*"\n' > "$dir/python3.13"; chmod +x "$dir/python3.13"
    run env PATH="$dir" "$sub" "${REPO_ROOT}/agency/tools/dispatch-monitor" --help
    assert_success
    assert_output_contains "REEXEC:"
    assert_output_contains "dispatch-monitor --help"
}

@test "python floor: AGENCY_PY_NO_REEXEC keeps the guard message" {
    local sub
    sub=$(command -v python3) || skip "no python3"
    if "$sub" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 13) else 1)'; then
        skip "python3 is already >= 3.13 here"
    fi
    run env AGENCY_PY_NO_REEXEC=1 "$sub" "${REPO_ROOT}/agency/tools/dispatch-monitor" --help
    assert_failure
    [[ "$output" == *"Python 3.13+ required"* ]]
}

@test "python floor: guard with no newer interpreter on PATH still fails cleanly" {
    local sub
    sub=$(command -v python3) || skip "no python3"
    if "$sub" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 13) else 1)'; then
        skip "python3 is already >= 3.13 here"
    fi
    local dir; dir=$(_stub_path)
    run env PATH="$dir" "$sub" "${REPO_ROOT}/agency/tools/dispatch-monitor" --help
    assert_failure
    [[ "$output" == *"Python 3.13+ required"* ]]
}

@test "python floor: template and tool carry the same re-exec block" {
    run grep -c "AGENCY_PY_NO_REEXEC" "${REPO_ROOT}/agency/templates/TOOL.py"
    [ "$output" -ge 2 ]
    run grep -c "AGENCY_PY_NO_REEXEC" "${REPO_ROOT}/agency/tools/dispatch-monitor"
    [ "$output" -ge 2 ]
}

@test "python floor: Linux install recipe never repoints /usr/bin/python3" {
    run grep -E '^\s+linux:.*update-alternatives' "${REPO_ROOT}/agency/config/agency-dependencies.yaml"
    assert_failure
}

# ─────────────────────────────────────────────────────────────────────────────
# agency deps on Linux / WSL
# ─────────────────────────────────────────────────────────────────────────────

@test "agency deps: reports the platform it checked" {
    run env AGENCY_PLATFORM_OVERRIDE=wsl "${REPO_ROOT}/agency/tools/agency" deps check required
    [[ "$output" == *"Agency Dependency Check (wsl)"* ]]
}

@test "agency deps: ghostty is skipped, not missing, on Linux" {
    local dir; dir=$(_stub_path bash awk grep sed head cut cat uname dirname git jq curl rsync gh node sqlite3 python3 findmnt df id)
    run env PATH="$dir" AGENCY_PLATFORM_OVERRIDE=linux /bin/bash "${REPO_ROOT}/agency/tools/agency" deps check required
    assert_output_contains "ghostty"
    assert_output_contains "not needed on linux"
    [[ "$output" != *"ghostty              (missing"* ]]
}

@test "agency deps: ghostty still counts as missing on macOS" {
    local dir; dir=$(_stub_path bash awk grep sed head cut cat uname dirname git jq curl rsync gh node sqlite3 python3 id)
    run env PATH="$dir" AGENCY_PLATFORM_OVERRIDE=darwin /bin/bash "${REPO_ROOT}/agency/tools/agency" deps check required
    [[ "$output" == *"ghostty"*"missing"* ]]
}

@test "agency deps: probes real binary names (bats, rg), not package names" {
    local dir; dir=$(_stub_path bash awk grep sed head cut cat uname dirname id findmnt df)
    printf '#!/bin/sh\necho "Bats 1.14.0"\n' > "$dir/bats"
    printf '#!/bin/sh\necho "ripgrep 13.0.0"\n' > "$dir/rg"
    chmod +x "$dir/bats" "$dir/rg"
    run env PATH="$dir" AGENCY_PLATFORM_OVERRIDE=linux /bin/bash "${REPO_ROOT}/agency/tools/agency" deps check testing
    [[ "$output" == *"✓"*"bats-core"*"1.14.0"* ]]
    run env PATH="$dir" AGENCY_PLATFORM_OVERRIDE=linux /bin/bash "${REPO_ROOT}/agency/tools/agency" deps check optional
    [[ "$output" == *"✓"*"ripgrep"*"13.0.0"* ]]
}

@test "agency deps: flags a sqlite3 below the floor instead of passing it" {
    local dir; dir=$(_stub_path bash awk grep sed head cut cat uname dirname git jq curl rsync gh node python3 id findmnt df)
    printf '#!/bin/sh\necho "3.37.2 2022-01-06 13:25:41 872ba256"\n' > "$dir/sqlite3"; chmod +x "$dir/sqlite3"
    run env PATH="$dir" AGENCY_PLATFORM_OVERRIDE=linux /bin/bash "${REPO_ROOT}/agency/tools/agency" deps check required
    assert_failure
    assert_output_contains "3.37.2 is below the 3.38 floor"
    assert_output_contains "agency deps install"
}

@test "agency deps: a python3.13 beside an old python3 satisfies the floor on Linux" {
    local dir; dir=$(_stub_path bash awk grep sed head cut cat uname dirname git jq curl rsync gh node sqlite3 id findmnt df)
    printf '#!/bin/sh\ncase "$1" in -c) echo 3.10;; *) echo "Python 3.10.12";; esac\n' > "$dir/python3"
    printf '#!/bin/sh\ncase "$1" in -c) echo 3.13;; *) echo "Python 3.13.13";; esac\n' > "$dir/python3.13"
    chmod +x "$dir/python3" "$dir/python3.13"
    run env PATH="$dir" AGENCY_PLATFORM_OVERRIDE=linux /bin/bash "${REPO_ROOT}/agency/tools/agency" deps check required
    [[ "$output" == *"✓"*"python3"*"3.13.13"* ]]
    [[ "$output" != *"python3"*"below the"* ]]
}

@test "agency deps: an old python3 alone is reported on Linux" {
    local dir; dir=$(_stub_path bash awk grep sed head cut cat uname dirname git jq curl rsync gh node sqlite3 id findmnt df)
    printf '#!/bin/sh\ncase "$1" in -c) echo 3.10;; *) echo "Python 3.10.12";; esac\n' > "$dir/python3"
    chmod +x "$dir/python3"
    run env PATH="$dir" AGENCY_PLATFORM_OVERRIDE=linux /bin/bash "${REPO_ROOT}/agency/tools/agency" deps check required
    assert_failure
    assert_output_contains "3.10.12 is below the 3.13 floor"
}

@test "agency deps: every required entry declares an apt package or an explicit null" {
    run awk '
        /^required:/ {t=1; next} /^[a-z]/ {t=0}
        t && /^  [A-Za-z0-9_-]+:[ \t]*$/ { if (name != "" && !apt) print name; name=$1; apt=0 }
        t && /^    apt:/ { apt=1 }
        END { if (name != "" && !apt) print name }
    ' "${REPO_ROOT}/agency/config/dependencies.yaml"
    [ -z "$output" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# lib/_linux-floors
# ─────────────────────────────────────────────────────────────────────────────

@test "_linux-floors: linux_ensure_sqlite is a no-op when the floor is met" {
    local dir; dir=$(_stub_path bash awk grep id)
    printf '#!/bin/sh\necho "3.54.1 2026-10-16"\n' > "$dir/sqlite3"; chmod +x "$dir/sqlite3"
    run env PATH="$dir" /bin/bash -c "source '$LIB/_platform'; source '$LIB/_linux-floors'; linux_ensure_sqlite 3.38.0"
    assert_success
    [ -z "$output" ]
}

@test "_linux-floors: sqlite build refuses to run without a compiler and says why" {
    local dir; dir=$(_stub_path bash awk grep id mktemp)
    printf '#!/bin/sh\necho "3.37.2 2022-01-06"\n' > "$dir/sqlite3"; chmod +x "$dir/sqlite3"
    run env PATH="$dir" AGENCY_LOCAL_BIN="$BATS_TEST_TMPDIR/out" /bin/bash -c "source '$LIB/_platform'; source '$LIB/_linux-floors'; linux_ensure_sqlite 3.38.0"
    assert_failure
    assert_output_contains "below the 3.38.0 floor"
    assert_output_contains "build-essential"
    [ ! -e "$BATS_TEST_TMPDIR/out/sqlite3" ]
}

@test "_linux-floors: linux_ensure_python is a no-op when a 3.13 exists" {
    local dir; dir=$(_stub_path bash id)
    printf '#!/bin/sh\necho 3.13\n' > "$dir/python3.13"; chmod +x "$dir/python3.13"
    run env PATH="$dir" /bin/bash -c "source '$LIB/_platform'; source '$LIB/_linux-floors'; linux_ensure_python 3.13"
    assert_success
    [ -z "$output" ]
}

@test "_linux-floors: missing python prints install help that leaves python3 alone" {
    local dir; dir=$(_stub_path bash id cat)
    run env PATH="$dir" /bin/bash -c "source '$LIB/_platform'; source '$LIB/_linux-floors'; linux_ensure_python 3.13"
    assert_failure
    assert_output_contains "Do not repoint /usr/bin/python3"
}

# ─────────────────────────────────────────────────────────────────────────────
# Herdr terminal provider (the Ghostty alternative that runs under WSL)
# ─────────────────────────────────────────────────────────────────────────────

# A stand-in `herdr` that records its arguments instead of talking to a server.
_fake_herdr() {
    local dir="$BATS_TEST_TMPDIR/herdr-bin"
    mkdir -p "$dir"
    cat > "$dir/herdr" <<SH
#!/bin/sh
echo "\$*" >> "$BATS_TEST_TMPDIR/herdr.calls"
case "\$1 \$2" in "integration status") echo "claude: current (v11) (/x)";; esac
exit 0
SH
    chmod +x "$dir/herdr"
    echo "$dir"
}

@test "herdr-status: no-op outside Herdr" {
    local dir; dir=$(_fake_herdr)
    run env -u HERDR_ENV HERDR_PANE_ID=w1:p1 HERDR_BIN_PATH="$dir/herdr" \
        bash -c "echo '{\"hook_event_name\":\"SessionStart\"}' | '${REPO_ROOT}/agency/hooks/herdr-status.sh'"
    assert_success
    [ ! -e "$BATS_TEST_TMPDIR/herdr.calls" ]
}

@test "herdr-status: SessionStart reports display-only identity for the calling pane" {
    local dir; dir=$(_fake_herdr)
    run env HERDR_ENV=1 HERDR_PANE_ID=w9:p3 HERDR_BIN_PATH="$dir/herdr" AGENTNAME=fallback-name \
        bash -c "echo '{\"hook_event_name\":\"SessionStart\"}' | '${REPO_ROOT}/agency/hooks/herdr-status.sh'"
    assert_success
    run cat "$BATS_TEST_TMPDIR/herdr.calls"
    [[ "$output" == "pane report-metadata w9:p3 --source agency --display-agent "*" --title "* ]]
    # Lifecycle state belongs to Herdr's own Claude integration.
    [[ "$output" != *"report-agent"* ]]
}

@test "herdr-status: SessionEnd clears what it set" {
    local dir; dir=$(_fake_herdr)
    run env HERDR_ENV=1 HERDR_PANE_ID=w9:p3 HERDR_BIN_PATH="$dir/herdr" \
        bash -c "echo '{\"hook_event_name\":\"SessionEnd\"}' | '${REPO_ROOT}/agency/hooks/herdr-status.sh'"
    assert_success
    run cat "$BATS_TEST_TMPDIR/herdr.calls"
    [ "$output" = "pane report-metadata w9:p3 --source agency --clear-display-agent --clear-title" ]
}

@test "herdr-status: other events and a missing herdr binary do nothing, exit 0" {
    local dir; dir=$(_fake_herdr)
    run env HERDR_ENV=1 HERDR_PANE_ID=w9:p3 HERDR_BIN_PATH="$dir/herdr" \
        bash -c "echo '{\"hook_event_name\":\"PreToolUse\"}' | '${REPO_ROOT}/agency/hooks/herdr-status.sh'"
    assert_success
    [ ! -e "$BATS_TEST_TMPDIR/herdr.calls" ]
    run env HERDR_ENV=1 HERDR_PANE_ID=w9:p3 HERDR_BIN_PATH=/nonexistent/herdr \
        bash -c "echo '{\"hook_event_name\":\"SessionStart\"}' | '${REPO_ROOT}/agency/hooks/herdr-status.sh'"
    assert_success
}

@test "terminal-setup-herdr: registers the hook once and is idempotent" {
    local proj="$BATS_TEST_TMPDIR/proj" dir; dir=$(_fake_herdr)
    mkdir -p "$proj/.claude" "$proj/agency/hooks"
    cp "${REPO_ROOT}/agency/hooks/herdr-status.sh" "$proj/agency/hooks/"
    cat > "$proj/.claude/settings.json" <<'JSON'
{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"existing-hook"}]}]},"other":true}
JSON
    run env PATH="$dir:$PATH" CLAUDE_PROJECT_DIR="$proj" "${REPO_ROOT}/agency/tools/terminal-setup-herdr"
    assert_success
    assert_output_contains "Registered herdr-status.sh"
    run env PATH="$dir:$PATH" CLAUDE_PROJECT_DIR="$proj" "${REPO_ROOT}/agency/tools/terminal-setup-herdr"
    assert_success
    assert_output_contains "Already registered"
    run grep -c "herdr-status.sh" "$proj/.claude/settings.json"
    [ "$output" -eq 2 ]
    # Existing content survives.
    run jq -r '.other, .hooks.SessionStart[0].hooks[0].command' "$proj/.claude/settings.json"
    [ "${lines[0]}" = "true" ]
    [ "${lines[1]}" = "existing-hook" ]
}

@test "terminal-setup-herdr: --check changes nothing and fails when unregistered" {
    local proj="$BATS_TEST_TMPDIR/proj" dir; dir=$(_fake_herdr)
    mkdir -p "$proj/.claude" "$proj/agency/hooks"
    cp "${REPO_ROOT}/agency/hooks/herdr-status.sh" "$proj/agency/hooks/"
    echo '{"hooks":{}}' > "$proj/.claude/settings.json"
    run env PATH="$dir:$PATH" CLAUDE_PROJECT_DIR="$proj" "${REPO_ROOT}/agency/tools/terminal-setup-herdr" --check
    assert_failure
    run cat "$proj/.claude/settings.json"
    [ "$output" = '{"hooks":{}}' ]
}

@test "terminal-setup: auto-detects herdr from TERM_PROGRAM" {
    run grep -A1 -E '^\s+herdr\)' "${REPO_ROOT}/agency/tools/terminal-setup"
    assert_output_contains "terminal-setup-herdr"
}
