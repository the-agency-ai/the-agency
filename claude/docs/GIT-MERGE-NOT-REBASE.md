# Git Discipline: Merge, Never Rebase

## The Rule

All branch synchronization in Agency projects uses **merge**, never **rebase**. This applies to:

- Master syncing with origin (`/sync-all`)
- Worktrees syncing with master (`/worktree-sync`, `git merge master`)
- Branches syncing before push (`/sync`)
- Post-PR-merge recovery (`/post-merge`)

## Why

Rebase rewrites commit history. In an Agency project with multiple worktrees, rewritten history breaks merge-bases between master and every worktree. This can cause:

1. **Data loss** — `git reset --hard origin/master` after detecting divergence drops all local commits not on origin, including installed framework files
2. **Cascade conflicts** — rebased master forces all worktrees to rebase too, creating conflict cascading across the fleet
3. **Disconnected histories** — if local and origin have different root commits (e.g., from initial repo setup differences), rebase cannot reconcile them

Merge preserves history. The merge commit creates a permanent connection point. Future operations find this as the merge-base and proceed normally.

## The Incident (2026-04-08)

A monofolk project with 13 active worktrees ran `/sync-all`. The divergence handler (Step 2.5) detected that origin/master had 157 new commits (from merged squash PRs) while local master had 363 commits (Agency framework + worktree work). The handler ran `git reset --hard origin/master`, which:

- Dropped the entire Agency framework installation from local master
- Broke all 13 worktrees (no valid merge-base with the reset master)
- Lost the statusline, hooks, permissions, dispatch system
- Required a 2-hour restore from a recovery tag + manual conflict resolution

Root cause: local repo and origin had different root commits (identical content, different SHAs — from GPG signature differences during initial setup). This made `git merge-base` return nothing, and the reset handler assumed all local work was already on origin.

## Enforcement (Triangle)

| Layer | Component | What it does |
|-------|-----------|-------------|
| **Hookify** | `block-reset-to-origin` | Blocks `git reset --hard origin/*` |
| **Hookify** | `block-raw-rebase` | Blocks `git rebase` |
| **Skill** | `/sync-all` | Uses `git merge origin/master` with merge-base guard |
| **Skill** | `/sync` | Uses `git merge <target>` before push (not rebase) |
| **Skill** | `/post-merge` | Uses `git merge origin/master` after PR merge (not reset) |
| **Skill** | `/worktree-sync` | Uses `git merge master` (already correct) |
| **Skill** | `/rebase` | DEPRECATED — points to merge-based alternatives |

## Git & Remote Discipline

**Universal rules (all agents):**

- **Remote master is read-only.** All changes reach origin through PRs. Never push to origin/master.
- **Never push without explicit permission.** Pushing is always deliberate. Mechanically enforced by hookify rules (block master push, warn on any push).
- **Lead commit messages with Phase-Iteration slug.** Format: `Phase 1.3: feat: concise summary`. The slug is first, before the prefix.

**By role:**

| Action | Feature agent (worktree) | Captain (master) | PM (subagent) |
|--------|-------------------------|-----------------|---------------|
| Write application code | Yes | Never | Never |
| Commit | Via `/iteration-complete`, `/phase-complete` | Coordination artifacts only | Never directly |
| Push to origin | Never | Via `/sync`, with approval | Never |
| Create PRs | Never | Yes, via `gh pr create` | Never |
| Run QG | Invokes `/quality-gate` | Invokes `/code-review` | Runs the protocol |
| Merge master | `git merge master` to pick up updates | Owns master | N/A |
| Land on master | Via `/phase-complete` | Receives landed work | N/A |

## CLAUDE.md Updates

Projects adopting this pattern should update their CLAUDE-THEAGENCY.md `Git & Remote Discipline` section:

### Replace this:

```markdown
- **Never `reset --hard` without confirming work is preserved.** A diverged branch may have new commits. Check first.
- **`/rebase` and `/sync-all` are purely local.** `/sync` is the only command that pushes.
```

### With this:

```markdown
- **Never `reset --hard origin/*`.** This drops all local commits not on origin, including framework files. Mechanically blocked by `block-reset-to-origin` hookify rule.
- **Never `git rebase`.** All branch sync uses merge. Rebase rewrites history and breaks worktree merge-bases. Mechanically blocked by `block-raw-rebase` hookify rule. See `claude/docs/GIT-MERGE-NOT-REBASE.md`.
- **`/sync-all` and `/sync` are merge-based.** `/sync-all` merges origin into local master (never pushes). `/sync` merges and pushes (the only push command).
```

### Update the role table:

In the "By role" table, the "Merge master" row is already correct (`git merge master`). No change needed.

### Update the sync-all description in the Worktrees section:

Replace references to "rebase" in `/sync-all` descriptions with "merge":

```markdown
- `/sync-all` — merges origin/master into local master, merges worktree work into master. Purely local, never pushes.
```

## Merge-Base Guard Pattern

Every skill that merges origin/master should include this guard:

```
1. Run `git merge-base origin/master HEAD`
2. If exit code 1 (no common ancestor): ABORT with actionable error
3. If exit code 0: proceed with merge
```

This catches disconnected histories before they cause damage. If the histories are disconnected, the user must run `git merge --allow-unrelated-histories origin/master` manually to connect them — a one-time operation that creates a permanent merge commit.

## PR Scope Management

When a project uses the captain's PR rebuild workflow (squash local work into scope-based PR branches), it needs a `pr-scopes.json` file to define which paths belong to which PR.

### Setup

Create `pr-scopes.json` in your project's scripts directory (e.g., `usr/{principal}/scripts/pr-scopes.json`):

```json
{
  "feature-a": {
    "include": [
      "apps/backend/src/feature-a/",
      "apps/frontend/pages/feature-a/",
      "usr/{principal}/feature-a/"
    ]
  },
  "feature-b": {
    "include": [
      "apps/backend/src/feature-b/",
      "usr/{principal}/feature-b/"
    ]
  },
  "shared": {
    "exclude": [
      "apps/backend/src/feature-a/",
      "apps/frontend/pages/feature-a/",
      "usr/{principal}/feature-a/",
      "apps/backend/src/feature-b/",
      "usr/{principal}/feature-b/"
    ]
  }
}
```

### Scope Types

- **INCLUDE scopes** — list the paths that belong to this PR. Only these paths are staged. Use for feature/workstream PRs.
- **EXCLUDE scopes** — list the paths to exclude (claimed by other scopes). Everything else is staged. Use for shared/infrastructure PRs (one per project, typically named `devex` or `shared`).

### Rules

1. **Every worktree gets a scope.** When you create a worktree, add a scope to pr-scopes.json with its paths.
2. **Include Agency artifacts.** Each scope should include `usr/{principal}/{project}/` so handoffs, QGRs, and dispatches travel with the feature code.
3. **The EXCLUDE scope catches everything else.** Shared files (root package.json, framework updates, CLAUDE.md changes) land in the EXCLUDE scope. Update its exclude list when adding new INCLUDE scopes.
4. **Paths that don't exist are silently skipped.** This is expected — a scope may include paths that only exist after the feature is built.

### Adding a New Scope

When creating a new worktree/workstream:

1. Identify the app code paths the worktree will create/modify
2. Add an INCLUDE scope to pr-scopes.json with those paths + `usr/{principal}/{name}/`
3. Add those same paths to the EXCLUDE scope's exclude list
4. Commit the updated pr-scopes.json

### The PR Rebuild Flow

The captain's `pr-rebuild.sh` script:
1. Creates/resets a PR branch from `origin/master`
2. Runs `git merge --squash master` to bring in local work
3. Filters by scope (INCLUDE: selectively `git add`; EXCLUDE: `git reset HEAD` on excluded paths)
4. Commits the scoped changes
5. The PR branch has a clean single-commit diff against origin/master
