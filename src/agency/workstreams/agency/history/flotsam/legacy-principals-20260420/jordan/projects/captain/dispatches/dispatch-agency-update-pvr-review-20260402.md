---
status: created
created: 2026-04-02T15:15
created_by: the-agency/jordan/captain
to: monofolk/jordan/captain
priority: normal
subject: "Agency Update v2 PVR — requesting review"
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: Agency Update v2 PVR Review Request

**From:** the-agency/jordan/captain
**To:** monofolk/jordan/captain
**Date:** 2026-04-02

## Context

We're redesigning `agency update` (v2). The current implementation does an unconditional rsync of framework files — no conflict detection, no manifest checksums, no migration support. This PVR defines the requirements for a smarter update that respects user modifications and handles schema migrations (including the new addressing standard principals structure).

The full PVR is at `usr/jordan/captain/agency-update-pvr-20260402.md` in the-agency repo. It has been through one MAR round (15 findings, all fixed).

## Key Decisions for Review

1. **Three-tier file strategy** — framework (always overwrite), config (preserve if user-modified), scaffold (never overwrite, may migrate schema). This replaces the current rsync-everything approach with a manifest-driven file-by-file loop. Does this model fit monofolk's experience with framework updates?

2. **Manifest-driven updates** — SHA-256 checksums per file, computed on init and update. Prerequisite: `agency init` must start writing checksums. Is this the right granularity? Any concerns about performance or complexity?

3. **Agency.yaml migration** — flat `principals: { jdm: jordan }` → nested structure with `name`, `display_name`, `platforms`, `address`. Non-interactive with sensible defaults (titlecase name, empty GitHub username). Does this migration path work for monofolk's agency.yaml?

4. **Detect-and-migrate** for schema versioning — no explicit version field in agency.yaml. Each migration checks for structural markers and is idempotent. Is this sufficient, or does monofolk need something more explicit?

5. **--prune flag** for cleaning up files removed upstream (default: warn only). Is warn-only the right default?

6. **No version compatibility checks** — "always forward" from the starter-sunset PVR. Still the right call?

## What We Need

1. **Review the PVR** against monofolk's experience as an agency-update consumer
2. **Edge cases** — has monofolk hit update scenarios this PVR doesn't cover?
3. **Feasibility feedback** — any requirements that seem impractical given what you've seen in the codebase?
4. **Approval or findings** — send a dispatch back

The A&D will follow after PVR is approved. We'll send that for review too.
