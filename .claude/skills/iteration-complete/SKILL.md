---
description: Run the quality gate after completing an iteration — review, fix, test, report, auto-commit
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Iteration Complete

Run this after completing each iteration. Invokes `/quality-gate` for the review+fix cycle, then auto-commits — no principal approval needed.

## Arguments

- $ARGUMENTS: Description of what was completed. Must include boundary type and phase-iteration (e.g., "iteration-complete 1.2: parser edge cases"). If empty or missing phase-iteration, ask the user before proceeding.

## Steps

### Step 1: Preconditions

1. If `$ARGUMENTS` is empty, ask the user what was completed before proceeding.
2. Run `git diff --stat HEAD` and `git status`. If no changed files, tell the user "Nothing to gate — no changes since last commit" and stop.
3. Identify the plan file in `docs/plans/` that this work belongs to. If none exists, note "no plan file" — the commit message will omit the Plan: line.

### Step 2: Determine the prior-iteration base ref

The QG's Hash A/Hash E diff is computed against the **prior iteration commit** (or the phase-start commit if this is the first iteration in the phase). Determine it as follows, in order:

1. **Read the plan file** in `docs/plans/` (or `claude/workstreams/*/`) for an iteration history / status table. The most recent prior iteration's commit SHA is the base. Many plans record this under "Quality Gate Reports" or a status table.
2. **Grep git log** for the prior iteration's commit: `git log --oneline --grep="Phase <P>\\." | head` — e.g., for iteration 1.3, the base is the SHA of the commit titled "Phase 1.2: ...". If this is iteration X.1 (first iteration in the phase), use the phase-start tag / commit (e.g., `v{phase}.0` or the commit titled "Phase <P-1>: ..." if no tag).
3. **Fallback:** `HEAD~1` — use only if steps 1 and 2 yield nothing, and note this in the handoff update as a fallback used.

Capture the SHA/ref as `$BASE_REF`.

### Step 3: Run the quality gate

Invoke `/quality-gate` via the Skill tool, passing arguments that include both the boundary description AND the base ref:

```
iteration-complete 1.2: parser edge cases --base <BASE_REF>
```

For example: `iteration-complete 1.2: parser edge cases --base abc1234`.

The leading `iteration-complete <phase-iter>` tells `/quality-gate` the boundary type (used in the receipt filename). The `--base <ref>` tells `/quality-gate` what baseline to use for Hash A / Hash E via `diff-hash --base`.

This runs the full QG protocol: parallel agent review → consolidate → bug-exposing tests → fix → coverage tests → confirm clean → present QGR → sign receipt via `receipt-sign` (five-hash chain, written to `claude/workstreams/{W}/qgr/`). Iteration-complete is auto-approved — Hash D = Hash C.

Wait for the QGR to be presented and the receipt signed before proceeding.

### Step 4: Commit automatically

At iteration boundaries, no approval is needed. Commit automatically after a clean QGR.

Use `/git-safe-commit` via the Skill tool. Pass it the full structured commit message from the QGR's "Proposed Commit" section. The message must follow the format from the injected `quality-gate.md` reference.

### Step 5: Update the plan

After committing, update the plan file in `docs/plans/` to reflect:

- What was done in this commit (iteration/phase status change)
- What the quality gate found (bugs fixed, test gaps closed)
- Any changes to the plan itself (scope adjustments, reordering, new findings)
- Iteration-level status table for multi-iteration phases
- **Append the full QGR** (all three tables + summary) under a "Quality Gate Reports" section. Each iteration gets its own subsection. This is required — the plan is the living record.

### Step 6: Update handoff

Locate the handoff file for this project (glob `usr/*/*/handoff.md` or `usr/*/captain/handoff.md`). Update with:

- Current phase and iteration status
- What was just committed (summary, not full QGR)
- What's next (next iteration or phase-complete)
- Any decisions made or context that would help a fresh session continue

### Step 7: Emit iteration-complete dispatch to captain (NEW — small-batch cadence)

Structured dispatch so captain's auto-ship daemon can respond. **Must run AFTER the commit (Step 4) so `commit_hash` is current.**

Capture these values:
- `ITERATION_SLUG` — from `$ARGUMENTS` (e.g., "1.2")
- `PHASE_NUM` — the phase number from the iteration slug
- `BRANCH` — current branch via `git branch --show-current`
- `COMMIT_HASH` — the commit you just made
- `SUMMARY` — one-line iteration summary from the commit's first line
- `RECEIPT_PATH` — the QGR receipt path from Step 3

Resolve captain's address: glob `usr/*/captain/` for the principal directory name, then captain address is `{repo}/{principal}/captain`. Repo is derived from the current repository name.

Emit the dispatch:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch create \
  --to {repo}/{principal}/captain \
  --type iteration-complete \
  --subject "Iteration {ITERATION_SLUG} complete on {BRANCH}" \
  --body "<structured YAML — see below>"
```

Body format (embed as plain text, captain parses):

```yaml
event: iteration-complete
iteration: {ITERATION_SLUG}
phase: {PHASE_NUM}
branch: {BRANCH}
commit_hash: {COMMIT_HASH}
summary: {SUMMARY}
qgr_receipt: {RECEIPT_PATH}
emitted_at: {ISO-8601 timestamp}
```

**Cascade isolation:** the commit-dispatch hook in `git-safe-commit` already skips its own cascade when `AGENCY_SKILL_BYPASS_CASCADE=1` is set in the environment. If the skill's agent runs multiple commits and you want to be SURE the cascade doesn't interfere, export this env var at skill start and unset it at skill end.

### Note

This command handles iteration boundaries only. At phase boundaries, use `/phase-complete` instead — it runs a deep QG, requires principal approval, and lands on master.

After completing this iteration, move to the next iteration. When all iterations in a phase are done, run `/phase-complete`.

### Cadence note (small-batch-cadence project)

Step 7's iteration-complete dispatch triggers captain's `auto-ship` daemon which opens a PR, waits for CI, and merges on green. Agents don't need to push or open PRs themselves — the daemon handles delivery to origin. See `claude/workstreams/captain/small-batch-cadence-*.md` for the full design (v1.1).
