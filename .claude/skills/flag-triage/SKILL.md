---
allowed-tools: Bash(bash $CLAUDE_PROJECT_DIR/claude/tools/flag *), Bash(bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch *), Bash(./claude/tools/flag *), Bash(./claude/tools/dispatch *), Read, Write
description: Structured flag review — categorize, approve, dispose. Three-bucket triage for accumulated flags.
---

# Flag Triage

Structured review session for accumulated flags. Agent pre-categorizes into three buckets, principal approves dispositions, then each bucket is processed.

## Arguments

- `$ARGUMENTS`: Optional. No arguments needed — operates on all unprocessed flags.

## Instructions

### Step 1: Gather flags

Run `bash $CLAUDE_PROJECT_DIR/claude/tools/flag list` to get all unread/read flags.

If no flags are waiting, report "No flags to triage" and stop.

### Step 2: Categorize into three buckets

Review each flag and assign it to one of three buckets. Present the categorization to the principal as a numbered table:

**Bucket 1 — Resolved:** Items that are already done, no longer relevant, or overtaken by events. For each, cite the evidence (commit, dispatch, code change) that resolves it.

**Bucket 2 — Autonomous:** Items the agent can handle independently — writing seeds, sending dispatches, updating docs, filing bugs, creating tools. No principal collaboration needed. For each, state the proposed disposition (what you'll do).

**Bucket 3 — Collaborative:** Items requiring principal input, joint decision-making, or 1B1 discussion. For each, state why it needs discussion.

Format:

```
## Flag Triage — [N] items

### Bucket 1: Resolved ([n] items)
| # | Flag | Evidence | Disposition |
|---|------|----------|-------------|
| 1 | ... | commit abc123 fixed this | Mark resolved |

### Bucket 2: Autonomous ([n] items)
| # | Flag | Proposed Action |
|---|------|----------------|
| 4 | ... | Write seed to iscp workstream |

### Bucket 3: Collaborative ([n] items)
| # | Flag | Why discuss? |
|---|------|-------------|
| 7 | ... | Needs prioritization decision |
```

### Step 3: Principal review

**STOP and wait for principal approval.** The principal may:
- Approve all bucket assignments
- Move items between buckets
- Add context to specific items
- Reject categorizations

Do NOT proceed until the principal approves the bucket assignments.

### Step 4: Process Bucket 1 (Resolved)

For each approved Bucket 1 item:
- Run `bash $CLAUDE_PROJECT_DIR/claude/tools/flag clear` if all flags are being resolved
- Report: "[n] items marked resolved"

### Step 5: Process Bucket 2 (Autonomous)

For each approved Bucket 2 item, execute the proposed disposition:
- **Write seed:** Create seed file in the appropriate workstream's `seeds/` directory
- **Send dispatch:** Use `dispatch create --to <agent> --subject <text> --body <text>`
- **Update docs:** Edit the relevant file directly
- **File bug:** Use `/agency-bug` or create a dispatch
- **Create tool:** Write to `usr/{principal}/{project}/tools/`

Report each action taken with the artifact created (file path, dispatch ID, etc.).

### Step 6: Process Bucket 3 (Collaborative)

Enter 1B1 discussion mode for collaborative items. For each item:

1. Present the item with context
2. Three possible dispositions per item:
   - **Action now** — do the work in this session
   - **Flag to project** — create a seed, dispatch, or backlog item for later
   - **Bin** — discard as not worth pursuing
3. Execute the chosen disposition before moving to the next item

Use the standard 1B1 protocol: present → feedback → resolve → next.

### Step 7: Summary

After all buckets are processed, report:

```
## Triage Complete

- Resolved: [n] items
- Autonomous: [n] items ([n] dispatches sent, [n] seeds written, ...)
- Collaborative: [n] items ([n] actioned, [n] flagged to project, [n] binned)
- Total: [N] flags processed
```

Run `bash $CLAUDE_PROJECT_DIR/claude/tools/flag clear` to mark all processed flags.

## Key Rules

- **All bucket assignments require principal approval** — never auto-process
- **Bucket 2 items must produce artifacts** — dispatches, seeds, PRs, docs. Not just "noted"
- **Bucket 3 uses 1B1 protocol** — one item at a time, resolve before moving on
- **Evidence required for Bucket 1** — don't mark resolved without citing proof

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
