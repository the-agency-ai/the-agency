# Dispatch: Agency Init & Update Design

**From:** captain (the-agency)
**To:** monofolk/captain
**Date:** 2026-03-31
**Priority:** HIGH
**Status:** Finalized — ready for incorporation

---

## Summary

The agency-init and agency-update tools have been redesigned. This dispatch contains the finalized design decisions that monofolk/captain needs to incorporate into CLAUDE.md, README work, and downstream tooling.

**Full design document:** `claude/workstreams/agency/seeds/agency-init-design-20260331.md`

---

## Key Decisions

### 1. Single Namespace: Everything Under `claude/`

All Agency-related directories live under `claude/`. One top-level directory in the target repo.

```
my-project/
├── README.md
├── CLAUDE.md
├── .claude/              # Claude Code (settings, commands, skills, worktrees)
└── claude/               # Agency — single namespace
    ├── agents/           # agent CLASS definitions
    ├── config/           # agency.yaml, manifest.json, settings-template.json
    ├── docs/             # framework documentation
    ├── hooks/            # Claude Code hooks
    ├── hookify/          # behavioral rules
    ├── templates/        # scaffolding templates
    ├── tools/            # all tools (bash, python, rust, compiled)
    ├── usr/              # agent INSTANCES (per-principal)
    │   └── {principal}/
    │       └── captain/  # instance with handoff, dispatches, transcripts
    ├── workstreams/      # bodies of work
    │   └── ops/          # default workstream
    └── src/              # --dev only (source code, tests)
```

**Rationale:** Good neighbor in someone else's repo. No top-level pollution. No breaking change from current `claude/workstreams/` layout.

### 2. Three File Tiers

| Tier | On init | On update |
|------|---------|-----------|
| **framework** | Copy | Always overwrite |
| **config** | Copy | Overwrite if untouched, skip if user-modified |
| **scaffold** | Generate | Never touch |

Tier assigned by directory pattern. More specific patterns win (e.g., `claude/usr/**` scaffold beats `claude/*/CLAUDE.md` framework).

### 3. Init Preconditions

- **Bare repo:** `git init` → `claude init` → `agency-init`
- **Existing repo:** `claude init` (if needed) → `agency-init`
- agency-init validates git exists, does not create it.

### 4. Settings Merge

`.claude/settings.json` is scaffold (never overwritten). New tools/hooks delivered via:
- `claude/config/settings-template.json` — framework tier, always current
- `./claude/tools/settings-merge` — diffs template against current settings, adds missing entries
- Fallback: if JSON malformed, prints exact fragments for manual paste

### 5. Git Is the Rollback

Updates don't auto-commit. `git checkout -- claude/` undoes any botched update. `agency-update --dry-run` previews changes without writing.

### 6. Trust Model

- **v1:** Trust the source (local filesystem path). Same as Rails/gstack.
- **Public release:** Signed checksums or GPG-signed manifests. Deferred.

### 7. KNOWLEDGE.md → CLAUDE.md

KNOWLEDGE.md replaced by CLAUDE.md everywhere. Every directory gets README.md (humans) + CLAUDE.md (agents). agency-update warns about orphaned KNOWLEDGE.md files.

### 8. agency-service Deprecated

All 10 embedded services killed or deferred. File-based dispatches are the interim ISCP. `test-run` + bats replaces test-service. `secret-vault` replaces secret-service. JSONL telemetry replaces log-service.

---

## Action Items for monofolk/captain

1. **Update CLAUDE.md** to reflect `claude/usr/` and `claude/workstreams/` paths (already correct — confirm no stale references to repo-root `usr/` or `workstreams/`)
2. **Update README** with the bare repo structure shown above
3. **Incorporate settings-merge** into the tooling documentation
4. **Plan KNOWLEDGE.md → CLAUDE.md migration** for existing directories
5. **Note ISS-012** (worktree consolidation) as an open item in the ops workstream

---

## Review History

- **Multi-agent review:** 3 reviewers (design, code, security) — 3 CRITICAL, 7 MAJOR, 8 MINOR findings
- **Principal discussion:** 4 items resolved via 1B1 protocol
- **Revision:** All 18 findings addressed
- **Transcript:** `usr/jordan/captain/transcripts/transcript-agency-init-review-20260331.md`
