#!/usr/bin/env bats
#
# Tests for post-merge-state — C#372 Fix B pending-post-merge tracker.
#
# What Problem: 2026-04-21 incident (issue #372) — 8 PRs merged to main
# without release tags. Fix A (pr-merge advisory nag) is advisory; captain
# can still forget. Fix B (this tool) is structural: state file blocks
# new-work captain skills until post-merge runs.
#
# What we test:
# - set/clear/check/get happy paths
# - check returns exit 1 when pending (signal, not error)
# - clear is idempotent
# - clear refuses wrong PR number (safety)
# - bad args rejected (exit 2)
# - state file format (JSON schema)
#
# Written: 2026-04-21 during C#372 Fix B.
#

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    # The tool uses an absolute path derived from SCRIPT_DIR, so we install
    # the tool + required libs into the BATS tmpdir and run it from there.
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p agency/tools/lib agency/config

    cp "${REPO_ROOT}/agency/tools/post-merge-state" agency/tools/post-merge-state
    chmod +x agency/tools/post-merge-state

    # Optional _colors lib (tool degrades gracefully without it, but install
    # for parity with production).
    cp "${REPO_ROOT}/agency/tools/lib/_colors" agency/tools/lib/_colors 2>/dev/null || true
}

teardown() {
    test_isolation_teardown
    [[ -d "${BATS_TEST_TMPDIR}" ]] && rm -rf "${BATS_TEST_TMPDIR}"
}

# ─── Happy paths ──────────────────────────────────────────────────────────

@test "post-merge-state: check exits 0 when no pending state" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state check
    [ "$status" -eq 0 ]
}

@test "post-merge-state: set creates state file with correct fields" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state set 405 main
    [ "$status" -eq 0 ]
    [ -f agency/config/post-merge-pending.json ]

    # Verify JSON fields
    run python3 -c '
import json
with open("agency/config/post-merge-pending.json") as f: d = json.load(f)
assert d["schema_version"] == 1, f"schema_version wrong: {d}"
assert d["pr_number"] == 405, f"pr_number wrong: {d}"
assert d["base_ref"] == "main", f"base_ref wrong: {d}"
assert "merged_at" in d and d["merged_at"].endswith("Z"), f"merged_at wrong: {d}"
assert d["tool_version"].startswith("1."), f"tool_version wrong: {d}"
print("ok")
'
    [ "$status" -eq 0 ]
    [[ "$output" == "ok" ]]
}

@test "post-merge-state: check exits 1 when state is set (signal, not error)" {
    cd "${BATS_TEST_TMPDIR}"
    ./agency/tools/post-merge-state set 405 main >/dev/null
    run ./agency/tools/post-merge-state check
    [ "$status" -eq 1 ]
    # Message on stderr must name the pending PR so captain knows what to fix
    [[ "$output" == *"PR #405"* ]]
    [[ "$output" == *"/pr-captain-post-merge"* ]]
}

@test "post-merge-state: get prints JSON of current state" {
    cd "${BATS_TEST_TMPDIR}"
    ./agency/tools/post-merge-state set 405 main >/dev/null
    run ./agency/tools/post-merge-state get
    [ "$status" -eq 0 ]
    [[ "$output" == *'"pr_number": 405'* ]]
    [[ "$output" == *'"base_ref": "main"'* ]]
}

@test "post-merge-state: get prints empty JSON when nothing pending" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state get
    [ "$status" -eq 0 ]
    [[ "$output" == "{}" ]]
}

@test "post-merge-state: clear removes state file" {
    cd "${BATS_TEST_TMPDIR}"
    ./agency/tools/post-merge-state set 405 main >/dev/null
    [ -f agency/config/post-merge-pending.json ]

    run ./agency/tools/post-merge-state clear 405
    [ "$status" -eq 0 ]
    [ ! -f agency/config/post-merge-pending.json ]

    # After clear, check passes again
    run ./agency/tools/post-merge-state check
    [ "$status" -eq 0 ]
}

@test "post-merge-state: clear is idempotent (no pending state)" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state clear 405
    [ "$status" -eq 0 ]
    [[ "$output" == *"no pending state to clear"* ]]
}

@test "post-merge-state: supports master as base ref" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state set 405 master
    [ "$status" -eq 0 ]
    run ./agency/tools/post-merge-state get
    [[ "$output" == *'"base_ref": "master"'* ]]
}

# ─── Safety: clear refuses wrong PR number ────────────────────────────────

@test "post-merge-state: clear refuses wrong PR number (guards against race)" {
    cd "${BATS_TEST_TMPDIR}"
    ./agency/tools/post-merge-state set 405 main >/dev/null

    # Attempt to clear for a different PR — should refuse
    run ./agency/tools/post-merge-state clear 999
    [ "$status" -eq 2 ]
    [[ "$output" == *"pending state is for PR #405"* ]]
    [[ "$output" == *"refusing to clear for PR #999"* ]]
    [[ "$output" == *"--force"* ]]  # must advise the escape hatch

    # State should still be set
    [ -f agency/config/post-merge-pending.json ]
    run ./agency/tools/post-merge-state check
    [ "$status" -eq 1 ]
}

# QG round 1 (design F8, reviewer-design): --force escape hatch for stuck state.

@test "post-merge-state: clear --force bypasses the wrong-PR guard" {
    cd "${BATS_TEST_TMPDIR}"
    ./agency/tools/post-merge-state set 405 main >/dev/null

    run ./agency/tools/post-merge-state clear 999 --force
    [ "$status" -eq 0 ]
    [[ "$output" == *"--force given"* ]]
    [ ! -f agency/config/post-merge-pending.json ]

    # Clean after clear
    run ./agency/tools/post-merge-state check
    [ "$status" -eq 0 ]
}

@test "post-merge-state: clear accepts --force in either position" {
    cd "${BATS_TEST_TMPDIR}"
    ./agency/tools/post-merge-state set 405 main >/dev/null
    # --force first, PR second
    run ./agency/tools/post-merge-state clear --force 999
    [ "$status" -eq 0 ]
    [ ! -f agency/config/post-merge-pending.json ]
}

# QG round 1 (reviewer-code #7): corrupt state file must NOT silently clear.

@test "post-merge-state: check on corrupt state file returns 1 + loud error" {
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p agency/config
    echo '{"corrupt' > agency/config/post-merge-pending.json  # truncated JSON
    run ./agency/tools/post-merge-state check
    [ "$status" -eq 1 ]
    [[ "$output" == *"post-merge-corrupt"* ]] || [[ "$output" == *"cannot be parsed"* ]]
    # State file must still exist — we refuse to silently delete
    [ -f agency/config/post-merge-pending.json ]
}

@test "post-merge-state: clear on corrupt file without --force refuses (die)" {
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p agency/config
    echo '{"corrupt' > agency/config/post-merge-pending.json
    run ./agency/tools/post-merge-state clear 999
    [ "$status" -eq 2 ]
    [[ "$output" == *"cannot be parsed"* ]] || [[ "$output" == *"--force"* ]]
    # Refuse means the corrupt file is NOT deleted
    [ -f agency/config/post-merge-pending.json ]
}

@test "post-merge-state: clear --force on corrupt file removes it" {
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p agency/config
    echo '{"corrupt' > agency/config/post-merge-pending.json
    run ./agency/tools/post-merge-state clear 999 --force
    [ "$status" -eq 0 ]
    [[ "$output" == *"corrupt"* ]] || [[ "$output" == *"--force given"* ]]
    [ ! -f agency/config/post-merge-pending.json ]
}

# QG round 1 (security F-2): base_ref validation.

@test "post-merge-state: set rejects base_ref with invalid characters" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state set 405 'main; rm -rf /'
    [ "$status" -eq 2 ]
    [[ "$output" == *"invalid characters"* ]]
}

@test "post-merge-state: set rejects base_ref with embedded quote" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state set 405 'main"break'
    [ "$status" -eq 2 ]
    [[ "$output" == *"invalid characters"* ]]
}

# QG round 1 (reviewer-code #8): atomic write — tmp + mv — verify the
# structural pattern is in place.

@test "post-merge-state: source contains atomic tmp+mv write pattern" {
    run grep -q 'mv -f "$tmp" "$STATE_FILE"' "${REPO_ROOT}/agency/tools/post-merge-state"
    [ "$status" -eq 0 ]
}

# QG round 1 (reviewer-design F1): tool sources _log-helper for audit trail.

@test "post-merge-state: sources _log-helper when present" {
    run grep -q '_log-helper' "${REPO_ROOT}/agency/tools/post-merge-state"
    [ "$status" -eq 0 ]
}

# ─── Bad args ─────────────────────────────────────────────────────────────

@test "post-merge-state: set rejects non-integer PR number" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state set notanumber main
    [ "$status" -eq 2 ]
    [[ "$output" == *"integer"* ]]
}

@test "post-merge-state: set rejects missing base-ref" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state set 405
    [ "$status" -eq 2 ]
    [[ "$output" == *"<pr-number> <base-ref>"* ]]
}

@test "post-merge-state: clear rejects non-integer PR number" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state clear notanumber
    [ "$status" -eq 2 ]
    [[ "$output" == *"integer"* ]]
}

@test "post-merge-state: unknown subcommand exits 2" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state weirdcmd
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown subcommand"* ]]
}

@test "post-merge-state: no subcommand exits 2" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state
    [ "$status" -eq 2 ]
    [[ "$output" == *"Missing subcommand"* ]]
}

# ─── --help / --version ───────────────────────────────────────────────────

@test "post-merge-state: --help works" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"post-merge-state"* ]]
    [[ "$output" == *"C#372 Fix B"* ]]
}

@test "post-merge-state: --version works" {
    cd "${BATS_TEST_TMPDIR}"
    run ./agency/tools/post-merge-state --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"post-merge-state"* ]]
    # Matches 1.x.y — bumped to 1.1.0 during QG round 1
    [[ "$output" =~ 1\.[0-9]+\.[0-9]+ ]]
}

# ─── Integration: full pr-merge → clear lifecycle ─────────────────────────

@test "post-merge-state: full lifecycle — clean → set → check pending → clear → check clean" {
    cd "${BATS_TEST_TMPDIR}"

    # Start clean
    run ./agency/tools/post-merge-state check
    [ "$status" -eq 0 ]

    # Simulate pr-merge calling set after a successful merge
    run ./agency/tools/post-merge-state set 405 main
    [ "$status" -eq 0 ]

    # Simulate captain-release / pr-captain-merge refusing
    run ./agency/tools/post-merge-state check
    [ "$status" -eq 1 ]

    # Simulate pr-captain-post-merge calling clear after gh release view succeeds
    run ./agency/tools/post-merge-state clear 405
    [ "$status" -eq 0 ]

    # Now new work can proceed
    run ./agency/tools/post-merge-state check
    [ "$status" -eq 0 ]
}
