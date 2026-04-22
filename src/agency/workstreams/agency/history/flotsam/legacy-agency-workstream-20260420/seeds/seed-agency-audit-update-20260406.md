---
type: seed
date: 2026-04-06
from: the-agency/jordan/captain
subject: "agency-audit + agency-update — structure validation and framework maintenance"
---

# Agency Audit + Update Seed

## Why Now

As agents and workstreams multiply, the repo structure drifts. Today's example: the identity bug created `usr/jordan/valueflow-pvr-20260406/` — a garbage directory that shouldn't exist. No tool caught it. No tool can catch it, because the canonical structure exists only as prose in CLAUDE-THEAGENCY.md.

## What's Needed

### 1. `structure.yaml` — Machine-readable canonical layout

Single source of truth for the repo structure. Defines:
- Required directories and their purpose
- Naming patterns (kebab-case, `{agent}-handoff.md`, etc.)
- Required files per directory type
- Optional vs mandatory structure elements

From this one file, generate:
- The tree diagram in CLAUDE-THEAGENCY.md
- The validation rules for agency-audit
- The scaffolding templates for agency-init

### 2. `agency-audit` — Structure validation tool

Runs before and after agency-update. Also runs standalone for health checks.

**Pre-update audit (blocking):**
- Does the structure match `structure.yaml`?
- Are there orphaned directories? (e.g., `usr/jordan/valueflow-pvr-20260406/`)
- Do agent registrations match worktrees?
- Do handoff files use `{agent}-handoff.md` convention?
- Are `.agency-agent` files present in all worktrees?
- Are there naming violations?
- Report findings, block update until clean.

**Post-update audit (reporting):**
- Did the update produce a valid structure?
- Were any files unexpectedly modified?
- Are all required files present?

### 3. `agency-update` — Framework update tool (already exists, needs hardening)

Existing tool at `claude/tools/agency-update`. Needs:
- Pre-flight audit (calls agency-audit, blocks on failure)
- Post-update audit (calls agency-audit, reports findings)
- Integration with `structure.yaml` for scaffolding decisions

## Relationship to Other Work

- **Valueflow** — agency-audit is enforcement infrastructure. Part of the enforcement ladder.
- **DevEx** — audit could be part of the pre-commit hook (lightweight structural checks).
- **Agency-init** — uses `structure.yaml` to scaffold new repos.
- **All agents** — audit catches structural drift before it causes bugs.

## Near-Term Priority

Spin up as a project within the agency workstream once the valueflow PVR is through MAR. Captain manages, may warrant a dedicated agent or DevEx handles it.
