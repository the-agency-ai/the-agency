# captain-release — examples

## Happy-path examples

### Full flow — captain lands framework fix

Captain on `captain-framework-fix` branch with staged changes:

```
/captain-release fix: resolve worktree-sync MAIN_BRANCH bug + add regression test
```

Expected flow: commit-precheck green → commit → push → PR created → version bumped 1.9 → 2.0 → summary printed.

### Stage without pushing

```
/captain-release --no-push misc: consolidate QGR receipts for pending PRs
```

Result: commit lands locally; no push. Captain pushes later manually.

### Push without PR

```
/captain-release --no-pr draft: initial sketch for REFERENCE-FOO.md
```

Result: commit + push to origin; no PR yet. Captain opens PR later.

---

## Edge-case examples

### On master (abort)

Captain accidentally runs from master:

```
/captain-release misc: whatever
```

Expected:
```
ABORT: never run /captain-release from master.
  Create a captain-* branch first: git-captain checkout-branch captain-<topic>
```

Exit 1.

### commit-precheck fails

Formatter finds issues:

```
/captain-release feat: add REFERENCE-ESTIMATION.md
```

Expected:
```
STOP: commit-precheck failed — formatter reports 3 unformatted files.
  Run 'oxfmt' to fix, then re-run /captain-release.
```

Exit 1. No commit.

### No changes to release

Captain runs the skill with nothing to commit:

```
/captain-release misc: whatever
```

Expected:
```
Nothing to release — working tree clean and no staged changes.
  If you meant to commit earlier work, use /git-safe-commit directly.
```

Exit 0. No-op.

---

## Integration examples

### Typical captain workflow

```
git-captain checkout-branch captain-ref-doc-update
# ... edits ...
/pr-prep "captain: REFERENCE update for X"
/captain-release docs(REFERENCE): update X with Y
# ... PR gets reviewed ...
/pr-captain-merge <N>
/pr-captain-post-merge <N>
```

Four skills, complete end-to-end.

### Compared to agent workflow

Agent:
```
/pr-prep "<agent-scope>"
/git-push <branch>
/pr-submit --scope "<one-liner>"
```

Captain:
```
/pr-captain-land <agent-branch>
```

`captain-release` is not used in the agent-owned path.

### Batched coord commits before release

Captain wants three coord artifacts in one PR:

```
git-safe-commit "housekeeping: capture QGR for #110" --no-work-item
git-safe-commit "housekeeping: archive handoff pre-compact" --no-work-item
git-safe-commit "housekeeping: file flag #68 details" --no-work-item
/captain-release housekeeping: consolidated coord from session X
```

The earlier three commits are already on the branch. `/captain-release` commits whatever's left (usually empty at this point), push, PR, bump. The PR description references all four commits.
