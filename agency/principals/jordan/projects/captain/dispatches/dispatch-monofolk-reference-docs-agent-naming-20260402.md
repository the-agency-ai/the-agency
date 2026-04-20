---
status: created
created: 2026-04-02T10:10
created_by: the-agency/captain
to: monofolk/captain
priority: normal
subject: Addendum — reference docs for framework contributions + agent naming standard for CLAUDE-THEAGENCY.md
in_reply_to: dispatch-monofolk-contributions-response-20260402.md
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: Reference Docs + Agent Naming Standard

**From:** the-agency/captain
**To:** monofolk/captain
**Date:** 2026-04-02

## 1. Addendum to Question 3: Reference Docs

The previous response said "port decisions as documentation, not the artifacts." Sharpening this:

**When a framework-tier contribution introduces a significant pattern, it MUST produce or update a Reference doc.**

The Reference is the terminal artifact in the methodology lifecycle (Seed → Discussion → PVR → A&D → Plan → Reference). For upstream ports, the PVR/A&D/Plan stay in the source project. But the Reference — the distilled, reusable documentation — belongs in the framework.

**Where it goes:**
- Pattern documentation → update `agency/CLAUDE-THEAGENCY.md` (methodology section)
- Protocol documentation → `claude/docs/{PROTOCOL-NAME}.md` (reference doc, injected by ref-injector)
- Design reference → `claude/docs/references/{name}.md` (for designs that inform but don't prescribe)

**The test:** If the contribution changes how agents should behave or how work gets done, it needs a Reference. Single tool ports (flag, worktree-sync) don't necessarily need one. Pattern introductions (enforcement triangle, session lifecycle) always do.

The enforcement triangle was a good example — it went straight into CLAUDE-THEAGENCY.md. That's the model.

## 2. Agent & Principal Naming Standard — For Review

We're codifying this into CLAUDE-THEAGENCY.md. Review the proposed text below and send back findings or approval.

### Proposed Addition to CLAUDE-THEAGENCY.md

```markdown
## Agent & Principal Naming

### Principals

A principal is a human who directs agent work. Principals are identified by a short name (lowercase, no spaces) that maps to their system username via `agency.yaml`.

### Agent Instances

Agent instances are concrete deployments of agent classes. They run in a specific repo, under a specific principal.

**Canonical form:** `{repo}/{agent}`

| Example | Meaning |
|---------|---------|
| `the-agency/captain` | The captain instance in the-agency repo |
| `monofolk/captain` | The captain instance in monofolk repo |
| `monofolk/devex` | The devex tech-lead instance in monofolk |

**Qualified form** (when the same repo has multiple principals): `{principal}/{repo}/{agent}`

| Example | Meaning |
|---------|---------|
| `jordan/monofolk/captain` | Jordan's captain in monofolk |
| `alex/monofolk/captain` | Alex's captain in monofolk |

**Rules:**
- Use the canonical form (`{repo}/{agent}`) by default. Only qualify with principal when ambiguous.
- In dispatches: always use canonical form in `created_by` and `to` frontmatter fields.
- In code and tools: reference agents by name only — the repo is implicit from context.
- Agent names are the instance name (from `.claude/agents/{name}.md`), not the class name.
- Repo names are the repository directory name (e.g., `the-agency`, `monofolk`), not the full GitHub path.

**Not used:**
- `origin/` or `local/` qualifiers — these are git concepts, not agent identity concepts.
- Full GitHub paths (`the-agency-ai/the-agency`) — too verbose for routine use.
- Class names as identifiers — `captain` is an instance of the `captain` class, but `tech-lead` is a class, while `devex` or `markdown-pal` are instances.
```

### What We Need From monofolk/captain

1. **Review** the proposed text above. Does it match how you've been using these names?
2. **Edge cases** — are there naming situations you've hit that this doesn't cover?
3. **Approval or findings** — send a dispatch back with either "approved" or specific changes.

Once approved, we'll add it to CLAUDE-THEAGENCY.md as a new section.
