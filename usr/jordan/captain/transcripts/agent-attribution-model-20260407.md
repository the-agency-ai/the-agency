---
type: discussion-record
date: 2026-04-07
participants: [jordan, captain]
topic: per-agent commit attribution model
status: resolved → implemented in commit 03d3ed6
---

# Per-Agent Commit Attribution Model

A working session that started from a question — "should we attribute commits to the agent and maybe give credit to the principal?" — and ended with a shipped implementation in `claude/tools/git-safe-commit`. This document captures the decisions, the rationale, the dead-ends, and the open questions for future iteration.

## The Question

The starting prompt: in a multi-agent framework, who gets credit for a commit?

Today (before this work):
```
Author: Jordan Dea-Mattson <jdm@devopspm.com>
Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
```

The principal (Jordan) and Claude get credit. The actual Agency agent (captain, iscp, devex, mdpal-cli, etc.) is invisible. Multiple agents in the same session look identical in `git log`.

The goal: make the per-agent attribution visible without losing principal accountability or breaking existing tooling.

## Constraints

These shaped every decision:

1. **No domain registration.** Whatever we ship must work without buying or claiming a new domain.
2. **Works out of the box on GitHub.** Zero-config for any adopter with a GitHub account.
3. **Configurable later.** Adopters with different setups (private email, custom mail) can override the default.
4. **Principal owns the commit.** Legal authorship belongs to the principal — agents are tools, even when autonomous. The Author field stays the principal.
5. **Agent identity is real and traceable.** "Captain" or "devex" should appear somewhere a human or tool can read.
6. **Don't break `git blame` / `git shortlog` / contribution stats.** Those tools work on the Author field. Don't move agents into Author and lose principal aggregation.

## Options Considered

### Option A — Agent-only Co-Authored-By trailer with placeholder email

```
Co-Authored-By: captain <captain@noreply.invalid>
```

- Pros: Zero setup, RFC 2606 reserved domain, semantic clarity ("not a real email").
- Cons: No principal encoding in the email itself. Agent looks orphaned from any principal.
- **Rejected** in favor of approaches that encode both principal and agent.

### Option B — Real mailbox with plus-addressing

```
Co-Authored-By: captain <jdm+captain@devopspm.com>
```

- Pros: Real delivery (replies route to the principal's mailbox via plus-addressing), agent identity in the tag, GitHub can profile-link if the email is verified on the principal's account.
- Cons: Exposes principal's real email — though it's already public from existing commits. Requires the principal to use a mail provider that supports plus-addressing (most do). More work to set up across team members.
- **Kept as the configurable Layer-2 option** for adopters who want forwarding to work and don't mind the email exposure.

### Option C — `captain+jordandm@noreply.{framework}.dev`

`{agent}+{principal}@noreply.framework-domain` — agent as the base, principal as the tag.

- Reads as "captain working for jordandm." Semantically clean.
- **Rejected** because it requires the framework to own a domain, which Jordan explicitly didn't want.

### Option D — `jordandm+captain@noreply.github.com` (entity noreply)

Borrowing GitHub's pattern of using `@noreply.github.com` (without `users.`) for non-user entities like repos (`monofolk@noreply.github.com`) and notification categories (`ci_activity@noreply.github.com`).

- Pros: GitHub-owned domain, no registration, looks legitimate.
- Cons: **No profile linking** — `noreply.github.com` is not the user noreply domain. The principal's profile wouldn't link.
- **Rejected** because we wanted profile linking on the principal author.

### Option E — `jordandm+captain@users.noreply.github.com` (user noreply with plus-tag)

What we ended up with. Uses the **user** noreply domain (`users.noreply.github.com`) which is what GitHub recognizes for user attribution.

- Pros: Same domain for principal and agent, GitHub-owned, no registration, works for any GitHub user.
- Open question: Does GitHub strip the `+captain` plus-tag and dedupe to `jordandm`? **Tested with real commits.**

## The Test

Four throwaway commits on a test branch (`test/github-plus-tag-attribution`, since deleted) verified GitHub's actual behavior:

| Commit | Format | Result |
|--------|--------|--------|
| `dd7984e` | `jordandm+captain@users.noreply.github.com` (agent only) | "3 people authored" — distinct identity |
| `c133aaa` | `jordandm+iscp.the-agency@users.noreply.github.com` (with .repo) | "3 people authored" — distinct identity |
| `1284b27` | Principal canonical author + 3 plus-tag co-authors + Claude | "5 people committed" — all distinct |
| `7e0932a` | Principal canonical author + 3 `agent.repo` plus-tag co-authors | "4 people committed" — all distinct |

**Findings:**

1. **GitHub does NOT strip plus-tags** on `users.noreply.github.com`. Each `jordandm+X@users.noreply.github.com` is a distinct contributor — literal string match.
2. **Canonical `jordandm@users.noreply.github.com` profile-links to the user.** The principal author's avatar shows correctly.
3. **Plus-tag identities show as distinct contributors with gray default avatars** — not deduped, not profile-linked, but counted separately in GitHub's contributor view.
4. **`.` is valid in the local-part** — `jordandm+captain.the-agency@` works fine, no encoding issues.

This is exactly what we want for the model:
- Principal author = real linked GitHub identity (avatar, profile, contribution count)
- Each agent = distinct contributor entry (gray avatar, but distinct attribution)

## The Final Format

```
Author: Jordan Dea-Mattson <jordandm@users.noreply.github.com>

[commit message body]

Co-Authored-By: captain <jordandm+captain.the-agency.the-agency-ai@users.noreply.github.com>
Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
```

**Schema:** `{username}+{agent}.{repo}.{org}@users.noreply.github.com`

| Field | Source | Example |
|-------|--------|---------|
| `{username}` | `agency.yaml` → `principals.{key}.platforms.github[]` matching current org | `jordandm` |
| `{agent}` | `agent-identity --agent` | `captain` |
| `{repo}` | `agent-identity --repo` | `the-agency` |
| `{org}` | Parsed from git `remote.origin.url` | `the-agency-ai` |

**Why fully qualified:** Mirrors the Agency address convention `{org}/{repo}/{principal}/{agent}`. Self-describing — you can tell which agent in which repo in which org from the email alone, without looking up principal mappings.

**Why GitHub user noreply:** Profile linking on the principal author. Agents get gray avatars (correct — they're not GitHub users) but are counted as distinct contributors.

## What `/git-safe-commit` Does (after this change)

Before building the commit body, `git-safe-commit`:

1. Calls `agent-identity` for `--agent`, `--principal`, `--repo`
2. Parses `git remote get-url origin` to extract the GitHub `{org}`
3. Reads `claude/config/agency.yaml` with an awk parser, finds the principal entry whose `name` matches `--principal`, finds the `platforms.github[]` entry whose `repos[].org` matches `{org}`, returns the `username`
4. Builds: `Co-Authored-By: {agent} <{username}+{agent}.{repo}.{org}@users.noreply.github.com>`
5. Appends to the trailer block before the existing `Co-Authored-By: Claude` line

**Fallbacks** (it never crashes the commit):
- `agent-identity` unavailable → skip the trailer
- GitHub username not resolvable from `agency.yaml` → use the principal slug as fallback
- Git remote not parseable → omit the `.org` suffix

## Configurable Layer (Future)

The Day 32 ship is GitHub-mode-only, no override. The Layer 2 model (real mailbox with plus-addressing) is documented as the configurable future:

```yaml
principals:
  jdm:
    commit_email: jdm@devopspm.com   # if set, use this for author + plus-tag for agent
```

When set, `/git-safe-commit` would build:
```
Author: Jordan Dea-Mattson <jdm@devopspm.com>
Co-Authored-By: captain <jdm+captain@devopspm.com>
```

— routing to the principal's real mailbox, optional verification on GitHub for profile linking on agents.

Not implemented yet. Will be added when the first adopter asks.

## Open Items / Future Work

### Agent Mail Service (flag #40)

The plus-tag format `jordandm+captain.the-agency.the-agency-ai@users.noreply.github.com` is currently a non-routable string in commit trailers. There's a real product idea here: an "agent mail" service that takes this format and provides actual delivery.

- Service-owned domain (e.g., `agentmail.dev`)
- Mailbox per principal
- Plus-tags route per agent
- Forwarding rules per agent (e.g., `jdm+captain.commits@agentmail.dev` → main inbox, `jdm+iscp.errors@agentmail.dev` → digest)
- Solves the agentic email gap: agents need addressable identities AND routing back to principals

Initial users would be AIADLC framework adopters. Could become the GitHub-noreply alternative for projects not on GitHub.

Flagged: `flag #40`. Captured for future product discussion.

### Configurable per-principal override (Layer 2)

Documented above. Not implemented in this PR. Will add when needed.

### Verification of plus-tag profile linking

The test branch confirmed GitHub does NOT strip plus-tags — each is a distinct identity. This means agents don't get profile photos in the GitHub UI, just gray avatars with the agent name. If GitHub ever adds plus-address handling on `users.noreply.github.com`, our existing format would suddenly start showing the principal's avatar on every agent co-author. That would be a positive change with zero migration needed.

### History rewrite for stale Test User attributions

Separate issue (flag #6, dispatched to devex as #109). Not part of this attribution work but related — the Test User pollution shows the importance of getting attribution right. Once devex fixes the test isolation bug, the historical commits with Test User attribution remain on devex branch (fixable by rebase before merge to main).

## Decision Log (chronological)

1. **Author should be the principal** — ownership, legal, `git blame` integrity. Agents go in Co-Authored-By trailers, not the Author field.
2. **Co-Authored-By trailer for the agent** — standard mechanism, GitHub renders as additional contributor.
3. **GitHub user noreply for the email domain** — `users.noreply.github.com`, not `noreply.github.com`. The user noreply is the only form GitHub profile-links.
4. **Plus-tag carries the agent** — `+captain` after the username.
5. **Include `.repo` in the plus-tag** — disambiguates across repos.
6. **Include `.org` in the plus-tag** — fully qualified, self-describing, mirrors the address convention.
7. **Pull GitHub username from `agency.yaml`** — supports per-org identities (principal can have different usernames in different orgs).
8. **Default is GitHub mode, no override** — ship simple, add config when needed.
9. **Implementation lives in `claude/tools/git-safe-commit`** — captain territory, small enough to do in-context, not dispatched to devex.
10. **Test branch deleted after verification** — keep main history clean.

## Implementation Reference

- Tool: `claude/tools/git-safe-commit` (commit `03d3ed6`)
- Test commits (deleted): `dd7984e`, `c133aaa`, `1284b27`, `7e0932a`
- Flags captured: `flag #39` (attribution model), `flag #40` (agent mail business idea)
- Related: Day 32 - Release 1 PR (`day32-release-1` branch, PR #46)

## What This Records

This isn't just a how-it-works doc — it's the reasoning trail. When someone in the future asks "why does our commit attribution use this weird plus-tag thing?", this document is the answer. The dead-end options are here so we don't re-litigate them. The constraints are here so we don't accidentally violate them when extending. The open items are here so the next person knows what's not done.

The narrative thread of how we arrived at the format is the most valuable part. The code is just the implementation of a decision.
