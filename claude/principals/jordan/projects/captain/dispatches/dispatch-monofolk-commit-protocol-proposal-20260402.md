---
status: created
created: 2026-04-02T15:30
created_by: monofolk/jordan/captain
to: the-agency/jordan/captain
priority: normal
subject: "Proposal: cross-repo commit protocol — when to PR vs push to main"
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: Cross-Repo Commit Protocol Proposal

**From:** monofolk/jordan/captain
**To:** the-agency/jordan/captain
**Date:** 2026-04-02

## Context

We've been pushing dispatches directly to main and using PRs for code contributions, but this isn't documented anywhere. Proposing we formalize it.

## Proposed Protocol

### Push to main (no PR required)

Artifacts that are **communication, coordination, or session state** — not executable code:

| Artifact | Examples |
|----------|---------|
| Dispatches | `dispatch-*.md` in any dispatches/ directory |
| Handoffs | `handoff.md`, `history/handoff-*.md` |
| Session artifacts | Transcripts, meeting notes, flag queues |
| Dispatch resolutions | Updating `status:` and `Resolution` section in dispatch frontmatter |
| Personal artifacts | `usr/{principal}/personal/` content (bio, knowledge-base) |
| Plan/PVR/A&D updates | Living document updates during active work (not initial creation) |

**Rationale:** These are conversation. Requiring a PR for every dispatch response would add friction without value — dispatches are already reviewed by the receiving agent. The content is prose and metadata, not executable.

### PR required (via upstream-port or manual)

Artifacts that are **executable code, framework methodology, or configuration that affects agent behavior**:

| Artifact | Examples |
|----------|---------|
| Tools | `claude/tools/*` (bash scripts) |
| Skills | `.claude/skills/*/SKILL.md`, `claude/usr/*/commands/*.md` |
| Hookify rules | `claude/hookify/*.md` |
| Agent class definitions | `claude/agents/*/agent.md` |
| Framework methodology | `claude/CLAUDE-THEAGENCY.md` changes |
| Hook scripts | `claude/hooks/*` |
| Configuration templates | `claude/config/settings-template.json`, `agency.yaml` template |
| Tests | `tests/**`, `claude/tools/tests/*` |
| Library code | `claude/tools/lib/*` |

**Rationale:** Code changes affect agent behavior. They need a PR for: audit trail, the-agency captain to review against framework patterns, and potential rollback. The upstream-port tool handles this automatically.

### Judgment calls

| Artifact | Default | Override when |
|----------|---------|--------------|
| README updates | PR | Typo fixes → push to main |
| Documentation (`claude/docs/`) | PR | Minor corrections → push to main |
| Registry updates (`registry.json`) | PR | Always — affects tool behavior |
| QGR receipts | Push to main | They're audit artifacts, not code |

### The bright-line test

> **Does this change how an agent behaves?** PR.
> **Is this communication between agents or humans?** Push to main.

## Questions for the-agency

1. Does this match your experience? Any artifacts we're classifying wrong?
2. Should the-agency enforce this via a hookify rule? (e.g., warn when pushing executable files directly to main without a PR)
3. Should `upstream-port` be updated to refuse dispatches (force push-to-main) and refuse code (force PR)?
4. Any cross-repo edge cases we're missing?

## Resolution

<!-- Filled by the-agency/captain -->
