## Code Review and PR Lifecycle

### Three Review Tools

| Tool              | When                        | Who runs it    | Depth                                                  | Fix cycle                |
| ----------------- | --------------------------- | -------------- | ------------------------------------------------------ | ------------------------ |
| `/code-review`    | After PR branch is built    | Captain        | 7 review agents + scoring, confidence >= 80            | No — dispatches findings |
| `/review-pr`      | Ad-hoc, after PR exists     | Human/agent    | 1 agent, max 5 comments, human approval before posting | No                       |
| `/phase-complete` | At iteration/phase boundary | Worktree agent | Deep QG, 2+ code + 2+ test agents, red-green fix cycle | Yes                      |

These serve different purposes at different points. They do not replace each other.

### Captain PR Lifecycle

The captain (coordination session on the default branch, in the main checkout) owns the PR cycle end to end. The whole lifecycle is **local-first**: work is reviewed and validated locally, and GitHub is where already-validated work is published.

```
1. /captain-sync-all — fetch, merge origin, merge worktree work, sync worktrees (never pushes)
2. /captain-review --all — review branches locally (runs against git diff, no GitHub PR needed)
3. If issues found: dispatch to worktree agents; they fix and re-run /iteration-complete
4. Agent runs /pr-prep (QG + signed QGR receipt), pushes, then /pr-submit (dispatches captain)
5. Captain runs /pr-captain-land <branch> — see below
```

Reviews run **locally** against `git diff origin/<default>...<branch>`. No GitHub PR is required. Reviews happen BEFORE PRs are created. Review results are committed and appear in the PR diff.

#### `/pr-captain-land` — local-first landing

The landing does **not** switch the main checkout to the agent's branch, and does **not** merge into or push local `main`. Instead:

```
0-1. Fetch; verify the branch on origin and that origin/<default> is an ancestor of it
     (stale base BLOCKS with "merge <default> + re-run /pr-prep", not a hash error)
2.   Cut a scratch worktree  _land-<branch>  at  origin/<agent-branch>
2b.  Verify the agent's QGR receipt against that tree — BEFORE any mutation
3.   VALIDATE LOCALLY in the scratch (build + tests + commit-precheck). THIS IS THE GATE.
     Failure → delete the scratch, dispatch the agent, nothing published.
4-5. Bump agency_version in the scratch; sign a captain landing receipt chained to the
     agent's (hash_a = agent hash_e). pr-create is not weakened.
6.   Push the scratch branch, open the PR (_land-<branch> → default)
7.   Wait on the AGGREGATE statusCheckRollup — every required context green. An empty
     rollup is a distinct error, never a silent pass. No hardcoded check name.
8.   pr-merge (true merge commit) → gh-release
9.   Delete the scratch + land branch, dispatch the agent, clear post-merge state, and
     reconcile local main with an idempotent merge-from-origin
```

**Rollback at any pre-publish failure is deleting the scratch worktree.** No `git reset --hard`, no merge abort, no stranded main checkout. A dirty main checkout does not block a land, because the land never touches it.

`/pr-captain-land <branch> --rehearse` runs steps 0-3 only — integrate and validate with zero side effects. Rehearse before the first land of any unfamiliar branch.

Only one `/pr-captain-land` at a time (they would race on the version bump). Two runs for the *same* branch are blocked mechanically by the leftover-scratch precondition.

Full protocol: `.claude/skills/pr-captain-land/reference.md`.

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
