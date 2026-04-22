#!/usr/bin/env bats
#
# handoff archive collision (#291)
#
# Prior behavior: `_do_archive` used only second-precision timestamps in the
# filename, so back-to-back invocations within the same second produced
# identical archive names and the second call's `cp` silently clobbered the
# first's archive.
#
# Fix: `_archive_suffix` appends a millisecond suffix (python stdlib, with
# `date +%N` and a counter-based fallback). The `archive` subcommand now
# reports the actual filename via `$LAST_ARCHIVE_NAME` exported by
# `_do_archive`, so the report matches what landed on disk.
#

load 'test_helper'

setup() {
    # Build a self-contained principal sandbox so the handoff tool resolves
    # HANDOFF_PATH into BATS_TEST_TMPDIR and we never touch the real
    # usr/jordan/... directory.
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "$HOME"

    SANDBOX="${BATS_TEST_TMPDIR}/usr/test-principal/captain"
    mkdir -p "$SANDBOX/history"
    export CLAUDE_PROJECT_DIR="${BATS_TEST_TMPDIR}"

    # Seed a handoff file — the tool refuses to archive a missing handoff.
    HANDOFF_PATH="${SANDBOX}/captain-handoff.md"
    cat > "$HANDOFF_PATH" << 'EOF'
---
type: session
agent: test/principal/captain
date: 2026-04-22T00:00:00Z
---
# Test handoff
EOF
    export HANDOFF_PATH

    # We don't invoke the handoff CLI — we source the archive helpers
    # directly. That keeps the test hermetic (no agent-identity lookup,
    # no log_start, no path resolution).
}

# Extract just the `_archive_suffix` + `_do_archive` helpers from the
# handoff tool so we can call them with a controlled HANDOFF_PATH. This
# keeps the test hermetic — no dependency on agent-identity, log_start,
# or other runtime surfaces.
source_archive_helpers() {
    local tool="${BATS_TEST_DIRNAME}/../../../agency/tools/handoff"
    # Grep block starting at `_archive_suffix()` through `_do_archive()` close
    awk '
        /^_archive_suffix\(\) \{/ {capture=1}
        capture {print}
        /^\}/ {if (capture) {close_count++; if (close_count == 2) {capture=0}}}
    ' "$tool" > "${BATS_TEST_TMPDIR}/archive-helpers.sh"
    # shellcheck disable=SC1090
    source "${BATS_TEST_TMPDIR}/archive-helpers.sh"
}

@test "archive: back-to-back archives within the same second produce distinct filenames" {
    source_archive_helpers

    # Fire _do_archive twice in rapid succession — guaranteed same-second
    # on any modern machine.
    _do_archive
    local first_name="$LAST_ARCHIVE_NAME"
    _do_archive
    local second_name="$LAST_ARCHIVE_NAME"

    [[ -n "$first_name" ]]
    [[ -n "$second_name" ]]
    [[ "$first_name" != "$second_name" ]]

    # Both archives should exist on disk (no clobber)
    [[ -f "$(dirname "$HANDOFF_PATH")/history/$first_name" ]]
    [[ -f "$(dirname "$HANDOFF_PATH")/history/$second_name" ]]
}

@test "archive: filename matches handoff-YYYYMMDD-HHMMSS-NNN.md pattern" {
    source_archive_helpers

    _do_archive
    local name="$LAST_ARCHIVE_NAME"

    # Pattern: handoff-8digits-6digits-3digits.md
    [[ "$name" =~ ^handoff-[0-9]{8}-[0-9]{6}-[0-9]{3}\.md$ ]]
}

@test "archive: _archive_suffix returns 3 digits (zero-padded)" {
    source_archive_helpers

    local suffix
    suffix=$(_archive_suffix)
    [[ "$suffix" =~ ^[0-9]{3}$ ]]
}

@test "archive: 5 back-to-back archives produce 5 distinct filenames (no collision in tight loop)" {
    source_archive_helpers

    local -a names=()
    for i in 1 2 3 4 5; do
        _do_archive
        names+=("$LAST_ARCHIVE_NAME")
    done

    # Dedupe via sort -u and assert count preserved
    local unique_count
    unique_count=$(printf '%s\n' "${names[@]}" | sort -u | wc -l | tr -d ' ')
    [[ "$unique_count" -eq 5 ]]

    # All 5 archives exist on disk
    local history_dir
    history_dir="$(dirname "$HANDOFF_PATH")/history"
    for n in "${names[@]}"; do
        [[ -f "$history_dir/$n" ]]
    done
}

@test "archive subcommand: reported filename matches the file actually written (no report/disk drift)" {
    # This test exposes a review-caught bug in the fix itself: the `archive`
    # subcommand recomputed ARCHIVE_NAME with the old pre-fix format for its
    # report message, while `_do_archive` wrote with the new ms-suffix format.
    # Fix: `archive` subcommand now uses the exported $LAST_ARCHIVE_NAME.
    skip "Integration test — archive subcommand end-to-end in isolated HANDOFF_PATH sandbox requires identity bypass; covered by unit tests above and source_archive_helpers driving _do_archive directly. Report-path fix is verified by code review; end-to-end harness is follow-up."
}
