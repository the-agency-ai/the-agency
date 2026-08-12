#!/usr/bin/env bats
#
# Tests for agency/tools/captain-release-notes
#
# Covers --version, --help, argument validation, window/base resolution,
# identity and workstream auto-detection, adversarial input, degraded
# dependencies, and skeleton generation against stubbed `gh` / `agent-identity`
# / `resolve-default-branch`.
#
# The stubs are the point: the tool's whole job is shaping `gh` output. The
# 2026-08 revival + QG found ten defects (agent-identity flag, jq masking, base
# scoping, argv injection, path traversal, window inversion, prior-file glob,
# limit conflation, flag-shaped values, captain-name splitting) that only stubs
# with realistic shape and an argv log can catch.
#

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    TOOL="${REPO_ROOT}/agency/tools/captain-release-notes"

    # Mock project
    export TEST_REPO="${BATS_TEST_TMPDIR}/mock-repo"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init --quiet --initial-branch=main 2>/dev/null || git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"

    # The tool probes CLAUDE_PROJECT_DIR BEFORE `git rev-parse`. Without this
    # export the suite is non-hermetic: run from inside a Claude Code session
    # it resolves the REAL repo, bypasses every stub below, and writes into
    # agency/workstreams/ of the live checkout. Sibling suites pin it the same
    # way (see agent-identity.bats).
    export CLAUDE_PROJECT_DIR="$TEST_REPO"

    mkdir -p agency/tools/lib agency/config agency/workstreams/mockproj/release-notes

    # minimal agency.yaml the tool parses
    cat > agency/config/agency.yaml <<YAML
project:
  name: "mockproj"
  timezone: "UTC"
YAML

    # initial commit
    echo "x" > README.md
    git add -A
    git commit -m "initial" --quiet
    git update-ref refs/remotes/origin/main HEAD

    cp "$TOOL" agency/tools/captain-release-notes
    chmod +x agency/tools/captain-release-notes
    cp "${REPO_ROOT}/agency/tools/lib/_colors" agency/tools/lib/_colors 2>/dev/null || true

    # agent-identity stub — bare invocation prints the fully qualified address.
    # The pre-revival tool called a `--agent-address` flag that never existed;
    # this stub errors on any flag so a regression is loud, not silent.
    cat > agency/tools/agent-identity <<'STUB'
#!/usr/bin/env bash
if [[ $# -gt 0 ]]; then
    echo "agent-identity stub: unsupported flag: $*" >&2
    exit 2
fi
echo "mockproj/alice/captain"
STUB
    chmod +x agency/tools/agent-identity

    # resolve-default-branch stub — accepts only the flags the real tool
    # supports, records argv, and errors otherwise so a drifted call cannot
    # silently degrade to `--base all`.
    export RDB_CALL_LOG="${BATS_TEST_TMPDIR}/rdb-calls.log"
    cat > agency/tools/resolve-default-branch <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${RDB_CALL_LOG:-/dev/null}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -C) shift 2 ;;
        --strict) shift ;;
        *) echo "resolve-default-branch stub: unsupported flag: $1" >&2; exit 2 ;;
    esac
done
echo "main"
STUB
    chmod +x agency/tools/resolve-default-branch

    # Stub gh on PATH so the tool can run offline.
    # Records the argv of each call so tests can assert on flags passed.
    export GH_CALL_LOG="${BATS_TEST_TMPDIR}/gh-calls.log"
    STUB_DIR="${BATS_TEST_TMPDIR}/stubs"
    mkdir -p "$STUB_DIR"
    cat > "$STUB_DIR/gh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${GH_CALL_LOG:-/dev/null}"
case "$1 $2" in
    "release list")
        cat <<'JSON'
[
  {"tagName":"v0.9","publishedAt":"2026-04-10T00:00:00Z","isLatest":false},
  {"tagName":"v1.0","publishedAt":"2026-04-20T00:00:00Z","isLatest":true}
]
JSON
        ;;
    "pr list")
        cat <<'JSON'
[
  {"number":11,"title":"feat: in window","mergedAt":"2026-04-15T00:00:00Z","author":{"login":"alice"}},
  {"number":12,"title":"fix: pipe | in title","mergedAt":"2026-04-18T00:00:00Z","author":{"login":null}},
  {"number":13,"title":"chore: after window","mergedAt":"2026-05-01T00:00:00Z","author":{"login":"bob"}}
]
JSON
        ;;
    *)
        echo '{}'
        ;;
esac
STUB
    chmod +x "$STUB_DIR/gh"
    export PATH="$STUB_DIR:$PATH"
}

teardown() {
    test_isolation_teardown
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# Replace the gh stub's response for one subcommand.
# Usage: stub_gh_response "release list" '<json>'
stub_gh_response() {
    local subcmd="$1" payload="$2"
    cat > "${BATS_TEST_TMPDIR}/stubs/gh" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "\${GH_CALL_LOG:-/dev/null}"
if [[ "\$1 \$2" == "$subcmd" ]]; then
    cat <<'PAYLOAD'
$payload
PAYLOAD
    exit 0
fi
case "\$1 \$2" in
    "release list")
        echo '[{"tagName":"v0.9","publishedAt":"2026-04-10T00:00:00Z","isLatest":false},{"tagName":"v1.0","publishedAt":"2026-04-20T00:00:00Z","isLatest":true}]'
        ;;
    "pr list") echo '[]' ;;
    *) echo '{}' ;;
esac
STUB
    chmod +x "${BATS_TEST_TMPDIR}/stubs/gh"
}

# ─────────────────────────────────────────────────────────────────────────────
# Version + help
# ─────────────────────────────────────────────────────────────────────────────

@test "captain-release-notes: --version shows tool version" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"captain-release-notes"* ]]
    [[ "$output" == *"1.3.0"* ]]
}

@test "captain-release-notes: --help shows usage" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Generate captain-to-captain release notes skeleton"* ]]
    [[ "$output" == *"--start-version"* ]]
    [[ "$output" == *"--audience"* ]]
    [[ "$output" == *"--base"* ]]
    [[ "$output" == *"--limit"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Arg validation
# ─────────────────────────────────────────────────────────────────────────────

@test "captain-release-notes: rejects unknown arg" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes --bogus
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown argument"* ]]
}

@test "captain-release-notes: rejects value-flag with no value" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes --start-version
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
}

@test "captain-release-notes: rejects a flag-shaped value" {
    cd "$TEST_REPO"
    # "--to --stdout" used to set TO_ADDR="--stdout" AND swallow the --stdout
    # flag, so the tool wrote a file with a garbage addressee.
    run ./agency/tools/captain-release-notes --to --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"got a flag: --stdout"* ]]
}

@test "captain-release-notes: rejects non-numeric --limit" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes --limit abc --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"--limit must be a positive integer"* ]]
}

@test "captain-release-notes: rejects --limit 0" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes --limit 0 --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"--limit must be a positive integer"* ]]
}

@test "captain-release-notes: rejects a malformed --start-date" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes --start-date 2026-04-15 --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"--start-date must be YYYY-MM-DDTHH:MM:SSZ"* ]]
}

@test "captain-release-notes: rejects --stdout together with --output" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes --stdout --output x.md
    [ "$status" -ne 0 ]
    [[ "$output" == *"mutually exclusive"* ]]
}

@test "captain-release-notes: rejects a newline in --audience" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --audience "fleet
injected_key: value" --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"--audience must be a single line"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Security: argv injection + path traversal
# ─────────────────────────────────────────────────────────────────────────────

@test "captain-release-notes: rejects a --base that smuggles gh flags" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --base "main --repo attacker/evil" \
        --start-version v0.9 --end-version v1.0 --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"--base must be a branch name"* ]]
    # And the smuggled flag never reached gh — validation fires before any
    # call, so the log must not even exist.
    run grep -q -- "--repo" "$GH_CALL_LOG"
    [ "$status" -ne 0 ]
}

@test "captain-release-notes: ignores a traversal-bearing prior end_version" {
    cd "$TEST_REPO"
    cat > agency/workstreams/mockproj/release-notes/release-notes-20260401-x-v0.5-v0.9.md <<'PRIOR'
---
type: release-notes
window:
  end_version: ../../../../../../tmp/pwned
---
PRIOR
    run ./agency/tools/captain-release-notes \
        --end-version v1.0 --start-date "2026-04-10T00:00:00Z" \
        --captain "test-captain" --workstream "mockproj" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Ignoring unusable end_version"* ]]
    # Output path stays inside the workstream.
    [[ "$output" != *"/tmp/pwned"* ]]
    [[ "$output" == *"agency/workstreams/mockproj/release-notes/release-notes-"* ]]
}

@test "captain-release-notes: refuses to write through a symlink" {
    cd "$TEST_REPO"
    mkdir -p decoy
    ln -s "$TEST_REPO/decoy/target.md" "agency/workstreams/mockproj/release-notes/link.md"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --output "agency/workstreams/mockproj/release-notes/link.md"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Refusing to write through a symlink"* ]]
    [ ! -f "decoy/target.md" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Dry run / stdout / file output
# ─────────────────────────────────────────────────────────────────────────────

@test "captain-release-notes: --dry-run reports target and row count without writing" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 \
        --end-version v1.0 \
        --captain "test-captain" \
        --workstream "mockproj" \
        --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
    [[ "$output" == *"agency/workstreams/mockproj/release-notes/release-notes-"* ]]
    [[ "$output" == *"PR rows: 2"* ]]
    # Frontmatter summary omits `to` when --to was not passed
    [[ "$output" == *"from/audience/window/prs_landed_count"* ]]

    # No file should have been written
    run bash -c "ls agency/workstreams/mockproj/release-notes/*.md 2>/dev/null | wc -l | tr -d ' '"
    [ "$output" == "0" ]
}

@test "captain-release-notes: --dry-run with --stdout reports stdout as the target" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" \
        --stdout --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"would write to: <stdout>"* ]]
}

@test "captain-release-notes: --stdout emits frontmatter + all placeholders" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 \
        --end-version v1.0 \
        --captain "test-captain" \
        --workstream "mockproj" \
        --stdout
    [ "$status" -eq 0 ]
    # Frontmatter
    [[ "$output" == *"type: release-notes"* ]]
    [[ "$output" == *"audience: any captain or principal working on mockproj"* ]]
    [[ "$output" == *"generated_by: captain-release-notes"* ]]
    # Body sections — all seven
    [[ "$output" == *"## TL;DR"* ]]
    [[ "$output" == *"## PRs landed"* ]]
    [[ "$output" == *"## Cross-repo / shared-package changes"* ]]
    [[ "$output" == *"## Master behavioral changes"* ]]
    [[ "$output" == *"## Open items / flags"* ]]
    [[ "$output" == *"## In-flight (not yet PR'd)"* ]]
    [[ "$output" == *"## Coordination requests"* ]]
    # Broadcast default: no addressee anywhere
    [[ "$output" != *"to: "* ]]
    [[ "$output" != *"Addressed to:"* ]]
}

@test "captain-release-notes: writes to default path" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 \
        --end-version v1.0 \
        --captain "test-captain" \
        --workstream "mockproj"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Release notes skeleton written"* ]]

    # Glob rather than pin the date — a run straddling 00:00 UTC would flake.
    run bash -c "ls agency/workstreams/mockproj/release-notes/release-notes-*-test-captain-v0.9-v1.0.md | wc -l | tr -d ' '"
    [ "$output" == "1" ]

    run bash -c "grep -lq '^type: release-notes$' agency/workstreams/mockproj/release-notes/release-notes-*-test-captain-v0.9-v1.0.md"
    [ "$status" -eq 0 ]
}

@test "captain-release-notes: --output writes to the given path" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" \
        --output "custom/notes.md"
    [ "$status" -eq 0 ]
    [ -f "custom/notes.md" ]
    run grep -q "^type: release-notes$" "custom/notes.md"
    [ "$status" -eq 0 ]
}

@test "captain-release-notes: fails cleanly on an uncreatable output directory" {
    cd "$TEST_REPO"
    # A regular file where a directory must go — mkdir -p cannot succeed.
    touch blocker
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --output "blocker/notes.md"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Could not create output directory"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Addressee + audience
# ─────────────────────────────────────────────────────────────────────────────

@test "captain-release-notes: --to populates frontmatter" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 \
        --end-version v1.0 \
        --captain "test-captain" \
        --workstream "mockproj" \
        --to "mockproj/alice/captain" \
        --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"to: mockproj/alice/captain"* ]]
    [[ "$output" == *"Addressed to:"* ]]
}

@test "captain-release-notes: --audience overrides default" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 \
        --end-version v1.0 \
        --captain "test-captain" \
        --workstream "mockproj" \
        --audience "the fleet" \
        --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"audience: the fleet"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Identity resolution
# ─────────────────────────────────────────────────────────────────────────────

@test "captain-release-notes: resolves captain from agent-identity" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"alice-captain"* ]]
    [[ "$output" != *"unknown-captain"* ]]
    [[ "$output" == *"from: mockproj/alice/captain"* ]]
}

@test "captain-release-notes: explicit --captain drives the from: address" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --workstream "mockproj" --captain "bob-captain" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"from: mockproj/bob/captain"* ]]
    [[ "$output" == *"**From:** bob-captain (mockproj/bob/captain)"* ]]
    [[ "$output" != *"from: mockproj/alice/captain"* ]]
}

@test "captain-release-notes: --captain keeps a hyphenated agent slug intact" {
    cd "$TEST_REPO"
    # The tool's own default name for a worktree agent is
    # {principal}-{branch-slug}. Splitting on the LAST hyphen mangled it into
    # alice-revive-release/notes. Principals are single-token; agents are not.
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --workstream "mockproj" --captain "alice-revive-release-notes" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"from: mockproj/alice/revive-release-notes"* ]]
}

@test "captain-release-notes: --captain accepts a full address" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --workstream "mockproj" --captain "mockproj/carol/captain" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"from: mockproj/carol/captain"* ]]
    [[ "$output" == *"**From:** carol-captain"* ]]
}

@test "captain-release-notes: rejects a --captain with no agent segment" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --workstream "mockproj" --captain "solo" --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"--captain must be <principal>-<agent>"* ]]
}

@test "captain-release-notes: degrades to unknown-captain without agent-identity" {
    cd "$TEST_REPO"
    rm agency/tools/agent-identity
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"from: mockproj/unknown/captain"* ]]
}

@test "captain-release-notes: warns when the running agent is not captain" {
    cd "$TEST_REPO"
    cat > agency/tools/agent-identity <<'STUB'
#!/usr/bin/env bash
echo "mockproj/alice/devex"
STUB
    chmod +x agency/tools/agent-identity
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"not captain"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# PR window filtering + table rendering
# ─────────────────────────────────────────────────────────────────────────────

@test "captain-release-notes: filters PRs to the date window" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"prs_landed_count: 2"* ]]
    [[ "$output" == *"#11"* ]]
    [[ "$output" == *"#12"* ]]
    [[ "$output" != *"chore: after window"* ]]
}

@test "captain-release-notes: --start-date overrides the start release publishedAt" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --start-date "2026-04-17T00:00:00Z" \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"wall_clock_start: 2026-04-17T00:00:00Z"* ]]
    # Only #12 (2026-04-18) survives the narrowed window
    [[ "$output" == *"prs_landed_count: 1"* ]]
    [[ "$output" != *"feat: in window"* ]]
}

@test "captain-release-notes: escapes pipes in PR titles" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"fix: pipe \\| in title"* ]]
}

@test "captain-release-notes: escapes backslashes before pipes" {
    cd "$TEST_REPO"
    stub_gh_response "pr list" '[{"number":21,"title":"weird \\| already escaped","mergedAt":"2026-04-15T00:00:00Z","author":{"login":"alice"}}]'
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    # Backslash escaped first, then the pipe: \\ + \|
    [[ "$output" == *'weird \\\| already escaped'* ]]
}

@test "captain-release-notes: renders null PR author as unknown" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"| unknown |"* ]]
}

@test "captain-release-notes: empty window warns and emits placeholder row" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-date "2026-04-19T00:00:00Z" \
        --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"prs_landed_count: 0"* ]]
    [[ "$output" == *"no merged PRs in window"* ]]
    [[ "$output" == *"No PRs matched"* ]]
}

@test "captain-release-notes: refuses an inverted window" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-date "2027-01-01T00:00:00Z" \
        --end-date "2026-01-01T00:00:00Z" \
        --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"Window is inverted"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Base-branch scoping + gh argv
# ─────────────────────────────────────────────────────────────────────────────

@test "captain-release-notes: scopes pr list to the default branch" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"base_branch: main"* ]]
    run grep -q -- "--base main" "$GH_CALL_LOG"
    [ "$status" -eq 0 ]
    # And resolve-default-branch was asked with -C, not bare
    run grep -q -- "-C " "$RDB_CALL_LOG"
    [ "$status" -eq 0 ]
}

@test "captain-release-notes: --base all omits the base filter" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" \
        --base all --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"base_branch: all"* ]]
    run grep -q -- "--base" "$GH_CALL_LOG"
    [ "$status" -ne 0 ]
}

@test "captain-release-notes: falls back to base=all without resolve-default-branch" {
    cd "$TEST_REPO"
    rm agency/tools/resolve-default-branch
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"Could not resolve a default branch"* ]]
    [[ "$output" == *"base_branch: all"* ]]
    run grep -q -- "--base" "$GH_CALL_LOG"
    [ "$status" -ne 0 ]
}

@test "captain-release-notes: passes --limit through to gh pr list only" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" \
        --limit 7 --stdout
    [ "$status" -eq 0 ]
    run grep -q -- "pr list --state merged --limit 7" "$GH_CALL_LOG"
    [ "$status" -eq 0 ]
    # Release discovery must NOT inherit the PR limit — truncating the release
    # list breaks publishedAt lookup for the window's start tag.
    run grep -q -- "release list --limit 7" "$GH_CALL_LOG"
    [ "$status" -ne 0 ]
}

@test "captain-release-notes: prefers the framework gh wrapper over PATH gh" {
    cd "$TEST_REPO"
    # A wrapper that marks itself and delegates to the PATH stub, mirroring
    # agency/tools/gh's strip-SCRIPT_DIR-from-PATH delegation.
    cat > agency/tools/gh <<'WRAP'
#!/usr/bin/env bash
printf 'wrapper\n' >> "${GH_CALL_LOG:-/dev/null}"
# agency/tools is not on PATH, so this resolves to the PATH stub — same
# delegation shape as the real wrapper.
exec gh "$@"
WRAP
    chmod +x agency/tools/gh
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    # Assert on the tool's output BEFORE any further `run` — `run` clobbers
    # $output, and asserting after it silently checks grep's output instead.
    # Wrapper stdout must not pollute the parsed JSON.
    [[ "$output" == *"prs_landed_count: 2"* ]]
    run grep -q "^wrapper$" "$GH_CALL_LOG"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Release discovery
# ─────────────────────────────────────────────────────────────────────────────

@test "captain-release-notes: auto-detects end version via isLatest" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    # v1.0 is isLatest even though v0.9 is first in the stub's list
    [[ "$output" == *"end_version: v1.0"* ]]
}

@test "captain-release-notes: dies when no releases exist and --end-version omitted" {
    cd "$TEST_REPO"
    stub_gh_response "release list" '[]'
    run ./agency/tools/captain-release-notes \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"could not auto-detect"* ]]
}

@test "captain-release-notes: survives non-array gh release JSON" {
    cd "$TEST_REPO"
    stub_gh_response "release list" '{"message":"Not Found"}'
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --start-date "2026-04-10T00:00:00Z" \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"type: release-notes"* ]]
}

@test "captain-release-notes: survives non-array gh pr JSON" {
    cd "$TEST_REPO"
    stub_gh_response "pr list" '{"message":"Not Found"}'
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"prs_landed_count: 0"* ]]
    [[ "$output" == *"no merged PRs in window"* ]]
}

@test "captain-release-notes: survives an array of non-objects from gh" {
    cd "$TEST_REPO"
    stub_gh_response "release list" '["v1.0","v0.9"]'
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --start-date "2026-04-10T00:00:00Z" \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"type: release-notes"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Prior-file (start version) auto-detection
# ─────────────────────────────────────────────────────────────────────────────

@test "captain-release-notes: auto-detects start version from prior file" {
    cd "$TEST_REPO"
    cat > agency/workstreams/mockproj/release-notes/release-notes-20260401-test-captain-v0.5-v0.9.md <<'PRIOR'
---
type: release-notes
window:
  start_version: v0.5
  end_version: v0.9
---
PRIOR
    run ./agency/tools/captain-release-notes \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"start_version: v0.9"* ]]
}

@test "captain-release-notes: picks the lexically-latest prior file, not the newest mtime" {
    cd "$TEST_REPO"
    D=agency/workstreams/mockproj/release-notes
    cat > "$D/release-notes-20260401-x-v0.5-v0.9.md" <<'PRIOR'
---
window:
  end_version: v0.9
---
PRIOR
    cat > "$D/release-notes-20260301-x-v0.1-v0.3.md" <<'PRIOR'
---
window:
  end_version: v0.3
---
PRIOR
    # Make the OLDER-named file the newest by mtime — `ls -t` would pick it.
    touch "$D/release-notes-20260301-x-v0.1-v0.3.md"
    run ./agency/tools/captain-release-notes \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"start_version: v0.9"* ]]
}

@test "captain-release-notes: ignores non-release-notes markdown in the directory" {
    cd "$TEST_REPO"
    D=agency/workstreams/mockproj/release-notes
    cat > "$D/release-notes-20260401-x-v0.5-v0.9.md" <<'PRIOR'
---
window:
  end_version: v0.9
---
PRIOR
    # Sorts after "release-notes-*" and would hijack the window under a bare
    # *.md glob.
    cat > "$D/zz-template.md" <<'STRAY'
---
window:
  end_version: NOT-A-VERSION
---
STRAY
    run ./agency/tools/captain-release-notes \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"start_version: v0.9"* ]]
    [[ "$output" != *"NOT-A-VERSION"* ]]
}

@test "captain-release-notes: strips quotes from a prior end_version" {
    cd "$TEST_REPO"
    cat > agency/workstreams/mockproj/release-notes/release-notes-20260401-x-v0.5-v0.9.md <<'PRIOR'
---
window:
  end_version: "v0.9"
---
PRIOR
    run ./agency/tools/captain-release-notes \
        --captain "test-captain" --workstream "mockproj" --dry-run
    [ "$status" -eq 0 ]
    # Quotes must not reach the window or the filename
    [[ "$output" == *'Window: v0.9 '* ]]
    [[ "$output" != *'"v0.9"'* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Workstream resolution
# ─────────────────────────────────────────────────────────────────────────────

@test "captain-release-notes: slugified project name drives the output path" {
    cd "$TEST_REPO"
    cat > agency/config/agency.yaml <<'YAML'
project:
  name: "Mock Proj"
  timezone: "UTC"
YAML
    mkdir -p agency/workstreams/mock-proj/release-notes
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain"
    [ "$status" -eq 0 ]
    # Assert the resolved workstream actually drives the path, not just the log
    run bash -c "ls agency/workstreams/mock-proj/release-notes/release-notes-*-test-captain-v0.9-v1.0.md | wc -l | tr -d ' '"
    [ "$output" == "1" ]
}

@test "captain-release-notes: falls back to repo name when project slug has no dir" {
    cd "$TEST_REPO"
    cat > agency/config/agency.yaml <<'YAML'
project:
  name: "My Project"
  timezone: "UTC"
YAML
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Workstream: mockproj"* ]]
}

@test "captain-release-notes: falls back to agency when nothing else matches" {
    cd "$TEST_REPO"
    cat > agency/config/agency.yaml <<'YAML'
project:
  name: "My Project"
  timezone: "UTC"
YAML
    rm -rf agency/workstreams/mockproj
    mkdir -p agency/workstreams/agency/release-notes
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Workstream: agency"* ]]
}

@test "captain-release-notes: warns when it must invent a workstream directory" {
    cd "$TEST_REPO"
    cat > agency/config/agency.yaml <<'YAML'
project:
  name: "My Project"
  timezone: "UTC"
YAML
    rm -rf agency/workstreams
    mkdir -p agency/workstreams
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"No existing workstream directory matched"* ]]
    [[ "$output" == *"Workstream: my-project"* ]]
}

@test "captain-release-notes: slugifies an explicit --workstream" {
    cd "$TEST_REPO"
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "../../escape" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" != *"../../escape"* ]]
    [[ "$output" == *"agency/workstreams/escape/release-notes/"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Environment / dependencies
# ─────────────────────────────────────────────────────────────────────────────

@test "captain-release-notes: honors CLAUDE_PROJECT_DIR over cwd" {
    cd "$BATS_TEST_TMPDIR"
    run env CLAUDE_PROJECT_DIR="$TEST_REPO" \
        "$TEST_REPO/agency/tools/captain-release-notes" \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Workstream: mockproj"* ]]
    [[ "$output" == *"$TEST_REPO/agency/workstreams/mockproj/release-notes/"* ]]
}

@test "captain-release-notes: dies when jq is missing" {
    cd "$TEST_REPO"
    BARE_DIR="${BATS_TEST_TMPDIR}/bare-path"
    mkdir -p "$BARE_DIR"
    ln -sf "$(command -v gh)" "$BARE_DIR/gh"
    for b in bash sed awk date ls mkdir tr grep dirname head tail sort cat git touch rm; do
        [[ -x "$(command -v $b)" ]] && ln -sf "$(command -v $b)" "$BARE_DIR/$b"
    done
    run env PATH="$BARE_DIR" ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"jq not found"* ]]
}

@test "captain-release-notes: dies when gh is missing" {
    cd "$TEST_REPO"
    BARE_DIR="${BATS_TEST_TMPDIR}/no-gh-path"
    mkdir -p "$BARE_DIR"
    for b in bash sed awk date ls mkdir tr grep dirname head tail sort cat jq git touch rm; do
        [[ -x "$(command -v $b)" ]] && ln -sf "$(command -v $b)" "$BARE_DIR/$b"
    done
    run env PATH="$BARE_DIR" ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"gh CLI not found"* ]]
}

@test "captain-release-notes: renders colors when lib/_colors is present" {
    cd "$TEST_REPO"
    [ -f agency/tools/lib/_colors ]
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj"
    [ "$status" -eq 0 ]
    [[ "$output" != *'\033['* ]]
    [[ "$output" == *"✓"* ]]
}

@test "captain-release-notes: renders colors with the inline fallback" {
    cd "$TEST_REPO"
    rm -f agency/tools/lib/_colors
    run ./agency/tools/captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj"
    [ "$status" -eq 0 ]
    [[ "$output" != *'\033['* ]]
    [[ "$output" == *"✓"* ]]
}
