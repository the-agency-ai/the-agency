---
allowed-tools: Bash(./claude/tools/stage-hash:*), Bash(./claude/tools/test-run:*), Bash(./claude/tools/commit-precheck:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Read, Glob, Grep, Edit, Write, Agent, Skill
description: Run the quality gate — parallel agent review, fix cycle, test, report. Composable — called by /iteration-complete and /phase-complete.
---

# Quality Gate — Composable Skill

Run the full quality gate protocol: parallel agent review → consolidate → bug-exposing tests → fix → coverage tests → confirm clean → present QGR.

This skill is **composable** — it runs the QG and returns the report. It does NOT commit, update the plan, or update the handoff. The caller (`/iteration-complete`, `/phase-complete`, `/plan-complete`) handles those steps.

The full QGR format and commit message structure are injected automatically via the ref-injector hook when this skill is invoked — refer to that injected content for the authoritative format.

The gate applies to **any artifact type** — code, commands, config, documentation. Adapt the review to the artifact: code gets correctness/security/performance review plus tests; commands and config get design review, spec compliance, and edge case analysis; documentation gets accuracy and completeness review. Report sections that don't apply are marked "N/A" with a brief explanation, never omitted.

## Arguments

- `$ARGUMENTS`: Description of what was completed (e.g., "Iteration 1.2: parser edge cases" or "Phase 1: types and parser"). Required — if empty, stop and ask the caller what was completed.

## Step 0: Preconditions

1. If `$ARGUMENTS` is empty, stop and ask what was completed before proceeding.
2. Run `git diff --stat HEAD` and `git status`. If no changed files, report "Nothing to gate — no changes since last commit" and stop.
3. Collect the list of changed files (staged + unstaged + untracked). This is the review scope.

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

## Step 3: Write bug-exposing tests

For each code issue in the consolidated list, write a test that **exposes the bug**.

- **Run the test and confirm it fails (red).** If the test passes, it doesn't expose the bug — rewrite it until it fails.
- Issues in config/docs that can't be tested programmatically are marked N/A in the report.
- Use the project's test infrastructure. Check for available test runners: `./claude/tools/test-run` if available, or the project's standard test command.

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

1. **Format check** — use `./claude/tools/commit-precheck` or the project's format command
2. **Lint** — use the project's lint command
3. **Typecheck** — if applicable
4. **Tests** — run the appropriate test suite via `./claude/tools/test-run` or the project's test command

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

## Step 10: Write QGR receipt file

After presenting the QGR, write it to a standalone file as the commit receipt. `/git-commit` checks for this file before allowing a commit.

### Naming convention

```
usr/{principal}/{project}/qgr-{boundary}-{phase-iter}-{stage-hash}-YYYYMMDD-HHMM.md
```

Where:
- `{principal}` — detected via `./claude/tools/agency whoami` or glob `usr/*/`
- `{project}` — the agent/project directory name
- `{boundary}` — one of: `iteration-complete`, `phase-complete`, `plan-complete`, `pr-prep`
- `{phase-iter}` — phase and iteration numbers (e.g., `1-2` for Phase 1, Iteration 2; `2` for Phase 2; omit for `pr-prep`)
- `{stage-hash}` — 7-character deterministic hash of the staged changes (computed by `./claude/tools/stage-hash`)
- `YYYYMMDD-HHMM` — timestamp

### How to write it

1. Parse the boundary type and phase-iteration from `$ARGUMENTS`. The caller (e.g., `/iteration-complete`) passes these. If not parseable, ask the caller.
2. Stage the files that will be committed: `git add` the relevant files.
3. Compute the stage hash: run `./claude/tools/stage-hash` and capture the output.
4. Generate the timestamp: `YYYYMMDD-HHMM` from the current time.
5. Write the full QGR content (as presented in Step 9) to the file.
6. Report the file path to the caller: "QGR receipt written to: `{path}`"

## Done

After writing the QGR receipt, the skill is complete. The caller handles:

- Committing (auto for iteration, approval-required for phase/plan)
- Updating the plan file (append QGR inline)
- Updating the handoff file

Return control to the caller.
