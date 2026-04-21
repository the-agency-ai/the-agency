#!/usr/bin/env bats
# test-session-pause.bats — unit tests for agency/tools/session-pause
#
# Covers A&D v3 §9.1 test matrix:
#   - CLI arg parsing (required args, invalid values)
#   - Identity resolution (--principal/--agent overrides)
#   - Clean tree handling (continuation + resumption framings)
#   - Dirty tree partitioning (coord vs non-coord + carve-outs)
#   - Coord classifier edge cases (usr/**, .claude/skills/**, agency/tools/**)
#   - Commit message format ("{trigger}: {agent} coord checkpoint")
#   - Handoff archival (existing, missing)
#   - Output shape (key=value, aborted emits error_reason)
#   - Lock contention + lock release
#   - Idempotency (double-PAUSE)
#   - Exit codes (0 ok, 1 aborted, 2 lock contention)
#
# Each test runs in an isolated tmp git repo via $BATS_TEST_TMPDIR so
# session-pause's REPO_ROOT (resolved from CLAUDE_PROJECT_DIR) points at
# the test sandbox, not the-agency itself.
#
# Session-lifecycle-refactor Plan v2 Iteration 2.1.

setup() {
    # Real tool under test — SCRIPT_DIR resolves from its own location,
    # so the tool will reach back to the real agency/tools/*
    # for sibling helpers (git-safe, git-safe-commit, agent-identity,
    # monitor-register). We override CLAUDE_PROJECT_DIR to scope dirty-
    # tree detection, handoff paths, and lock keys to the sandbox.
    TOOL="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)/agency/tools/session-pause"
    [[ -x "$TOOL" ]] || { echo "session-pause not executable at $TOOL" >&2; return 1; }

    # Sandbox git repo
    export REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$REPO"
    cd "$REPO"
    git init -q
    git config user.email test@example.com
    git config user.name "Test"
    git config commit.gpgsign false
    mkdir -p usr/testp/testa/history usr/testp/testa/dispatches
    touch usr/testp/testa/testa-handoff.md
    # Gitignore session-state that isn't meant for git:
    #   .claude/logs/     — tool telemetry (log_start/log_end writes here)
    # Mirrors the real the-agency .gitignore.
    # Must be committed in the INITIAL commit because .gitignore edits are
    # non-coord by session-pause's classifier (would otherwise abort).
    cat > .gitignore <<'EOF'
.claude/logs/
agency/config/monitor-pids.json
EOF
    git add usr/testp/testa/testa-handoff.md .gitignore
    git commit -qm "initial"

    export CLAUDE_PROJECT_DIR="$REPO"
    export AGENCY_PROJECT_ROOT="$REPO"
}

teardown() {
    # Kill any lingering lock directories outside the sandbox.
    rm -rf "${TMPDIR:-/tmp}"/agency-session-pause-*.lock 2>/dev/null || true
}

# ── Helpers ────────────────────────────────────────────────────────────────
_run_pause() {
    "$TOOL" --principal testp --agent testa "$@"
}

_emit_line() {
    # Extract the value for a given key=value line from output.
    local key="$1" output="$2"
    echo "$output" | awk -F= -v k="$key" '$1==k { for(i=2;i<=NF;i++){printf "%s%s", (i>2?"=":""), $i} print ""}'
}

# ── CLI arg parsing (3 tests) ──────────────────────────────────────────────

@test "missing --framing aborts with error_reason" {
    run "$TOOL" --trigger smoke --principal testp --agent testa
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*--framing"
}

@test "missing --trigger aborts with error_reason" {
    run "$TOOL" --framing continuation --principal testp --agent testa
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*--trigger"
}

@test "invalid --framing value aborts with error_reason" {
    run "$TOOL" --framing nonsense --trigger smoke --principal testp --agent testa
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*invalid"
}

# ── Identity override (2 tests) ────────────────────────────────────────────

@test "--principal override applies to handoff path" {
    mkdir -p usr/otherp/testa
    touch usr/otherp/testa/testa-handoff.md
    run "$TOOL" --framing continuation --trigger smoke --principal otherp --agent testa
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "handoff_path=.*usr/otherp/testa/testa-handoff.md"
}

@test "--agent override applies to handoff filename" {
    mkdir -p usr/testp/otheragent
    touch usr/testp/otheragent/otheragent-handoff.md
    run "$TOOL" --framing continuation --trigger smoke --principal testp --agent otheragent
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "handoff_path=.*usr/testp/otheragent/otheragent-handoff.md"
}

# ── Clean tree handling (2 tests) ──────────────────────────────────────────

@test "continuation framing on clean tree emits ok + commit_sha=none" {
    run _run_pause --framing continuation --trigger clean-test
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
    echo "$output" | grep -q "^commit_sha=none$"
    echo "$output" | grep -q "^framing=continuation$"
}

@test "resumption framing on clean tree emits ok + framing=resumption" {
    run _run_pause --framing resumption --trigger clean-resumption
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
    echo "$output" | grep -q "^framing=resumption$"
}

# ── Dirty tree partitioning (5 tests) ──────────────────────────────────────

@test "dirty tree with only coord files commits via coord checkpoint" {
    echo "edit" >> usr/testp/testa/testa-handoff.md
    echo "note" > usr/testp/testa/notes.md
    run _run_pause --framing continuation --trigger coord-dirty
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
    # commit_sha should NOT be "none"
    ! echo "$output" | grep -q "^commit_sha=none$"
}

@test "dirty tree with non-coord framework code aborts" {
    mkdir -p agency/tools
    echo "fake tool" > agency/tools/fake-tool
    run _run_pause --framing continuation --trigger noncoord-dirty
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*framework code uncommitted"
}

@test "dirty tree with mixed coord + non-coord aborts (non-coord dominates)" {
    echo "edit" >> usr/testp/testa/testa-handoff.md
    mkdir -p agency/tools
    echo "fake" > agency/tools/fake
    run _run_pause --framing continuation --trigger mixed-dirty
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
}

@test ".claude/settings.json is carved out (treated as non-coord → abort)" {
    mkdir -p .claude
    echo '{}' > .claude/settings.json
    run _run_pause --framing continuation --trigger settings-test
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "error_reason=.*framework code uncommitted"
    echo "$output" | grep -q ".claude/settings.json"
}

@test ".gitignore is carved out (treated as non-coord → abort)" {
    echo "*.log" > .gitignore
    run _run_pause --framing continuation --trigger gitignore-test
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "error_reason=.*framework code uncommitted"
    echo "$output" | grep -q ".gitignore"
}

# ── Coord classifier edge cases (3 tests) ──────────────────────────────────

@test "usr/{principal}/* classified as coord" {
    echo "ad-hoc file" > usr/testp/testa/random.txt
    run _run_pause --framing continuation --trigger usr-coord
    [ "$status" -eq 0 ]
    # random.txt should now be tracked + committed (not in status porcelain).
    # NOTE: a history/handoff-*.md archive remains untracked by design —
    # it's picked up by the next PAUSE as coord. So tree is not fully clean,
    # but random.txt specifically is committed.
    run git log -1 --name-only --format=''
    echo "$output" | grep -q "usr/testp/testa/random.txt"
}

@test ".claude/skills/*/SKILL.md classified as coord" {
    mkdir -p .claude/skills/smoke-skill
    echo "# smoke" > .claude/skills/smoke-skill/SKILL.md
    run _run_pause --framing continuation --trigger skill-coord
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
}

@test "agency/tools/* classified as non-coord (requires QG)" {
    mkdir -p agency/tools
    echo "#!/bin/bash" > agency/tools/new-tool
    run _run_pause --framing continuation --trigger tool-noncoord
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "agency/tools/new-tool"
}

# ── Commit message format (1 test) ─────────────────────────────────────────

@test "commit message follows {trigger}: {agent} coord checkpoint template" {
    echo "edit" >> usr/testp/testa/testa-handoff.md
    run _run_pause --framing continuation --trigger msg-test
    [ "$status" -eq 0 ]
    # git-safe-commit prepends {workstream}/{agent}: but our trigger portion
    # should appear verbatim.
    run git log -1 --format='%s'
    echo "$output" | grep -q "msg-test: testa coord checkpoint"
}

# ── Handoff archival (2 tests) ─────────────────────────────────────────────

@test "existing handoff is archived with timestamped filename" {
    echo "old content" > usr/testp/testa/testa-handoff.md
    run _run_pause --framing continuation --trigger archive-test
    [ "$status" -eq 0 ]
    archived=$(_emit_line archived_previous_handoff "$output")
    [ "$archived" != "none" ]
    [ -f "$archived" ]
    grep -q "old content" "$archived"
}

@test "no prior handoff emits archived_previous_handoff=none" {
    # Remove the default handoff so no archive happens
    rm usr/testp/testa/testa-handoff.md
    run _run_pause --framing continuation --trigger no-archive
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^archived_previous_handoff=none$"
}

# ── Output shape (2 tests) ─────────────────────────────────────────────────

@test "success output contains all 5 standard keys" {
    run _run_pause --framing continuation --trigger shape-test
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^handoff_path="
    echo "$output" | grep -q "^archived_previous_handoff="
    echo "$output" | grep -q "^commit_sha="
    echo "$output" | grep -q "^framing="
    echo "$output" | grep -q "^status=ok$"
}

@test "aborted output emits status=aborted AND error_reason=" {
    run "$TOOL" --framing bogus --trigger x --principal testp --agent testa
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "^error_reason="
}

# ── Lock (2 tests per MAR R1 P0) ───────────────────────────────────────────

@test "concurrent PAUSE: second call exits 2 (lock contention)" {
    # Manually create the lock directory to simulate contention
    LOCK_KEY=$(python3 -c 'import hashlib, sys; print(hashlib.sha1(sys.argv[1].encode()).hexdigest()[:16])' \
        "$REPO/usr/testp/testa/testa-handoff.md")
    LOCK_DIR="${TMPDIR:-/tmp}/agency-session-pause-${LOCK_KEY}.lock"
    mkdir "$LOCK_DIR"
    # Write a running PID into the lock so stale-detection doesn't kick in.
    echo $$ > "$LOCK_DIR/pid"

    # Real PAUSE should now time out after 5s and return exit 2.
    run _run_pause --framing continuation --trigger lock-test
    [ "$status" -eq 2 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*lock timeout"

    # Cleanup
    rm -rf "$LOCK_DIR"
}

@test "lock is released after successful PAUSE" {
    run _run_pause --framing continuation --trigger release-test
    [ "$status" -eq 0 ]
    LOCK_KEY=$(python3 -c 'import hashlib, sys; print(hashlib.sha1(sys.argv[1].encode()).hexdigest()[:16])' \
        "$REPO/usr/testp/testa/testa-handoff.md")
    LOCK_DIR="${TMPDIR:-/tmp}/agency-session-pause-${LOCK_KEY}.lock"
    [ ! -d "$LOCK_DIR" ]
}

# ── Idempotency (2 tests per MAR P0) ───────────────────────────────────────

@test "double PAUSE on clean tree is safe (second call succeeds)" {
    run _run_pause --framing continuation --trigger double-1
    [ "$status" -eq 0 ]
    run _run_pause --framing continuation --trigger double-2
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
}

@test "second PAUSE after first is safe — back-to-back idempotency" {
    echo "edit" >> usr/testp/testa/testa-handoff.md
    run _run_pause --framing continuation --trigger idem-1
    [ "$status" -eq 0 ]
    # First call committed the handoff edit AND created an untracked archive
    # in history/. The second call sees the archive as a coord file and
    # commits it. commit_sha will be a real SHA (not "none") — this is the
    # architectural tradeoff: each PAUSE's archive is committed by the NEXT
    # PAUSE. Both calls succeed; no error, no lock contention.
    run _run_pause --framing continuation --trigger idem-2
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
}

# ── Monitor stop (2 tests per A&D §3.2 step 5) ─────────────────────────────

@test "resumption framing with empty monitor registry is a no-op (no error)" {
    # Ensure no registry exists
    rm -f agency/config/monitor-pids.json 2>/dev/null || true
    run _run_pause --framing resumption --trigger no-monitors
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^framing=resumption$"
    echo "$output" | grep -q "^status=ok$"
}

@test "continuation framing does NOT attempt to stop monitors" {
    # Pre-populate a registry with a fake entry. If continuation tried to
    # stop monitors, it would fail verify and maybe emit stderr. It should
    # not touch the registry at all.
    mkdir -p agency/config
    cat > agency/config/monitor-pids.json <<'EOF'
[{"pid": 99999, "start_time_epoch": 0, "cmdline_hash": "fake", "monitor_type": "dispatch", "registered_at": "2026-04-20T00:00:00Z"}]
EOF
    run _run_pause --framing continuation --trigger monitors-survive
    [ "$status" -eq 0 ]
    # Registry unchanged
    grep -q "99999" agency/config/monitor-pids.json
}

# ── Exit codes (1 test) ────────────────────────────────────────────────────

@test "exit code 2 is specific to lock contention (distinct from exit 1 abort)" {
    # Exit 1: aborted for any non-lock reason
    run "$TOOL" --framing bogus --trigger x --principal testp --agent testa
    [ "$status" -eq 1 ]

    # Exit 2: only for lock timeout
    LOCK_KEY=$(python3 -c 'import hashlib, sys; print(hashlib.sha1(sys.argv[1].encode()).hexdigest()[:16])' \
        "$REPO/usr/testp/testa/testa-handoff.md")
    LOCK_DIR="${TMPDIR:-/tmp}/agency-session-pause-${LOCK_KEY}.lock"
    mkdir "$LOCK_DIR"
    echo $$ > "$LOCK_DIR/pid"

    run _run_pause --framing continuation --trigger lock2
    [ "$status" -eq 2 ]

    rm -rf "$LOCK_DIR"
}

# ── QG-iteration-complete hardening tests (added 2026-04-20 per reviewer findings) ──

# Sec-1: symlink handoff must be refused, not followed
@test "handoff that is a symlink is refused with clear error_reason" {
    rm -f usr/testp/testa/testa-handoff.md
    # Point the handoff at an unrelated file to simulate a malicious symlink
    echo "target content" > "$BATS_TEST_TMPDIR/other-file.txt"
    ln -sf "$BATS_TEST_TMPDIR/other-file.txt" usr/testp/testa/testa-handoff.md
    run _run_pause --framing continuation --trigger symlink-test
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*symlink.*refusing to archive"
}

# Sec-2: principal whitelist rejects path-traversal sequences
@test "--principal with path-traversal is rejected" {
    run "$TOOL" --framing continuation --trigger sec2 --principal "../../etc" --agent testa
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "error_reason=.*invalid --principal"
}

@test "--agent with path-traversal is rejected" {
    run "$TOOL" --framing continuation --trigger sec2b --principal testp --agent "../evil"
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "error_reason=.*invalid --agent"
}

# Sec-3: trigger control chars rejected (prevents commit-log-injection)
@test "--trigger with newline is rejected" {
    run _run_pause --framing continuation --trigger "line1
line2"
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "error_reason=.*control characters"
}

@test "--trigger overlong (>128 chars) is rejected" {
    longstr=$(printf 'a%.0s' {1..200})
    run _run_pause --framing continuation --trigger "$longstr"
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "error_reason=.*exceeds 128"
}

# A3: schema_version + tool_version must be in output
@test "success output emits schema_version=1 and tool_version" {
    run _run_pause --framing continuation --trigger schema-test
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^schema_version=1$"
    echo "$output" | grep -qE "^tool_version=[0-9]+\.[0-9]+\.[0-9]+$"
}

# F10: renamed file in porcelain is classified on the NEW path
@test "renamed file in porcelain uses the new path for classification" {
    # Create + commit a coord file, then git mv it to another coord path
    echo "old" > usr/testp/testa/renamed-old.md
    git add usr/testp/testa/renamed-old.md
    git commit -qm "pre-rename"
    git mv usr/testp/testa/renamed-old.md usr/testp/testa/renamed-new.md
    run _run_pause --framing continuation --trigger rename-test
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
    # The new path should be in the commit
    run git log -1 --name-only --format=''
    echo "$output" | grep -q "usr/testp/testa/renamed-new.md"
}

# T3 / F9: identity resolver fallback — unset overrides + break agent-identity
# via CLAUDE_AGENT_NAME="" + no .claude-agent + on an unknown branch must abort
# with a clear "could not resolve" message. We sidestep agent-identity by
# blocking PATH for it — simpler: pass only --principal and drop --agent, then
# expect "could not resolve agent" (since no override and agent-identity in
# the test sandbox resolves to a different value than expected).
@test "missing both --principal and --agent falls back to agent-identity (may resolve or abort gracefully)" {
    # No agent-identity file in sandbox; agent-identity will try git branch
    # detection, which will resolve to 'captain' (master branch default).
    # Either path is acceptable — the goal is: don't crash, emit structured output.
    run "$TOOL" --framing continuation --trigger identity-fallback
    # Must exit 0 (successful resolve) OR exit 1 with structured aborted+error_reason
    if [ "$status" -eq 0 ]; then
        echo "$output" | grep -q "^status=ok$"
    else
        [ "$status" -eq 1 ]
        echo "$output" | grep -q "^status=aborted$"
        echo "$output" | grep -qE "error_reason=.*(could not resolve|invalid --(principal|agent)|cannot)"
    fi
}

# F4: positive coord tests for framework paths beyond .claude/skills/
@test "agency/config/* classified as coord" {
    mkdir -p agency/config
    echo "foo: bar" > agency/config/smoke.yaml
    run _run_pause --framing continuation --trigger config-coord
    [ "$status" -eq 0 ]
    run git log -1 --name-only --format=''
    echo "$output" | grep -q "agency/config/smoke.yaml"
}

@test "agency/hookify/* classified as coord" {
    mkdir -p agency/hookify
    echo "# rule" > agency/hookify/smoke-rule.md
    run _run_pause --framing continuation --trigger hookify-coord
    [ "$status" -eq 0 ]
    run git log -1 --name-only --format=''
    echo "$output" | grep -q "agency/hookify/smoke-rule.md"
}

@test "agency/CLAUDE-*.md classified as coord" {
    mkdir -p agency
    echo "# agency instructions" > agency/CLAUDE-SMOKE.md
    run _run_pause --framing continuation --trigger agencymd-coord
    [ "$status" -eq 0 ]
    run git log -1 --name-only --format=''
    echo "$output" | grep -q "agency/CLAUDE-SMOKE.md"
}

# F5: non-coord carve-outs symmetric to agency/tools/*
@test "apps/* classified as non-coord (aborts)" {
    mkdir -p apps/backend/src
    echo "const x = 1;" > apps/backend/src/smoke.ts
    run _run_pause --framing continuation --trigger apps-noncoord
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "apps/backend/src/smoke.ts"
}

@test "packages/* classified as non-coord (aborts)" {
    mkdir -p packages/ui/src
    echo "export const y = 2;" > packages/ui/src/smoke.ts
    run _run_pause --framing continuation --trigger pkg-noncoord
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "packages/ui/src/smoke.ts"
}

# F15 + B13-B16 contract: filesystem-level failure in the coord pipeline
# always emits structured status=aborted + error_reason (never a silent
# set -e exit-1). Strategy: make the handoff unreadable so an error surfaces
# somewhere in the dirty-scan / stage / commit / archive pipeline. The
# specific abort message varies (git-safe-add vs cp), but the CONTRACT is
# that exit 1 always comes with both status= and error_reason= keys.
@test "filesystem failure in coord pipeline always emits structured abort" {
    chmod 000 usr/testp/testa/testa-handoff.md 2>/dev/null || skip "cannot change permissions"
    run _run_pause --framing continuation --trigger archive-fail
    chmod 644 usr/testp/testa/testa-handoff.md 2>/dev/null || true
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "^error_reason="
}

# ── Handoff force-commit (v1.2.0 — principal directive, the-agency#355) ──

# F-HC1: When framework code is dirty AND handoff is dirty, handoff is force-committed first.
@test "handoff force-commit: dirty handoff + dirty framework code → handoff persisted, then abort" {
    echo "note added mid-session" >> usr/testp/testa/testa-handoff.md
    mkdir -p agency/tools
    echo "// wip framework code" > agency/tools/some-tool
    run _run_pause --framing continuation --trigger force-commit-test
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    # The handoff force-commit SHA must be emitted + non-none
    echo "$output" | grep -qE "^handoff_commit_sha=[0-9a-f]{40}$"
    ! echo "$output" | grep -q "^handoff_commit_sha=none$"
    # Error mentions framework code + hints the handoff was persisted
    echo "$output" | grep -q "error_reason=.*framework code uncommitted"
    echo "$output" | grep -q "error_reason=.*Handoff persisted"
    # The handoff file itself is NOT in git status anymore (it was committed)
    run git status --porcelain -uall
    ! echo "$output" | grep -q "testa-handoff.md"
    # Framework file IS still dirty (not committed)
    echo "$output" | grep -q "agency/tools/some-tool"
}

# F-HC2: Clean handoff + dirty framework code → no handoff force-commit, just abort.
@test "handoff force-commit: clean handoff + dirty framework → no force-commit, handoff_commit_sha=none" {
    # Handoff clean (from setup). Only framework code dirty.
    mkdir -p agency/tools
    echo "// wip" > agency/tools/only-framework
    run _run_pause --framing continuation --trigger no-handoff-force
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -q "^handoff_commit_sha=none$"
    echo "$output" | grep -q "error_reason=.*framework code uncommitted"
    # Error does NOT mention "Handoff persisted" (because none was)
    ! echo "$output" | grep -q "error_reason=.*Handoff persisted"
}

# F-HC3: Dirty handoff + other coord + dirty framework → ONLY handoff is force-committed.
@test "handoff force-commit: only handoff is committed, other coord stays dirty until abort" {
    echo "handoff note" >> usr/testp/testa/testa-handoff.md
    echo "seed content" > usr/testp/testa/seeds-note.md
    mkdir -p agency/tools
    echo "// wip" > agency/tools/other-tool
    run _run_pause --framing continuation --trigger selective-force
    [ "$status" -eq 1 ]
    echo "$output" | grep -q "^status=aborted$"
    echo "$output" | grep -qE "^handoff_commit_sha=[0-9a-f]{40}$"
    # Handoff is NOT dirty anymore
    run git status --porcelain -uall
    ! echo "$output" | grep -q "testa-handoff.md"
    # But the other coord file (seeds-note.md) IS still dirty — only handoff
    # got the force-commit, not every coord file. This is intentional per
    # Option B design (handoff lane separate from coord-checkpoint lane).
    echo "$output" | grep -q "seeds-note.md"
    # Framework file still dirty too
    echo "$output" | grep -q "agency/tools/other-tool"
}

# F-HC4: Happy path — only handoff dirty, no framework → normal coord checkpoint, handoff_commit_sha=none.
@test "handoff force-commit: only handoff dirty (no framework) → normal checkpoint, handoff_commit_sha=none" {
    echo "routine edit" >> usr/testp/testa/testa-handoff.md
    run _run_pause --framing continuation --trigger normal-path
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
    # No force-commit in the happy path — handoff goes through as part of
    # the normal coord checkpoint.
    echo "$output" | grep -q "^handoff_commit_sha=none$"
    # commit_sha IS set — the normal checkpoint happened.
    ! echo "$output" | grep -q "^commit_sha=none$"
}

# B22: test that a negative-pid entry in monitor registry does NOT call os.kill
# (can't easily assert negative — but we can assert the tool doesn't hang or crash)
@test "resumption with a malicious pid<=1 entry in monitor registry is safe" {
    mkdir -p agency/config
    # Registry with catastrophic PIDs: -1 (all-processes), 0 (process-group),
    # 1 (init). All should be filtered by the pid<=1 guard.
    cat > agency/config/monitor-pids.json <<'EOF'
[
  {"pid": -1, "start_time_epoch": 0, "cmdline_hash": "fake", "monitor_type": "dispatch", "registered_at": "2026-04-20T00:00:00Z"},
  {"pid": 0,  "start_time_epoch": 0, "cmdline_hash": "fake", "monitor_type": "ci",       "registered_at": "2026-04-20T00:00:00Z"},
  {"pid": 1,  "start_time_epoch": 0, "cmdline_hash": "fake", "monitor_type": "issue",    "registered_at": "2026-04-20T00:00:00Z"}
]
EOF
    run _run_pause --framing resumption --trigger malicious-pid
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "^status=ok$"
}
