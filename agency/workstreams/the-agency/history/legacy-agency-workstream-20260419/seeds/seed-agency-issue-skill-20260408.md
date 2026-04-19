---
type: seed
workstream: agency
date: 2026-04-08
captured_by: the-agency/jordan/captain
principal: jordan
status: shipped-v1
discussion: 1B1 with principal 2026-04-08
v1_implementation:
  tool: agency/tools/agency-issue
  skill: .claude/skills/agency-issue/SKILL.md
  config: agency/config/agency.yaml (issues.github.target_repo)
  reports_dir: usr/jordan/reports/
  smoke_test_issue: https://github.com/the-agency-ai/the-agency/issues/52
---

**SHIPPED v1 — 2026-04-08.** Captain implemented in-session. Tool, skill, config, reports directory all in place. Smoke-tested by filing this very design as the first agency issue: [#52](https://github.com/the-agency-ai/the-agency/issues/52). Five verbs working: file, list, view, comment, close.


# Seed: `/agency-issue` skill

A skill for filing, viewing, commenting on, and updating issues against the-agency framework itself. Two-way channel with GitHub issues on `the-agency-ai/the-agency` — richer than `/feedback` (which is fire-and-forget to Anthropic, no status visibility, no update path).

## Scope

Filing and tracking **GitHub issues on the-agency repo** — platform and framework issues discovered by current users (human or agent) of the-agency.

**Explicitly NOT in scope (this version):**
- Project-local issue tracking for downstream adopters' own projects
- A generic issue-tracker primitive for arbitrary repos
- Cross-repo issue routing (monofolk, other orgs)
- Internal-only issues that never go to GitHub

## Decisions (from 1B1 with principal 2026-04-08)

### Item 1 — Audience scope
**Decision:** Narrow. For the-agency users (human or agent) who want to file issues in the-agency GitHub repo. Platform/framework issues, not local implementation issues.

**Options considered:**
- **(A) Local-only** — each agency instance has its own issue tracker, never crosses repo boundaries. Rejected: framework bugs downstream adopters hit stay invisible to the maintainer.
- **(B) Upstream-always** — every issue goes to the-agency central tracker. **Selected** (effectively).
- **(C) Hybrid local-first with optional routing** — project-local vs framework classification. Rejected for v1 as out of scope; revisit if downstream adopters hit project-local tracking needs.

### Item 2 — Thin vs fat wrapper
**Decision:** Thin wrapper — live `gh` calls, no local SQLite cache. BUT writes a persisted report file to `usr/{principal}/reports/` for every filed issue (same pattern as Claude Code feedback reports), capturing the GitHub issue ID, date filed, full content, and a response log.

**Options considered:**
- **(A) Thin wrapper, no state** — pure `gh` passthrough. Rejected: no audit trail of what we've filed.
- **(B) Fat wrapper with local SQLite mirror** — sync + offline browse + delta notification. Rejected for v1 as premature; GitHub handles most of this already.
- **(C) Thin now, fat later** — ship thin, extract fat pieces if needed. **Selected.**

### Item 3 — Sibling to `/feedback` or shared primitive?
**Decision:** Independent siblings. `/agency-issue` matches `/feedback`'s report format and index structure by imitation, but no shared primitive. When a third external target appears (monofolk, client repos, etc.), extract a shared primitive then.

**Critical distinction:** `/feedback` is Anthropic/Claude Code — fire-and-forget to a vendor. `/agency-issue` is our own project — two-way channel, we own the repo, we're the maintainer. The patterns look similar but the relationships are categorically different.

**Options considered:**
- **(A) Independent siblings** — duplicated logic, may drift. **Selected (as C).**
- **(B) Shared primitive under the hood** — DRY but premature abstraction. Rejected for v1.
- **(C) Independent now, extract primitive later** — **Effectively selected.**

### Item 4 — Permissions
**Decision:**
- **A (who files)** = **(i) Anyone in the agency** — human or agent, no approval gating
- **B (who comments)** = **Anyone who could comment on that issue on GitHub** — delegate to GitHub's permission model
- **C (who closes/resolves)** = **Whoever filed it, and whoever has those permissions at the-agency** — delegate to GitHub again
- **D (draft-and-approve before filing)** = **No** — unlike `/feedback` (vendor gating), we own the repo; cost of a wrong issue is trivial (just close it), cost of approval friction is real

**Options considered (for filing, A):**
- (i) Anyone in the agency — **Selected.**
- (ii) Agents surface via flags, captain consolidates — rejected, adds friction
- (iii) Human-only — rejected, blocks autonomous agent friction capture

**Options considered (for commenting, B):**
- (i) Anyone who can invoke the skill — superseded
- **GitHub permission model** — **Selected.** Skill delegates authz to `gh`.

**Options considered (for closing, C):**
- (i) Principal only — superseded
- (ii) Captain + principal — superseded
- **Filer + maintainers** — **Selected.** Matches GitHub's model; skill delegates.

**Principle:** the skill delegates all authorization decisions to GitHub. No custom permission logic on our side. Simpler, safer, harder to get wrong.

### Item 5 — Reports directory location
**Decision:** **Principal-scoped** at `usr/{principal}/reports/`. Reports are the principal's external-filing record; the filing agent is metadata (in frontmatter), not a path segment.

**Follow-up:** today's Claude Code feedback report (currently at `usr/jordan/captain/reports/`) needs to migrate to `usr/jordan/reports/`. REPORTS-INDEX.md moves with it.

**Options considered:**
- (A) Principal-scoped — **Selected.**
- (B) Captain-scoped (current state for the one existing report) — rejected; conflates captain's work with principal's filings
- (C) Hybrid per-agent reports dirs — rejected; scales but adds union-index machinery we don't need yet

### Item 6 — Labels and categories
**Decision (revised):** **No labels in v1.** Originally we agreed on a minimal 4-dimension label set (type, component, priority, reporter), but principal pushed back: *"Do we really need labels? Or just we file issues and they triage and determine from the description? Are we making this too complex?"*

Files issues with good descriptions. Triage is reading the body, not filtering on label dimensions. GitHub's built-in `open/closed` state + search is enough at low volume. Add labels later if/when volume justifies them.

**Implication:** this eliminates Item 10.B (label setup machinery) entirely. No `gh label create` calls, no setup subcommand, no `labels-bootstrapped` cache marker. Filing path is pure.

**Options considered:**
- 4-dimension label set (`type:*`, `component:*`, `priority:*`, `reporter:*`) — initially selected, then rejected as premature complexity
- **No labels** — **Selected.** Triage from body content. Add labels when volume justifies.
- Richer vocabulary (priority text, performance sub-type, etc.) — rejected for same reason

### Item 7 — Internal linkage between issues and seeds/dispatches
**Decision:** **(B) Plain text "Related" section in the issue body** with paths to internal artifacts (seeds, dispatches, transcripts) + **attachment capability** for additional context.

**Attachment implementation notes:**
- **Text attachments** (logs, transcripts, code snippets) — embed as fenced code blocks or `<details>` expandables in the issue body
- **Binary attachments** (screenshots, zip files) — upload via `gh gist create` first, link in the issue body
- `gh issue create` does not natively support file attachments; these are workarounds

**Options considered:**
- **(A) No internal linking** — rejected, loses audit trail
- **(B) Plain text "Related" section** — **Selected for v1.**
- **(C) Full bidirectional linkage** (frontmatter backlinks in related seeds) — deferred; revisit when we have lots of cross-references

### Item 8 — How does the agency learn about GitHub responses?
**Decision:** **(A) Pull-on-demand only** for v1. No background polling, no notification. `agency-issue status <id>` / `list` / `view <id>` hit GitHub live when invoked.

**Later:** add a status-line indicator ("📋 N issues with new activity") once the Fleet Awareness status-line infrastructure ships. Natural second consumer of the silent status-line pattern.

**Options considered:**
- **(A) Pull-on-demand only** — **Selected for v1.**
- **(B) Status-line periodic check** — deferred to post-Fleet-Awareness
- **(C) Hook-based notification** (new hook like iscp-check for GitHub) — rejected, the status-line path will be cleaner and we'll have it soon
- **(D) Rely on GitHub's own notifications** — philosophy, not infrastructure; acceptable fallback

### Item 9 — Valueflow integration (issues ↔ seeds ↔ plans)
**Decision:**

**Direction 1 (Issue → internal work):** **(i) Manual promotion — agents can triage, not just the principal.** Principal directive: *"Agents can triage as well. I want you to triage."* Any agent (captain especially) reads filed issues, proposes triage decisions, drafts seeds, and surfaces candidates for promotion. Principal has final say on non-obvious calls. Captain-driven triage is the default expectation for a healthy agency. No auto-seeding.

**Direction 2 (Internal work → issue closure):** **(ii) Skill-assisted.** `agency-issue close <id>` wraps `gh issue close` with a closing comment, optionally linked to the PR/commit that fixed it. Updates the local report file with the closing state.

**Options considered for Direction 1:**
- (i) Manual promotion — **Selected.**
- (ii) Auto-seed every filed issue — rejected, clutters seeds/
- (iii) Label-driven (`accepted` triggers seed creation) — deferred; plausible once we see filing volume

**Options considered for Direction 2:**
- (i) Pure manual (`gh issue close` by hand, or `Fixes #NNN` in PR) — too thin
- **(ii) Skill-assisted close** — **Selected.**
- (iii) QGR-integrated (`/phase-complete` auto-closes referenced issues) — deferred, nice-to-have

## Verb set (from Item 4 discussion)

| Verb | What | Authz |
|------|------|-------|
| `file` | Create a new issue | Anyone |
| `list` | List open / all issues | Anyone |
| `view <id>` | Show issue + comments | Anyone |
| `status <id>` | Short status line | Anyone |
| `comment <id> <text>` | Add a comment | GitHub permissions |
| `update <id> --title ... --body ...` | Edit the issue | GitHub permissions (filer or maintainer) |
| `close <id>` / `resolve <id>` | Mark resolved | GitHub permissions (filer + maintainer) |

### Item 10 — Setup and prerequisites

1B1'd as four sub-items.

#### Item 10.A — Target repo configuration
**Decision:** `agency.yaml` config block under `issues.{provider}.target_repo`. Auto-populated from git remote on init when possible; override-able. The SPEC-PROVIDER pattern (see "Future: SPEC-PROVIDER pattern" section below) means the target lives in provider-specific config, not at the skill level.

For v1: `issues.github.target_repo: the-agency-ai/the-agency`. Single target.

**Options considered:**
- (i) Hardcoded — rejected, breaks on fork
- **(ii) `agency.yaml` config block** — **Selected.**
- (iii) Auto-detect from git remote origin — rejected, breaks for downstream worktrees

#### Item 10.B — Label setup
**Decision: DROPPED.** Item 6 killed labels for v1, so there is no label setup. Skipped entirely.

#### Item 10.C — First-run detection
**Decision:** Simple. Only check is `gh auth status` on every invocation (~50ms, fast enough). No caching. No bootstrap markers. No setup state.

#### Item 10.D — Failure modes
**Decision:** Three named cases plus pass-through of `gh` errors:

1. **`gh` not installed** → actionable error: "Install gh CLI: https://cli.github.com/"
2. **`gh` not authenticated** → actionable error: "Run `gh auth login` to authenticate"
3. **No write access to target repo** → actionable error explaining the user lacks write access to `{repo}`
4. **All other `gh` failures** (network, rate limit, etc.) → pass through `gh`'s error message verbatim with context about which verb was invoked

That covers it.

## Future-version notes (captured for v2 and beyond)

### Future: SPEC-PROVIDER pattern

Principal raised this during the 1B1: *"I envision we will want to eventually allow people to file issues against the-agency (platform, framework, tools, etc) and later file issues against their own project. For us it is the same thing. So, maybe it is a SPEC:PROVIDER pattern, where agency-issue [VERB] calls a (in this case) github-issue [VERB]."*

The natural v2+ shape:

```
/agency-issue file              (contract skill — agency semantics + reports + audit)
       ↓
  agency/tools/agency-issue     (top-level dispatcher, reads issues.provider from agency.yaml)
       ↓
  agency/tools/agency-issue-github   (GitHub provider, wraps gh CLI)
```

Later providers: `agency-issue-gitlab`, `agency-issue-linear`, `agency-issue-jira`, etc. Same skill contract, pluggable backend.

**Layering:**
- **`/agency-issue`** (contract skill) — agency semantics: report files, frontmatter, internal audit trail, "Related" sections, REPORTS-INDEX updates
- **`agency-issue-github`** (provider) — GitHub-specific: `gh` CLI wrapping, GitHub URL formats, GitHub permission delegation
- **Target repo(s)** in provider config under `agency.yaml` — provider-specific, not skill-level

```yaml
issues:
  provider: github
  github:
    target_repo: the-agency-ai/the-agency  # v1: single target
    # v2+: multi-target support
    # targets:
    #   platform: the-agency-ai/the-agency   # framework issues
    #   project: my-org/my-repo              # local project issues
```

This is the **fourth SPEC-PROVIDER consumer** after `secret`, `preview`, `deploy`. Pattern is the right shape for "agency semantics layered over a pluggable backend." But **not in v1** — v1 stays simple, single target, single provider, no pattern overhead.

### Future: Multi-instance contract pattern (principal directive)

Principal directive (2026-04-08): *"Consider that the model (SPEC:PROVIDER) should be flexible and powerful enough for the skills to be used with for example linear. So, I use agency-issue to report an issue to the agency github, but I can report local-issue to my linear?"*

The implication: the **same contract** (file, view, comment, close) should support **multiple instances**, each pointing at a different provider + target. Not just `/agency-issue` with a swappable provider — but a *family* of skills built from the same contract:

```
contract: issue (verbs: file, view, list, comment, update, close)
                              ↓
        ┌─────────────────────┼─────────────────────┐
        ↓                     ↓                     ↓
  /agency-issue         /local-issue          /vendor-issue (etc)
        │                     │                     │
  provider: github      provider: linear      provider: gitlab
  target: the-agency-ai/the-agency
                        target: user's Linear board
                                              target: vendor's gitlab
```

Each skill instance:
- Uses the **same contract** (same verb names, same arg shapes, same output format)
- Has its **own provider** binding (github, linear, gitlab, jira, etc.)
- Has its **own target config** in `agency.yaml`
- Writes to its **own section of the reports index** (or one shared index with a `target:` column)

**Three possible shapes for this:**

1. **Shared contract definition + per-instance skills.** Define the issue contract in one place (e.g., `claude/contracts/issue.md`). Each instance skill (`/agency-issue`, `/local-issue`, etc.) implements the contract by composing a provider tool. Skills are thin; the contract is the spec.

2. **One generic skill `/issue` with `--scope` flag.** `/issue file --scope agency`, `/issue file --scope local`. Single skill, multiple scopes, each scope has provider+target config in `agency.yaml`.
   ```yaml
   issues:
     scopes:
       agency: { provider: github, target: the-agency-ai/the-agency }
       local: { provider: linear, target: user-linear-board-id }
   ```

3. **Skill family with sibling implementations.** `/agency-issue`, `/local-issue`, `/vendor-issue` are independent skills that all happen to follow the same contract by convention. Some shared library code, but each skill is its own surface area.

**Trade-offs:**

- **Shape 1** is the cleanest abstractly but requires a contracts mechanism we don't have today
- **Shape 2** is simpler implementation-wise (one skill, scopes) but loses the discoverability of distinct `/agency-issue` vs `/local-issue` slash commands
- **Shape 3** matches our existing skill-per-purpose convention but risks drift between siblings

**Captain's lean:** Shape 1 (contract-driven) is the right end-state. Shape 2 (one skill, scopes) is a reasonable v1 of the multi-instance pattern. Shape 3 (sibling skills) is what we're already doing implicitly (e.g., `/feedback` and `/agency-issue` are de facto siblings of an unspoken contract).

**Defer the choice** until v2 when we have a concrete second consumer (Linear, gitlab, or local-issue use case). v1 ships single-instance `/agency-issue` only. The contract emerges through use.

### Other future questions

- **Multi-target support** within a single provider (platform vs project issues)
- **Issue templates.** GitHub supports `.github/ISSUE_TEMPLATE/`. Should the-agency ship one matching our format? Skill could pre-fill from the template.
- **Status-line indicator** for "issues with new activity" — natural second consumer of fleet awareness status-line infrastructure
- **Comment-thread-as-dispatch-thread** mapping — could a GitHub issue comment become a dispatch in our system? Probably not, but worth considering when fleet awareness matures.
- **Closing issues from PR merge** via `Fixes #NNN` semantics — GitHub already does this; do we need anything beyond?
- **Filing from within a worktree.** v1 ignores worktree state and uses the configured target repo. v2+ may want worktree-aware target selection.
- **Graceful degradation when `gh` auth is stale or offline.** v1 fails clearly; v2+ may want cached read-only fallback.

## Related Agency work

- **`usr/jordan/reports/REPORTS-INDEX.md`** (to be migrated from captain/) — the principal-scoped reports index; this skill is a second consumer of that pattern
- **`/feedback`** (Claude Code / Anthropic) — sibling skill, independent implementation, similar format conventions
- **Fleet Awareness seed** (`seed-fleet-awareness-20260408.md`) — the status-line indicator approach (Item 8, future) will share status-line infrastructure
- **Silent periodic tool calls seed** (`seed-silent-periodic-tool-calls-20260408.md`) — related to how we'd eventually add proactive GitHub-activity notification
- **Captain's reports tracking pattern** — REPORTS-INDEX.md + per-report markdown file, invented today for Claude Code feedback filing

## Next steps

1. `/define` — produce a proper PVR from this seed (not yet done)
2. `/design` — A&D document covering the skill contract, report file format, label setup, error handling
3. Plan — phases and iterations; likely a single-phase ship since it's a thin skill
4. Implement — wrap `gh` with the decided verb set, create the label set on the repo, write the first filed issue through it

## Conversation source

Captured during Day 33 from a principal-captain 1B1 on 2026-04-08. Principal's framing: "This is a skill for filing, viewing, fetching, and updating issues that users find in the agency. Two parts: the user part (file, view, see status, update/comment) and the captain/agency agent/agency principal part (view, update, comment, resolve, etc.)."

Discussion resolved items 1-9 of the 10-item 1B1 agenda. Principal's closing direction: "Capture all of these options + what we selected in the seed, so we can think about next version options." This seed is that record.
