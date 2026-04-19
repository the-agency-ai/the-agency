# captain-release — unique protocol

## Version-bump parsing rules

Resolution order:

1. **D#-R# pattern** in PR title → map to `agency_version` or `monofolk_version` per repo convention
2. **Release-type tag in PR body** (e.g., `Release-Type: minor`) → semver bump
3. **Default** → increment the primary version field (`monofolk_version` in monofolk, `agency_version` in the-agency)

The bump happens AFTER the PR is created (Step 6) so the PR's diff shows the actual substance, and the version bump is a follow-up commit on the same branch.

## `--no-push` / `--no-pr` semantics

- `--no-push` skips Steps 4, 5, 6 entirely. Captain has a local commit only. Useful when captain wants to stage multiple commits before pushing.
- `--no-pr` keeps push (Step 4) but skips PR creation (Step 5). Captain intends to open the PR manually via different flow.
- Both flags can be combined; effectively just runs Steps 1-3 (commit).

## Differences from `/pr-captain-land`

| Aspect | `/captain-release` | `/pr-captain-land` |
|---|---|---|
| Branch origin | captain creates the work on a captain-* branch | agent creates work on agent branch, submits via /pr-submit |
| QG responsibility | captain runs /pr-prep before /captain-release | agent runs /pr-prep before /pr-submit |
| Version bump | captain does it in this skill's Step 6 | captain does it in /pr-captain-land's Step 4 |
| PR creation | captain-authored description (this skill) | captain-authored description wrapping agent's scope |
| Merge | separate subsequent `/pr-captain-merge` invocation | included as Step 7 of /pr-captain-land |
| Release creation | separate subsequent `/pr-captain-post-merge` | included as Step 8 of /pr-captain-land |

Rule of thumb: use `/captain-release` for captain-authored work. Use `/pr-captain-land` when captain is landing an agent's prepared branch.

## Recovery flows

- **commit-precheck fails after captain has already committed**: edit files, re-stage, `git commit --amend` (captain-authorized via git-safe-commit), re-run.
- **Push rejected on force-with-lease**: someone else pushed to the captain-* branch (rare — captain owns it). Fetch, inspect, decide: rebase-equivalent via `git-safe merge-from-master` or abort.
- **pr-create blocks on QGR mismatch**: diff-hash drifted since QG receipt was signed. Re-run `/pr-prep`. Common after captain's coord commits on master between QG and PR create.

## Release-tag-check interaction

The `release-tag-check` GitHub Actions workflow requires every merge commit on master to have a matching release tag. `captain-release` doesn't create the release tag — that's `/pr-captain-post-merge`'s job after merge. But `captain-release` DOES ensure the version-bump commit is present on the branch, which is the precondition for `/pr-captain-post-merge` to derive the tag correctly.
