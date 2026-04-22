# pr-captain-post-merge — examples

## Happy-path examples

### Normal post-merge after a well-prepared PR

Captain merged PR #110 (pr-captain-merge), now runs:

```
/pr-captain-post-merge 110
```

Expected output:
```
Post-merge complete:
  PR:             #110 (feat: /service-add + /ui-add SPEC-PROVIDER scaffolding)
  Version:        1.7 → 1.8
  Release:        v1.8 created at https://github.com/org/repo/releases/tag/v1.8
  Master:         synced with origin/master (e47ce53a)
  Worktrees:      synced via /sync-all
  Branch cleanup: devex kept (worktree branch, not a feature branch)
```

### Post-merge with auto-detected PR

Captain says "the PR merged" without specifying number. Skill queries latest merged PR and confirms:

```
/pr-captain-post-merge
```

Expected prompt: "Most recently merged PR is #110 (feat: /service-add...). Proceed? [y/N]"

### Post-merge with release detection for D#-R# pattern

Captain merged PR #193 titled "D41-R5: ...". Release tag auto-derived:

```
/pr-captain-post-merge 193
```

Expected: release `v41.5` created (not `v1.N`).

---

## Edge-case examples

### PR not merged yet (Step 2 fails)

```
/pr-captain-post-merge 111
```

Expected output:
```
STOP: PR #111 state is OPEN, not MERGED.
  Merge the PR first via /pr-captain-merge 111 [--principal-approved]
  Then re-run /pr-captain-post-merge 111.
```

Exit 1.

### Manifest version not bumped (Step 6 warn)

Captain merged PR #112 but version wasn't bumped before PR creation:

```
/pr-captain-post-merge 112
```

Expected output:
```
STOP: manifest.json shows agency_version 1.8. No bump detected for this PR.
  Version should have been bumped before PR creation (/pr-prep or /release).
  Do NOT push directly to main to fix.
  Create a follow-up PR that bumps to 1.9, then re-run /pr-captain-post-merge 112.
```

Exit 1. No release created.

### Release creation fails mid-flight (Step 6)

`gh-release create` returns non-zero (token expired, network flake):

```
/pr-captain-post-merge 110
```

Expected output:
```
FAIL: release v1.8 creation failed: <error from gh>.
  Resolve (token / network / quota) and retry.
  Do NOT proceed to branch cleanup — main CI will go red until release lands.
```

Exit 2. Step 7 and 8 skipped.

### Branch-delete fails (Step 7 warn)

Branch doesn't exist locally (captain already deleted remote via `pr-merge --delete-branch`):

```
/pr-captain-post-merge 110
```

Step 7 output:
```
[pr-captain-post-merge] Step 7: PR branch 'captain-X' not found locally — already cleaned up.
```

Skill continues to Step 8. Exit 0.

### Invoked from worktree (should refuse)

Agent runs `/pr-captain-post-merge` from their worktree:

Expected: `paths: []` + `disable-model-invocation: true` combined with Step 1 precondition:
```
REFUSED: pr-captain-post-merge must run in main checkout on master.
  You are in: .claude/worktrees/devex
  Ask captain to run it, or switch to main checkout.
```

Exit 2.

---

## Integration examples

### As Step 8 of `/pr-captain-land`

When captain runs the full captain-owned PR lifecycle:

```
/pr-captain-land <agent-branch>
```

Internally:
- Step 7 invokes `/pr-captain-merge`
- Step 8 invokes `/pr-captain-post-merge`

Output from `/pr-captain-land` includes the combined report.

### Chained with `/collaborate` for cross-repo notice

After a PR that affects cross-repo collaborators:

```
/pr-captain-post-merge 110
/collaborate create the-agency --subject "sister-repo v1.8 shipped — /service-add + /ui-add"
```

Cross-repo dispatch follows the release.

### After a hotfix PR (non-standard version scheme)

Hotfix PR #197 with no D#-R# in title:

```
/pr-captain-post-merge 197
```

Resolution order fallback kicks in → tag `v1.8.pr197` created. Skill reports the naming fallback explicitly so captain can verify.

### Manually after `/release` (legacy flow)

If captain used legacy `/release` flow (which creates the PR but doesn't run post-merge automatically):

```
/release  # creates + pushes + merges PR
/pr-captain-post-merge <N>  # landed + release + cleanup
```

New workflow prefers `/pr-captain-land` which chains everything.
