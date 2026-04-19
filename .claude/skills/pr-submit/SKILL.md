---
name: pr-submit
description: Agent-side signal to captain that your branch is ready for PR landing. Runs preconditions (clean tree, pushed, matching QGR receipt) then dispatches captain with a structured payload. Captain's /pr-captain-land picks it up. Replaces the distributed "agent creates PR" model with a captain-owned PR lifecycle (the-agency#296).
agency-skill-version: 2
when_to_use: Agent in a worktree after /pr-prep succeeds and branch is pushed to origin. Replaces manual /pr-create invocation by agents. NEVER from master or main checkout — that's captain's /pr-captain-land.
argument-hint: "--scope \"one-line PR summary\" [--priority normal|high]"
paths:
  - .claude/worktrees/**
required_reading:
  - claude/REFERENCE-CODE-REVIEW-LIFECYCLE.md
  - claude/REFERENCE-RECEIPT-INFRASTRUCTURE.md
  - claude/REFERENCE-ISCP-PROTOCOL.md
---

<!--
  allowed-tools intentionally omitted — inherits Bash(*) from
  .claude/settings.json. Subcommand-level restriction at the skill level
  silently blocked fleet agents in the past (flag #62/#63; devex dispatch
  #171). This skill composes git-safe, dispatch, and diff-hash — tool-level
  narrow restriction would work but needs maintenance as composed tools
  evolve. Inherit Bash(*) is safer.
-->

# pr-submit

Agent-side handoff to captain: "my branch is ready for PR landing." Captain picks up the dispatch and runs `/pr-captain-land` to own the remaining PR lifecycle (version bump, PR creation, CI wait, merge, release, fleet-notify).

## Why this exists

Per the-agency#296: the distributed "agent creates PR, captain merges" model causes four failure modes that the captain-owned lifecycle eliminates:

- **Version-bump races** — two agents bump `monofolk_version` simultaneously against the same `origin/master` baseline; one loses.
- **QGR hash races** — captain's coord commits land on master between an agent's QG and that agent's PR creation, invalidating the receipt mid-flow.
- **Split release responsibility** — agent opens PR but captain creates the release; ownership is asymmetric and release steps get skipped.
- **Inconsistent PR descriptions** — each agent writes their own; no fleet-wide coherence for review or history-mining.

Solution: captain owns the PR lifecycle end-to-end. Agent owns substance + QG. `/pr-submit` is the single handoff point — a structured dispatch with branch, SHA, diff-hash, receipt path, and scope summary.

## Required reading

Before running, Read the files listed in `required_reading:` frontmatter.

- `REFERENCE-CODE-REVIEW-LIFECYCLE.md` — where this skill sits in the end-to-end PR flow.
- `REFERENCE-RECEIPT-INFRASTRUCTURE.md` — the five-hash receipt chain this skill verifies against.
- `REFERENCE-ISCP-PROTOCOL.md` — the dispatch protocol the handoff uses.

The dispatch payload schema itself is in this skill's `reference.md`.

## Usage

```
/pr-submit --scope "one-line PR summary"
/pr-submit --scope "..." --priority high
```

- `--scope`: **required.** One-line summary of what this PR delivers (becomes part of the dispatch subject + body).
- `--priority normal|high`: optional. Defaults to `normal`. `high` raises dispatch visibility in captain's queue.

## Preconditions

The script enforces all of these before dispatching; any failure exits non-zero with a clear error and **no** dispatch is sent:

1. Running in an agent worktree (`.claude/worktrees/<name>/`), **not** the main checkout.
2. Current branch is not `master` / `main` / `HEAD` (not detached).
3. Tree is clean — `git status --porcelain` empty.
4. Current branch is pushed to origin and `origin/<branch>` equals local `HEAD`.
5. A QGR receipt exists at `claude/workstreams/**/qgr/*qgr-pr-prep-*-{hash}.md` where `{hash}` matches the current `diff-hash` against `origin/master`.

If preconditions 3 or 4 fail, fix them (commit/push via `/git-safe-commit` or `/sync`) and retry. If precondition 5 fails, you need to re-run `/pr-prep` to sign a fresh receipt.

## Flow / Steps

### Step 1: Preflight

`scripts/pr-submit` computes all preconditions. If any fail, exit 1 with a one-line reason. No partial state.

### Step 2: Resolve identity + branch state

1. Resolve agent identity via `./claude/tools/agent-identity` (principal + agent + repo).
2. Capture `BRANCH` = `git rev-parse --abbrev-ref HEAD`.
3. Capture `SHA` = `git rev-parse HEAD`.
4. Verify `git rev-parse "origin/$BRANCH"` equals `SHA`.

### Step 3: Compute diff-hash

```
./claude/tools/diff-hash --base origin/master --json
```

Capture the full SHA-256 and the 7-char short form. The 7-char short form is what matches the receipt filename suffix.

### Step 4: Locate receipt

Glob for `claude/workstreams/**/qgr/*qgr-pr-prep-*-{hash-short}.md`. Exactly one receipt should match. If zero, exit 1 — agent must re-run `/pr-prep`. If multiple, pick the most recent and warn.

### Step 5: Compose dispatch payload

Follow the schema in `reference.md` (protocol v1.0). Envelope:

```
to:       monofolk/{principal}/captain
type:     pr-submit
priority: normal | high
subject:  "Ready for PR landing: {branch} — {scope}"
```

Body is the markdown template in `reference.md` — branch, SHA, diff-hash, receipt path, scope, captain-action list.

### Step 6: Emit dispatch

```
./claude/tools/dispatch create \
  --to monofolk/{principal}/captain \
  --type pr-submit \
  --subject "<subject>" \
  --body "<body>"
```

Capture the dispatch ID. Report to the agent: "Submitted to captain as dispatch `<id>`. Captain will run `/pr-captain-land <branch>`; you'll receive a `master-updated` dispatch when the PR lands."

### Step 7: Stand by

Agent does NOT:

- Create the PR
- Bump `monofolk_version`
- Merge
- Create the release

Agent stands by to respond to review comments via `/pr-respond` if any come. On merge, a `master-updated` dispatch arrives with PR URL + release tag.

## Failure modes

- **Preflight fails** (Step 1): exit 1 with the failing precondition. No mutation, no dispatch. Fix the precondition and retry.
- **Origin mismatch** (Step 2.4): local HEAD and `origin/<branch>` diverge. Push or pull first (`./claude/tools/git-push <branch>` or `git-safe fetch` + merge).
- **Receipt missing** (Step 4): no QGR matching current diff-hash. Re-run `/pr-prep` to regenerate.
- **Dispatch emission fails** (Step 6): ISCP tool error. Script exits 1; agent retries. Dispatch creation is idempotent-safe (duplicate dispatches just clutter the queue — captain can resolve).
- **Captain never picks up**: a non-failure but a stall. Agent can re-dispatch with `--priority high` or flag the captain directly.

## What this does NOT do

- **Does not create the PR.** That's captain's `/pr-captain-land`. Agent must not run `gh pr create` or `/pr-create` after this.
- **Does not bump `monofolk_version`.** Captain is the single writer.
- **Does not merge anything.** Agent has no write access to master.
- **Does not modify the branch.** The branch stays exactly as `/pr-prep` left it.
- **Does not wait for captain.** Fire-and-forget dispatch; agent returns to other work.

## Status

`active` (v2, agency-skill-version 2 from birth — this skill is the Phase 1 pilot for the-agency#296 captain-owned PR lifecycle). Ready for fleet-wide dogfood on designex / patient / of-mobile next PRs.

## Related

- `/pr-captain-land` — captain-side companion; consumes this skill's dispatch
- `/pr-prep` — the QG-before-PR-create that produces the receipt this skill verifies
- `/pr-respond` — agent-side skill for handling captain review comments (planned)
- `claude/tools/dispatch` — the ISCP tool this skill wraps for emission
- `claude/tools/diff-hash` — receipt-matching hash
- `claude/tools/agent-identity` — principal/agent/repo resolution
- `reference.md` — dispatch payload schema (protocol v1.0)
- `examples.md` — happy-path + failure-mode examples
- the-agency#296 — PR lifecycle ownership design
- the-agency#298 — skill refactor recommendation
- the-agency#314 — upstream package MAR summary
- the-agency#315 — V1→V2 migration master issue

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
