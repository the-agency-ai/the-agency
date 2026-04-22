## PR Lifecycle

### Overview

All changes reach origin/master through PRs. The captain orchestrates the lifecycle.

### "No Pre-Commit Code Reviews"

The Agency runs code review **before PRs are created**, not after. This inverts the typical GitHub flow:

1. Worktree agents build and test locally (quality gates at every commit)
2. Captain reviews locally against `git diff` (no GitHub PR needed yet)
3. Issues found are dispatched back to worktree agents
4. Only after code passes local review does the captain push and create a PR
5. GitHub PR review is the human oversight layer — the automated review already happened

### Why?

- Review results are committed to the repo (audit trail)
- Faster iteration (no waiting for CI/GitHub)
- Works before PRs exist
- Review customizable (7 agents, configurable focus areas)
- Size limits of external review tools don't apply

### The Flow

```
Agent builds on worktree branch
  -> Lands on local master via `git push . HEAD:master`
  -> Captain runs /sync-all (detects new work)
  -> Captain rebuilds PR branch (squash)
  -> Captain runs /captain-review (local, 7 agents)
  -> If issues: dispatch to worktree agent, iterate
  -> If clean: push PR branch, create draft PR
  -> Human reviews, approves, merges
  -> /post-merge syncs everything
```

### Conventions

- **Remote master is read-only.** Never push directly.
- **PR branches are ephemeral.** Rebuilt from master on each cycle.
- **Review files live in the repo.** Committed alongside the code they review.
- **Principal decides disposition.** Captain never merges a PR autonomously.
