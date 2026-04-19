# pr-captain-merge — examples

## Happy-path examples

### Minimal merge

Captain on master, PR #42 has green CI, principal approved via GitHub review (not just verbal).

```
/pr-captain-merge 42
```

Expected output:
```
Merging PR #42...
Merged successfully: https://github.com/org/repo/pull/42
Next: sync master with `./claude/tools/_sync-main-ref` or run /post-merge
```

Exit 0. Branch protection respected (no admin bypass needed because GitHub review was present).

### Merge with principal approval (verbal, admin bypass)

Captain on master, PR #42 green, principal said "yes, merge it" in this conversation. No GitHub review.

```
/pr-captain-merge 42 --principal-approved
```

Expected output:
```
Merging PR #42 (admin bypass, principal-approved)...
Merged: https://github.com/org/repo/pull/42
Admin invocation logged.
```

Exit 0.

### Merge + delete-branch

Captain wants to clean up remote branch after merge.

```
/pr-captain-merge 42 --delete-branch
```

Expected: same as minimal, plus remote branch deleted.

### Dry-run preview

Captain wants to confirm what would happen without touching GitHub.

```
/pr-captain-merge 42 --dry-run
```

Expected output: "[DRY-RUN] Would merge PR #42 via true merge commit. Principal-approved: no. Branch protection: respected."

Exit 0, no merge performed.

---

## Edge-case examples

### Branch-protection block (no principal approval)

PR #42 has no GitHub review, captain tries to merge without `--principal-approved`.

```
/pr-captain-merge 42
```

Expected output:
```
BLOCKED: PR #42 cannot merge — branch protection requires 1 approval.
Resolutions:
  (a) Ask principal to `gh pr review 42 --approve` in GitHub UI, then retry.
  (b) If principal authorized in this conversation, retry with --principal-approved.
```

Exit 3.

### Merge conflict

PR #42 has conflicts with master.

```
/pr-captain-merge 42
```

Expected output:
```
MERGE CONFLICT: PR #42 cannot merge cleanly.
Resolve locally:
  gh pr checkout 42
  ./claude/tools/git-safe merge-from-master --remote
  # resolve conflicts
  ./claude/tools/git-safe add <files>
  ./claude/tools/git-captain merge-continue
  ./claude/tools/git-push <branch>
  # then retry /pr-captain-merge 42
```

Exit 1.

### Invoked from a worktree (should refuse)

Agent runs `/pr-captain-merge` from their worktree.

Expected: skill's `paths: []` plus `disable-model-invocation: true` means it shouldn't auto-fire. If agent manually invokes, the underlying `claude/tools/pr-merge` checks context and refuses:

```
REFUSED: pr-merge must be invoked from main checkout on master. You're in a worktree.
Ask captain to run /pr-captain-merge instead.
```

Exit 2.

### Squash/rebase attempt (structural impossibility)

No flag exists on the skill or the tool to squash or rebase. If an agent tries `--squash`, the tool rejects:

```
REFUSED: --squash is not supported. pr-captain-merge always uses true merge commit.
See claude/REFERENCE-GIT-MERGE-NOT-REBASE.md for rationale.
```

Exit 2.

---

## Integration examples

### As Step 7 of `/pr-captain-land`

When captain runs the full captain-owned PR lifecycle:

```
/pr-captain-land <agent-branch>
```

Internally, Step 7 invokes `pr-captain-merge`:
```
→ CI green, merging PR #45...
→ Merged: https://github.com/org/repo/pull/45
→ Step 8: creating release v1.10...
```

The `--principal-approved` flag propagates from `pr-captain-land`'s caller.

### Before `/post-merge`

Captain merges via this skill, then runs `/post-merge` (or the refactored `/pr-captain-post-merge`) to create release + fleet-notify:

```
/pr-captain-merge 42 --principal-approved
/post-merge 42
```

Results: PR merged + v-tag created + fleet dispatched.

### With `/collaborate` for cross-repo

If merged PR affects cross-repo collaborators:

```
/pr-captain-merge 42 --principal-approved
/collaborate create the-agency --subject "monofolk PR #42 merged, includes framework port X"
```

Cross-repo notice follows the merge.
