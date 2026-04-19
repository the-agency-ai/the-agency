# pr-captain-post-merge — unique protocol

Most of this skill's behavior is covered by `required_reading:` docs (git-merge discipline, worktree discipline, safe tools) and by the underlying tools (`gh-release`, `git-captain`, `/sync-all`). Skill-unique content:

## Release naming protocol

The GitHub release tag is derived from the merged PR's title/branch. Resolution order:

1. **`D#-R#` pattern** in PR title (e.g., `D39-R1: ...`) → tag `v39.1`
2. **`agency-skill-version`-matched pattern** in PR body → tag per the-agency convention (if applicable)
3. **`monofolk_version` match** against current `manifest.json` → tag `v<monofolk_version>` (e.g., `v1.8`)
4. **Hotfix / non-standard** → `v<monofolk_version>.pr<PR-number>` (e.g., `v1.8.pr110`)

The tag is NEVER chosen by captain's judgment after the fact. It's derived mechanically from committed state (manifest + PR title).

## Release notes composition

Release notes body is captain-authored from:

- PR title (one-liner)
- PR description summary (2-3 sentences max)
- Key changes listed in PR description
- Incident lineage if applicable (e.g., "fixes the-agency#296")
- Link back to the PR

Release notes are NOT the PR description verbatim — they're audience-for-release-readers. Less jargon than PR descriptions; more "what shipped + why it matters."

## The `release-tag-check` contract

GitHub Actions workflow `release-tag-check` runs on every push to master. If a merge commit lands without a matching release tag, CI goes red on main immediately. This skill's Step 6 is the gate that prevents that red state.

**Failure mode:** if Step 6 fails and captain proceeds to Step 7 (branch cleanup), main CI will be red until a release is created manually. The skill's hard-verify in Step 6 is there specifically to prevent that progression.

## Composition with `/pr-captain-land`

When captain runs `/pr-captain-land`, this skill is invoked as Step 8. In that composition:

- The merge (Step 7 of `/pr-captain-land`) has already happened via `/pr-captain-merge`
- Steps 1-2 of this skill are skipped (parent skill has verified)
- Steps 3-8 run in sequence
- Exit code propagates; if Step 6 (release creation) fails, the full land flow fails

See `.claude/skills/pr-captain-land/references/land-protocol.md` for the full integration.

## Recovery flows

### Release created with wrong tag

`gh release delete v<wrong>` + re-run Step 6 with correct version. Only safe if no downstream deployment referenced the bad tag.

### Master already synced before skill runs

Step 4 detects no divergence; merge-from-origin is a no-op. Skill continues to Step 5 normally.

### /sync-all fails

Step 5 fails → skill reports, captain investigates worktree state. Release (Step 6) can still proceed; worktree sync is per-worktree and not release-blocking.

### Branch already deleted

Step 7 no-op. Skill reports "kept / already-gone" and exits clean.
