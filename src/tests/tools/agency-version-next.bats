#!/usr/bin/env bats
#
# agency-version-next — the agency_version bump policy, as a pure primitive.
#
# Extracted from pr-captain-land, where it was inline Python whose
# `sys.exit(1)` killed the CALLER under `set -euo pipefail` before the
# caller's own "could not bump version" error could run — leaving the
# landing's scratch worktree stranded. The table below is what makes that
# failure mode a reported error instead of a silent abort.

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
TOOL="${REPO_ROOT}/agency/tools/agency-version-next"

@test "agency-version-next: exists and is executable" {
    [ -x "$TOOL" ]
}

@test "agency-version-next: is syntactically valid bash" {
    bash -n "$TOOL"
}

@test "agency-version-next: --help exits 0" {
    run bash "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "agency-version-next: no argument is a usage error (exit 2)" {
    run bash "$TOOL"
    [ "$status" -eq 2 ]
}

@test "agency-version-next: two arguments is a usage error (exit 2)" {
    run bash "$TOOL" 1.2 3.4
    [ "$status" -eq 2 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# The policy
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-version-next: 46.25 → 46.26" {
    run bash "$TOOL" 46.25
    [ "$status" -eq 0 ]
    [ "$output" = "46.26" ]
}

@test "agency-version-next: 46.9 → 46.10 (numeric, not lexical)" {
    run bash "$TOOL" 46.9
    [ "$status" -eq 0 ]
    [ "$output" = "46.10" ]
}

@test "agency-version-next: 46.99 → 46.100 (no rollover into the first component)" {
    run bash "$TOOL" 46.99
    [ "$status" -eq 0 ]
    [ "$output" = "46.100" ]
}

@test "agency-version-next: a zero-padded component is base-10, not octal" {
    # 10# is load-bearing: bash reads a leading-zero literal as octal, so
    # "08" would be a syntax error and "07" would bump to 8 by luck.
    run bash "$TOOL" 46.08
    [ "$status" -eq 0 ]
    [ "$output" = "46.9" ]
}

@test "agency-version-next: single component 46 → 47" {
    run bash "$TOOL" 46
    [ "$status" -eq 0 ]
    [ "$output" = "47" ]
}

@test "agency-version-next: 0.0 → 0.1" {
    run bash "$TOOL" 0.0
    [ "$status" -eq 0 ]
    [ "$output" = "0.1" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Refusals — each must exit 1 with an EMPTY stdout, so
# `NEW=$(agency-version-next "$CUR") || die` reaches its error path with no value
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-version-next: three-component semver is refused, not guessed" {
    run bash -c "bash '$TOOL' 1.2.3 2>/dev/null"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "agency-version-next: the semver refusal explains itself on stderr" {
    run bash -c "bash '$TOOL' 1.2.3 2>&1 >/dev/null"
    [[ "$output" == *"Refusing to guess"* ]]
}

@test "agency-version-next: non-numeric input is refused" {
    run bash -c "bash '$TOOL' abc 2>/dev/null"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "agency-version-next: empty string is refused" {
    run bash -c "bash '$TOOL' '' 2>/dev/null"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "agency-version-next: a v-prefix is refused (callers strip it)" {
    run bash -c "bash '$TOOL' v46.25 2>/dev/null"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "agency-version-next: a trailing suffix is refused" {
    run bash -c "bash '$TOOL' 46.25-rc1 2>/dev/null"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# The integration property the extraction exists for
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-version-next: a refusal lets the CALLER report, instead of aborting it" {
    # This is the whole point. The inline Python form killed the caller
    # outright under `set -euo pipefail`; the || branch never ran.
    run bash -c "
        set -euo pipefail
        NEW=\$(bash '$TOOL' 1.2.3 2>/dev/null) || { echo 'CALLER HANDLED IT'; exit 7; }
        echo \"UNEXPECTED: \$NEW\"
    "
    [ "$status" -eq 7 ]
    [ "$output" = "CALLER HANDLED IT" ]
}

@test "agency-version-next: matches the version currently in the manifest" {
    # Guards against the manifest drifting into a format the bump refuses —
    # which would make every land abort at step 4.
    current="$(python3 -c '
import json
print(json.load(open("'"${REPO_ROOT}"'/agency/config/manifest.json"))["agency_version"])
')"
    run bash "$TOOL" "$current"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [ "$output" != "$current" ]
}
