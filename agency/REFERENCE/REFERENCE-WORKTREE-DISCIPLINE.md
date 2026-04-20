<!-- What Problem: The monolithic CLAUDE-THEAGENCY.md bootloader loads ~12K tokens
     on every session start, but worktree rules are only needed by agents working in
     worktrees (or the captain coordinating them). Extracting this into a standalone
     ref doc lets the ref-injector hook inject it on demand.

     How & Why: Verbatim extraction from CLAUDE-THEAGENCY.md "Worktrees & Master"
     section (lines 367-418). Kept as-is because these are operational rules —
     the identity resolution bug explanation and naming convention are precise
     and must not be paraphrased. The ref-injector hook will inject this when
     worktree-create, sync-all, phase-complete, or iteration-complete skills run.

     Written: 2026-04-12 during devex session (CLAUDE.md bootloader refactoring) -->

## Worktrees & Master

Agents work either on **master** (the main checkout) or on a **worktree** (an isolated branch). Know which you are and follow the rules for each.

### Master (Captain)

The captain session runs on master. It coordinates — syncs worktrees, builds PR branches, dispatches reviews, pushes to origin. The captain does not implement features.

- `/sync-all` — merges worktree work into master, syncs all worktrees. Purely local, never pushes.
- `/sync` and `/release` — the commands that push. `/sync` for branch push, `/release` for full PR flow (commit + push + PR + version bump). Both wrap `./claude/tools/git-push` which blocks main/master.
- `/captain-review` — reviews PR branches locally, dispatches findings.
- Direct commits to master are only for coordination artifacts (handoffs, dispatches, review files).

### Worktrees (Feature Agents)

Worktree agents implement features on isolated branches. They build, test, and land on master via boundary commands.

- Work on your branch. Commit at iteration boundaries via `/iteration-complete`.
- Land on master at phase boundaries via `/phase-complete` (squash, deep QG, approval, push to local master).
- Merge master regularly (`git merge master`) to pick up dispatches, CLAUDE.md updates, and other agents' work.
- The `iscp-check` hook automatically notifies you of unread dispatches on SessionStart — you don't need to merge master to know about them. However, you still need to merge master to access dispatch payload files (the DB notification tells you the file exists; the payload lives on master).
- Never push to origin directly — the captain manages PR branches and pushes.

**Critical: never `cd` to the main checkout from a worktree.** Agent identity resolution uses the current working directory's git branch. When a worktree agent `cd`s to the main repo, `agent-identity` resolves the branch as `main` → identity becomes `captain` → handoffs and dispatches go to the wrong agent. The `cd-to-main-block` hookify rule blocks this pattern (and absolute paths to tools in the main repo). **Always use relative paths from your worktree:** `./claude/tools/dispatch list`, never `cd /path/to/main && ./claude/tools/dispatch list` or `/Users/.../the-agency/claude/tools/dispatch list`.

### When to Create a Worktree

- **New prototype or feature** — always a worktree. Use `/workstream-create` or `/prototype-create` (planned via SPEC-PROVIDER pattern).
- **Bug fix or small change** — can work on master if it's a quick fix that doesn't need isolation.
- **Dispatch handling** — `iscp-check` notifies the worktree agent automatically. The agent runs `dispatch read <id>` to see the payload. If the payload file is on master, merge master first to access it.

### Branch Protection

`main` is protected at the GitHub level:

- **Direct pushes to main are blocked** — GitHub enforces this via branch protection rules. Even with write access, `git push origin main` is rejected.
- **All changes require a PR** — including captain coordination artifacts that land on master locally. The captain builds a PR branch, pushes it to origin, and merges via GitHub.
- **PR approval required** — at least one approval before merge.
- **Smoke test status check required** — the smoke test CI job must pass before merge is allowed.

This means: `git push origin main` will fail. Use `/sync` (which pushes the current branch, not main) and then open a PR. The `/release` skill handles the full flow: QG → commit → push branch → create PR.

---

### Worktree Naming Convention

Worktree directory names follow `{workstream}-{agent}` with a **collapse rule** when the agent name matches or extends the workstream name:

```
if agent == workstream OR agent.startswith(workstream + "-"):
    name = agent               # collapse: drop the workstream prefix
else:
    name = "workstream-agent"  # full form: join with hyphen
```

| Workstream | Agent | Worktree name | Why |
|-----------|-------|---------------|-----|
| `devex` | `devex` | `devex` | exact match → collapse |
| `iscp` | `iscp` | `iscp` | exact match → collapse |
| `mdpal` | `mdpal-app` | `mdpal-app` | prefix match → collapse |
| `mdpal` | `mdpal-cli` | `mdpal-cli` | prefix match → collapse |
| `agency` | `captain` | `agency-captain` | no match → full form |
| `fleet` | `captain` | `fleet-captain` | no match → full form |

`worktree-create --workstream <ws> --agent <ag>` enforces the rule. Use `--compute-only` to print the canonical name without creating the worktree. The positional form `worktree-create <name>` is preserved for ad-hoc worktrees that don't belong to a workstream (experiments, fix branches, etc.).
