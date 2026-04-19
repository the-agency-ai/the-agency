# pr-captain-merge — unique protocol

This skill's unique protocol is thin — most of the behavior is in `claude/tools/pr-merge` and documented by the required_reading `GIT-MERGE-NOT-REBASE.md`. What lives here:

## The `--principal-approved` contract

`--principal-approved` is a captain **attestation**, not a user flag. When captain passes `--principal-approved` to `claude/tools/pr-merge`, captain is asserting:

> "The principal has, in THIS conversation, authorized merging PR #N using admin-bypass if branch protection gates are in the way. I am invoking `--admin` under their authority."

**Rules:**

1. **In-conversation means in-conversation.** Not "the principal approved this PR last week." The authorization must be visible to any reviewer reading the transcript.
2. **Principal's exact words matter less than explicit authorization.** "yes, merge" / "go ahead and merge that" / "ship it with principal approval" — all explicit.
3. **Ambiguous authorizations do NOT qualify.** "looks good" is not authorization. "I'll review later" is not authorization.
4. **When in doubt, DO NOT pass `--principal-approved`.** Let branch protection do its job.

## Exit-code semantics (from `claude/tools/pr-merge`)

| Exit | Meaning | Skill response |
|---|---|---|
| 0 | Merged successfully | Report URL, recommend next step (`post-merge`, sync master) |
| 1 | Merge conflict | Send back for agent to resolve; don't loop in captain |
| 2 | General tool error | Surface stderr; captain investigates |
| 3 | Branch-protection block | Two paths (see Step 3 in SKILL.md) |

## Composition with `pr-captain-land`

When captain runs `/pr-captain-land`, this skill is invoked as Step 7 of the 9-step land flow. In that composition:

- `--principal-approved` is passed if captain initiated `/pr-captain-land` with the flag (principal authorized the full lifecycle, not just the merge)
- Exit codes propagate to `/pr-captain-land`'s step handler — Step 8 (release) does not run if this Step 7 fails

See `pr-captain-land/references/land-protocol.md` for the full integration.

## Why the tool is separate from the skill

`claude/tools/pr-merge` is a bash tool invokable outside Claude (during CI, manual captain shell, etc.). The skill wraps it with Claude-context preconditions + principal-approval attestation. Same pattern as other Triangle-enforced operations:

- Tool: does the work
- Skill: composes the work with context + guardrails
- Hookify: prevents raw invocation

## Principal-approval logging

`claude/tools/pr-merge` logs every `--admin` invocation with:
- PR number
- Captain identity (from `agent-identity`)
- Timestamp
- Session reference

Log lives in `~/.agency/<repo>/logs/pr-merge.log`. Audit trail for post-incident review.
