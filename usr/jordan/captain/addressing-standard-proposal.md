---
type: proposal
date: 2026-04-02
subject: Agent Addressing Standard
status: draft — pending MAR
---

# Agent Addressing Standard — Proposal

## 1. Proposed CLAUDE-THEAGENCY.md Section

Insert after "Session Handoff" section, before "Discussion Protocol (1B1)":

---

## Agent & Principal Addressing

### Concepts

A **principal** is a human who directs agent work. Principals are identified by a short name (lowercase, no spaces) mapped from their system username via `agency.yaml`.

An **agent** is an AI instance running under a principal's direction. Agent instances are registered in `.claude/agents/{name}.md` and belong to exactly one principal. (Future: shared agents that serve a repo or value stream without a specific principal.)

### Address Hierarchy

```
{org}/{repo}/{principal}/{agent}
```

Four levels, from broadest to narrowest:

| Level | What | Example |
|-------|------|---------|
| Org | Hosting namespace (GitHub org, GitLab group) | `the-agency-ai`, `OrdinaryFolk` |
| Repo | Repository name | `the-agency`, `monofolk` |
| Principal | Human directing the agent | `jordan`, `peter` |
| Agent | Agent instance name | `captain`, `devex` |

### Address Forms

Use the shortest unambiguous form for the context. Use fully qualified in all written records.

| Form | Pattern | When |
|------|---------|------|
| Bare | `captain` | Same repo, same principal — conversation and code |
| Principal-scoped | `jordan/captain` | Same repo, multi-principal — conversation and code |
| Cross-repo, single-principal | `monofolk/captain` | Different repo, only one principal — conversation only |
| Fully qualified | `monofolk/jordan/captain` | Different repo — dispatches, handoffs, all written records |
| Org-qualified | `OrdinaryFolk/monofolk/jordan/captain` | Repo name collision across orgs |

**Rule: Dispatches and handoffs always use fully qualified form** (`{repo}/{principal}/{agent}`). Short forms are for conversation and code comments. The written record must be unambiguous regardless of future context changes (new principals, repo forks, etc.).

### Principal Identity Across Repos

A principal may have different identities on different platforms:

| Repo | Local name | GitHub identity | Org |
|------|-----------|----------------|-----|
| the-agency | `jordan` | `jordandm` | `the-agency-ai` |
| monofolk | `jordan` | `jordan-of` | `OrdinaryFolk` |

The local name is repo-scoped (mapped in `agency.yaml`). The platform identity is org-scoped. The physical person may be the same, but the framework treats each `{repo}/{principal}` as a distinct context — different role, different permissions, different sandbox.

### Resolution

Addresses are resolved, not routed directly. The `remotes` section in `agency.yaml` maps short repo names to their hosting location:

```yaml
remotes:
  monofolk:
    url: github.com/OrdinaryFolk/monofolk
  the-agency:
    url: github.com/the-agency-ai/the-agency
```

This is the "DNS" layer — it maps logical names to physical locations. The transport (git push/pull, future IACP) is separate from addressing.

### Future: Shared Agents

A shared agent serves a repo or value stream rather than a specific principal. Addressing TBD — likely `{repo}/_/{agent}` or `{repo}/{agent}` with a reserved principal name. Not implemented yet.

---

## 2. Tooling Impact

### dispatch-create tool

**Current:** `From: ${PRINCIPAL}/captain` — missing repo, uses bare form.
**Change:** `From: {repo}/{principal}/{agent}` — fully qualified.

The tool needs:
- Auto-detect repo name (basename of git root, or from agency.yaml)
- Accept `--from` and `--to` flags with full addresses
- Default `--from` to `{repo}/{principal}/captain`
- Frontmatter should use structured fields, not inline markdown

**New frontmatter format:**
```yaml
---
status: created
created: 2026-04-02T10:10
from: the-agency/jordan/captain
to: monofolk/jordan/captain
priority: normal
subject: "..."
in_reply_to: "..."
---
```

### dispatch skill

**Change:** When invoking dispatch-create, pass fully qualified `--from` and `--to`.

### handoff tool

**Current:** No agent identity in frontmatter — just `type`, `date`, `branch`, `trigger`.
**Change:** Add `agent` field with fully qualified address.

```yaml
---
type: session
date: 2026-04-02 09:05
agent: the-agency/jordan/captain
branch: main
trigger: monofolk-plan-complete
---
```

### agency.yaml

**Add `remotes` section** for address resolution:

```yaml
remotes:
  monofolk:
    url: github.com/OrdinaryFolk/monofolk
```

**Add `identity` section** to capture the local principal's platform mapping:

```yaml
identity:
  jordan:
    github: jordandm
    # Could add: gitlab, email, etc.
```

### Commit messages

**Current:** `housekeeping/captain: ...` — bare agent name with workstream prefix.
**No change needed.** Commit messages are repo-local context. Bare form is correct here.

### Agent registration (.claude/agents/{name}.md)

**Add optional `address` field** to frontmatter:

```yaml
---
name: captain
description: "..."
model: opus
address: the-agency/jordan/captain
---
```

Auto-populated by agency-init. Used by tools to determine the agent's fully qualified address.

## 3. Migration

- Update dispatch-create tool to use new frontmatter format
- Update handoff tool to include `agent` field
- Add `remotes` section to agency.yaml (and to agency-init template)
- Add `identity` section to agency.yaml
- Add `address` field to agent registrations
- Existing dispatches and handoffs are NOT retroactively updated — they're historical records
- New dispatches from this point forward use fully qualified addressing

## 4. Relationship to ISCP / IACP

This addressing standard is a prerequisite for both protocols:

- **ISCP (Inter-Session Communication Protocol):** Same agent, across sessions. Address is implicit (it's always you). But handoffs now carry the agent's address for auditability.
- **IACP (Inter-Agency Communication Protocol):** Different agents, potentially cross-repo. Fully qualified addresses are the envelope. Resolution via `remotes` in agency.yaml is the routing layer. Transport (git push/pull today, dedicated protocol later) is separate.

The addressing standard defines the "email address." ISCP defines local delivery. IACP defines internet mail. The transport is SMTP-equivalent — pluggable, not part of the address.
