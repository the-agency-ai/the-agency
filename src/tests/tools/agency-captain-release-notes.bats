#!/usr/bin/env bats
#
# Tests for agency/tools/agency-captain-release-notes
#
# Covers --version, --help, argument parsing, window/base resolution, identity
# and workstream auto-detection, and skeleton generation (frontmatter + PR
# table) against a stubbed `gh` CLI.
#
# The stubs are the point: the tool's whole job is shaping `gh` output, and the
# 2026-08 revival found three defects (agent-identity flag, jq masking, base
# scoping) that only a stub with realistic shape can catch.
#

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    TOOL="${REPO_ROOT}/agency/tools/agency-captain-release-notes"

    # Mock project
    export TEST_REPO="${BATS_TEST_TMPDIR}/mock-repo"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init --quiet --initial-branch=main 2>/dev/null || git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"

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

    cp "$TOOL" agency/tools/agency-captain-release-notes
    chmod +x agency/tools/agency-captain-release-notes
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

    # resolve-default-branch stub
    cat > agency/tools/resolve-default-branch <<'STUB'
#!/usr/bin/env bash
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

# ─────────────────────────────────────────────────────────────────────────────
# Version + help
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: --version shows tool version" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"agency-captain-release-notes"* ]]
    [[ "$output" == *"1.1.0"* ]]
}

@test "agency-captain-release-notes: --help shows usage" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Generate captain-to-captain release notes skeleton"* ]]
    [[ "$output" == *"--start-version"* ]]
    [[ "$output" == *"--audience"* ]]
    [[ "$output" == *"--base"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Arg parsing
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: rejects unknown arg" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes --bogus
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown argument"* ]]
}

@test "agency-captain-release-notes: rejects value-flag with no value" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes --start-version
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires a value"* ]]
}

@test "agency-captain-release-notes: rejects non-numeric --limit" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes --limit abc --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"--limit must be a positive integer"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Dry run with explicit window
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: --dry-run reports without writing" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 \
        --end-version v1.0 \
        --captain "test-captain" \
        --workstream "mockproj" \
        --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]

    # No file should have been written
    run bash -c "ls agency/workstreams/mockproj/release-notes/*.md 2>/dev/null | wc -l | tr -d ' '"
    [ "$output" == "0" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Stdout mode prints frontmatter + sections
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: --stdout emits frontmatter + placeholders" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 \
        --end-version v1.0 \
        --captain "test-captain" \
        --workstream "mockproj" \
        --stdout
    [ "$status" -eq 0 ]
    # Frontmatter
    [[ "$output" == *"type: release-notes"* ]]
    [[ "$output" == *"audience: any captain or principal working on mockproj"* ]]
    [[ "$output" == *"generated_by: agency-captain-release-notes"* ]]
    # Body sections
    [[ "$output" == *"## TL;DR"* ]]
    [[ "$output" == *"## PRs landed"* ]]
    [[ "$output" == *"## Cross-repo / shared-package changes"* ]]
    [[ "$output" == *"## Open items / flags"* ]]
    [[ "$output" == *"## In-flight (not yet PR'd)"* ]]
    [[ "$output" == *"## Coordination requests"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# File output with default path
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: writes to default path" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 \
        --end-version v1.0 \
        --captain "test-captain" \
        --workstream "mockproj"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Release notes skeleton written"* ]]

    # File should exist under default path
    DATE_TODAY=$(date -u +%Y%m%d)
    EXPECTED_FILE="agency/workstreams/mockproj/release-notes/release-notes-${DATE_TODAY}-test-captain-v0.9-v1.0.md"
    [ -f "$EXPECTED_FILE" ]

    # And should carry the frontmatter
    run grep -q "^type: release-notes$" "$EXPECTED_FILE"
    [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Explicit --to adds frontmatter entry
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: --to populates frontmatter" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 \
        --end-version v1.0 \
        --captain "test-captain" \
        --workstream "mockproj" \
        --to "mockproj/alice/captain" \
        --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"to: mockproj/alice/captain"* ]]
    # Addressed to line in body too
    [[ "$output" == *"Addressed to:"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Custom --audience passes through
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: --audience overrides default" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
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
# Regression: agent-identity is called with NO flags (revival fix)
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: resolves captain from agent-identity" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    # {principal}-{agent} from "mockproj/alice/captain"
    [[ "$output" == *"alice-captain"* ]]
    [[ "$output" != *"unknown-captain"* ]]
    # Fully qualified address in frontmatter `from:`
    [[ "$output" == *"from: mockproj/alice/captain"* ]]
}

@test "agency-captain-release-notes: explicit --captain drives the from: address" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --workstream "mockproj" --captain "bob-captain" --stdout
    [ "$status" -eq 0 ]
    # Header name and frontmatter address must agree — they diverged before the
    # 2026-08 revival (from: silently kept the agent-identity address).
    [[ "$output" == *"from: mockproj/bob/captain"* ]]
    [[ "$output" == *"**From:** bob-captain (mockproj/bob/captain)"* ]]
    [[ "$output" != *"from: mockproj/alice/captain"* ]]
}

@test "agency-captain-release-notes: --captain splits on the last hyphen" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --workstream "mockproj" --captain "jordan-of-captain" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"from: mockproj/jordan-of/captain"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Regression: PR window filtering + table rendering (revival fixes)
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: filters PRs to the date window" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"prs_landed_count: 2"* ]]
    [[ "$output" == *"#11"* ]]
    [[ "$output" == *"#12"* ]]
    # #13 merged 2026-05-01, after the v1.0 publish date — excluded
    [[ "$output" != *"chore: after window"* ]]
}

@test "agency-captain-release-notes: escapes pipes in PR titles" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"fix: pipe \\| in title"* ]]
}

@test "agency-captain-release-notes: renders null PR author as unknown" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"| unknown |"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Regression: base-branch scoping (revival fix)
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: scopes pr list to the default branch" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"base_branch: main"* ]]
    run grep -q -- "--base main" "$GH_CALL_LOG"
    [ "$status" -eq 0 ]
}

@test "agency-captain-release-notes: --base all omits the base filter" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" \
        --base all --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"base_branch: all"* ]]
    run grep -q -- "--base" "$GH_CALL_LOG"
    [ "$status" -ne 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Regression: end-version auto-detect uses isLatest, not list order
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: auto-detects end version via isLatest" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    # v1.0 is isLatest even though v0.9 is first in the stub's list
    [[ "$output" == *"end_version: v1.0"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Regression: start-version auto-detect from prior release-notes file
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: auto-detects start version from prior file" {
    cd "$TEST_REPO"
    cat > agency/workstreams/mockproj/release-notes/release-notes-20260401-test-captain-v0.5-v0.9.md <<'PRIOR'
---
type: release-notes
window:
  start_version: v0.5
  end_version: v0.9
---
PRIOR
    run ./agency/tools/agency-captain-release-notes \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"start_version: v0.9"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Regression: workstream auto-resolution from a free-text project name
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: slugifies free-text project name for workstream" {
    cd "$TEST_REPO"
    cat > agency/config/agency.yaml <<'YAML'
project:
  name: "Mock Proj"
  timezone: "UTC"
YAML
    mkdir -p agency/workstreams/mock-proj/release-notes
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Workstream: mock-proj"* ]]
}

@test "agency-captain-release-notes: falls back to repo name when project slug has no dir" {
    cd "$TEST_REPO"
    cat > agency/config/agency.yaml <<'YAML'
project:
  name: "My Project"
  timezone: "UTC"
YAML
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --dry-run
    [ "$status" -eq 0 ]
    # agency/workstreams/my-project does not exist; the repo name from
    # agent-identity ("mockproj") does, so it wins over the "agency" fallback.
    [[ "$output" == *"Workstream: mockproj"* ]]
}

@test "agency-captain-release-notes: falls back to agency when nothing else matches" {
    cd "$TEST_REPO"
    cat > agency/config/agency.yaml <<'YAML'
project:
  name: "My Project"
  timezone: "UTC"
YAML
    rm -rf agency/workstreams/mockproj
    mkdir -p agency/workstreams/agency/release-notes
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Workstream: agency"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Regression: jq is a hard dependency, not a silently-swallowed one
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: dies when jq is missing" {
    cd "$TEST_REPO"
    BARE_DIR="${BATS_TEST_TMPDIR}/bare-path"
    mkdir -p "$BARE_DIR"
    ln -sf "$(command -v gh)" "$BARE_DIR/gh"
    for b in bash sed awk date ls mkdir tr grep dirname head tail sort cat; do
        [[ -x "$(command -v $b)" ]] && ln -sf "$(command -v $b)" "$BARE_DIR/$b"
    done
    run env PATH="$BARE_DIR" ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 --stdout
    [ "$status" -ne 0 ]
    [[ "$output" == *"jq not found"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Regression: color codes are rendered, never printed literally
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: never emits literal escape text" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj"
    [ "$status" -eq 0 ]
    [[ "$output" != *'\033['* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Empty window still produces a valid table
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: empty window warns and emits placeholder row" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-date "2027-01-01T00:00:00Z" \
        --end-date "2027-01-02T00:00:00Z" \
        --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" --stdout
    [ "$status" -eq 0 ]
    [[ "$output" == *"prs_landed_count: 0"* ]]
    [[ "$output" == *"no merged PRs in window"* ]]
    [[ "$output" == *"No PRs matched"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# --output overrides the default path
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-captain-release-notes: --output writes to the given path" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes \
        --start-version v0.9 --end-version v1.0 \
        --captain "test-captain" --workstream "mockproj" \
        --output "custom/notes.md"
    [ "$status" -eq 0 ]
    [ -f "custom/notes.md" ]
    run grep -q "^type: release-notes$" "custom/notes.md"
    [ "$status" -eq 0 ]
}
