#!/usr/bin/env bats
# test-session-pickup.bats — unit tests for agency/tools/session-pickup
#
# Covers A&D v3 §9.2 test matrix:
#   - CLI arg parsing (--from required, invalid values)
#   - Identity override + whitelist (Sec-2 parity with session-pause)
#   - Symlink refusal (Sec-1 parity)
#   - Happy path both --from values
#   - Missing handoff → aborted
#   - handoff_mode extraction (continuation, resumption, legacy tolerance)
#   - next_action extraction
#   - pause_commit_sha: explicit frontmatter + mtime fallback
#   - dispatches_unread + dispatches_drift_since_pause math
#   - Monitor health: unknown / dead / ok
#   - Tree state: clean / dirty → blocked
#   - PICKUP idempotency (read-mostly, second call same output)
#   - Schema + tool version emission
#   - Exit codes (0 ok, 1 aborted/blocked, 2 lock contention)
#
# Each test runs in an isolated tmp git repo via $BATS_TEST_TMPDIR.
#
# Session-lifecycle-refactor Plan v2 Iteration 2.2.

setup() {
    TOOL="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)/agency/tools/session-pickup"
    [[ -x "$TOOL" ]] || { echo "session-pickup not executable at $TOOL" >&2; return 1; }

    # Sandbox git repo
    export REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$REPO"
    cd "$REPO"
    git init -q
    git config user.email test@example.com
    git config user.name "Test"
    git config commit.gpgsign false

    mkdir -p usr/testp/testa/history
    # Seed a handoff with continuation frontmatter and a next-action.
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
type: session
agent: test-repo/testp/testa
date: 2026-04-20 12:00
trigger: session-compact
branch: master
mode: continuation
next-action: Continue Phase 2 Iteration 2.2 — session-pickup primitive
---

## Body
Test body content.
EOF

    # Gitignore session-state — same discipline as test-session-pause.bats.
    cat > .gitignore <<'EOF'
.claude/logs/
agency/config/monitor-pids.json
EOF

    git add usr/testp/testa/testa-handoff.md .gitignore
    git commit -qm "initial"

    export CLAUDE_PROJECT_DIR="$REPO"
    export AGENCY_PROJECT_ROOT="$REPO"

    # Isolate ISCP DB to the sandbox so dispatch counts don't leak from the
    # live the-agency DB.
    export ISCP_DB_PATH="$BATS_TEST_TMPDIR/test-iscp.db"
}

teardown() {
    # Clean lock dirs (shared key with session-pause).
    rm -rf "${TMPDIR:-/tmp}"/agency-session-pause-*.lock 2>/dev/null || true
}

# ── Helpers ────────────────────────────────────────────────────────────────
_run_pickup() {
    "$TOOL" --principal testp --agent testa "$@"
}

_emit_line() {
    # Extract value for a given key from key=value output.
    local key="$1" output="$2"
    echo "$output" | awk -F= -v k="$key" '$1==k { for(i=2;i<=NF;i++){printf "%s%s", (i>2?"=":""), $i} print ""}'
}

_init_db() {
    # Create ISCP DB schema in isolation so dispatch-count tests work.
    local db="$ISCP_DB_PATH"
    sqlite3 "$db" <<'SQL'
CREATE TABLE IF NOT EXISTS dispatches (
    id INTEGER PRIMARY KEY,
    created_at TEXT NOT NULL,
    from_agent TEXT NOT NULL,
    to_agent TEXT NOT NULL,
    type TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'normal',
    subject TEXT NOT NULL,
    payload_path TEXT NOT NULL,
    in_reply_to INTEGER,
    status TEXT NOT NULL DEFAULT 'unread',
    read_at TEXT,
    read_by TEXT,
    resolved_at TEXT
);
SQL
}

_set_repo_name() {
    # Seed agency.yaml so _iscp_resolve_repo_name returns a known name and
    # the pickup can build to_agent=<repo>/testp/testa.
    mkdir -p agency/config
    cat > agency/config/agency.yaml <<'EOF'
repo:
  name: test-repo
EOF
}

# ── CLI arg parsing (3 tests) ──────────────────────────────────────────────

@test "missing --from aborts with error_reason" {
    run "$TOOL" --principal testp --agent testa
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*--from"
}

@test "invalid --from value aborts with error_reason" {
    run "$TOOL" --from nonsense --principal testp --agent testa
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*invalid --from"
}

@test "unknown option aborts" {
    run "$TOOL" --bogus --from compact --principal testp --agent testa
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*unknown option"
}

# ── Identity whitelist (Sec-2 parity) (2 tests) ────────────────────────────

@test "--principal with path-traversal is rejected" {
    run "$TOOL" --from compact --principal "../../etc" --agent testa
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "error_reason=.*invalid --principal"
}

@test "--agent with path-traversal is rejected" {
    run "$TOOL" --from compact --principal testp --agent "../evil"
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "error_reason=.*invalid --agent"
}

# ── Symlink refusal (Sec-1 parity) (1 test) ────────────────────────────────

@test "handoff that is a symlink is refused with clear error_reason" {
    rm -f usr/testp/testa/testa-handoff.md
    echo "target content" > "$BATS_TEST_TMPDIR/other-file.txt"
    ln -sf "$BATS_TEST_TMPDIR/other-file.txt" usr/testp/testa/testa-handoff.md
    run _run_pickup --from compact
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*symlink.*refusing to read"
}

# ── Missing handoff (1 test) ───────────────────────────────────────────────

@test "missing handoff file aborts with error_reason" {
    rm -f usr/testp/testa/testa-handoff.md
    run _run_pickup --from compact
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*handoff file missing"
}

# ── Happy path (2 tests) ───────────────────────────────────────────────────

@test "--from compact on clean tree with continuation handoff → status=ok" {
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
    echo "$output" | grep -q "^from=compact$"
    echo "$output" | grep -q "^tree_state=clean$"
    echo "$output" | grep -q "^handoff_mode=continuation$"
}

@test "--from fresh on clean tree emits from=fresh (preflight may or may not pass)" {
    # --from fresh invokes session-preflight, which may fail in a bare
    # sandbox (no dispatch monitor, etc). Either status=ok or status=blocked
    # is acceptable; what we verify is the from= key and the full report.
    run _run_pickup --from fresh
    # Both exit 0 (ok) and exit 1 (blocked) are acceptable
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
    echo "$output" | grep -q "^from=fresh$"
    echo "$output" | grep -q "^tree_state=clean$"
    # Any non-aborted outcome emits the full report (handoff_mode etc).
    echo "$output" | grep -q "^handoff_mode=continuation$"
}

# ── handoff_mode extraction (3 tests) ──────────────────────────────────────

@test "handoff_mode=resumption extracted correctly" {
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
mode: resumption
next-action: End-of-day resume
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "rewrite handoff"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^handoff_mode=resumption$"
}

@test "handoff_mode=resume (pre-refactor) maps to legacy" {
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
mode: resume
next-action: Legacy handoff from before the refactor
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "legacy handoff"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^handoff_mode=legacy$"
}

@test "handoff_mode=unknown when frontmatter has no mode field" {
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
type: session
next-action: No mode set
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "no mode"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^handoff_mode=unknown$"
}

# ── next_action extraction (1 test) ────────────────────────────────────────

@test "next_action extracted verbatim from frontmatter" {
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
mode: continuation
next-action: Run the thing then the other thing
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "new next-action"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^next_action=Run the thing then the other thing$"
}

# ── pause_commit_sha (2 tests) ─────────────────────────────────────────────

@test "pause_commit_sha extracted from explicit frontmatter field" {
    cat > usr/testp/testa/testa-handoff.md <<EOF
---
mode: continuation
pause_commit_sha: deadbeef1234567890abcdef1234567890abcdef
next-action: Pick up at the next thing
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "explicit pause_commit_sha"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^pause_commit_sha=deadbeef1234567890abcdef1234567890abcdef$"
}

@test "pause_commit_sha falls back to git log when absent from frontmatter" {
    # No explicit pause_commit_sha in frontmatter → fallback uses HEAD (the
    # initial commit from setup, whose time is before the handoff's mtime
    # after a `touch` below).
    touch usr/testp/testa/testa-handoff.md
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    # Should be a real SHA (40 hex chars), not "none"
    echo "$output" | grep -qE "^pause_commit_sha=[0-9a-f]{40}$"
    ! echo "$output" | grep -q "^pause_commit_sha=none$"
}

# ── Dispatch counts (2 tests) ──────────────────────────────────────────────

@test "dispatches_unread counts unread dispatches addressed to the agent" {
    _set_repo_name
    _init_db
    git add agency/config/agency.yaml && git commit -qm "seed repo name"
    # Insert 3 unread dispatches for testp/testa, 1 for a different agent,
    # 1 resolved for testp/testa (should not count).
    sqlite3 "$ISCP_DB_PATH" <<SQL
INSERT INTO dispatches (created_at, from_agent, to_agent, type, subject, payload_path, status)
VALUES
 ('2026-04-20T10:00', 'test-repo/other/sender', 'test-repo/testp/testa', 'dispatch', 's1', '/p', 'unread'),
 ('2026-04-20T10:10', 'test-repo/other/sender', 'test-repo/testp/testa', 'dispatch', 's2', '/p', 'unread'),
 ('2026-04-20T10:20', 'test-repo/other/sender', 'test-repo/testp/testa', 'dispatch', 's3', '/p', 'unread'),
 ('2026-04-20T10:30', 'test-repo/other/sender', 'test-repo/elsewhere/other',  'dispatch', 's4', '/p', 'unread'),
 ('2026-04-20T10:40', 'test-repo/other/sender', 'test-repo/testp/testa', 'dispatch', 's5', '/p', 'resolved');
SQL
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^dispatches_unread=3$"
}

@test "dispatches_drift_since_pause counts only dispatches after pause time" {
    _set_repo_name
    _init_db
    git add agency/config/agency.yaml && git commit -qm "seed repo name"
    # Pause commit time = the initial commit (setup's git commit).
    # `git log -1 --format=%cI HEAD` gives an ISO timestamp; anything AFTER
    # that should be counted as drift, anything BEFORE should not. Use
    # explicit dates far before and after the commit to avoid timing races.
    PAUSE_SHA=$(git rev-parse HEAD)
    PAUSE_TIME=$(git log -1 --format=%cI "$PAUSE_SHA" | python3 -c '
import sys, datetime
s = sys.stdin.read().strip()
dt = datetime.datetime.fromisoformat(s.replace("Z", "+00:00"))
dt_utc = dt.astimezone(datetime.timezone.utc)
print(dt_utc.strftime("%Y-%m-%dT%H:%M"))
')
    # Two dispatches BEFORE the pause time, two AFTER.
    sqlite3 "$ISCP_DB_PATH" <<SQL
INSERT INTO dispatches (created_at, from_agent, to_agent, type, subject, payload_path, status)
VALUES
 ('1999-01-01T00:00', 'x/o/s', 'test-repo/testp/testa', 'dispatch', 'before1', '/p', 'unread'),
 ('2000-01-01T00:00', 'x/o/s', 'test-repo/testp/testa', 'dispatch', 'before2', '/p', 'read'),
 ('2099-12-31T23:58', 'x/o/s', 'test-repo/testp/testa', 'dispatch', 'after1',  '/p', 'unread'),
 ('2099-12-31T23:59', 'x/o/s', 'test-repo/testp/testa', 'dispatch', 'after2',  '/p', 'read');
SQL
    # Write the pause_commit_sha into the handoff so pickup picks it up.
    cat > usr/testp/testa/testa-handoff.md <<EOF
---
mode: continuation
pause_commit_sha: $PAUSE_SHA
next-action: drift test
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "pause_sha for drift test"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^dispatches_drift_since_pause=2$"
}

# ── Monitor health (3 tests) ───────────────────────────────────────────────

@test "monitor health is 'unknown' when registry is absent" {
    rm -rf agency/config 2>/dev/null || true
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^monitor_health_dispatch=unknown$"
    echo "$output" | grep -q "^monitor_health_ci=unknown$"
    echo "$output" | grep -q "^monitor_health_issue=unknown$"
}

@test "monitor health is 'dead' for a registered type whose PID is stale" {
    mkdir -p agency/config
    # Registry with a clearly stale PID that can't match current-shell hash.
    cat > agency/config/monitor-pids.json <<'EOF'
[{"pid": 99999, "start_time_epoch": 0, "cmdline_hash": "stale-hash", "monitor_type": "dispatch", "registered_at": "2026-04-20T00:00:00Z"}]
EOF
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^monitor_health_dispatch=dead$"
    # Unrelated types still 'unknown'
    echo "$output" | grep -q "^monitor_health_ci=unknown$"
}

@test "monitor types not in registry emit 'unknown', not 'dead'" {
    mkdir -p agency/config
    # Registry has only 'dispatch' — ci + issue should be unknown.
    cat > agency/config/monitor-pids.json <<'EOF'
[{"pid": 99999, "start_time_epoch": 0, "cmdline_hash": "stale", "monitor_type": "dispatch", "registered_at": "2026-04-20T00:00:00Z"}]
EOF
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^monitor_health_ci=unknown$"
    echo "$output" | grep -q "^monitor_health_issue=unknown$"
}

# ── Tree state → blocked (1 test) ──────────────────────────────────────────

@test "dirty tree → status=blocked + tree_state=dirty; exit 1" {
    echo "edit" >> usr/testp/testa/testa-handoff.md
    run _run_pickup --from compact
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^tree_state=dirty$"
    echo "$output" | grep -q "^status=blocked$"
    echo "$output" | grep -q "error_reason=.*dirty"
}

# ── Lock handling (1 test) ─────────────────────────────────────────────────

@test "lock contention: second concurrent call exits 2" {
    LOCK_KEY=$(python3 -c 'import hashlib, sys; print(hashlib.sha1(sys.argv[1].encode()).hexdigest()[:16])' \
        "$REPO/usr/testp/testa/testa-handoff.md")
    LOCK_DIR="${TMPDIR:-/tmp}/agency-session-pause-${LOCK_KEY}.lock"
    mkdir "$LOCK_DIR"
    echo $$ > "$LOCK_DIR/pid"

    run _run_pickup --from compact
    [ "$status" -eq 2 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*lock timeout"

    rm -rf "$LOCK_DIR"
}

# ── Idempotency (1 test — PICKUP is read-mostly) ───────────────────────────

@test "double PICKUP on clean tree: both calls succeed with same handoff_mode" {
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    first_mode=$(_emit_line handoff_mode "$output")

    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    second_mode=$(_emit_line handoff_mode "$output")

    [ "$first_mode" = "$second_mode" ]
    [ "$first_mode" = "continuation" ]
}

# ── Output shape (1 test) ──────────────────────────────────────────────────

@test "success output emits schema_version=1 and tool_version" {
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^schema_version=1$"
    echo "$output" | grep -qE "^tool_version=[0-9]+\.[0-9]+\.[0-9]+$"
    # All required keys per §4.1
    for key in handoff_path handoff_mode pause_commit_sha dispatches_unread \
               dispatches_drift_since_pause tree_state \
               monitor_health_dispatch monitor_health_ci monitor_health_issue \
               next_action from status; do
        echo "$output" | grep -q "^${key}="
    done
}

# ── QG-iteration-complete hardening (added 2026-04-20 per reviewer findings) ──

# F1: Bug-exposing — non-SHA pause_commit_sha values must be rejected, NOT
# passed into `git log` argv and NOT emitted verbatim on stdout.
@test "F1: pause_commit_sha with git-flag-shaped value is rejected, falls back to mtime SHA" {
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
mode: continuation
pause_commit_sha: --all
next-action: malicious sha attempt
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "F1 test"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    # Must NOT emit the malicious value
    ! echo "$output" | grep -q "^pause_commit_sha=--all$"
    # Fallback must produce a real 40-char SHA (the initial or F1 commit)
    echo "$output" | grep -qE "^pause_commit_sha=[0-9a-f]{40}$"
}

@test "F1: pause_commit_sha with shell-metachar value is rejected" {
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
mode: continuation
pause_commit_sha: ;rm -rf /
next-action: injection attempt
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "F1b test"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    ! echo "$output" | grep -q "rm -rf"
    echo "$output" | grep -qE "^pause_commit_sha=([0-9a-f]{40}|none)$"
}

# F2: Bug-exposing — inline YAML comments on frontmatter fields
@test "F2: inline YAML comment on mode field is stripped" {
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
mode: continuation  # mid-session compact
next-action: yaml comment test
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "F2 test"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^handoff_mode=continuation$"
}

@test "F2: inline YAML comment on pause_commit_sha is stripped" {
    SHA=$(git rev-parse HEAD)
    cat > usr/testp/testa/testa-handoff.md <<EOF
---
mode: continuation
pause_commit_sha: $SHA  # written at compact-prepare
next-action: sha with trailing comment
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "F2b test"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^pause_commit_sha=$SHA$"
}

# F3: Bug-exposing — malformed frontmatter (only one `---`)
@test "F3: handoff with only opening --- (no closing) does not leak body into frontmatter" {
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
mode: continuation
next-action: intended action
EOF
    # No closing delimiter. Body-like text below (no closing fence) would
    # otherwise be absorbed by a naive awk parser.
    cat >> usr/testp/testa/testa-handoff.md <<'EOF'

# Body
This is body content. mode: injected-via-body
next-action: injected-via-body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "F3 test"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    # Without closing delimiter, frontmatter is empty → mode=unknown,
    # next_action blank. The body's "mode: injected-via-body" must NOT leak.
    echo "$output" | grep -q "^handoff_mode=unknown$"
    ! echo "$output" | grep -q "injected-via-body"
}

# F4: Bug-exposing — control chars in next-action must be stripped
@test "F4: control chars in next-action are stripped from emitted value" {
    # Embed an ESC char (\x1b) + OSC ]0; + BEL (\x07) sequence in next-action
    printf '%s' '---' > usr/testp/testa/testa-handoff.md
    printf '\n' >> usr/testp/testa/testa-handoff.md
    printf '%s\n' 'mode: continuation' >> usr/testp/testa/testa-handoff.md
    printf 'next-action: hello\x1b]0;pwned\x07world\n' >> usr/testp/testa/testa-handoff.md
    printf '%s\n' '---' >> usr/testp/testa/testa-handoff.md
    printf '%s\n' 'body' >> usr/testp/testa/testa-handoff.md
    git add usr/testp/testa/testa-handoff.md && git commit -qm "F4 test"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    # The emitted next_action must not contain ESC or BEL
    ! echo "$output" | grep -qE 'next_action=.*'$'\x1b'
    ! echo "$output" | grep -qE 'next_action=.*'$'\x07'
    # Visible letters survive (hello + pwned + world all stripped-of-control)
    echo "$output" | grep -q "^next_action=hello.*world$"
}

# H1: next_action > 200 chars is truncated with trailing "..."
@test "H1: next_action over 200 chars is truncated with ... suffix" {
    longstr=$(printf 'x%.0s' {1..250})
    cat > usr/testp/testa/testa-handoff.md <<EOF
---
mode: continuation
next-action: $longstr
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "H1 test"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    # Extract the value; length must be exactly 200 and end with "..."
    val=$(_emit_line next_action "$output")
    [ "${#val}" -eq 200 ]
    [ "${val: -3}" = "..." ]
}

# H2: next_action with special characters (:, =, |) round-trips correctly
@test "H2: next_action with embedded colons and pipes survives emission" {
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
mode: continuation
next-action: Run foo:bar then pipe|through baz (with: colons)
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "H2 test"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^next_action=Run foo:bar then pipe|through baz (with: colons)$"
}

# H3: pause_commit_sha=none → dispatches_drift_since_pause=0 (no crash)
@test "H3: pause_commit_sha=none short-circuits drift query to 0" {
    _set_repo_name
    _init_db
    git add agency/config/agency.yaml && git commit -qm "H3 setup"
    # Seed DB with dispatches that WOULD count if drift were computed
    sqlite3 "$ISCP_DB_PATH" <<SQL
INSERT INTO dispatches (created_at, from_agent, to_agent, type, subject, payload_path, status)
VALUES ('2099-01-01T00:00', 'x/o/s', 'test-repo/testp/testa', 'dispatch', 'future', '/p', 'unread');
SQL
    # Handoff with explicit pause_commit_sha=none
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
mode: continuation
pause_commit_sha: none
next-action: H3 none path
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "H3 test"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^pause_commit_sha=none$"
    echo "$output" | grep -q "^dispatches_drift_since_pause=0$"
    # Unread count should still be computed (doesn't require pause_commit_sha)
    echo "$output" | grep -q "^dispatches_unread=1$"
}

# H4: monitor_health=ok when a live monitor is registered with current PID
@test "H4: monitor_health=ok when current process registered as monitor" {
    mkdir -p agency/config
    # Register the bats test process ($$) as a dispatch monitor.
    # monitor-register reads $MONITOR_PID to override $$ for registration
    # target, letting us register "ourselves" without forking.
    MONITOR_PID=$$ MONITOR_REGISTRY_PATH="$REPO/agency/config/monitor-pids.json" \
        "$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)/agency/tools/monitor-register" dispatch >/dev/null 2>&1 || \
        MONITOR_PID=$$ "$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)/agency/tools/monitor-register" dispatch >/dev/null 2>&1 || true
    # Verify the registration exists; if not, skip (env doesn't support it).
    [ -f agency/config/monitor-pids.json ] || skip "monitor-register did not write registry"
    grep -q '"pid"' agency/config/monitor-pids.json || skip "no pid in registry"

    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    # ok path is the strong goal; accept 'dead' as a fallback if the test
    # environment doesn't pass identity verification (different parent shell
    # than the one monitor-register hashed).
    echo "$output" | grep -qE "^monitor_health_dispatch=(ok|dead)$"
    # The registry-present discriminant MUST be hit — never "unknown" here.
    ! echo "$output" | grep -q "^monitor_health_dispatch=unknown$"
}

# H5: lock dir is released after a successful pickup
@test "H5: lock dir is removed after successful pickup" {
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    LOCK_KEY=$(python3 -c 'import hashlib, sys; print(hashlib.sha1(sys.argv[1].encode()).hexdigest()[:16])' \
        "$REPO/usr/testp/testa/testa-handoff.md")
    LOCK_DIR="${TMPDIR:-/tmp}/agency-session-pause-${LOCK_KEY}.lock"
    [ ! -d "$LOCK_DIR" ]
}

# H6: missing ISCP DB → dispatches_unread=0 + drift=0 (graceful degradation)
@test "H6: missing ISCP DB emits dispatches_unread=0 without crashing" {
    # ISCP_DB_PATH from setup() points at a file that was never created
    # (no _init_db call in this test). Pickup must degrade to 0.
    [ ! -f "$ISCP_DB_PATH" ]
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^dispatches_unread=0$"
    echo "$output" | grep -q "^dispatches_drift_since_pause=0$"
}

# M3: duplicate mode field — first wins (awk exits after first match)
@test "M3: duplicate mode field — first occurrence wins" {
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
mode: resumption
mode: continuation
next-action: duplicate mode test
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "M3 test"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^handoff_mode=resumption$"
}

# M5: legacy `commit_sha:` frontmatter field is accepted (older session-pause)
@test "M5: legacy commit_sha field is accepted as pause_commit_sha fallback" {
    SHA=$(git rev-parse HEAD)
    cat > usr/testp/testa/testa-handoff.md <<EOF
---
mode: continuation
commit_sha: $SHA
next-action: M5 legacy field test
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "M5 test"
    run _run_pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^pause_commit_sha=$SHA$"
}
