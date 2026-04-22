---
description: Run the quality gate — parallel agent review, fix cycle, test, report. Composable — called by /iteration-complete and /phase-complete.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Quality Gate — Composable Skill

Run the full quality gate protocol: parallel agent review → consolidate → bug-exposing tests → fix → coverage tests → confirm clean → present QGR.

This skill is **composable** — it runs the QG and returns the report. It does NOT commit, update the plan, or update the handoff. The caller (`/iteration-complete`, `/phase-complete`, `/plan-complete`) handles those steps.

The full QGR format and commit message structure are injected automatically via the ref-injector hook when this skill is invoked — refer to that injected content for the authoritative format.

The gate applies to **any artifact type** — code, commands, config, documentation. Adapt the review to the artifact: code gets correctness/security/performance review plus tests; commands and config get design review, spec compliance, and edge case analysis; documentation gets accuracy and completeness review. Report sections that don't apply are marked "N/A" with a brief explanation, never omitted.

## Arguments

- `$ARGUMENTS`: Description of what was completed (e.g., "Iteration 1.2: parser edge cases" or "Phase 1: types and parser"). Required — if empty, stop and ask the caller what was completed.
- `--base <ref>`: Baseline ref for the diff hash chain. Optional. If omitted, defaults to `origin/main`. Callers pass:
  - `/iteration-complete` → `--base {prior-iteration-commit}`
  - `/phase-complete` → `--base {phase-start-tag}`
  - `/pr-prep` / `/plan-complete` → `--base origin/main`

Parse `--base <ref>` out of `$ARGUMENTS` at the start of Step 0. The remainder is the description. If no `--base` is present, set `BASE_REF=origin/main`.

## Step 0: Preconditions

1. If `$ARGUMENTS` (after stripping `--base`) is empty, stop and ask what was completed before proceeding.
2. Run `./agency/tools/skill-verify --quiet`. If it fails, report the missing/invalid skills and stop — the framework is incomplete.
3. Run `git diff --stat HEAD` and `git status`. If no changed files, report "Nothing to gate — no changes since last commit" and stop.
4. Collect the list of changed files (staged + unstaged + untracked). This is the review scope.
5. **Capture Hash A** (original artifact into review): run `./agency/tools/diff-hash --base "$BASE_REF" --json` and capture the full SHA-256 from the JSON output. Record as `HASH_A`. This is the state of the code BEFORE any QG work begins.

## Step 1: Parallel review — Formal agents + own review

Launch **all four reviewer agents in parallel**, plus conduct your own review simultaneously.

### Reviewer agents

Provide each agent with the list of changed files and instruct them to read those files.

1. **reviewer-code** (subagent_type: `reviewer-code`) — Bugs, logic errors, null handling, type mismatches, runtime crashes. Focus on correctness.

2. **reviewer-security** (subagent_type: `reviewer-security`) — OWASP Top 10, injection risks, auth/authz gaps, data exposure, secrets. Focus on security.

3. **reviewer-design** (subagent_type: `reviewer-design`) — Architecture patterns, convention compliance, API design, structural consistency. Focus on design quality.

4. **reviewer-test** (subagent_type: `reviewer-test`) — Test coverage gaps, missing edge cases, stale assertions, test/implementation consistency. Focus on test quality.

Launch all four in a single parallel Agent tool call. Each agent runs independently with read-only tools (Read, Grep, Glob).

### Your own review

While agents run, read the changed files yourself. Look for:

- Architectural issues agents might miss (cross-cutting concerns, subtle interactions)
- Domain-specific concerns (business logic correctness, data model integrity)
- Convention violations specific to this project's patterns
- Integration issues between changed components

## Step 2: Score and consolidate

Take ALL findings from the 4 agents + your own review and send them to the **reviewer-scorer** agent (subagent_type: `reviewer-scorer`, model: haiku) for confidence scoring.

Provide the scorer with:

- The full list of findings (with file paths, descriptions, categories)
- The list of changed files for context

The scorer rates each finding 0-100. **Filter out findings scored below 50.** (The QG fixes real issues — threshold 50 catches anything the scorer considers "likely real." Note: the scorer's output shows both >=80 and >=50 thresholds for informational purposes — the QG uses >=50 as the operative threshold.)

Merge and deduplicate the surviving findings into a single prioritized list. Assign each an ID (1, 2, 3...).

**Capture Hash B** (raw review findings): write the consolidated findings list (the post-scorer, deduplicated, prioritized list with IDs) to a temp file — e.g., `$(mktemp -t qg-findings)`. Then run `./agency/tools/diff-hash --file <temp-file> --json` and capture the full SHA-256 as `HASH_B`.

### Capture Hash C (triage)

After the findings list is finalized (post-scorer, deduplicated, with author triage decisions — what's accepted, what's rejected, what's deferred into a bucket), write the triage summary to a temp file — e.g., `$(mktemp -t qg-triage)`. Include per-finding disposition (accept / reject / defer / bucket) and any rationale. Then run `./agency/tools/diff-hash --file <temp-file> --json` and capture the full SHA-256 as `HASH_C`.

## Step 3: Write bug-exposing tests

For each code issue in the consolidated list, write a test that **exposes the bug**.

- **Run the test and confirm it fails (red).** If the test passes, it doesn't expose the bug — rewrite it until it fails.
- Issues in config/docs that can't be tested programmatically are marked N/A in the report.
- Use the project's test infrastructure. Check for available test runners: `./agency/tools/test-run` if available, or the project's standard test command.

## Step 4: Fix issues

Fix each issue. **Re-run the exposing test and confirm it now passes (green).**

Red → green is the proof the fix works. If you can't demonstrate the red → green cycle, you don't have a valid bug-exposing test.

Do NOT defer findings. Fix everything. "Fix what you find."

## Step 5: Review test coverage

Using the reviewer-test findings (from Step 1), decide what additional tests are needed:

- Edge cases not covered
- Error paths not exercised
- Integration boundaries not tested
- Performance-sensitive paths not benchmarked

If the work has no testable code (pure docs/config), note "N/A" in the report.

## Step 6: Add coverage tests

Write the additional tests identified in Step 5.

## Step 7: Fix any new issues

If new tests expose problems, fix them.

## Step 8: Confirm all clean

Run checks scoped to the changed files. Use the project's quality tooling:

1. **Format check** — use `./agency/tools/commit-precheck` or the project's format command
2. **Lint** — use the project's lint command
3. **Typecheck** — if applicable
4. **Tests** — run the appropriate test suite via `./agency/tools/test-run` or the project's test command

Address any failures. Re-run until all pass. The Failing row must be 0.

## Step 9: Present quality gate report

Present the QGR in the **exact format** from the injected `quality-gate.md` reference. This includes all sections:

- Issues Found and Fixed table
- Quality Gate Accountability table
- Coverage Health table
- Checks table
- Quality Gate Summary (Stages 1-8)
- What Was Found and Fixed narrative
- Proposed Commit (message + files list)

The QGR format in the injected reference is the source of truth — do not use a different format.

### Agent attribution in the summary

In the "Stage 1 — Parallel Review" section, attribute findings to the formal agents:

```
**Stage 1 — Parallel Review**
- reviewer-code: N issues (bugs, logic errors, correctness)
- reviewer-security: N issues (security, injection, auth)
- reviewer-design: N issues (patterns, conventions, API design)
- reviewer-test: N issues (coverage gaps, stale tests, consistency)
- reviewer-scorer: scored N findings, N passed threshold (>=50)
- Own review: N issues (describe what you looked at)
```

## Step 10: Sign receipt (five-hash chain)

After presenting the QGR, sign a receipt via `./agency/tools/receipt-sign`. Receipts live in `agency/workstreams/{W}/qgr/` (or `rgr/` for review gates) with full provenance naming and a five-hash chain of trust.

### Capture Hash D (principal 1B1)

- **If principal 1B1 occurred** (this QG included a discussion/transcript with the principal, typically for `phase-complete` / `plan-complete` / `pr-prep`): hash the transcript file. Run `./agency/tools/diff-hash --file <transcript-path> --json` and capture the full SHA-256 as `HASH_D`. Record `HASH_D_SOURCE="transcript"` and `HASH_D_TRANSCRIPT=<transcript-path>`.
- **If auto-approved** (no 1B1 — typical for `iteration-complete`): set `HASH_D=$HASH_C` and `HASH_D_SOURCE="auto-approved — no principal 1B1"`. Omit `--hash-d-transcript`. (receipt-sign also auto-detects this when hash-d == hash-c.)

### Capture Hash E (final state)

After Step 8 confirmed everything is clean and all fixes are staged/written to disk, run `./agency/tools/diff-hash --base "$BASE_REF" --json` and capture the full SHA-256 as `HASH_E`. This is the final artifact state — what will be committed.

### Parse boundary and metadata

1. Parse the boundary type from `$ARGUMENTS` (first token after any `--base` is stripped): one of `iteration-complete`, `phase-complete`, `plan-complete`, `pr-prep`.
2. Detect principal via `./agency/tools/agency whoami` (or glob `usr/*/`).
3. Detect agent/workstream/project — from the agent's identity (`./agency/tools/agent-identity` if available) or from the caller's context. Workstream typically matches the current branch/worktree; project matches the active plan/A&D.
4. Write a short `--summary` string derived from the description in `$ARGUMENTS` (the text after the boundary token).

### Call receipt-sign

```
./agency/tools/receipt-sign \
  --type qgr \
  --boundary <iteration-complete|phase-complete|plan-complete|pr-prep> \
  --org the-agency \
  --principal <principal> \
  --agent <agent> \
  --workstream <workstream> \
  --project <project> \
  --hash-a "$HASH_A" \
  --hash-b "$HASH_B" \
  --hash-c "$HASH_C" \
  --hash-d "$HASH_D" \
  --hash-e "$HASH_E" \
  --hash-d-source "$HASH_D_SOURCE" \
  [--hash-d-transcript "$HASH_D_TRANSCRIPT"] \
  --diff-base "$BASE_REF" \
  --summary "<short summary>"
```

Capture the receipt path printed by `receipt-sign` (it writes to `agency/workstreams/{W}/qgr/` with the naming convention `{org}-{principal}-{agent}-{ws}-{proj}-qgr-{boundary}-{YYYYMMDD-HHMM}-{hash_e_short}.md`).

### Report to caller

Report: "Receipt signed: `agency/workstreams/{W}/qgr/{filename}`"

### Backward compatibility note

Do NOT write the old `usr/{principal}/{project}/qgr-*.md` stage-hash receipt — that path is retired. During transition, `receipt-verify` still recognizes old-format receipts at `usr/**/qgr-*.md` (per Plan Iteration 1.4) so in-flight PRs aren't broken, but new QG runs MUST emit receipts only via `receipt-sign`. The sunset condition: backward compat is removed when no old-format receipts remain in the repo.

## Done

After signing the receipt, the skill is complete. The caller handles:

- Committing (auto for iteration, approval-required for phase/plan)
- Updating the plan file (append QGR inline)
- Updating the handoff file

Return control to the caller.
