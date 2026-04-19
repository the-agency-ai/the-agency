# pr-submit — examples

## Happy-path examples

### Agent finishes work, dispatches captain

Agent in `.claude/worktrees/devex`, branch `jordan-devex-d12-r3`, tree clean, pushed, receipt signed from `/pr-prep`:

```
/pr-submit --scope "devex: fix worktree-sync MAIN_BRANCH resolution — never read HEAD of main checkout"
```

Expected:

```
[pr-submit] Preflight OK: worktree=devex, branch=jordan-devex-d12-r3, sha=a3f9b21, pushed=ok
[pr-submit] Diff hash: 8b4c2e1 (vs origin/master)
[pr-submit] Receipt: claude/workstreams/devex/qgr/monofolk-jordan-devex-devex-d12r3-qgr-pr-prep-20260419-1430-8b4c2e1.md
[pr-submit] Dispatched to monofolk/jordan/captain as d-019da47f-8b4c
→ Captain will run /pr-captain-land jordan-devex-d12-r3
→ You'll receive a master-updated dispatch when the PR lands.
```

Size: S. Fast pass, ~2-3 seconds.

### High-priority submission

Agent has a fleet-blocking fix ready:

```
/pr-submit --scope "devex: fix raw gh pr create block breaking every worktree" --priority high
```

Dispatch is marked `priority: high` — captain's dispatch monitor surfaces it above normal-priority items.

## Failure-mode examples

### Not in a worktree

Agent accidentally runs from main checkout:

```
/pr-submit --scope "..."
```

```
[pr-submit] ERROR: Preflight failed — not in an agent worktree.
  Current: /Users/jordan_of/code/monofolk (main checkout)
  Expected: .claude/worktrees/<name>/
  Fix: cd into the agent's worktree, or if you're captain, use /pr-captain-land instead.
```

Exit 1. No dispatch sent.

### Dirty tree

```
/pr-submit --scope "..."
```

```
[pr-submit] ERROR: Preflight failed — tree not clean.
  Uncommitted: 2 files (src/foo.ts, tests/foo.test.ts)
  Fix: commit or stash via /git-safe-commit or /session-compact.
```

Exit 1.

### Unpushed or diverged from origin

```
[pr-submit] ERROR: Preflight failed — local HEAD and origin/<branch> diverge.
  local:  a3f9b21
  origin: e47ce53
  Fix: run /sync or push via ./claude/tools/git-push <branch>.
```

Exit 1.

### Receipt missing

```
[pr-submit] ERROR: Preflight failed — no QGR receipt matches current diff-hash (8b4c2e1).
  Searched: claude/workstreams/**/qgr/*qgr-pr-prep-*-8b4c2e1.md
  Fix: run /pr-prep to sign a fresh receipt, then re-try /pr-submit.
```

Exit 1. The receipt is the proof the QG ran against this exact state; no skipping.

### Multiple receipts match (warning, not failure)

Rare — two `/pr-prep` runs produced matching hashes (e.g., no change between runs):

```
[pr-submit] WARN: 2 receipts match diff-hash 8b4c2e1. Using most recent:
  claude/workstreams/devex/qgr/monofolk-jordan-devex-devex-d12r3-qgr-pr-prep-20260419-1430-8b4c2e1.md
[pr-submit] Dispatched to captain as d-019da47f-8b4c
```

Proceeds with exit 0. Captain re-verifies during `/pr-captain-land`.

## Dispatch payload example

The dispatch body that lands in captain's inbox (see `reference.md` for full schema):

```markdown
# Ready for PR landing — devex: fix worktree-sync MAIN_BRANCH resolution

## Branch ready

- **Branch:** `jordan-devex-d12-r3`
- **Agent:** monofolk/jordan/devex
- **HEAD:** `a3f9b21f...` (pushed to origin)
- **Diff base:** `origin/master`
- **Diff hash:** `8b4c2e1`

## QGR receipt

- **Path:** `claude/workstreams/devex/qgr/monofolk-jordan-devex-devex-d12r3-qgr-pr-prep-20260419-1430-8b4c2e1.md`
- **Verified:** local receipt file matches current state

## Scope summary

devex: fix worktree-sync MAIN_BRANCH resolution — never read HEAD of main checkout

## Captain action requested

Run /pr-captain-land on branch `jordan-devex-d12-r3`:

1. Switch to `jordan-devex-d12-r3`
2. Verify receipt against current state
3. Bump `monofolk_version` in manifest (serialized — single writer)
4. Create PR with captain-authored fleet-aware description
5. Watch CI (`lint-and-test` gate)
6. Merge when green
7. Create GitHub release v{monofolk_version}
8. Dispatch back with merge confirmation + release tag

## What I (agent) will NOT do

- Create the PR myself
- Bump `monofolk_version` myself
- Merge myself
- Create the release myself

Captain owns the PR lifecycle. I stand by to /pr-respond if review comments come.

Over.

-- monofolk/jordan/devex
```

## What to expect next

Captain picks up the dispatch (either via `dispatch-monitor` or manual read), runs `/pr-captain-land <branch>`, and you eventually get back:

- `master-updated` dispatch with PR URL + release tag
- Any review comments routed via `/pr-respond`
- If CI fails or receipt mismatches: a `pr-submit-rejected` dispatch telling you to re-prep and re-submit

No additional action required from the agent unless review or rejection comes.
