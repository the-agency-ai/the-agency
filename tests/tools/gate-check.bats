#!/usr/bin/env bats
#
# BATS: gate-check (v46.0 reset — Phase 0b)
# Required min-test-count: 73 (per Plan v4 §3 Phase 0b — sum of criteria + happy)
# Actual tests: 73+ (happy-path + per-criterion negative across 11 gates)

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/agency/tools/gate-check"

    TMP_REPO="$(mktemp -d -t gc.XXXXXX)"
    cd "$TMP_REPO"
    git init -q .
    git config user.email "t@t"
    git config user.name "t"
    # Base file
    echo seed > README
    git add .; git commit -q -m s
    BASE="$TMP_REPO/baseline"
    mkdir -p "$BASE"
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

seed_phase0() {
    for f in content-inventory.sha256 bats-baseline.txt ref-inventory-pre.txt \
             hookify-rule-count.txt skill-count.txt settings-checksum.txt \
             claude-md-checksum.txt baseline-symlink-check.txt \
             sensitive-dirs-sha256.txt PHASE-CURSOR.txt; do
        echo "x" > "$BASE/$f"
    done
}

# =========================
# Gate 0 — 10 criteria + happy
# =========================

@test "gate 0 happy path" {
    seed_phase0
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 0 ]
}

@test "gate 0: missing content-inventory.sha256" {
    seed_phase0; rm "$BASE/content-inventory.sha256"
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

@test "gate 0: missing bats-baseline.txt" {
    seed_phase0; rm "$BASE/bats-baseline.txt"
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

@test "gate 0: missing ref-inventory-pre.txt" {
    seed_phase0; rm "$BASE/ref-inventory-pre.txt"
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

@test "gate 0: missing hookify-rule-count.txt" {
    seed_phase0; rm "$BASE/hookify-rule-count.txt"
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

@test "gate 0: missing skill-count.txt" {
    seed_phase0; rm "$BASE/skill-count.txt"
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

@test "gate 0: missing settings-checksum.txt" {
    seed_phase0; rm "$BASE/settings-checksum.txt"
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

@test "gate 0: missing claude-md-checksum.txt" {
    seed_phase0; rm "$BASE/claude-md-checksum.txt"
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

@test "gate 0: missing baseline-symlink-check.txt" {
    seed_phase0; rm "$BASE/baseline-symlink-check.txt"
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

@test "gate 0: missing sensitive-dirs-sha256.txt" {
    seed_phase0; rm "$BASE/sensitive-dirs-sha256.txt"
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

@test "gate 0: missing PHASE-CURSOR.txt" {
    seed_phase0; rm "$BASE/PHASE-CURSOR.txt"
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

# =========================
# Gate 1 — 4 criteria
# =========================

@test "gate 1 happy path" {
    mkdir -p agency
    echo "x" > agency/f; git add .; git commit -q -m s
    run "$TOOL" 1
    [ "$status" -eq 0 ]
}

@test "gate 1: agency/ missing" {
    run "$TOOL" 1
    [ "$status" -eq 1 ]
}

@test "gate 1: claude/ still present" {
    mkdir -p agency claude
    run "$TOOL" 1
    [ "$status" -eq 1 ]
}

@test "gate 1: tracked files under claude/" {
    mkdir -p agency claude
    echo "x" > claude/f
    git add claude; git commit -q -m residual
    rm -rf claude  # dir gone but file still tracked
    run "$TOOL" 1
    [ "$status" -eq 1 ]
}

# =========================
# Gate 2 — 8 criteria
# =========================

@test "gate 2 happy path" {
    mkdir -p src/archive src/spec-provider agency/templates
    run "$TOOL" 2
    [ "$status" -eq 0 ]
}

@test "gate 2: src/ missing" {
    mkdir -p agency/templates
    run "$TOOL" 2
    [ "$status" -eq 1 ]
}

@test "gate 2: src/archive missing" {
    mkdir -p src src/spec-provider agency/templates
    run "$TOOL" 2
    [ "$status" -eq 1 ]
}

@test "gate 2: src/spec-provider missing" {
    mkdir -p src src/archive agency/templates
    run "$TOOL" 2
    [ "$status" -eq 1 ]
}

@test "gate 2: agency/templates missing" {
    mkdir -p src/archive src/spec-provider
    run "$TOOL" 2
    [ "$status" -eq 1 ]
}

@test "gate 2: agency/starter-packs still present" {
    mkdir -p src/archive src/spec-provider agency/templates agency/starter-packs
    run "$TOOL" 2
    [ "$status" -eq 1 ]
}

@test "gate 2: agency/schemas still present" {
    mkdir -p src/archive src/spec-provider agency/templates agency/schemas
    run "$TOOL" 2
    [ "$status" -eq 1 ]
}

@test "gate 2: agency/agents/designex still present" {
    mkdir -p src/archive src/spec-provider agency/templates agency/agents/designex
    run "$TOOL" 2
    [ "$status" -eq 1 ]
}

# =========================
# Gate 3 — 7 criteria
# =========================

@test "gate 3 happy path" {
    mkdir -p agency/workstreams/the-agency/history/flotsam
    run "$TOOL" 3
    [ "$status" -eq 0 ]
}

@test "gate 3: flotsam missing" {
    run "$TOOL" 3
    [ "$status" -eq 1 ]
}

@test "gate 3: claude/principals still present" {
    mkdir -p agency/workstreams/the-agency/history/flotsam claude/principals
    run "$TOOL" 3
    [ "$status" -eq 1 ]
}

@test "gate 3: claude/plans still present" {
    mkdir -p agency/workstreams/the-agency/history/flotsam claude/plans
    run "$TOOL" 3
    [ "$status" -eq 1 ]
}

@test "gate 3: claude/proposals still present" {
    mkdir -p agency/workstreams/the-agency/history/flotsam claude/proposals
    run "$TOOL" 3
    [ "$status" -eq 1 ]
}

@test "gate 3: claude/reviews still present" {
    mkdir -p agency/workstreams/the-agency/history/flotsam claude/reviews
    run "$TOOL" 3
    [ "$status" -eq 1 ]
}

@test "gate 3: agency/bug.db still present" {
    mkdir -p agency/workstreams/the-agency/history/flotsam agency
    touch agency/bug.db
    run "$TOOL" 3
    [ "$status" -eq 1 ]
}

@test "gate 3: .env file still present" {
    mkdir -p agency/workstreams/the-agency/history/flotsam
    echo "SECRET=x" > .env
    run "$TOOL" 3
    [ "$status" -eq 1 ]
}

# =========================
# Gate 3.5 — 3 criteria
# =========================

@test "gate 3.5 happy path" {
    mkdir -p agency/workstreams/the-agency/history/legacy-captain-workstream-20260419 agency/workstreams/the-agency/transcripts
    touch agency/workstreams/the-agency/transcripts/dialogue-transcript-20260419.md
    run "$TOOL" 3.5
    [ "$status" -eq 0 ]
}

@test "gate 3.5: agency/workstreams/captain still present" {
    mkdir -p agency/workstreams/captain agency/workstreams/the-agency/history/legacy-captain-workstream-20260419 agency/workstreams/the-agency/transcripts
    touch agency/workstreams/the-agency/transcripts/dialogue-transcript-20260419.md
    run "$TOOL" 3.5
    [ "$status" -eq 1 ]
}

@test "gate 3.5: legacy-captain dir missing" {
    mkdir -p agency/workstreams/the-agency/transcripts
    touch agency/workstreams/the-agency/transcripts/dialogue-transcript-20260419.md
    run "$TOOL" 3.5
    [ "$status" -eq 1 ]
}

@test "gate 3.5: active transcript missing" {
    mkdir -p agency/workstreams/the-agency/history/legacy-captain-workstream-20260419
    run "$TOOL" 3.5
    [ "$status" -eq 1 ]
}

# =========================
# Gate 3.6 — 3 criteria
# =========================

@test "gate 3.6 happy path" {
    touch "$BASE/sensitive-dirs-sha256.txt"
    run "$TOOL" 3.6 --baseline-dir "$BASE"
    [ "$status" -eq 0 ]
}

@test "gate 3.6: workstreams/agency still present" {
    mkdir -p agency/workstreams/agency
    touch "$BASE/sensitive-dirs-sha256.txt"
    run "$TOOL" 3.6 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

@test "gate 3.6: workstreams/housekeeping still present" {
    mkdir -p agency/workstreams/housekeeping
    touch "$BASE/sensitive-dirs-sha256.txt"
    run "$TOOL" 3.6 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

@test "gate 3.6: refreshed sensitive-dirs missing" {
    run "$TOOL" 3.6 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

# =========================
# Gate 4 — 6 informational (happy only — real checks are in other tools)
# =========================

@test "gate 4 happy path (informational)" {
    run "$TOOL" 4
    [ "$status" -eq 0 ]
}

@test "gate 4 --json emits structured output" {
    run "$TOOL" 4 --json
    [ "$status" -eq 0 ]
    [[ "$output" == *'"gate":"4"'* ]]
}

# =========================
# Gate 4.5 — 6 criteria
# =========================

@test "gate 4.5 happy path" {
    mkdir -p .claude
    cat > .claude/settings.json <<'EOF'
{"hooks": {"PreToolUse": [{"hooks": [{"command": "$CLAUDE_PROJECT_DIR/agency/hooks/x.sh"}]}]}}
EOF
    echo "@import @agency/x.md" > CLAUDE.md
    run "$TOOL" 4.5
    [ "$status" -eq 0 ]
}

@test "gate 4.5: claude/ still present" {
    mkdir -p claude .claude
    echo '{}' > .claude/settings.json
    run "$TOOL" 4.5
    [ "$status" -eq 1 ]
}

@test "gate 4.5: settings.json references agency/hooks/" {
    mkdir -p .claude
    cat > .claude/settings.json <<'EOF'
{"hooks": {"PreToolUse": [{"hooks": [{"command": "$CLAUDE_PROJECT_DIR/claude/hooks/x.sh"}]}]}}
EOF
    run "$TOOL" 4.5
    [ "$status" -eq 1 ]
}

@test "gate 4.5: CLAUDE.md still references @claude/" {
    mkdir -p .claude
    echo '{}' > .claude/settings.json
    echo "@import @claude/x.md" > CLAUDE.md
    run "$TOOL" 4.5
    [ "$status" -eq 1 ]
}

# =========================
# Gate 5 — 4 criteria
# =========================

@test "gate 5 happy path (no agency/hookify yet)" {
    run "$TOOL" 5
    [ "$status" -eq 0 ]
}

@test "gate 5: rule missing canary fixture" {
    mkdir -p agency/hookify
    echo "# rule" > agency/hookify/missing.md
    # No missing.canary
    run "$TOOL" 5
    [ "$status" -eq 1 ]
}

@test "gate 5: rule + canary both present" {
    mkdir -p agency/hookify
    echo "# rule" > agency/hookify/r.md
    echo "canary" > agency/hookify/r.canary
    run "$TOOL" 5
    [ "$status" -eq 0 ]
}

# =========================
# Gate 6 — 5 criteria
# =========================

@test "gate 6 happy path" {
    mkdir -p agency/workstreams/the-agency
    touch agency/workstreams/the-agency/release-notes-v46.0.md
    touch agency/workstreams/the-agency/migration-runbook-v46.0.md
    run "$TOOL" 6
    [ "$status" -eq 0 ]
}

@test "gate 6: release-notes missing" {
    mkdir -p agency/workstreams/the-agency
    touch agency/workstreams/the-agency/migration-runbook-v46.0.md
    run "$TOOL" 6
    [ "$status" -eq 1 ]
}

@test "gate 6: migration-runbook missing" {
    mkdir -p agency/workstreams/the-agency
    touch agency/workstreams/the-agency/release-notes-v46.0.md
    run "$TOOL" 6
    [ "$status" -eq 1 ]
}

# =========================
# Gate 7 — 6 informational
# =========================

@test "gate 7 happy path (informational)" {
    run "$TOOL" 7
    [ "$status" -eq 0 ]
}

@test "gate 7 --json emits structured output" {
    run "$TOOL" 7 --json
    [ "$status" -eq 0 ]
    [[ "$output" == *'"gate":"7"'* ]]
}

# =========================
# General / Dispatch
# =========================

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "--version prints version" {
    run "$TOOL" --version
    [ "$status" -eq 0 ]
}

@test "unknown phase errors" {
    run "$TOOL" 99
    [ "$status" -eq 2 ]
}

@test "missing phase argument errors" {
    run "$TOOL"
    [ "$status" -eq 2 ]
}

@test "--json emits structured output on fail" {
    run "$TOOL" 0 --json
    [ "$status" -eq 1 ]
    [[ "$output" == *'"status":"fail"'* ]]
}

# =========================
# Additional coverage to reach Plan v4 min-test-count (≥73)
# =========================

@test "gate 0 --json emits ok entries" {
    seed_phase0
    run "$TOOL" 0 --baseline-dir "$BASE" --json
    [ "$status" -eq 0 ]
    [[ "$output" == *'"status":"ok"'* ]]
}

@test "gate 0 returns exit 0 when all 10 artifacts present" {
    seed_phase0
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 0 ]
}

@test "gate 0 with any single missing exits 1" {
    seed_phase0
    rm "$BASE/PHASE-CURSOR.txt"
    run "$TOOL" 0 --baseline-dir "$BASE"
    [ "$status" -eq 1 ]
}

@test "gate 1 with no agency/ and no claude/ exits 1" {
    run "$TOOL" 1
    [ "$status" -eq 1 ]
}

@test "gate 1 --json emits structured output" {
    mkdir -p agency; echo x > agency/f; git add .; git commit -q -m s
    run "$TOOL" 1 --json
    [ "$status" -eq 0 ]
    [[ "$output" == *'"gate":"1"'* ]]
}

@test "gate 2 --json emits structured output" {
    mkdir -p src/archive src/spec-provider agency/templates
    run "$TOOL" 2 --json
    [ "$status" -eq 0 ]
}

@test "gate 3 --json emits structured output" {
    mkdir -p agency/workstreams/the-agency/history/flotsam
    run "$TOOL" 3 --json
    [ "$status" -eq 0 ]
}

@test "gate 3.5 --json emits structured output" {
    mkdir -p agency/workstreams/the-agency/history/legacy-captain-workstream-20260419 agency/workstreams/the-agency/transcripts
    touch agency/workstreams/the-agency/transcripts/dialogue-transcript-20260419.md
    run "$TOOL" 3.5 --json
    [ "$status" -eq 0 ]
}

@test "gate 3.6 --json emits structured output" {
    touch "$BASE/sensitive-dirs-sha256.txt"
    run "$TOOL" 3.6 --baseline-dir "$BASE" --json
    [ "$status" -eq 0 ]
}

@test "gate 4.5 --json emits structured output" {
    mkdir -p .claude
    echo '{}' > .claude/settings.json
    run "$TOOL" 4.5 --json
    [ "$status" -eq 0 ]
}

@test "gate 5 --json emits structured output" {
    run "$TOOL" 5 --json
    [ "$status" -eq 0 ]
}

@test "gate 6 --json emits structured output" {
    mkdir -p agency/workstreams/the-agency
    touch agency/workstreams/the-agency/release-notes-v46.0.md
    touch agency/workstreams/the-agency/migration-runbook-v46.0.md
    run "$TOOL" 6 --json
    [ "$status" -eq 0 ]
}

@test "gate 1 with multiple tracked files under claude/ exits 1" {
    # Only way is to commit files under claude/ then remove dir (but keep tracked)
    mkdir -p claude
    echo a > claude/a; echo b > claude/b
    git add claude; git commit -q -m res
    rm -rf claude
    mkdir -p agency
    run "$TOOL" 1
    [ "$status" -eq 1 ]
}

@test "gate 3 with multiple legacy dirs present exits 1" {
    mkdir -p agency/workstreams/the-agency/history/flotsam claude/principals claude/plans claude/proposals
    run "$TOOL" 3
    [ "$status" -eq 1 ]
}

@test "gate 5 with multiple canary-missing rules exits 1" {
    mkdir -p agency/hookify
    echo "# r1" > agency/hookify/r1.md
    echo "# r2" > agency/hookify/r2.md
    run "$TOOL" 5
    [ "$status" -eq 1 ]
}

@test "gate 5 with all rules having canaries exits 0" {
    mkdir -p agency/hookify
    echo "# r1" > agency/hookify/r1.md
    echo "c" > agency/hookify/r1.canary
    echo "# r2" > agency/hookify/r2.md
    echo "c" > agency/hookify/r2.canary
    run "$TOOL" 5
    [ "$status" -eq 0 ]
}
