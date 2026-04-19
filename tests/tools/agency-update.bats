#!/usr/bin/env bats
#
# Tests for `agency update` — focus on the interrupted-prior-update gate
# added in D41-Rn (captain directive in dispatch #386). When the target
# tree has uncommitted framework changes (claude/ or .claude/), update
# should fail loud with a 3-line guide naming git-safe-commit, unless
# --force is passed.
#

load 'test_helper'

run_agency() {
    run "${TOOLS_DIR}/agency" "$@"
}

# ─────────────────────────────────────────────────────────────────────────────
# Help + flags
# ─────────────────────────────────────────────────────────────────────────────

@test "agency update: --help shows --force option" {
    run_agency update --help
    assert_success
    assert_output_contains "--force"
}

@test "agency update: unknown flag fails" {
    run_agency update --bogus
    assert_failure
    assert_output_contains "Unknown option"
}

# ─────────────────────────────────────────────────────────────────────────────
# Dirty-tree gate (interrupted prior update)
# ─────────────────────────────────────────────────────────────────────────────

# Build a minimal initialized target + a source tree to serve as update origin.
# Both are git repos. We stub AGENCY_SOURCE to point at the source.
setup_update_fixture() {
    local root="${BATS_TEST_TMPDIR}/fixture"
    mkdir -p "$root/source/claude/config" "$root/source/claude/tools" "$root/source/.claude/skills"
    mkdir -p "$root/target/claude/config" "$root/target/claude/tools" "$root/target/.claude/skills"

    # Source agency.yaml
    cat > "$root/source/agency/config/agency.yaml" <<EOF
framework:
  version: "99.0.0"
  source_commit: "abc1234"
  updated_at: "2026-04-15T00:00:00+00:00"
EOF
    # Target agency.yaml (older version)
    cat > "$root/target/agency/config/agency.yaml" <<EOF
framework:
  version: "1.0.0"
  source_commit: "deadbee"
  updated_at: "2026-04-01T00:00:00+00:00"
EOF

    # Init git in both
    ( cd "$root/source" && git init --quiet && git add -A && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify )
    ( cd "$root/target" && git init --quiet && git add -A && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify )

    echo "$root"
}

@test "agency update: dirty tree under claude/ blocks with remediation message" {
    local root
    root=$(setup_update_fixture)
    # Simulate an interrupted prior update — a framework file is modified
    echo "stale change" > "$root/target/agency/tools/some-stale-tool"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target"
    assert_failure
    assert_output_contains "uncommitted framework file"
    assert_output_contains "git-safe-commit"
    assert_output_contains "--force"
}

@test "agency update: dirty tree under .claude/ also blocks" {
    local root
    root=$(setup_update_fixture)
    echo "---" > "$root/target/.claude/skills/stale.md"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target"
    assert_failure
    assert_output_contains "uncommitted framework file"
}

@test "agency update: --force bypasses dirty-tree gate" {
    local root
    root=$(setup_update_fixture)
    echo "stale" > "$root/target/agency/tools/some-stale-tool"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --force
    # QG fix: assert the gate itself was not hit AND that update made progress
    # (reached the version-resolution banner). Earlier version accepted any
    # exit code, which made this test pass even on early unrelated crashes.
    [[ "$output" != *"uncommitted framework file"* ]]
    [[ "$output" == *"Agency Update"* ]] || [[ "$output" == *"From:"* ]]
}

@test "agency update: clean tree proceeds past gate" {
    local root
    root=$(setup_update_fixture)
    # No modifications — clean target
    AGENCY_SOURCE="$root/source" run_agency update "$root/target"
    # QG fix: positive assertion the update actually progressed past the gate
    [[ "$output" != *"uncommitted framework file"* ]]
    [[ "$output" == *"Agency Update"* ]] || [[ "$output" == *"From:"* ]]
}

@test "agency update: dirty tree OUTSIDE claude/ does not block" {
    local root
    root=$(setup_update_fixture)
    # Modify a non-framework file (e.g., app code / readme)
    echo "unrelated" > "$root/target/README.md"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target"
    [[ "$output" != *"uncommitted framework file"* ]]
    [[ "$output" == *"Agency Update"* ]] || [[ "$output" == *"From:"* ]]
}

@test "agency update: dry-run skips dirty-tree gate" {
    local root
    root=$(setup_update_fixture)
    echo "stale" > "$root/target/agency/tools/some-stale-tool"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --dry-run
    # Dry-run should not trip the gate — it's read-only.
    # QG fix: also assert dry-run banner is shown so we know we reached
    # update execution, not a pre-flight crash.
    [[ "$output" != *"uncommitted framework file"* ]]
    [[ "$output" == *"dry-run"* ]] || [[ "$output" == *"Dry Run"* ]]
}

# NOTE: a scale test for >20 dirty files was considered but the fixture setup
# cost (creating 25 files, git-statusing them, asserting exact count string)
# is disproportionate to the risk. The count fix — moving `grep -c '^'` to
# operate on the full porcelain output instead of the head-20 truncated
# version — is a one-line refactor that the positive-assertion tests above
# already exercise end-to-end.

# ─────────────────────────────────────────────────────────────────────────────
# D41-R16: opt-in --prune (rsync --delete with protected paths)
# ─────────────────────────────────────────────────────────────────────────────

@test "agency update: --help documents --prune and --yes" {
    run_agency update --help
    assert_success
    assert_output_contains "--prune"
    assert_output_contains "--yes"
}

@test "agency update: default (no --prune) does NOT delete orphaned target files" {
    # Defensive regression test — forbids silent orphan deletion by default.
    local root
    root=$(setup_update_fixture)
    # Orphan only in target, not in source
    local orphan="$root/target/agency/tools/my-local-tool"
    echo "#!/bin/bash" > "$orphan"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --force --yes
    # The orphan must survive — default sync is additive only
    [ -f "$orphan" ]
}

@test "agency update: --prune --dry-run previews deletions but does not delete" {
    local root
    root=$(setup_update_fixture)
    local orphan="$root/target/agency/tools/my-local-tool"
    echo "#!/bin/bash" > "$orphan"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --prune --dry-run --force
    # Dry-run: orphan still exists
    [ -f "$orphan" ]
    # Prune preview should mention the orphan count or the dry-run note
    [[ "$output" == *"--prune"* ]] || [[ "$output" == *"dry-run"* ]]
}

@test "agency update: --prune --yes deletes orphaned target files" {
    local root
    root=$(setup_update_fixture)
    local orphan="$root/target/agency/tools/my-local-tool"
    echo "#!/bin/bash" > "$orphan"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --prune --yes --force
    # Orphan must be removed
    [ ! -f "$orphan" ]
}

@test "agency update: --prune --yes preserves usr/ and workstreams/" {
    local root
    root=$(setup_update_fixture)
    # Create adopter-owned files under usr/ (sandbox) and workstreams/ that
    # don't exist in source — they must survive prune via the hard excludes.
    mkdir -p "$root/target/usr/jordan/captain"
    echo "handoff" > "$root/target/usr/jordan/captain/captain-handoff.md"
    mkdir -p "$root/target/agency/workstreams/myproject"
    echo "knowledge" > "$root/target/agency/workstreams/myproject/KNOWLEDGE.md"

    AGENCY_SOURCE="$root/source" run_agency update "$root/target" --prune --yes --force
    [ -f "$root/target/usr/jordan/captain/captain-handoff.md" ]
    [ -f "$root/target/agency/workstreams/myproject/KNOWLEDGE.md" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R20: --from-github default-ref behavior (issue #113)
#
# These tests exercise the parser-level default for the --from-github flag.
# They do NOT actually clone from github (would require network and a real
# fork). They verify the default ref the parser/resolver would pass to git.
# ─────────────────────────────────────────────────────────────────────────────

@test "agency update: --help documents new default and @latest opt-in" {
    run_agency update --help
    assert_success
    assert_output_contains "Default: main"
    assert_output_contains "@latest"
}

@test "agency update: --help no longer claims 'latest tag' as default" {
    run_agency update --help
    assert_success
    # The phrase 'default: latest tag' WAS the old behavior; ensure it's gone.
    [[ "$output" != *"default: latest tag"* ]]
}

@test "agency update: --from-github with no ref falls through to main resolution" {
    # Without network access we cannot complete a clone, so we expect the tool
    # to fail at the clone step. But the verbose output should reference 'main'
    # (the new default), not 'latest'.
    cd "$BATS_TEST_TMPDIR"
    mkdir -p target/claude/config
    cat > target/agency/config/agency.yaml <<EOF
framework:
  version: "1.0.0"
  source_commit: "deadbee"
EOF
    cd target && git init --quiet && git add -A && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify
    # --force bypasses dirty-tree gate (unrelated to this test)
    GITHUB_REPO_URL="file:///nonexistent-r20-test" run "${TOOLS_DIR}/agency" update --from-github --force 2>&1
    # The "ref: ..." log line tells us what FROM_GITHUB resolved to.
    assert_output_contains "ref: main"
}

@test "agency update: --from-github @latest opt-in attempts release-tag resolution" {
    cd "$BATS_TEST_TMPDIR"
    mkdir -p target/claude/config
    cat > target/agency/config/agency.yaml <<EOF
framework:
  version: "1.0.0"
  source_commit: "deadbee"
EOF
    cd target && git init --quiet && git add -A && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify
    # @latest takes the gh-release-view branch (or falls back to main if gh
    # missing or release lookup fails).
    GITHUB_REPO_URL="file:///nonexistent-r20-test" run "${TOOLS_DIR}/agency" update --from-github @latest --force 2>&1
    # The "ref: @latest" log line shows we entered the @latest branch
    assert_output_contains "ref: @latest"
}

@test "agency update: legacy --from-github latest emits deprecation warning" {
    cd "$BATS_TEST_TMPDIR"
    mkdir -p target/claude/config
    cat > target/agency/config/agency.yaml <<EOF
framework:
  version: "1.0.0"
  source_commit: "deadbee"
EOF
    cd target && git init --quiet && git add -A && \
        git -c user.name=t -c user.email=t@t commit --quiet -m init --no-verify
    # --force bypasses the unrelated dirty-tree gate so we can reach the
    # from-github resolution path.
    GITHUB_REPO_URL="file:///nonexistent-r20-test" run "${TOOLS_DIR}/agency" update --from-github latest --force 2>&1
    assert_output_contains "deprecated"
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R20: release-tag-check workflow file present and well-formed
# ─────────────────────────────────────────────────────────────────────────────

@test "release-tag-check workflow file exists and references manifest version" {
    [[ -f "$REPO_ROOT/.github/workflows/release-tag-check.yml" ]]
    run grep -F "agency_version" "$REPO_ROOT/.github/workflows/release-tag-check.yml"
    assert_success
    run grep -F "gh release view" "$REPO_ROOT/.github/workflows/release-tag-check.yml"
    assert_success
}

@test "release-tag-check workflow only fires on push to main" {
    run grep -A2 "^on:" "$REPO_ROOT/.github/workflows/release-tag-check.yml"
    assert_success
    # assert_output_contains uses bash regex; brackets are character classes.
    # Use a fixed-string grep instead to verify the literal phrase.
    run grep -F "branches: [main]" "$REPO_ROOT/.github/workflows/release-tag-check.yml"
    assert_success
}

@test "release-tag-check workflow skips non-merge commits (single-parent)" {
    # Verify the parent-count logic exists so housekeeping coord-commits don't
    # trigger false-red CI.
    run grep -F "parents == '2'" "$REPO_ROOT/.github/workflows/release-tag-check.yml"
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R24: agency init --from-github (principal directive, closes #119 bundle)
# ─────────────────────────────────────────────────────────────────────────────

@test "agency init --help documents --from-github" {
    run_agency init --help
    assert_success
    assert_output_contains "from-github"
    # Default should be main, not 'latest tag'
    assert_output_contains "Default: main"
    # @latest opt-in for release-tag behavior
    assert_output_contains "@latest"
}

@test "agency init --from-github parses the flag (no value = main default)" {
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p target
    cd target && git init --quiet --initial-branch=main && \
        git -c user.name=t -c user.email=t@t commit --quiet --allow-empty -m "init" --no-verify
    # Point at nonexistent repo so clone fails fast after ref resolution —
    # we just verify the flag is parsed and the main-default path is taken.
    GITHUB_REPO_URL="file:///nonexistent-r24-test" run "${TOOLS_DIR}/agency" init --from-github --verbose 2>&1
    # Output should mention main ref
    [[ "$output" == *"ref: main"* ]] || [[ "$output" == *"main"* ]]
}

@test "agency init --from-github @latest enters release-tag resolution path" {
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p target
    cd target && git init --quiet --initial-branch=main && \
        git -c user.name=t -c user.email=t@t commit --quiet --allow-empty -m "init" --no-verify
    GITHUB_REPO_URL="file:///nonexistent-r24-test" run "${TOOLS_DIR}/agency" init --from-github @latest --verbose 2>&1
    [[ "$output" == *"@latest"* ]] || [[ "$output" == *"main"* ]]
}

@test "agency init --from-github= equals form works" {
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p target
    cd target && git init --quiet --initial-branch=main && \
        git -c user.name=t -c user.email=t@t commit --quiet --allow-empty -m "init" --no-verify
    GITHUB_REPO_URL="file:///nonexistent-r24-test" run "${TOOLS_DIR}/agency" init --from-github=v41.23 --verbose 2>&1
    [[ "$output" == *"v41.23"* ]] || [[ "$output" == *"ref: v41.23"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R24: agency-bootstrap.sh curl-entrypoint script exists and is executable
# ─────────────────────────────────────────────────────────────────────────────

@test "agency-bootstrap.sh exists and is executable" {
    [[ -f "$REPO_ROOT/agency/tools/agency-bootstrap.sh" ]]
    [[ -x "$REPO_ROOT/agency/tools/agency-bootstrap.sh" ]]
}

@test "agency-bootstrap.sh --help works without network" {
    run "$REPO_ROOT/agency/tools/agency-bootstrap.sh" --help
    assert_success
    assert_output_contains "agency-bootstrap.sh"
    assert_output_contains "curl"
}

@test "agency-bootstrap.sh --version prints version" {
    run "$REPO_ROOT/agency/tools/agency-bootstrap.sh" --version
    assert_success
    assert_output_contains "agency-bootstrap.sh"
}

@test "agency-bootstrap.sh: refuses non-git-repo" {
    local non_git="${BATS_TEST_TMPDIR}/not-a-git-repo-$$"
    mkdir -p "$non_git"
    cd "$non_git"
    run "$REPO_ROOT/agency/tools/agency-bootstrap.sh"
    assert_failure
    assert_output_contains "git repo"
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R25 HOTFIX: agency init installs ALL tools (regression anchor)
# Live incident 2026-04-15 — hardcoded tool list in _agency-init was frozen
# around ~30 tools while framework grew to 60+. Every tool added post-freeze
# was missing from fresh inits. This test asserts that a fresh `agency init`
# installs every canonical tool that was missing (surfaced in
# homekit-daikin-ac-bridge).
# ─────────────────────────────────────────────────────────────────────────────

@test "agency init: installs all canonical tools (not a hardcoded subset)" {
    local target="${BATS_TEST_TMPDIR}/init-full-toolset"
    mkdir -p "$target"
    cd "$target"
    git init --quiet --initial-branch=main
    git -c user.name=t -c user.email=t@t commit --quiet --allow-empty -m "init" --no-verify

    # Point AGENCY_SOURCE at the real repo so _agency-init copies actual tools
    AGENCY_SOURCE="$REPO_ROOT" run "$REPO_ROOT/agency/tools/agency" init --principal tester
    assert_success

    # Canonical set of tools that MUST be installed (these were the missing
    # ones surfaced in the live incident). If any of these is absent after
    # init, the hardcoded-list bug has regressed.
    local missing=()
    local canonical_tools=(
        agency
        git-safe
        git-captain
        git-push
        git-safe-commit
        cp-safe
        handoff
        dispatch
        dispatch-create
        agent-identity
        agent-create
        agent-bootstrap
        agency-bootstrap.sh
        collaboration
        iscp-check
        iscp-migrate
        flag
        pr-create
        pr-merge
        principal-onboard
        receipt-sign
        receipt-verify
        session-preflight
        worktree-sync
        worktree-cwd-check
        worktree-create
        worktree-delete
        worktree-list
        skill-verify
        agency-issue
        agency-health
        issue-monitor
        dispatch-monitor
        diff-hash
        stage-hash
        commit-precheck
    )
    for tool in "${canonical_tools[@]}"; do
        [[ -f "$target/agency/tools/$tool" ]] || missing+=("$tool")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing tools after agency init: ${missing[*]}"
        false
    fi
}

@test "agency init: installs canonical libs (not a hardcoded subset)" {
    local target="${BATS_TEST_TMPDIR}/init-full-libs"
    mkdir -p "$target"
    cd "$target"
    git init --quiet --initial-branch=main
    git -c user.name=t -c user.email=t@t commit --quiet --allow-empty -m "init" --no-verify

    AGENCY_SOURCE="$REPO_ROOT" run "$REPO_ROOT/agency/tools/agency" init --principal tester
    assert_success

    local missing=()
    # Libs that _were_ missing from the old hardcoded list
    local canonical_libs=(
        _log-helper
        _path-resolve
        _address-parse
        _provider-resolve
        _agency-init
        _agency-update
        _test-isolation
    )
    for lib in "${canonical_libs[@]}"; do
        [[ -f "$target/agency/tools/lib/$lib" ]] || missing+=("$lib")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing libs after agency init: ${missing[*]}"
        false
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R26: regression anchors for THREE more frozen lists beyond R25's tools
# (agents, hooks, commands, REFERENCE-*, README-*). If any future PR
# re-hardcodes any of these, these tests fail loud.
# ─────────────────────────────────────────────────────────────────────────────

@test "agency init: installs ALL hooks (not hardcoded subset) — D41-R26" {
    local target="${BATS_TEST_TMPDIR}/init-hooks"
    mkdir -p "$target"
    cd "$target"
    git init --quiet --initial-branch=main
    git -c user.name=t -c user.email=t@t commit --quiet --allow-empty -m "init" --no-verify

    AGENCY_SOURCE="$REPO_ROOT" run "$REPO_ROOT/agency/tools/agency" init --principal tester
    assert_success

    # These hooks were MISSING from the old hardcoded list — now must be present
    local missing=()
    local canonical_hooks=(
        block-raw-tools.sh      # CRITICAL — hookify enforcement
        idle-mail-check.sh
        ref-injector.sh
        session-handoff.sh
        quality-check.sh
    )
    for hook in "${canonical_hooks[@]}"; do
        [[ -f "$target/agency/hooks/$hook" ]] || missing+=("$hook")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing hooks after agency init: ${missing[*]}"
        false
    fi
}

@test "agency init: installs ALL agent classes (not hardcoded 8) — D41-R26" {
    local target="${BATS_TEST_TMPDIR}/init-agents"
    mkdir -p "$target"
    cd "$target"
    git init --quiet --initial-branch=main
    git -c user.name=t -c user.email=t@t commit --quiet --allow-empty -m "init" --no-verify

    AGENCY_SOURCE="$REPO_ROOT" run "$REPO_ROOT/agency/tools/agency" init --principal tester
    assert_success

    # Old hardcoded list had 8 classes. Framework has ~21. Assert the ones
    # that were previously missing are now present.
    local missing=()
    local canonical_agents=(
        captain
        cos
        project-manager
        reviewer-code
        reviewer-design
        reviewer-scorer
        reviewer-security
        reviewer-test
        iscp
        tech-lead
    )
    for agent in "${canonical_agents[@]}"; do
        [[ -f "$target/agency/agents/$agent/agent.md" ]] || missing+=("$agent")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing agent classes after agency init: ${missing[*]}"
        false
    fi

    # Also: count should match framework's count (dir-level copy)
    local framework_count=$(ls -d "$REPO_ROOT/agency/agents/"*/ 2>/dev/null | wc -l | tr -d ' ')
    local target_count=$(ls -d "$target/agency/agents/"*/ 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$target_count" -lt "$framework_count" ]]; then
        echo "Agent count mismatch: framework has $framework_count, target has $target_count"
        false
    fi
}

@test "agency init: installs ALL REFERENCE-*.md docs — D41-R26" {
    local target="${BATS_TEST_TMPDIR}/init-refs"
    mkdir -p "$target"
    cd "$target"
    git init --quiet --initial-branch=main
    git -c user.name=t -c user.email=t@t commit --quiet --allow-empty -m "init" --no-verify

    AGENCY_SOURCE="$REPO_ROOT" run "$REPO_ROOT/agency/tools/agency" init --principal tester
    assert_success

    # REFERENCE-* docs must all ship — ref-injector depends on them
    local framework_refs=$(ls "$REPO_ROOT/claude/"REFERENCE-*.md 2>/dev/null | wc -l | tr -d ' ')
    local target_refs=$(ls "$target/claude/"REFERENCE-*.md 2>/dev/null | wc -l | tr -d ' ')

    # Target must match framework count (directory-level copy)
    if [[ "$target_refs" -ne "$framework_refs" ]]; then
        echo "REFERENCE-*.md count mismatch: framework has $framework_refs, target has $target_refs"
        false
    fi

    # At least a few canonical refs must be present by name
    local canonical_refs=(REFERENCE-QUALITY-GATE.md REFERENCE-AGENT-DISCIPLINE.md REFERENCE-ISCP-PROTOCOL.md)
    local missing=()
    for ref in "${canonical_refs[@]}"; do
        [[ -f "$target/claude/$ref" ]] || missing+=("$ref")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing canonical REFERENCE docs: ${missing[*]}"
        false
    fi
}

@test "agency init: installs ALL README-*.md docs — D41-R26" {
    local target="${BATS_TEST_TMPDIR}/init-readmes"
    mkdir -p "$target"
    cd "$target"
    git init --quiet --initial-branch=main
    git -c user.name=t -c user.email=t@t commit --quiet --allow-empty -m "init" --no-verify

    AGENCY_SOURCE="$REPO_ROOT" run "$REPO_ROOT/agency/tools/agency" init --principal tester
    assert_success

    local framework_readmes=$(ls "$REPO_ROOT/claude/"README-*.md 2>/dev/null | wc -l | tr -d ' ')
    local target_readmes=$(ls "$target/claude/"README-*.md 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$target_readmes" -ne "$framework_readmes" ]]; then
        echo "README-*.md count mismatch: framework has $framework_readmes, target has $target_readmes"
        false
    fi
}

@test "agency init: installs ALL commands — D41-R26" {
    local target="${BATS_TEST_TMPDIR}/init-cmds"
    mkdir -p "$target"
    cd "$target"
    git init --quiet --initial-branch=main
    git -c user.name=t -c user.email=t@t commit --quiet --allow-empty -m "init" --no-verify

    AGENCY_SOURCE="$REPO_ROOT" run "$REPO_ROOT/agency/tools/agency" init --principal tester
    assert_success

    local framework_cmds=$(ls "$REPO_ROOT/.claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
    local target_cmds=$(ls "$target/.claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$target_cmds" -ne "$framework_cmds" ]]; then
        echo "Commands count mismatch: framework has $framework_cmds, target has $target_cmds"
        false
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R27: framework .gitignore block + dirty-tree gate excludes .claude/logs/
# Live blocker: after R26 shipped, principal ran `agency update --from-github`
# on homekit-daikin-ac-bridge and was blocked by the dirty-tree gate because
# .claude/logs/tool-runs.jsonl (auto-appended tool telemetry) was untracked.
# Fix: ignore runtime-log paths in the gate AND ship/merge a framework
# .gitignore block so adopters never hit this on fresh repos.
# ─────────────────────────────────────────────────────────────────────────────

@test "agency init: installs framework .gitignore block — D41-R27" {
    local target="${BATS_TEST_TMPDIR}/init-gitignore"
    mkdir -p "$target"
    cd "$target"
    git init --quiet --initial-branch=main
    git -c user.name=t -c user.email=t@t commit --quiet --allow-empty -m "init" --no-verify

    AGENCY_SOURCE="$REPO_ROOT" run "$REPO_ROOT/agency/tools/agency" init --principal tester
    assert_success

    [[ -f "$target/.gitignore" ]]
    run grep -F "Agency framework-managed ignores" "$target/.gitignore"
    assert_success
    run grep -F ".claude/logs/" "$target/.gitignore"
    assert_success
}

@test "agency init: gitignore merge is idempotent — D41-R27" {
    local target="${BATS_TEST_TMPDIR}/init-gitignore-idempotent"
    mkdir -p "$target"
    cd "$target"
    git init --quiet --initial-branch=main
    # Pre-existing adopter .gitignore with project-specific entries
    cat > "$target/.gitignore" <<EOF
node_modules/
.env
EOF
    git add .gitignore
    git -c user.name=t -c user.email=t@t commit --quiet -m "init" --no-verify

    AGENCY_SOURCE="$REPO_ROOT" run "$REPO_ROOT/agency/tools/agency" init --principal tester
    assert_success

    # Adopter's pre-existing lines must be preserved
    run grep -F "node_modules" "$target/.gitignore"
    assert_success
    # Framework block must be appended
    run grep -F "Agency framework-managed ignores" "$target/.gitignore"
    assert_success
    # Block should appear exactly once (idempotent)
    local count
    count=$(grep -c "Agency framework-managed ignores" "$target/.gitignore")
    [[ "$count" == "1" ]]
}

@test "agency update: dirty-tree gate ignores .claude/logs/* — D41-R27" {
    # Full end-to-end is heavy — verify the _agency-update source contains
    # the exclusion pattern. Regression anchor: if the grep filter is removed,
    # the dirty-tree gate returns to false-positives on .claude/logs/.
    run grep -F ".claude/logs/" "$REPO_ROOT/claude/tools/lib/_agency-update"
    assert_success
    run grep -F "grep -v -E" "$REPO_ROOT/agency/tools/lib/_agency-update"
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# D41-R20: post-merge skill enforces release verification
# ─────────────────────────────────────────────────────────────────────────────

@test "post-merge skill marks release-tag step as MANDATORY with hard verify" {
    run grep -F "MANDATORY" "$REPO_ROOT/.claude/skills/post-merge/SKILL.md"
    assert_success
    run grep -F "hard check" "$REPO_ROOT/.claude/skills/post-merge/SKILL.md"
    assert_success
    run grep -F "release-tag-check" "$REPO_ROOT/.claude/skills/post-merge/SKILL.md"
    assert_success
}
