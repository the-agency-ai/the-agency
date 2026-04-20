#!/usr/bin/env bats
#
# collaboration tool — frontmatter status detection (PR #87 D41-R3 fixes).
# Tests the `_update_frontmatter_status` awk-based rewrite and the
# frontmatter-scoped unread detection in `cmd_check`.
#
# Source the helpers directly so we can call _update_frontmatter_status
# without spinning up a full repo + collaboration check.
#

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
COLLAB="${REPO_ROOT}/agency/tools/collaboration"

setup() {
    BATS_TEST_TMPDIR="$(mktemp -d)"
    export BATS_TEST_TMPDIR

    # Source just the helper functions, suppressing tool execution.
    # The script runs `cmd_*` only via the dispatch case; sourcing without
    # arguments is safe.
    set +u
    source "$COLLAB" >/dev/null 2>&1 || true
    set -u
}

teardown() {
    rm -rf "$BATS_TEST_TMPDIR"
}

@test "_update_frontmatter_status: replaces existing status in frontmatter" {
    local f="$BATS_TEST_TMPDIR/d.md"
    printf -- '---\nfrom: a\nstatus: unread\nsubject: hi\n---\n\nbody\n' > "$f"
    _update_frontmatter_status "$f" "read"
    grep -q '^status: read$' "$f"
}

@test "_update_frontmatter_status: inserts status when absent (before closing ---)" {
    local f="$BATS_TEST_TMPDIR/d.md"
    printf -- '---\nfrom: a\nsubject: hi\n---\n\nbody\n' > "$f"
    _update_frontmatter_status "$f" "read"
    grep -q '^status: read$' "$f"
    # Inserted exactly once
    [ "$(grep -c '^status: ' "$f")" -eq 1 ]
}

@test "_update_frontmatter_status: ignores body lines that look like frontmatter" {
    local f="$BATS_TEST_TMPDIR/d.md"
    printf -- '---\nfrom: a\nsubject: hi\nstatus: unread\n---\n\nbody quotes:\nstatus: resolved\n' > "$f"
    _update_frontmatter_status "$f" "read"
    # The frontmatter status changes
    head -10 "$f" | grep -q '^status: read$'
    # The body line is preserved verbatim
    grep -q '^status: resolved$' "$f"
}

@test "_update_frontmatter_status: missing file returns error" {
    run _update_frontmatter_status "$BATS_TEST_TMPDIR/nope.md" "read"
    [ "$status" -ne 0 ]
}

@test "frontmatter-scoped unread detection: body 'status: resolved' does not mark read" {
    # Verify the awk script used in cmd_check by running it inline.
    local f="$BATS_TEST_TMPDIR/d.md"
    printf -- '---\nfrom: a\nsubject: hi\n---\n\nReply quotes:\nstatus: resolved\n' > "$f"
    local fm_status
    fm_status=$(awk '
        BEGIN { in_fm = 0; opened = 0 }
        /^---[[:space:]]*$/ {
            if (!opened) { opened = 1; in_fm = 1; next }
            if (in_fm)   { exit }
        }
        in_fm && /^status:[[:space:]]/ {
            sub(/^status:[[:space:]]*/, "")
            print
            exit
        }
    ' "$f")
    [ -z "$fm_status" ]
}

@test "frontmatter-scoped unread detection: explicit unread is detected" {
    local f="$BATS_TEST_TMPDIR/d.md"
    printf -- '---\nfrom: a\nstatus: unread\nsubject: hi\n---\n\nbody\n' > "$f"
    local fm_status
    fm_status=$(awk '
        BEGIN { in_fm = 0; opened = 0 }
        /^---[[:space:]]*$/ {
            if (!opened) { opened = 1; in_fm = 1; next }
            if (in_fm)   { exit }
        }
        in_fm && /^status:[[:space:]]/ {
            sub(/^status:[[:space:]]*/, "")
            print
            exit
        }
    ' "$f")
    [ "$fm_status" = "unread" ]
}
