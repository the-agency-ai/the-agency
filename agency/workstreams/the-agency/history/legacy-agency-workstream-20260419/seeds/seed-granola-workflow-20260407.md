---
type: seed
workstream: agency
date: 2026-04-07
status: parked — awaits prioritization
source: flag #37
captured-by: the-agency/jordan/captain
---

# Seed: Granola Workflow — External Material Ingestion Pipeline

## The Problem

Granola transcripts (meeting summaries + raw transcripts) are a **primary source of seed material** today. We have no formal pipeline for getting them into the framework. They live wherever Granola puts them; they get into the repo via ad hoc copy-paste during agent sessions; there's no redaction, no classification, no consistent location.

This bites us in two ways:

1. **Friction at capture time** — when a Granola transcript inspires a seed/discussion, the agent has to manually paste content, decide where it goes, and figure out what to redact (if anything). The friction discourages capture.

2. **Inconsistency at retrieval time** — past transcripts referenced by current work are hard to find. Some are in `usr/jordan/captain/transcripts/`, some are in `claude/workstreams/{ws}/seeds/`, some are inline in handoffs, some are nowhere.

## What's Needed

A formal workflow for pulling external materials (Granola summaries + transcripts) into the repo:

### 1. Ingestion Process

- A standardized location for Granola materials (probably `usr/{principal}/granola/{date}/`)
- A way to bring them in: tool, skill, or manual convention
- Naming convention that ties them to source meeting + date + topic
- Both summary AND raw transcript captured (summary for quick reference, raw for full context when needed)

### 2. Redact Functionality

External materials may contain:
- Other people's PII (names, emails, contact info)
- Sensitive business information
- Information about people/orgs not in the project
- Things the principal wouldn't want in a public repo

The pipeline needs a redact step: either automated (regex patterns + named-entity removal) or principal-reviewed (interactive markup before commit). Default should be conservative — when in doubt, flag for manual review.

### 3. Classification

Not every external material is a seed. Three categories:

- **Seed material** — directly inspires PVR/discussion work; goes to `agency/workstreams/{ws}/seeds/`
- **Reference** — context that informs decisions but isn't a starting point; goes to `agency/workstreams/{ws}/references/` or similar
- **Ephemeral** — useful in the moment but not worth committing; goes to `usr/{principal}/{project}/tmp/` (gitignored)

The pipeline asks the principal to classify on capture, with sensible defaults.

### 4. Tooling

- A tool/skill to pull the latest Granola export and stage it
- A redact step (interactive or automated)
- A classification + commit step
- Cross-references: from the Granola material file back to the project work it inspired (and vice versa)

## Why This Matters

The Valueflow methodology starts with Idea → Seed. Seeds are the entry point. **If seed capture has friction, the whole flow has friction at the source.** Granola transcripts are one of the highest-volume seed sources today. Formalizing this pipeline reduces friction at the most important point in the flow.

Also: continual learning depends on having historical context. When a future session asks "why did we decide X six months ago?", the answer often lives in a Granola transcript that someone heard but never captured. Proper pipelines = better mining = better continual improvement.

## Constraints

- **Don't expose PII or sensitive info** in public commits — redaction is mandatory, not optional
- **Don't make capture harder than current ad hoc copy-paste** — if the formal pipeline has friction, it'll get bypassed
- **Don't build a big system** — start with the simplest thing that addresses the friction (a tool + a convention), iterate from there

## Open Design Questions

1. **Where do raw Granola exports live?** Per-principal sandbox (`usr/{principal}/granola/`)? Framework directory? Outside git entirely?
2. **Redact automation vs review?** Where's the right balance? Maybe heuristic redaction with mandatory principal sign-off before commit?
3. **Classification at capture vs lazy?** Force the principal to classify upfront (strict) or default to "ephemeral" and allow promotion later (lazy)?
4. **Granola API integration?** Granola has an API — should the tool pull from the API directly, or rely on file exports?
5. **Cross-reference mechanism?** Front matter? Sidecar metadata file? A central index?

## Related

- Flag #14, #15: agency-audit + structure.yaml seeds (could include granola/ in structure validation)
- Continual learning loop: transcript mining (planned, deferred to V2.1)
- This seed is captain-side, but consumers include all workstream agents

## Spin-Up Notes

When prioritized, this could become its own workstream (`agency/workstreams/granola/`) or live as an iteration in the agency workstream. Decision point: how big does the design get? If just a tool + convention, it's an iteration. If a full pipeline with API integration, classification UI, and continual learning hooks, it's a workstream.

Recommend starting as an iteration (tool + convention + redact step) and graduating to a workstream if the scope grows.

## Captured From

Flag #37 (2026-04-07T02:59:56Z): "SEED/PROCESS: workflow for pulling in external materials from Granola (summary + transcript). These might be seed materials or general project context. Need: (1) ingestion process — where do they live, how do agents access them, (2) redact functionality — strip PII/sensitive info before they enter the repo, (3) classification — seed vs reference vs ephemeral, (4) tooling to support the workflow. Granola transcripts are a primary source of seed material today and we have no formal pipeline."
