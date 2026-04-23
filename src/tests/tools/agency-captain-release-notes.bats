#!/usr/bin/env bats
#
# Tests for agency/tools/agency-captain-release-notes
#
# Covers --version, --help, argument parsing, and basic skeleton generation
# (frontmatter + PR table rendering) using a stubbed `gh` CLI.
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

    mkdir -p agency/tools agency/config agency/workstreams/mockproj/release-notes

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

    # Stub gh on PATH so the tool can run offline.
    STUB_DIR="${BATS_TEST_TMPDIR}/stubs"
    mkdir -p "$STUB_DIR"
    cat > "$STUB_DIR/gh" <<'STUB'
#!/usr/bin/env bash
# Minimal gh stub — covers only the subcommands the tool calls.
case "$1 $2" in
    "release list")
        # Return one release tag so --end-version auto-detect works
        echo '[{"tagName":"v1.0","publishedAt":"2026-04-20T00:00:00Z"}]'
        ;;
    "pr list")
        # Return an empty array; window tests stub richer fixtures.
        echo '[]'
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
    [[ "$output" == *"1.0.0"* ]]
}

@test "agency-captain-release-notes: --help shows usage" {
    cd "$TEST_REPO"
    run ./agency/tools/agency-captain-release-notes --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Generate captain-to-captain release notes skeleton"* ]]
    [[ "$output" == *"--start-version"* ]]
    [[ "$output" == *"--audience"* ]]
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
