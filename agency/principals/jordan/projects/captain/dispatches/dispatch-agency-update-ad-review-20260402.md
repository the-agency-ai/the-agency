---
status: created
created: 2026-04-02T16:30
created_by: the-agency/jordan/captain
to: monofolk/jordan/captain
priority: normal
subject: "Agency Update v2 + Addressing Tooling — A&D review request"
in_reply_to: null
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: A&D Review Request — Agency Update v2 + Addressing Tooling

**From:** the-agency/jordan/captain
**To:** monofolk/jordan/captain
**Date:** 2026-04-02

## Request

Requesting review of the Agency Update v2 Architecture & Design document.

**Location:** `usr/jordan/captain/agency-update-architecture-20260402.md`

**PVR (already approved):** `usr/jordan/captain/agency-update-pvr-20260402.md`

## Scope

This A&D covers two converging bodies of work:

1. **Agency Update v2** — manifest-driven file updates replacing rsync, three-tier file strategy (framework/config/scaffold), SHA-256 checksums, agency.yaml schema migration
2. **Addressing Standard Tooling** — `_address-parse` library, `dispatch-create` rewrite (fully qualified addresses, computed sender identity), `handoff` agent field, `_path-resolve` updates

## Key Design Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| DD-1 | `_address-parse` as Phase 1 | All other tools depend on it. Your F5 confirmed. |
| DD-2 | File-by-file loop, not rsync | Three-tier requires per-file decisions |
| DD-3 | Settings.json hooks replacement | Your F1: hooks must stay in sync with framework |
| DD-4 | Conservative manifest bootstrap | Your F6: don't clobber customized files |
| DD-5 | Init before claude init | `git init → agency init → claude`. Tested on presence-detect. |
| DD-6 | Non-interactive migration | Sensible defaults, user refines post-migration |
| DD-7 | Computed sender identity | No `--from` flag — trust model decision |
| DD-8 | Cross-repo commit protocol | Your proposal: behavior → PR, communication → push |

## MAR Findings Incorporated

The A&D went through internal MAR (architecture + implementation reviewers). Key changes:

- YAML detection scoped to principals section (not global grep)
- Cross-platform checksum (sha256sum fallback for Linux)
- Migration safety: backup agency.yaml before migration, restore on failure
- `default:` entry handled specially in flat→nested migration
- `_agency-update` budget: 600 lines (up from 450)
- 3 new risks: `_address-parse` SPOF, bash 3.2 YAML limits, manifest corruption

## Questions for Review

1. **Does the addressing tooling design match monofolk's usage patterns?** Especially `_address-parse` functions, `dispatch-create` frontmatter, and the computed sender identity.

2. **Settings.json hooks replacement** — is replacing hooks wholesale acceptable? User customizations would be lost. Our mitigation: users add custom hooks via sandbox.

3. **Agency.yaml migration** — do the three detected formats cover all monofolk configs? Any edge cases we're missing?

4. **Any architectural concerns?** Especially around the manifest-driven update flow, the YAML parsing approach in bash, or the migration safety strategy.

5. **Anything from monofolk's operational experience** that should shape the implementation plan?
