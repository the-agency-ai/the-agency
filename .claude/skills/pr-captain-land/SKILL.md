---
name: pr-captain-land
description: Captain-only. Land an agent's prepared branch — switch, verify receipt, bump monofolk_version, create PR, watch CI, merge, release, notify agent. The single-writer serialization point for monofolk_version and PR creation. Companion to /pr-submit (the-agency#296 Phase 1 pilot). The `captain-` qualifier in the name signals scope at a glance (complements paths + disable-model-invocation enforcement).
agency-skill-version: 2
when_to_use: Captain on master in main checkout, after a /pr-submit dispatch from an agent. NEVER from a worktree. NEVER auto-invoked (disable-model-invocation + empty paths).
argument-hint: "<agent-branch> [--dry-run] [--title \"...\"] [--no-release]"
paths: []
required_reading:
  - claude/REFERENCE-CODE-REVIEW-LIFECYCLE.md
  - claude/REFERENCE-RECEIPT-INFRASTRUCTURE.md
  - claude/REFERENCE-GIT-MERGE-NOT-REBASE.md
  - claude/REFERENCE-SAFE-TOOLS.md
---

<!--
  allowed-tools intentionally omitted — inherits Bash(*) from
  .claude/settings.json. Subcommand-level restriction silently blocked
  fleet agents (flag #62/#63; devex dispatch #171). This skill composes
  git-safe, git-captain, git-push, git-safe-commit, pr-create,
  pr-captain-merge, gh-release, dispatch, diff-hash, and gh — tool-level
  narrow restriction would work but needs maintenance. Inherit Bash(*).
  Defense in depth is layered via disable-model-invocation + paths: [] +
  captain- name + runtime precondition (see "Captain-only — four-layer
  defense" below).
-->

# pr-captain-land

Captain-side skill that lands an agent's prepared branch as a merged PR + GitHub release + fleet notification. Companion to `/pr-submit`. This is the single-writer serialization point for `monofolk_version` and PR creation — eliminates the version-bump and receipt-hash races the pre-v2 distributed model created.

**Name pattern:** `pr-` prefix groups with the PR skill family (so `/pr<tab>` autocomplete shows the full kit). `captain-` qualifier flags captain-only scope in the skill listing without requiring the reader to open SKILL.md.

## Why this exists

Per the-agency#296 — one captain, one writer, one serialization point. Every PR, every version bump, every release goes through this skill when driven by an agent's `/pr-submit`.

Pre-v2 (distributed PR ownership) failure modes this skill eliminates:

- Agent A and agent B both run `/pr-prep` + `/pr-create` concurrently → both bump `monofolk_version` → one loses, the other's release tag is wrong.
- Captain lands a coord commit on master between an agent's `/pr-prep` and that agent's `/pr-create` → the receipt's diff-hash no longer matches → `pr-create` blocks with a confusing error.
- Agent opens PR with a one-line body → fleet reviewers can't tell what changed without diving into diff.

Captain-owned: captain is serialized by definition (one captain), captain re-verifies the receipt at the moment of landing, captain authors a fleet-aware PR body that references agent + scope + receipt.

## Required reading

Before running, Read the files listed in `required_reading:` frontmatter.

- `REFERENCE-CODE-REVIEW-LIFECYCLE.md` — end-to-end PR flow
- `REFERENCE-RECEIPT-INFRASTRUCTURE.md` — five-hash chain, receipt re-verification semantics
- `REFERENCE-GIT-MERGE-NOT-REBASE.md` — merge discipline (`pr-captain-merge` enforces)
- `REFERENCE-SAFE-TOOLS.md` — the safe-tool family this skill composes

This skill's `reference.md` is the step-by-step land protocol with failure-mode recovery.

## Usage

```
/pr-captain-land <agent-branch>
/pr-captain-land <agent-branch> --dry-run
/pr-captain-land <agent-branch> --title "Custom PR title"
/pr-captain-land <agent-branch> --no-release
```

- `<agent-branch>`: **required.** The branch that `/pr-submit` identified.
- `--dry-run`: walk the preflight + preview the PR body; no mutation.
- `--title`: override the default PR title (which derives from the agent's scope).
- `--no-release`: skip Step 8 (release creation). Used when landing a PR that explicitly shouldn't cut a release (rare).

## Preconditions

The script enforces **all** of these before any mutation; any failure exits non-zero with a clear error and no state change:

1. Running in the **main checkout** (first entry of `git worktree list`). Not in a `.claude/worktrees/` path.
2. Current branch is `master` or `main`.
3. Master tree is clean (`git status --porcelain` empty).
4. `<agent-branch>` exists on origin (`git ls-remote --heads origin <agent-branch>` non-empty).
5. `<agent-branch>` passes safe-name validation: regex `^[a-zA-Z0-9][a-zA-Z0-9/_.-]*$`, no `..`, no leading `-`.
6. Diff-hash of `<agent-branch>` vs `origin/master` matches a QGR receipt at `claude/workstreams/**/qgr/*qgr-pr-prep-*-{hash}.md`.

Any failure → zero mutation, clean error message, exit 1.

## Flow / Steps

The script at `scripts/pr-captain-land` walks these nine steps. Full failure-mode detail is in `reference.md`.

### Step 1: Preflight

Verify all six preconditions. If any fail, exit 1.

### Step 2: Switch to agent branch

```
./claude/tools/git-captain switch-branch <agent-branch>
```

Main checkout is now on agent's branch.

### Step 3: Verify receipt against current state

```
./claude/tools/diff-hash --base origin/master --json
```

Find receipt at `claude/workstreams/**/qgr/*qgr-pr-prep-*-{hash}.md`. If missing, agent's state drifted — switch back to master, exit 1, tell agent to re-run `/pr-prep` + `/pr-submit`.

### Step 4: Bump `monofolk_version`

Read `claude/config/manifest.json`. Bump minor (e.g., `1.8 → 1.9`). Refresh `updated_at` to current UTC timestamp.

**Security note:** version-bump is done via Python env-var substitution (`MANIFEST=... NEW_VER=... python3 -c '...os.environ[...]...'`), **not** f-string interpolation. This blocks code-injection via adversarial branch names. (Fix landed in `ccf054ad` per MAR finding F-SEC-1 / CRITICAL-3.)

Commit via `git-safe-commit`:

```
chore(manifest): bump monofolk_version {old} → {new} for PR landing (captain)
```

Push to origin.

### Step 5: Create PR

```
./claude/tools/pr-create --title "<title>" --body "<captain-authored fleet-aware body>"
```

Title derives from agent's `--scope` or `--title` override. Body wraps agent's scope with:

- "Captain-landed PR via `pr-captain-land` (the-agency#296 Phase 1)"
- Branch, receipt path, diff-hash, version bump
- "Release `v{new}` will follow on merge"

### Step 6: Switch back to master

```
./claude/tools/git-captain switch-branch master
```

Captain sits on master during the CI-wait phase. Avoids any accidental commit on the PR branch.

### Step 7: Watch CI

Poll `gh pr view {num} --json statusCheckRollup` every 20 seconds. Only gates on `lint-and-test`.

| State | Action |
|---|---|
| SUCCESS | proceed to Step 8 |
| FAILURE | exit 1 — agent must fix + push + resubmit |
| PENDING / IN_PROGRESS | wait 20s, poll again |

Max 30 attempts = 10 minutes. On timeout, exit 1.

`deploy-preview-backend` is environmental flake and ignored by this skill.

### Step 8: Merge + release

Merge:

```
./claude/tools/pr-merge {pr-num} --principal-approved
```

True merge commit — never squash, never rebase (enforced by `pr-captain-merge` / underlying `pr-merge`).

Sync master:

```
./claude/tools/git-captain fetch
./claude/tools/git-captain merge-from-origin
```

Release (unless `--no-release`):

```
./claude/tools/gh-release create v{new-version} --target master --title "..." --notes "..."
```

Release notes: captain-authored, references PR number + agent.

### Step 9: Dispatch agent

```
./claude/tools/dispatch create \
  --to <agent-address> \
  --type master-updated \
  --subject "PR #{num} landed — v{new} released" \
  --body "<PR URL, release URL, version bump, Phase 1 pilot feedback request>"
```

Agent picks up on next `/session-resume` or via dispatch monitor.

## Failure modes

- **Preflight fails** (Step 1): exit 1, no mutation. Captain resolves (switch to main checkout, clean tree, ensure branch exists, verify agent submitted).
- **Branch-name validation fails** (Step 1.5): rare — injection attempt or malformed branch. Exit 1. Agent renames.
- **Receipt mismatch** (Step 3): master drifted. Exit 1 with switch-back-to-master. Agent re-runs `/pr-prep` + `/pr-submit`.
- **Version-bump push fails** (Step 4): concurrent captain activity or branch-protection edge. Switch back to master, exit 1. Captain investigates.
- **`pr-create` blocks on receipt** (Step 5): re-verify hash, retry once; on second failure, exit 1 and ask captain to investigate.
- **CI failure** (Step 7): version-bump commit stays on agent's branch; agent can fix + push + resubmit via `/pr-submit`. Version doesn't re-bump on retry (captain detects current == target).
- **CI timeout** (Step 7): exit 1, captain investigates manually.
- **Merge fails** (Step 8): likely branch-protection edge. Captain falls back to manual `/pr-captain-merge <num> --principal-approved`.
- **Release creation fails** (Step 8): merge succeeded, release failed. Warn captain, suggest manual `gh release create`. Skill returns 0 because merge is the primary outcome. (MAR follow-up H13 tracks stricter semantics.)
- **Dispatch emission fails** (Step 9): warn, exit 0. Merge + release are the authoritative record; dispatch is notification.

## What this does NOT do

- **Does not write code.** Agent's branch is the substance; captain lands it as-is (plus the version-bump).
- **Does not modify agent's existing commits.** Only appends the version-bump commit.
- **Does not squash or rebase.** `pr-captain-merge` enforces true merge commit per framework discipline.
- **Does not auto-retry on failure.** Failures need captain attention; no silent retries that mask real issues.
- **Does not fire from an agent context.** Four-layer defense (below) makes this impossible.

## Captain-only — four-layer defense

Defense in depth against accidental invocation from the wrong context:

1. **`disable-model-invocation: true`** in frontmatter — Claude cannot auto-invoke. Captain must explicitly type the command.
2. **`paths: []`** (intentionally empty) — no file-path auto-activation. (Contrast with `pr-submit` which has `paths: [.claude/worktrees/**]`.)
3. **Name contains `captain-`** — any human or agent browsing the skill list sees scope at a glance.
4. **Runtime precondition** — script's Step 1 refuses unless in main checkout on master.

Any single layer failing is caught by the next. All four must fail simultaneously for an unauthorized invocation to land a PR.

## Status

`active` (v2, agency-skill-version 2 from birth — Phase 1 pilot for the-agency#296). Scripts hardened in `ccf054ad` per MAR findings (Python env-var substitution + branch-name validation). Ready for fleet-wide dogfood on next agent PRs.

## Related

- `/pr-submit` — agent-side companion; this skill consumes its dispatch
- `/pr-captain-merge` — the merge primitive this skill calls at Step 8
- `/pr-prep` — the QG-before-PR-create that signs the receipt this skill re-verifies
- `/pr-captain-post-merge` — alternative entry for post-merge tasks (release + fleet-notify) when landing was done manually
- `claude/tools/pr-create` — PR creation tool (receipt-aware)
- `claude/tools/pr-merge` — safe-merge primitive (underlies `/pr-captain-merge`)
- `claude/tools/gh-release` — release creation wrapper
- `claude/tools/dispatch` — ISCP dispatch tool
- `claude/tools/diff-hash` — receipt-matching hash
- `reference.md` — full step-by-step protocol + recovery flows
- `examples.md` — happy-path + failure-mode examples
- the-agency#296 — PR lifecycle ownership design
- the-agency#298 — skill refactor recommendation
- the-agency#314 — upstream package MAR summary (this skill's scripts hardened there)
- the-agency#315 — V1→V2 migration master issue

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
