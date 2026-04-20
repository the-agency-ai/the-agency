## Code Review and PR Lifecycle

### Three Review Tools

| Tool              | When                        | Who runs it    | Depth                                                  | Fix cycle                |
| ----------------- | --------------------------- | -------------- | ------------------------------------------------------ | ------------------------ |
| `/code-review`    | After PR branch is built    | Captain        | 7 review agents + scoring, confidence >= 80            | No — dispatches findings |
| `/review-pr`      | Ad-hoc, after PR exists     | Human/agent    | 1 agent, max 5 comments, human approval before posting | No                       |
| `/phase-complete` | At iteration/phase boundary | Worktree agent | Deep QG, 2+ code + 2+ test agents, red-green fix cycle | Yes                      |

These serve different purposes at different points. They do not replace each other.

### Captain PR Lifecycle

The captain (coordination session on master) manages the full PR cycle:

```
1. /sync-all — merge worktree work into master
2. Rebuild PR branches (reset -> squash -> stage -> commit)
3. /captain-review --all — review all PR branches locally (runs against git diff, no GitHub PR needed)
4. If issues found: dispatch to worktree agents via dispatch files
5. Worktree agents fix issues -> land on master via /iteration-complete
6. If no issues (or after fixes land): rebuild PR branches (now includes fixes + review files)
7. Push and create draft PRs (review results visible in the diff)
8. Human review -> convert to ready-for-review -> merge
```

Reviews run **locally** against `git diff origin/master...<branch>`. No GitHub PR is required. Reviews happen BEFORE PRs are created. The review results are committed to the repo and included in the PR diff.

If all PRs are clean (zero issues >= 80 confidence), skip steps 4-5 and proceed directly to step 6.

### Code Review Dispatch

When the captain runs `/captain-review`, it generates two files per project:

1. **Review file** — `agency/workstreams/{workstream}/qgr/{workstream}-review-YYYYMMDD-HHmm.md`
   - Full review output from all 7 agents
   - All issues with confidence scores
   - Filtered issues (>= 80) and below-threshold issues

2. **Dispatch file** (if issues found) — `agency/workstreams/{workstream}/qgr/{workstream}-dispatch-YYYYMMDD-HHmm.md`
   - Issues to fix, with file paths, line numbers, suggested fixes
   - Reviewed commit SHA for staleness checking
   - Instructions for the worktree agent

The captain commits review and dispatch files to master, then notifies the worktree agent.

### Worktree Agent: Handling a Dispatch

When you receive a review dispatch via ISCP:

1. Run `dispatch list` to see pending dispatches with their integer IDs
2. Run `dispatch read <id>` to read the payload and mark it as read
3. Evaluate findings, fix with red-green cycle, append a resolution table
4. Run `/iteration-complete` to commit your fixes
5. Run `dispatch resolve <id>` to mark the dispatch resolved
6. For review dispatches, send a `review-response` dispatch with `--reply-to <id>`

The dispatch file itself is **review input** from an independent 7-agent review process — not an action list. Use your judgment.

1. **Merge master** to pick up the dispatch file (if the payload is on master)
2. **Read the dispatch file** — most recent in `agency/workstreams/{workstream}/qgr/`
3. **Check the reviewed SHA** — verify it's in your branch history
4. **Evaluate each finding for validity.** Investigate the code. Document your assessment.
5. **For valid findings, write a bug-exposing test.** Confirm it fails (red).
6. **Fix the issue.** Confirm the test passes (green).
7. **For disputed findings,** document your reasoning. Do not silently skip.
8. **Append a resolution table** to the dispatch file:

```markdown
### Resolution

| #   | Finding                   | Status   | Action                                       | Tests |
| --- | ------------------------- | -------- | -------------------------------------------- | ----- |
| 1   | Loop detection wrong node | Fixed    | Rewrote detectLoop to check nextNode         | +3    |
| 2   | Nested resolver binding   | Fixed    | Added getNestedValue helper                  | +2    |
| 11  | Resolver shape mismatch   | Disputed | buildEvalCtx flattens outputs, paths correct | N/A   |

Commit: <SHA>
```

Status values: **Fixed**, **Disputed** (with reasoning), **Stale** (code changed since review), **Deferred** (with reason), **N/A** (not applicable).

9. **Run `/iteration-complete`** — the QG validates your work.
10. **Land on master** — the captain detects your commit during the next `/sync-all`.

### Review File Convention

```
agency/workstreams/{workstream}/
  qgr/
    {workstream}-review-YYYYMMDD-HHmm.md
    {workstream}-dispatch-YYYYMMDD-HHmm.md
```

YYYYMMDD-HHmm timestamps — multiple reviews per day get unique timestamps. These files are committed to the repo and appear in the PR diff as the audit trail.
