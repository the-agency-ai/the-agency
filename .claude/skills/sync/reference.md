# sync — unique protocol

## Target branch semantics

- **Default (`origin/master`)**: most common usage. Before pushing, pull in the latest master state so the push contains all prior master content + this branch's unique commits.
- **Explicit (`<target>`)**: rare. Useful when syncing between feature branches or when target is a different upstream ref.

Resolution:

```
TARGET="${1:-origin/master}"
```

## Why merge before push?

Convention: every push to origin should include all master content up to the tip that was current when you started the branch. This is `git merge origin/master` — integrate upstream before sharing yours.

Alternative (rebase-before-push) is BANNED by framework per `REFERENCE-GIT-MERGE-NOT-REBASE.md`. Merge commits preserve the branch's real history; rebase creates synthetic commits that break bisect and blur authorship.

## The `git-push` tool as the authorized path

`agency/tools/git-push` is the only permitted push invocation. It:

- Blocks pushes to `main` / `master` branches (hard refusal)
- Requires `--force-with-lease` for any force push (blocks bare `--force`)
- Logs every push to `~/.agency/<repo>/logs/push.log`
- Returns distinct exit codes for different failure modes (branch protection, rejected, network)

Hookify rules `block-raw-tools.sh` ensures bare `git push` is blocked at the shell level. This skill + the tool together enforce the single-push-path discipline.

## Composition with `/captain-release`

`/captain-release` internally invokes `/sync` semantics in Step 4 (push step). The combined flow is:

1. QG → 2. commit → 3. confirm push → 4. `git-push` → 5. PR create → 6. version bump → 7. push version bump

The inner push steps (4 and 7) both use the underlying `agency/tools/git-push`. `/sync` provides a standalone invocation of the same primitive for cases where captain has already committed separately and just needs to push.

## Force-with-lease vs force

- **`--force-with-lease`**: refuses push if remote has changed since last fetch. Safe for overwriting YOUR own prior pushed commits after rebase / amend. (But we don't rebase here.)
- **`--force` (bare)**: overwrites remote regardless. Can destroy teammates' work. **Banned.**

`git-push` tool defaults to `--force-with-lease` when a force push is requested. Bare `--force` requires explicit principal-approved override (not implemented; deliberately absent).

## When NOT to use `/sync`

- **On master**: use a PR (agent-side: `/pr-submit`; captain: `/captain-release`).
- **For a release**: use `/captain-release` (includes sync + PR + version bump).
- **For fleet-wide master sync**: use `/captain-sync-all` (local-only; never pushes).
- **To sync a single worktree with master**: use `/worktree-sync` (merges master locally; never pushes).
