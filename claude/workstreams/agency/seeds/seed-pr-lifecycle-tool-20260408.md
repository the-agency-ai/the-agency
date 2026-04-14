---
type: seed
workstream: agency
date: 2026-04-08
captured_by: the-agency/jordan/captain
principal: jordan
status: seed
---

# Seed: PR lifecycle tool + skill

## What it is

A tool + skill that wraps the full PR lifecycle: **push → create draft → monitor → request review → merge**. Today captain (or any agent shipping work) walks through this manually with `gh pr create`, then watches for reviews, then `gh pr merge`. Just like `agency-issue` and `release-plan`, it's a captain-manual flow that should become a tool.

## Where it sits in the pattern

This is the **third tool in the "captain manually does X, that should be a tool" pattern** after `agency-issue` (Day 33) and `release-plan` (Day 33). Same shape:

- A bash tool wrapping `gh` and `git`
- A skill markdown for agent discovery
- Persisted state per filed PR (in `usr/{principal}/reports/` or a new `usr/{principal}/prs/`)
- Hooks into the existing release flow (called by `release-plan --apply` once that exists, or run standalone)

## Verbs (proposed)

| Verb | What |
|------|------|
| `pr push` | Push current branch to origin (`git push -u origin {branch}`) |
| `pr create` | Create draft PR with title + body (autodetect from commit history) |
| `pr open` | Push + create in one step |
| `pr view [id]` | Show PR status, reviews, checks (default: current branch's PR) |
| `pr review-request <reviewer>` | Request review from a person/team |
| `pr ready` | Mark draft PR ready for review |
| `pr merge [id]` | Merge with the right strategy (squash by default for our pattern) |
| `pr close [id]` | Close without merging |
| `pr list` | List open PRs |

## Integration with existing skills

- **`/sync`** — currently the only skill that pushes. PR tool would coordinate, not replace.
- **`/pr-prep`** — runs the QG before creating a PR. PR tool would call `/pr-prep` first.
- **`/captain-review`** — captain reviews draft PRs and dispatches findings. PR tool would surface PRs needing review.
- **`/code-review`** — multi-agent code review with confidence scoring. PR tool would surface review status.
- **`/post-merge`** — runs after a PR is merged on GitHub. PR tool would chain into this on `pr merge`.
- **`release-plan`** — generates the commit plan. PR tool consumes the plan output (release-plan → execute commits → pr open).

The natural composed flow:

```
release-plan          → propose plan
git-safe-commit (xN)       → execute commits per plan
pr open               → push + create draft PR
(reviews happen)
pr ready              → mark ready for review
pr merge              → merge + post-merge cleanup
```

## Permissions

- **`pr push`** is the destructive op — push is **principal-only** per current rules. Tool should refuse to push without explicit confirmation flag (`--confirm` or `--principal-approved`). Captain still can't auto-push.
- **`pr create` (draft)** can be run by any agent — drafts are reversible.
- **`pr merge`** is principal-only. Tool refuses without `--principal-approved`.
- **All read verbs** (view, list) are anyone.

## Future-version notes

- **Multi-target support** — the `pr` family of verbs targets the current repo's origin. v2+ could support cross-repo PRs (e.g., upstream port to monofolk), matching the SPEC-PROVIDER pattern other tools are heading toward.
- **Auto-summary from release-plan** — `pr open` could read the most recent release-plan output and auto-fill PR title/body from the commit groupings.
- **Review tracking in reports** — each PR gets a record in `usr/{principal}/reports/` (or new `usr/{principal}/prs/`) with merge status, review history, related issues.
- **GitHub status check polling** — could surface CI status in the captain's view alongside dispatch counts.

## Slot

The natural follow-on to `release-plan`. Build when the next release cycle has a quiet moment, OR fold into Day 33 R2 if there's time.

## Conversation source

Captured during Day 33 R1 push, when principal asked: *"Should we create a tool and tie it to the skill for PR creation, pushing, and merging?"* Captain's answer: yes, same pattern as agency-issue and release-plan. This seed is the record.
