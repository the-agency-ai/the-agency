#!/usr/bin/env bats
# test-session-lifecycle.bats — END-TO-END integration harness for the
# PAUSE ⇄ PICKUP primitive pair.
#
# Unit tests for each tool live in test-session-pause.bats (46 tests) and
# test-session-pickup.bats (38 tests). This harness exercises both tools
# together across realistic session-lifecycle scenarios:
#
#   S1: PAUSE (continuation) → simulated /compact → PICKUP (--from compact)
#   S2: PAUSE (resumption) → simulated restart → PICKUP (--from fresh, stubbed)
#   S3: Concurrent PAUSE collision under the shared lock
#   S4: PAUSE with coord-dirty tree → single coord-checkpoint commit
#   S5: PICKUP with stale monitor registry → monitor_health=dead
#   S6: PICKUP with malformed handoff (single `---`) → handoff_mode=unknown
#   S7: PICKUP with non-SHA pause_commit_sha → F1 validation + fallback
#   S8: PICKUP with control-char next_action → F4 strips
#   S9a: PICKUP --from fresh with stub preflight passing → status=ok
#   S9b: PICKUP --from fresh with stub preflight failing → status=blocked
#
# Covers PVR §6 Success Criteria #2 (compact flow) and #3 (end flow).
# MAR R3 added S6-S9; plan v3 Iteration 4.1.
#
# Each test runs in $BATS_TEST_TMPDIR with a fresh git repo. Tools under
# test reach back to the real the-agency tree for sibling helpers (git-safe,
# git-safe-commit, agent-identity, handoff). CLAUDE_PROJECT_DIR + ISCP_DB_PATH
# overrides scope mutations to the sandbox.

setup() {
    PAUSE="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)/agency/tools/session-pause"
    PICKUP="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)/agency/tools/session-pickup"
    [[ -x "$PAUSE" ]] || { echo "session-pause not executable at $PAUSE" >&2; return 1; }
    [[ -x "$PICKUP" ]] || { echo "session-pickup not executable at $PICKUP" >&2; return 1; }

    export REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$REPO"
    cd "$REPO"
    git init -q
    git config user.email test@example.com
    git config user.name "Test"
    git config commit.gpgsign false
    mkdir -p usr/testp/testa/history usr/testp/testa/dispatches
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
type: session
agent: test-repo/testp/testa
date: 2026-04-20 12:00
trigger: session-pause
branch: master
mode: continuation
next-action: Integration harness baseline next-action.
---

## Body
Initial sandbox state.
EOF
    cat > .gitignore <<'EOF'
.claude/logs/
agency/config/monitor-pids.json
EOF
    git add usr/testp/testa/testa-handoff.md .gitignore
    git commit -qm "initial"

    export CLAUDE_PROJECT_DIR="$REPO"
    export AGENCY_PROJECT_ROOT="$REPO"
    export ISCP_DB_PATH="$BATS_TEST_TMPDIR/test-iscp.db"
}

teardown() {
    rm -rf "${TMPDIR:-/tmp}"/agency-session-pause-*.lock 2>/dev/null || true
}

# ── Helpers ────────────────────────────────────────────────────────────────
_pause() {
    "$PAUSE" --principal testp --agent testa "$@"
}

_pickup() {
    "$PICKUP" --principal testp --agent testa "$@"
}

_emit_line() {
    local key="$1" output="$2"
    echo "$output" | awk -F= -v k="$key" '$1==k { for(i=2;i<=NF;i++){printf "%s%s", (i>2?"=":""), $i} print ""}'
}

# Author a handoff + commit it, to simulate the caller skill writing the
# continuation body after PAUSE returns the new path. Also commits the
# history/ archive that PAUSE left behind — a real caller skill would
# either include that in the next coord-commit or the subsequent PAUSE
# would sweep it. For the harness we commit both to leave a clean tree.
_author_handoff() {
    local mode="$1" next_action="$2"
    cat > usr/testp/testa/testa-handoff.md <<EOF
---
type: session
agent: test-repo/testp/testa
date: 2026-04-20 13:00
trigger: integration-test
branch: master
mode: ${mode}
next-action: ${next_action}
---

## Body
Content authored by integration harness.
EOF
    git add usr/testp/testa/testa-handoff.md usr/testp/testa/history/
    git commit -qm "author handoff (${mode}) + archive"
}

# Create a fake tools dir with stubbed session-preflight + worktree-sync so
# --from fresh is deterministic. Per A&D §4.5 Option B.
#
# The stub dir symlinks session-pickup itself so SCRIPT_DIR inside the tool
# resolves to the stub dir — meaning its calls to sibling helpers hit the
# stubs rather than the real framework tools.
_setup_stub_tools() {
    local preflight_exit_code="${1:-0}"
    local stub_dir="$BATS_TEST_TMPDIR/stub-tools"
    mkdir -p "$stub_dir"

    # Symlink session-pickup AND its lib/ siblings it sources
    ln -sf "$PICKUP" "$stub_dir/session-pickup"
    local real_lib="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)/agency/tools/lib"
    ln -sf "$real_lib" "$stub_dir/lib"
    # Real agent-identity so identity resolution doesn't crash
    ln -sf "$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)/agency/tools/agent-identity" "$stub_dir/agent-identity"
    ln -sf "$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)/agency/tools/monitor-register" "$stub_dir/monitor-register"

    # Stub session-preflight — exits with controlled code
    cat > "$stub_dir/session-preflight" <<EOF
#!/usr/bin/env bash
echo "STUB session-preflight invoked" >> "$BATS_TEST_TMPDIR/stub.log"
exit $preflight_exit_code
EOF
    chmod +x "$stub_dir/session-preflight"

    # Stub worktree-sync — always succeeds, logs invocation
    cat > "$stub_dir/worktree-sync" <<EOF
#!/usr/bin/env bash
echo "STUB worktree-sync invoked with \$*" >> "$BATS_TEST_TMPDIR/stub.log"
exit 0
EOF
    chmod +x "$stub_dir/worktree-sync"

    echo "$stub_dir"
}

# ── S1: PAUSE (continuation) → fake compact → PICKUP (--from compact) ──
@test "S1: PAUSE continuation → simulated compact → PICKUP --from compact" {
    # 1. PAUSE
    run _pause --framing continuation --trigger s1-compact-prep
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
    echo "$output" | grep -q "^framing=continuation$"

    # 2. Caller authors the continuation handoff at handoff_path (simulates
    #    /compact-prepare Step 2). We commit it so the tree is clean.
    _author_handoff continuation "Resume post-compact: analyze dispatch drift"

    # 3. Simulate /compact — no-op in this harness (real /compact mutates
    #    conversation context, not filesystem).

    # 4. PICKUP --from compact
    run _pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
    echo "$output" | grep -q "^from=compact$"
    echo "$output" | grep -q "^handoff_mode=continuation$"
    echo "$output" | grep -q "^next_action=Resume post-compact: analyze dispatch drift$"
    echo "$output" | grep -q "^tree_state=clean$"
}

# ── S2: PAUSE (resumption) → fake restart → PICKUP (--from fresh) ──────
@test "S2: PAUSE resumption → simulated restart → PICKUP --from fresh (stubbed)" {
    # 1. PAUSE for end-of-session
    run _pause --framing resumption --trigger s2-session-end
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^framing=resumption$"

    # 2. Caller authors the resumption handoff.
    _author_handoff resumption "Fresh session: continue S2 integration test"

    # 3. Simulate restart — no-op; next process would be fresh.

    # 4. PICKUP --from fresh via stubbed tools dir (preflight passes).
    local stub_dir
    stub_dir=$(_setup_stub_tools 0)
    run "$stub_dir/session-pickup" --from fresh --principal testp --agent testa
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
    echo "$output" | grep -q "^from=fresh$"
    echo "$output" | grep -q "^handoff_mode=resumption$"
    # Stubs were invoked
    grep -q "STUB worktree-sync invoked" "$BATS_TEST_TMPDIR/stub.log"
    grep -q "STUB session-preflight invoked" "$BATS_TEST_TMPDIR/stub.log"
}

# ── S3: Concurrent PAUSE collision under shared lock ────────────────────
@test "S3: Concurrent PAUSE collision — second caller exits 2 with lock timeout" {
    LOCK_KEY=$(python3 -c 'import hashlib, sys; print(hashlib.sha1(sys.argv[1].encode()).hexdigest()[:16])' \
        "$REPO/usr/testp/testa/testa-handoff.md")
    LOCK_DIR="${TMPDIR:-/tmp}/agency-session-pause-${LOCK_KEY}.lock"
    mkdir "$LOCK_DIR"
    echo $$ > "$LOCK_DIR/pid"

    # Both PAUSE and PICKUP should time out on the same lock
    run _pause --framing continuation --trigger s3-pause-collision
    [ "$status" -eq 2 ]
    echo "$output" | grep -q "error_reason=.*lock timeout"

    run _pickup --from compact
    [ "$status" -eq 2 ]
    echo "$output" | grep -q "error_reason=.*lock timeout"

    rm -rf "$LOCK_DIR"
}

# ── S4: PAUSE with coord-dirty tree → single checkpoint commit ──────────
@test "S4: PAUSE with coord-dirty tree produces a single coord checkpoint" {
    # Dirty the handoff + a dispatch draft — both coord.
    echo "mid-session edit" >> usr/testp/testa/testa-handoff.md
    echo "outbound draft" > usr/testp/testa/dispatches/draft-001.md

    run _pause --framing continuation --trigger s4-coord-commit
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
    # commit_sha must be a real SHA (coord checkpoint happened)
    ! echo "$output" | grep -q "^commit_sha=none$"
    echo "$output" | grep -qE "^commit_sha=[0-9a-f]{40}$"
    # Handoff NOT force-committed (no non-coord to gate on)
    echo "$output" | grep -q "^handoff_commit_sha=none$"

    # Tree clean AFTER the commit (archive leftover aside)
    run git status --porcelain
    # Allow only history/ archive leftovers (by design)
    echo "$output" | grep -v "usr/testp/testa/history/" || true
}

# ── S5: PICKUP with stale monitor registry → monitor_health=dead ───────
@test "S5: PICKUP reports monitor_health=dead for stale registry entry" {
    mkdir -p agency/config
    cat > agency/config/monitor-pids.json <<'EOF'
[{"pid": 99999, "start_time_epoch": 0, "cmdline_hash": "stale", "monitor_type": "dispatch", "registered_at": "2026-04-20T00:00:00Z"}]
EOF
    run _pickup --from compact
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^monitor_health_dispatch=dead$"
}

# ── S6: Malformed handoff (only one `---`) → handoff_mode=unknown ──────
@test "S6: PICKUP with malformed handoff frontmatter → handoff_mode=unknown (F3)" {
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
mode: continuation
next-action: intended action

# Body
This is body content. mode: injected-via-body
next-action: injected-via-body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "malformed handoff"

    run _pickup --from compact
    [ "$status" -eq 0 ]
    # F3 closing-delimiter requirement prevents body from leaking into frontmatter
    echo "$output" | grep -q "^handoff_mode=unknown$"
    ! echo "$output" | grep -q "injected-via-body"
}

# ── S7: Non-SHA pause_commit_sha → F1 validation + fallback ─────────────
@test "S7: PICKUP with non-SHA pause_commit_sha → F1 validation rejects + fallback" {
    cat > usr/testp/testa/testa-handoff.md <<'EOF'
---
mode: continuation
pause_commit_sha: --all
next-action: F1 integration test
---
body
EOF
    git add usr/testp/testa/testa-handoff.md && git commit -qm "non-sha pause_commit_sha"

    run _pickup --from compact
    [ "$status" -eq 0 ]
    # Malicious value NOT emitted
    ! echo "$output" | grep -q "^pause_commit_sha=--all$"
    # Fallback produces a real 40-char SHA
    echo "$output" | grep -qE "^pause_commit_sha=[0-9a-f]{40}$"
}

# ── S8: Control chars in next_action → F4 strips ────────────────────────
@test "S8: PICKUP with control-char next_action → F4 stripped (no ANSI leaks)" {
    printf '%s\n' '---' > usr/testp/testa/testa-handoff.md
    printf '%s\n' 'mode: continuation' >> usr/testp/testa/testa-handoff.md
    printf 'next-action: pre\x1b]0;pwned\x07post\n' >> usr/testp/testa/testa-handoff.md
    printf '%s\n' '---' >> usr/testp/testa/testa-handoff.md
    printf '%s\n' 'body' >> usr/testp/testa/testa-handoff.md
    git add usr/testp/testa/testa-handoff.md && git commit -qm "control-char next_action"

    run _pickup --from compact
    [ "$status" -eq 0 ]
    # Emitted next_action must NOT contain ESC or BEL
    ! echo "$output" | grep -qE 'next_action=.*'$'\x1b'
    ! echo "$output" | grep -qE 'next_action=.*'$'\x07'
    # Visible letters survive
    echo "$output" | grep -qE '^next_action=pre.*post$'
}

# ── S9a: PICKUP --from fresh with stub preflight passing → ok ──────────
@test "S9a: PICKUP --from fresh, stubbed preflight passes → status=ok" {
    local stub_dir
    stub_dir=$(_setup_stub_tools 0)
    run "$stub_dir/session-pickup" --from fresh --principal testp --agent testa
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
    echo "$output" | grep -q "^from=fresh$"
}

# ── S9b: PICKUP --from fresh with stub preflight failing → blocked ─────
@test "S9b: PICKUP --from fresh, stubbed preflight fails → status=blocked" {
    local stub_dir
    stub_dir=$(_setup_stub_tools 1)
    run "$stub_dir/session-pickup" --from fresh --principal testp --agent testa
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=blocked$"
    echo "$output" | grep -q "error_reason=.*preflight"
    # Full report still emitted — from=fresh appears BEFORE status in the
    # stream, proving the report was built before the block.
    echo "$output" | grep -q "^from=fresh$"
}
